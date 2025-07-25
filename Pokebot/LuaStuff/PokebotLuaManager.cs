using BizHawk.Client.Common;
using BizHawk.Client.EmuHawk;
using BizHawk.Common;
using BizHawk.Common.PathExtensions;
using BizHawk.Emulation.Common;
using NLua;
using NLua.Native;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading;
using System.Windows.Forms;

namespace Wyanido.Pokebot.LuaStuff
{
    public class PokebotLuaManager : ILuaLibraries
    {
        public static string PokebotLuaPath => Path.Combine([PathUtils.DataDirectoryPath, "ExternalTools", "lua"]);
        public static string ScriptsPath => Path.Combine([PokebotLuaPath, "scripts"]);
        public static PokebotLuaManager Instance { set; get; }

        public string EngineName => "NLua+Lua";

        public Action<string> OnExit;

        public bool FrameAdvanceRequested { get; private set; }
        public bool IsRebootingCore { get; set; }
        public bool IsUpdateSupressed { get; set; }
        public bool IsInInputOrMemoryCallback { get; set; }
        public PathEntryCollection PathEntries { get; private set; }

        public LuaFunctionList RegisteredFunctions { get; }
        public LuaFileList ScriptList { get; }
        public LuaDocumentation Docs { get; } = [];

        public NLuaTableHelper GetTableHelper() => tableHelper;

        public static readonly bool LuaMethodsLoaded = LuaNativeMethodLoader.EnsureNativeMethodsLoaded();

        private ApiContainer apiContainer;

        private readonly DisplayManagerBase displayManager;
        private readonly InputManager inputManager;
        private readonly MainForm mainForm;
        private readonly IEmulator emulator;
        private readonly NLuaTableHelper tableHelper;

        private Lua lua = new();
        private LuaThread currentThread;

        private PokebotConsoleLibrary? PokebotConsole => Libraries.ContainsKey(typeof(PokebotConsoleLibrary)) ? (PokebotConsoleLibrary)Libraries[typeof(PokebotConsoleLibrary)] : null;
        private FormsLuaLibrary FormsLibrary => (FormsLuaLibrary)Libraries[typeof(FormsLuaLibrary)];
        private EmulationLuaLibrary EmulationLuaLibrary => (EmulationLuaLibrary)Libraries[typeof(EmulationLuaLibrary)];
        private readonly IDictionary<Type, LuaLibraryBase> Libraries = new Dictionary<Type, LuaLibraryBase>();
        private EventWaitHandle LuaWait;

        public PokebotLuaManager(LuaFileList scriptList, LuaFunctionList registeredFuncList, IEmulatorServiceProvider serviceProvider, MainForm mainForm, DisplayManagerBase displayManager, InputManager inputManager, Config config, IEmulator emulator, IGameInfo game, RichTextBox outputBox)
        {
            if (!LuaMethodsLoaded)
                throw new InvalidOperationException("The Lua dynamic library was not able to be loaded");

            Instance = this;

            this.displayManager = displayManager;
            this.inputManager = inputManager;
            this.mainForm = mainForm;
            this.emulator = emulator;

            tableHelper = new NLuaTableHelper(lua, LogToLuaConsole);
            LuaWait = new AutoResetEvent(false);
            PathEntries = config.PathEntries;
            RegisteredFunctions = registeredFuncList;
            ScriptList = scriptList;
            apiContainer = ApiManager.RestartLua(serviceProvider, LogToLuaConsole, this.mainForm, this.displayManager, this.inputManager, this.mainForm.MovieSession, this.mainForm.Tools, config, emulator, game);

            LuaSandbox.DefaultLogger = (message) => PrintError(message);

            RegisterLibraryMethods(serviceProvider);
            SetPlatformPackagePath();
            PokebotConsole.OutputBox = outputBox;

            EmulationLuaLibrary.FrameAdvanceCallback = FrameAdvance;
            EmulationLuaLibrary.YieldCallback = EmuYield;
        }

