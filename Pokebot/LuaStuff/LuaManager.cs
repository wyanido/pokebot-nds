using BizHawk.Client.Common;
using BizHawk.Client.EmuHawk;
using BizHawk.Emulation.Common;

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Windows.Forms;

namespace Wyanido.Pokebot.LuaStuff
{
    public class LuaManager
    {
        public PokebotLuaManager LuaLibraries { get; private set; }

        private IEmulator Emulator;

        private void DetachRegisteredFunctions(LuaFile lf)
        {
            foreach (var nlf in LuaLibraries.RegisteredFunctions.Where(f => f.LuaFile == lf).ToList())
                nlf.DetachFromScript();
        }

        public void Close() => LuaLibraries?.Close();

        public void UpdateBefore()
        {
            if (LuaLibraries.IsUpdateSupressed)
                return;

            LuaLibraries.CallFrameBeforeEvent();
        }

        public void UpdateAfter()
        {
            if (LuaLibraries.IsUpdateSupressed)
                return;

            LuaLibraries.CallFrameAfterEvent();
            ResumeScripts(true);
        }

        public List<LuaFile> GetRunningScripts()
        {
            if (LuaLibraries == null)
                return [];
            else
                return [.. LuaLibraries.ScriptList.Where(lf => lf.Enabled)];
        }

        public void Restart(IEmulator emulator, Config? config, IGameInfo game, IMainFormForTools mainForm, DisplayManagerBase displayManager, InputManager inputManager, RichTextBox outputBox)
        {
            var runningScripts = GetRunningScripts();

            Emulator = emulator;

            // Things we need to do with the existing LuaImp before we can make a new one
            if (LuaLibraries is not null)
            {
                if (LuaLibraries.IsRebootingCore)
                {
                    // Even if the lua console is self-rebooting from client.reboot_core() we still want to re-inject dependencies
                    LuaLibraries.Restart(Emulator.ServiceProvider, config, Emulator, game);
                    return;
                }

                StopAllScripts();
            }

            LuaFileList newScripts = new(LuaLibraries?.ScriptList, onChanged: SessionChangedCallback);
            LuaFunctionList registeredFuncList = new(onChanged: UpdateRegisteredFunctionsDialog);

            LuaLibraries?.Close();
            LuaLibraries = new PokebotLuaManager(
                newScripts,
                registeredFuncList,
                Emulator.ServiceProvider,
                (MainForm)mainForm,
                displayManager,
                inputManager,
                config,
                Emulator,
                game,
                outputBox);

            foreach (var file in runningScripts)
            {
                RunScript(file, () =>
                {
                    PokebotLuaManager.PrintDebug($"Resumed script {file}");
                }, (ex) =>
                {
                    PokebotLuaManager.PrintError($"Failed to resume script {file}: {ex}");
                });
            }
        }

        /// <summary>
        /// resumes suspended Co-routines
        /// </summary>
        /// <param name="includeFrameWaiters">should frame waiters be waken up? only use this immediately before a frame of emulation</param>
        public void ResumeScripts(bool includeFrameWaiters)
        {
            if (LuaLibraries.ScriptList.Count is 0
                || LuaLibraries.IsUpdateSupressed)
            {
                return;
            }

            foreach (var lf in LuaLibraries.ScriptList.Where(static lf => lf.State is LuaFile.RunState.Running && lf.Thread is not null).ToList())
            {
                try
                {
                    LuaSandbox.Sandbox(lf.Thread, () =>
                    {
                        var prohibit = lf.FrameWaiting && !includeFrameWaiters;

                        if (!prohibit)
                        {
                            var (waitForFrame, terminated) = LuaLibraries.ResumeScript(lf);

                            if (terminated)
                            {
                                LuaLibraries.CallExitEvent(lf);
                                lf.Stop();
                                DetachRegisteredFunctions(lf);
                            }

                            lf.FrameWaiting = waitForFrame;
                        }
                    }, () =>
                    {
                        lf.Stop();
                        DetachRegisteredFunctions(lf);
                    });
                }
                catch (Exception ex)
                {
                    PokebotLuaManager.PrintError(ex);
                }
            }
        }

        private void UpdateRegisteredFunctionsDialog()
        {
            PokebotLuaManager.PrintDebug("Registered functions updated");
        }

        private void SessionChangedCallback()
        {
            PokebotLuaManager.PrintDebug("Lua session changed");
        }

        /// <summary>
        /// Loads a Lua script from a file and adds it to the scripts list.
        /// </summary>
        public LuaFile AddScript(string path)
        {
            if (!File.Exists(path))
                throw new IOException($"Couldn't find the Lua file at {path}");

            var luaFile = new LuaFile("", path)
            { State = LuaFile.RunState.Disabled };

            LuaLibraries.ScriptList.Add(luaFile);

            return luaFile;
        }

        /// <summary>
        /// Stops an active Lua script.
        /// </summary>
        public void StopScript(LuaFile file) => LuaLibraries?.StopScript(file);

        /// <summary>
        /// Stops all active Lua scripts.
        /// </summary>
        public void StopAllScripts()
        {
            foreach (var file in LuaLibraries.ScriptList)
                StopScript(file);
        }

        /// <summary>
        /// Runs a Lua file directly without adding it to the scripts list.
        /// </summary>
        public void RunScript(string path, Action? callback = null, Action<Exception>? exceptionCallback = null)
        {
            if (!File.Exists(path))
            {
                exceptionCallback?.Invoke(new IOException($"Couldn't find the Lua file at {path}"));
                return;
            }

            var file = new LuaFile("", path)
            { State = LuaFile.RunState.Disabled };

            RunScript(file, callback, exceptionCallback);
        }

        /// <summary>
        /// Runs a previously loaded Lua script.
        /// </summary>
        public void RunScript(LuaFile file, Action? callback = null, Action<Exception>? exceptionCallback = null)
        {
            if (!File.Exists(file.Path))
            {
                exceptionCallback?.Invoke(new IOException($"Couldn't find the file at {file.Path}"));
                return;
            }

            try
            {
                LuaSandbox.Sandbox(file.Thread, () =>
                {
                    LuaLibraries.SpawnAndSetFileThread(file.Path, file);
                    LuaSandbox.CreateSandbox(file.Thread, Path.GetDirectoryName(file.Path));

                    file.State = LuaFile.RunState.Running;
                    callback?.Invoke();
                },
                () => file.State = LuaFile.RunState.Disabled);
            }
            catch (IOException ex)
            {
                file.State = LuaFile.RunState.Disabled;
                exceptionCallback?.Invoke(ex);
            }
            catch (Exception ex)
            {
                file.State = LuaFile.RunState.Disabled;
                exceptionCallback?.Invoke(ex);
            }
        }
    }
}
