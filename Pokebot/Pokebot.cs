using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;

using BizHawk.Client.Common;
using BizHawk.Client.EmuHawk;
using BizHawk.Emulation.Common;

using Wyanido.Pokebot.LuaLibrary;
using Wyanido.Pokebot.Settings;

namespace Wyanido.Pokebot;

[ExternalTool("Pokebot")]
public sealed partial class Pokebot : ToolFormBase, IExternalToolForm
{
    public ApiContainer? _maybeAPIContainer { get; set; }
    public ApiContainer APIs => _maybeAPIContainer!;

    protected override string WindowTitleStatic => "Pokebot";

    private RichTextBox consoleOutput;
    private MenuStrip optionsMenu;
    private ToolStripMenuItem aboutMenu;
    private TabControl tabs;
    private TabPage party;
    private SplitContainer splitContainer2;
    private Panel panel1;
    private TreeView scriptsTree;
    private TabControl tabControl1;
    private TabPage dashboardPage;
    private TabPage scriptPage;
    private Button buttonStop;
    private SplitContainer splitContainer1;
    private Button buttonRun;
    private GameManager gameDetector;
    private GameDefinition? loadedGame;

    private bool wasRunningScripts = false;

    [RequiredService]
    private IEmulator Emulator { get; set; }

    private PokebotLuaLibraries lua;
    private ScriptConfig scriptConfig;

    public Pokebot()
    {
        InitializeComponent();

        Closing += (o, e) => lua?.Close();
    }

    public override void Restart()
    {
        gameDetector = new(APIs);

        LuaFileList newScripts = new(lua?.ScriptList, onChanged: SessionChangedCallback);
        LuaFunctionList registeredFuncList = new(onChanged: UpdateRegisteredFunctionsDialog);
        lua = new PokebotLuaLibraries(newScripts, registeredFuncList, Emulator.ServiceProvider, (MainForm)MainForm, DisplayManager, InputManager, Config, Emulator, Game, consoleOutput);

        loadedGame = gameDetector.DetectGame();
        RefreshScriptsList();

        scriptConfig = ScriptConfig.LoadOrEmpty(ScriptConfig.DefaultConfigPath);
    }

    private void UpdateRegisteredFunctionsDialog()
    {

    }

    private void SessionChangedCallback()
    {
        throw new NotImplementedException();
    }

    private void RefreshScriptsList()
    {
        if (loadedGame == null)
        {
            PokebotLuaLibraries.Print("Couldn't find any scripts, because no game is loaded!");
            return;
        }

        PokebotLuaLibraries.PrintDebug("Searching for available scripts...");
        scriptsTree.Nodes.Clear();

        var scripts = GameManager.GetGameScripts(loadedGame);
        var count = scripts.Count();
        if (count == 0)
        {
            PokebotLuaLibraries.Print($"Couldn't find any .lua scripts for this game! Did you copy the Pokebot/ folder into BizHawk/ExternalTools?");
            return;
        }

        PopulateScriptsTree(scripts);
        PokebotLuaLibraries.PrintDebug($"Found {count} scripts for this game");
    }

    /// <summary>
    /// Adds the scripts to the 'Available Scripts' tree. Paths are displayed relative to the lua/scripts folder.
    /// </summary>
    private void PopulateScriptsTree(List<string> paths)
    {
        var separator = Path.DirectorySeparatorChar;
        TreeNode? lastNode = null;
        string subPathAgg;

        foreach (var absolutePath in paths)
        {
            var path = absolutePath.Replace(PokebotLuaLibraries.ScriptsPath + separator, "");
            subPathAgg = string.Empty;

            foreach (string subPath in path.Split(separator))
            {
                subPathAgg += subPath + separator;
                var nodes = scriptsTree.Nodes.Find(subPathAgg, true);

                if (nodes.Length == 0)
                {
                    if (lastNode == null)
                        lastNode = scriptsTree.Nodes.Add(subPathAgg, subPath); // Root node
                    else
                        lastNode = lastNode.Nodes.Add(subPathAgg, subPath); // Subfolder node

                    lastNode.Tag = new Tuple<string, bool>(absolutePath, true);
                }
                else
                {
                    // Path nodes
                    lastNode = nodes[0];
                    lastNode.ForeColor = SystemColors.GrayText;
                    lastNode.Tag = new Tuple<string, bool>(absolutePath, false);
                }
            }

            lastNode = null;
        }

        scriptsTree.ExpandAll();
    }

    protected override void UpdateBefore()
    {
        lua.CallFrameBeforeEvent();
    }

    protected override void UpdateAfter()
    {
        lua.CallFrameAfterEvent();

        // Update button state
        var scripts = lua.ActiveScripts;

        if (scripts.Count > 0 && !wasRunningScripts)
        {
            wasRunningScripts = true;
            buttonStop.Enabled = true;
            buttonRun.Enabled = false;
        }
        else if (scripts.Count == 0 && wasRunningScripts)
        {
            wasRunningScripts = false;
            buttonStop.Enabled = false;
            buttonRun.Enabled = true;
        }
    }

    protected override void FastUpdateBefore()
    {
        UpdateBefore();
    }

    protected override void FastUpdateAfter()
    {
        UpdateAfter();
    }

    private void buttonStop_Click(object sender, EventArgs e)
    {
        lua.DisableAllScripts();
    }