        /// <summary>
        /// Registers every known public library to the current Lua instance.
        /// </summary>
        private void RegisterLibraryMethods(IEmulatorServiceProvider serviceProvider)
        {
            var libraries = BizHawk.Client.Common.ReflectionCache.Types.Concat(BizHawk.Client.EmuHawk.ReflectionCache.Types)
                .Where(static t => typeof(LuaLibraryBase).IsAssignableFrom(t) && t.IsSealed);

            foreach (var lib in libraries)
            {
                var isLibReleased = lib.GetCustomAttribute<LuaLibraryAttribute>(inherit: false)?.Released is not false;

                if (!isLibReleased && !VersionInfo.DeveloperBuild) // Skip unreleased libs
                    continue;

                try
                {
                    RegisterLibrary(lib, serviceProvider);
                }
                catch (Exception ex)
                {
                    PrintDebug(ex);
                }
            }

            RegisterLibrary(typeof(PokebotConsoleLibrary), serviceProvider);

            lua.RegisterFunction("print", this, typeof(PokebotLuaManager).GetMethod(nameof(Print)));
        }

        /// <summary>
        /// Registers every public method of the given Library to the current Lua instance.
        /// </summary>
        private LuaLibraryBase RegisterLibrary(Type library, IEmulatorServiceProvider serviceProvider)
        {
            if (!ServiceInjector.IsAvailable(serviceProvider, library) ||
                !ServiceInjector.UpdateServices(serviceProvider, library, mayCache: true))
                throw new Exception($"Library {library} has required service(s) that can't be fulfilled. It will not be loaded.");

            if (Activator.CreateInstance(library, this, apiContainer, (Action<string>)LogToLuaConsole) is not LuaLibraryBase instance)
                throw new Exception($"Failed to create instance of library {library}. It will not be loaded.");

            var tableName = instance.Name;

            lua.NewTable(tableName);

            // Register public methods that are annotated with [LuaMethod()]
            foreach (var method in library.GetMethods())
            {
                var attributes = (LuaMethodAttribute[])method.GetCustomAttributes(typeof(LuaMethodAttribute), false);
                if (attributes.Length == 0) continue;

                var methodName = attributes[0].Name;

                lua.RegisterFunction($"{tableName}.{methodName}", instance, method);
            }

            // Assign hardcoded references to lib instance
            if (instance is ClientLuaLibrary clientLib)
            {
                clientLib.MainForm = mainForm;
            }
            else if (instance is FormsLuaLibrary formsLib)
            {
                formsLib.MainForm = mainForm;
            }
            else if (instance is GuiLuaLibrary guiLib)
            {
                // emu lib may be null now, depending on order of ReflectionCache.Types, but definitely won't be null when this is called
                guiLib.CreateLuaCanvasCallback = (width, height, x, y) =>
                {
                    var canvas = new LuaCanvas(EmulationLuaLibrary, width, height, x, y, tableHelper, LogToLuaConsole);
                    canvas.Show();

                    return tableHelper.ObjectToTable(canvas);
                };
            }
            else if (instance is TAStudioLuaLibrary tastudioLib)
            {
                tastudioLib.Tools = mainForm.Tools;
            }

            Libraries.Add(library, instance);
            PrintDebug($"Registered library {library}");

            return instance;
        }

        public LuaTable GetTable(string path) => lua.GetTable(path);

        public Dictionary<object, object> GetDict(string path)
        {
            var table = GetTable(path);
            return lua.GetTableDict(table);
        }

        /// <summary>
        /// Sets the package path in the Lua environment based on the host OS.
        /// </summary>
        private void SetPlatformPackagePath()
        {
            var packageTable = (LuaTable)lua["package"];
            var luaPath = PathEntries.LuaAbsolutePath();

            if (OSTailoredCode.IsUnixHost)
            {
                // add %exe%/Lua to library resolution pathset (LUA_PATH)
                // this is done already on windows, but not on linux it seems?
                packageTable["path"] = $"{luaPath}/?.lua;{luaPath}?/init.lua;{packageTable["path"]}";
                // we need to modifiy the cpath so it looks at our lua dir too, and remove the relative pathing
                // we do this on Windows too, but keep in mind Linux uses .so and Windows use .dll
                // TODO: Does the relative pathing issue Windows has also affect Linux? I'd assume so...
                packageTable["cpath"] = $"{luaPath}/?.so;{luaPath}/loadall.so;{packageTable["cpath"]}";
                packageTable["cpath"] = ((string)packageTable["cpath"]).Replace(";./?.so", "");
            }
            else
            {
                packageTable["cpath"] = $"{luaPath}\\?.dll;{luaPath}\\loadall.dll;{packageTable["cpath"]}";
                packageTable["cpath"] = ((string)packageTable["cpath"]).Replace(";.\\?.dll", "");
            }
        }

        /// <summary>
        /// Updates the API references for each Lua library.
        /// </summary>
        public void Restart(IEmulatorServiceProvider newServiceProvider, Config config, IEmulator emulator, IGameInfo game)
        {
            apiContainer = ApiManager.RestartLua(newServiceProvider, LogToLuaConsole, mainForm, displayManager, inputManager, mainForm.MovieSession, mainForm.Tools, config, emulator, game);
            PathEntries = config.PathEntries;

            foreach (var lib in Libraries.Values)
            {
                lib.APIs = apiContainer;

                if (!ServiceInjector.UpdateServices(newServiceProvider, lib, mayCache: true))
                    throw new Exception("Lua lib has required service(s) that can't be fulfilled");

                lib.Restarted();
            }
        }

        public void CallSaveStateEvent(string name)
        {
            try
            {
                foreach (var lf in RegisteredFunctions.Where(static l => l.Event == NamedLuaFunction.EVENT_TYPE_SAVESTATE))
                {
                    lf.Call(name);
                }
            }
            catch (Exception e)
            {
                LogToLuaConsole($"error running function attached by lua function event.onsavestate\nError message: {e.Message}");
            }
        }

        public void CallLoadStateEvent(string name)
        {
            try
            {
                foreach (var lf in RegisteredFunctions.Where(static l => l.Event == NamedLuaFunction.EVENT_TYPE_LOADSTATE))
                {
                    lf.Call(name);
                }
            }
            catch (Exception e)
            {
                LogToLuaConsole($"error running function attached by lua function event.onloadstate\nError message: {e.Message}");
            }
        }

        public void CallFrameBeforeEvent()
        {
            if (IsUpdateSupressed) return;

            try
            {
                foreach (var lf in RegisteredFunctions.Where(static l => l.Event == NamedLuaFunction.EVENT_TYPE_PREFRAME))
                {
                    lf.Call();
                }
            }
            catch (Exception e)
            {
                LogToLuaConsole($"error running function attached by lua function event.onframestart\nError message: {e.Message}");
            }
        }

        public void CallFrameAfterEvent()
        {
            if (IsUpdateSupressed) return;

            try
            {
                foreach (var lf in RegisteredFunctions.Where(static l => l.Event == NamedLuaFunction.EVENT_TYPE_POSTFRAME))
                {
                    lf.Call();
                }
            }
            catch (Exception e)
            {
                LogToLuaConsole($"error running function attached by lua function event.onframeend\nError message: {e.Message}");
            }
        }

        public void CallExitEvent(LuaFile lf)
        {
            foreach (var exitCallback in RegisteredFunctions
                .Where(l => l.Event == NamedLuaFunction.EVENT_TYPE_ENGINESTOP
                    && (l.LuaFile.Path == lf.Path || ReferenceEquals(l.LuaFile.Thread, lf.Thread)))
                .ToList())
            {
                exitCallback.Call();
            }

            OnExit?.Invoke(lf.Path);
        }

        public void CallCloseEvent(LuaFile lf)
        {
            foreach (var closeCallback in RegisteredFunctions
                .Where(l => l.Event == NamedLuaFunction.EVENT_TYPE_CONSOLECLOSE
                    && (l.LuaFile.Path == lf.Path || ReferenceEquals(l.LuaFile.Thread, lf.Thread)))
                .ToList())
            {
                closeCallback.Call();
            }
        }