    private void scriptsTree_AfterSelect(object sender, TreeViewEventArgs e)
    {
        var value = (Tuple<string, bool>)e.Node.Tag;
        var isPathNode = !value.Item2;

        if (isPathNode)
        {
            e.Node.EndEdit(true);
            return;
        }

        var filename = e.Node.Text;
        var absolutePath = value.Item1;

        selectedScript.Text = filename;
        selectedScript.Tag = absolutePath;

        // Evaluate the config properties this script uses
        PokebotLuaLibraries.PrintDebug($"Preloading script {filename} to get config values...");

        GetScriptConfigProperties(absolutePath, (properties) =>
        {
            configPage.SetLayoutFromProperties(properties);

            // Display current config on form, then copy the values back in
            // and save to default any missing properties the script may have.
            configPage.SetFromScriptConfig(ref scriptConfig);
            configPage.CopyToScriptConfig(ref scriptConfig);
            scriptConfig.SaveToFile();
        });
    }

    private void RunDependencyDir(string dir)
    {
        var files = GameManager.GetGameScriptsFromDirectory(loadedGame, dir);

        foreach (var file in files)
            lua.LoadScript(file, true);
    }

    private void LoadGameDependencies()
    {
        if (loadedGame == null)
            throw new Exception("No game is loaded. Couldn't determine which scripts to load.");

        lua.LoadScript(Path.Combine([PokebotLuaLibraries.PokebotDataPath, "core.lua"]), true);

        lua.ExecuteString("_ROM = {}");
        lua.ExecuteString($"_ROM.offset = {loadedGame.MemoryOffset}");
        lua.ExecuteString($"_ROM.version = \"{loadedGame.GameCode}\"");
        lua.ExecuteString($"_ROM.language = \"{loadedGame.LanguageCode}\"");

        RunDependencyDir(Path.Combine(PokebotLuaLibraries.PokebotDataPath, "modules"));
        RunDependencyDir(Path.Combine(PokebotLuaLibraries.PokebotDataPath, "constants"));
        RunDependencyDir(Path.Combine(PokebotLuaLibraries.PokebotDataPath, "methods"));
    }

    private bool TryLoadGameDependencies()
    {
        PokebotLuaLibraries.PrintDebug("Loading script dependencies...");

        try
        {
            LoadGameDependencies();
            PokebotLuaLibraries.PrintDebug("Done!...");
        }
        catch (Exception ex)
        {
            PokebotLuaLibraries.PrintError($"One or more dependencies of the script failed to load: {ex}");
            return false;
        }

        return true;
    }

    private void GetScriptConfigProperties(string file, Action<ConfigFormProperty[]> callback)
    {
        lua.RemoveAllScripts();
        lua.ExecuteString("_CONFIG = {}");

        if (!TryLoadGameDependencies())
            return;

        // Load keys required by this script's dependencies
        var generalKeys = lua.GetTableDict("_CONFIG");
        var script = lua.LoadScript(file, true);

        Action<LuaFile> evalProperties = null;

        evalProperties = (LuaFile luaFile) =>
        {
            if (luaFile != script)
                return;

            lua.OnExit -= evalProperties;

            var scriptKeys = lua.GetTableDict("_CONFIG");
            var properties = new List<ConfigFormProperty>();

            properties = [.. scriptKeys.Select((p) => {
                var key = p.Key.ToString();
                var type = p.Value.GetType();
                var defaultValue = p.Value;

                return new ConfigFormProperty(key, type, defaultValue);
            })];

            callback.Invoke([.. properties]);
        };

        lua.OnExit += evalProperties;
    }

    private void runScript_Click(object sender, EventArgs e)
    {
        var mainPath = Path.Combine([PokebotLuaLibraries.PokebotDataPath, "main.lua"]);
        lua.LoadScript(mainPath, true);
    }

    private void openFolder_Click(object sender, EventArgs e)
    {

    }

    private void clearConsole_Click(object sender, EventArgs e)
    {
        PokebotLuaLibraries.Clear();
    }

    private void button1_Click(object sender, EventArgs e)
    {
        RefreshScriptsList();
    }

    private void SubmitConsoleCommand()
    {
        var command = consoleInput.Text;

        try
        {
            var result = lua.ExecuteString(command);
            PokebotLuaLibraries.Print(result);
        }
        catch (Exception ex)
        {
            PokebotLuaLibraries.PrintError(ex);
        }

        consoleInput.Text = "";
    }

    private void consoleInput_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.KeyCode == Keys.Enter)
        {
            SubmitConsoleCommand();
            e.Handled = true;
            e.SuppressKeyPress = true;
        }
    }

    private void button2_Click(object sender, EventArgs e)
    {
        SubmitConsoleCommand();
    }

    private void clearLuaConsoleToolStripMenuItem_Click(object sender, EventArgs e)
    {
        PokebotLuaLibraries.Clear();
    }

    private void openFolderToolStripMenuItem_Click(object sender, EventArgs e)
    {
        try
        {
            Process.Start(PokebotLuaLibraries.ScriptsPath);
        }
        catch (Exception ex)
        {
            PokebotLuaLibraries.PrintError($"Couldn't open the folder at {PokebotLuaLibraries.ScriptsPath}: {ex}");
        }
    }

    private void saveConfigChanges_Click(object sender, EventArgs e)
    {
        // Update the config values from the form and write to disk
        configPage.CopyToScriptConfig(ref scriptConfig);
        scriptConfig.SaveToFile(ScriptConfig.DefaultConfigPath);
    }

    private void resetConfig_Click(object sender, EventArgs e)
    {
        // Reset the config form back to the last saved state
        configPage.SetFromScriptConfig(ref scriptConfig);
    }

    private void openFolderToolStripMenuItem1_Click(object sender, EventArgs e)
    {
        try
        {
            Process.Start(PokebotLuaLibraries.PokebotDataPath);
        }
        catch (Exception ex)
        {
            PokebotLuaLibraries.PrintError($"Couldn't open the folder at {PokebotLuaLibraries.ScriptsPath}: {ex}");
        }
    }
}