        public void Close()
        {
            foreach (var script in ScriptList)
                CallCloseEvent(script);

            RegisteredFunctions.Clear(mainForm.Emulator);
            ScriptList.Clear();
            FormsLibrary.DestroyAll();
            lua.Dispose();
            lua = null;
        }

        public INamedLuaFunction CreateAndRegisterNamedFunction(
            LuaFunction function,
            string theEvent,
            Action<string> logCallback,
            LuaFile luaFile,
            string name = null)
        {
            var nlf = new NamedLuaFunction(function, theEvent, logCallback, luaFile, () => lua.NewThread(), this, name);
            RegisteredFunctions.Add(nlf);
            return nlf;
        }

        public bool RemoveNamedFunctionMatching(Func<INamedLuaFunction, bool> predicate)
        {
            var nlf = (NamedLuaFunction)RegisteredFunctions.FirstOrDefault(predicate);
            if (nlf == null) return false;
            RegisteredFunctions.Remove(nlf, mainForm.Emulator);
            return true;
        }

        public LuaThread SpawnCoroutine(string file)
        {
            var content = File.ReadAllText(file);
            var main = lua.LoadString(content, "main");
            return lua.NewThread(main);
        }

        public void SpawnAndSetFileThread(string filePath, LuaFile lf)
        {
            lf.Thread = SpawnCoroutine(filePath);
        }

        public object[] RunScriptPersistent(string file)
        {
            var function = lua.LoadFile(file);
            return function.Call();
        }

        /// <summary>
        /// Runs the provided string as a Lua command in the global context so
        /// that any values set will persist in the current environment.
        /// </summary>
        public object[] RunStringPersistent(string command)
        {
            const string ChunkName = "input"; // shows up in error messages

            // Use LoadString to separate parsing and execution, to tell syntax errors and runtime errors apart
            LuaFunction func;

            try
            {
                // Adding a return is necessary to get out return values of functions and turn expressions ("1+1" etc.) into valid statements
                func = lua.LoadString($"return {command}", ChunkName);
            }
            catch (Exception)
            {
                var result = lua.DoString(command, ChunkName);
                return result;
            }

            try
            {
                using (func)
                {
                    var result = func.Call();

                    if (result is not ([] or [null]))
                        return result;
                }
            }
            catch (Exception ex)
            {
                PrintError(ex);
            }

            return null;
        }

        public void StopScript(LuaFile file)
        {
            if (file.IsSeparator) return;

            file.State = LuaFile.RunState.Disabled;

            if (file.Thread is not null)
            {
                CallExitEvent(file);
                RegisteredFunctions.RemoveForFile(file, emulator);
                file.Stop();
            }
        }

        public (bool WaitForFrame, bool Terminated) ResumeScript(LuaFile lf)
        {
            currentThread = lf.Thread;

            try
            {
                LuaLibraryBase.SetCurrentThread(lf);

                var execResult = currentThread.Resume();

                currentThread = null;
                var result = execResult switch
                {
                    LuaStatus.OK => (WaitForFrame: false, Terminated: true),
                    LuaStatus.Yield => (WaitForFrame: FrameAdvanceRequested, Terminated: false),
                    _ => throw new InvalidOperationException($"{nameof(currentThread.Resume)}() returned {execResult}?"),
                };

                FrameAdvanceRequested = false;
                return result;
            }
            finally
            {
                LuaLibraryBase.ClearCurrentThread();
            }
        }

        public static void Clear() => Instance?.PokebotConsole?.Clear();

        public static void Print(params object[] outputs) => Instance?.PokebotConsole?.Log(outputs);

        public static void PrintDebug(params object[] outputs) => Instance?.PokebotConsole?.LogDebug(outputs);

        public static void PrintError(params object[] outputs) => Instance?.PokebotConsole?.LogError(outputs);

        private static void LogToLuaConsole(object outputs) => Instance?.PokebotConsole?.Log(outputs);

        private void FrameAdvance()
        {
            FrameAdvanceRequested = true;
            currentThread.Yield();
        }

        private void EmuYield()
        {
            currentThread.Yield();
        }

        public object[] ExecuteString(string command) => RunStringPersistent(command);
    }
}
