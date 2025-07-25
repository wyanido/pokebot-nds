using BizHawk.Client.Common;
using BizHawk.Client.EmuHawk;
using BizHawk.Emulation.Common;

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using Wyanido.Pokebot.LuaStuff;

namespace Wyanido.Pokebot;

[ExternalTool("Pokebot")]
public sealed partial class Pokebot : ToolFormBase, IExternalToolForm
{
    public ApiContainer? _maybeAPIContainer { get; set; }
    public ApiContainer APIs => _maybeAPIContainer!;

    protected override string WindowTitleStatic => "Pokebot";

    private RichTextBox consoleOutput;
    private Label framerateLabel;
    private Label loadedGameLabel;
    private MenuStrip optionsMenu;
    private ToolStripMenuItem aboutMenu;
    private TabControl tabs;
    private TabPage party;
    private SplitContainer splitContainer2;
    private Panel panel1;
    private FlowLayoutPanel headerStatus;
    private TreeView scriptsTree;
    private TabControl tabControl1;
    private TabPage dashboardPage;
    private TabPage scriptPage;
    private Button buttonStop;
    private Button buttonOpenFolder;
    private Button buttonClear;
    private TextBox selectedScripts;
    private SplitContainer splitContainer1;
    private Button buttonRun;
    private TableLayoutPanel scriptActions;
    private GameManager gameDetector;
    private GameDefinition? loadedGame;

    private bool wasRunningScripts = false;

    [RequiredService]
    private IEmulator Emulator { get; set; }

    private readonly LuaManager lua;

    public Pokebot()
    {
        InitializeComponent();
        lua = new LuaManager();

        Closing += (o, e) => lua.Close();
    }

    public override void Restart()
    {
        gameDetector = new(APIs);

        lua.Restart(Emulator, Config, Game, MainForm, DisplayManager, InputManager, consoleOutput);
        UpdateLoadedGame();
        RefreshScriptsList();
    }

    private void RefreshScriptsList()
    {
        if (loadedGame == null)
        {
            PokebotLuaManager.Print("Couldn't find any scripts, because no game is loaded!");
            return;
        }

        PokebotLuaManager.Print("Searching for scripts...");
        scriptsTree.Nodes.Clear();

        var scripts = GameManager.GetGameScripts(loadedGame);
        var count = scripts.Count();
        if (count == 0)
        {
            PokebotLuaManager.Print($"Couldn't find any .lua scripts for this game! Did you copy the lua/ folder into BizHawk/ExternalTools?");
            return;
        }

        PopulateScriptsTree(scripts);
        PokebotLuaManager.Print($"Loaded {count} scripts");
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
            var path = absolutePath.Replace(PokebotLuaManager.ScriptsPath + separator, "");
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

    private void UpdateLoadedGame()
    {
        loadedGame = gameDetector.DetectGame();

        if (loadedGame == null)
        {
            loadedGameLabel.Text = $"no game loaded :(";
            return;
        }

        loadedGameLabel.Text = $"{loadedGame.GameCode} ({loadedGame.LanguageCode})";
        PokebotLuaManager.Print($"Loaded {loadedGame.Title}");
    }

    protected override void UpdateBefore()
    {
        lua.UpdateBefore();
    }

    protected override void UpdateAfter()
    {
        var framerate = APIs.EmuClient.GetApproxFramerate();
        framerateLabel.Text = $"FPS: {framerate}";

        lua.UpdateAfter();

        // Update button state
        var scripts = lua.GetRunningScripts();

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
        lua.StopAllScripts();
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

        selectedScripts.Text = filename;
        selectedScripts.Tag = absolutePath;

        // Evaluate the config properties this script uses
        PokebotLuaManager.PrintDebug($"Preloading script {filename} to get config values...");
        //buttonRun.Enabled = false;

        GetScriptConfigProperties(absolutePath, (properties) =>
        {
            PokebotLuaManager.Print("out");

            foreach (var property in properties)
                PokebotLuaManager.PrintDebug(property.Item1);

            //buttonRun.Enabled = true;
        });
    }

    private void RunDependencyDir(string dir)
    {
        var files = GameManager.GetGameScriptsFromDirectory(loadedGame, dir);

        foreach (var file in files)
            lua.LuaLibraries.RunScriptPersistent(file);
    }

    private void LoadGameDependencies()
    {
        if (loadedGame == null)
            throw new Exception("No game is loaded. Couldn't determine which scripts to load.");

        lua.LuaLibraries.RunScriptPersistent(Path.Combine([PokebotLuaManager.PokebotLuaPath, "core.lua"]));

        lua.LuaLibraries.RunStringPersistent("_ROM = {}");
        lua.LuaLibraries.RunStringPersistent($"_ROM.offset = {loadedGame.MemoryOffset}");
        lua.LuaLibraries.RunStringPersistent($"_ROM.version = \"{loadedGame.GameCode}\"");
        lua.LuaLibraries.RunStringPersistent($"_ROM.language = \"{loadedGame.LanguageCode}\"");

        RunDependencyDir(Path.Combine(PokebotLuaManager.PokebotLuaPath, "modules"));
        RunDependencyDir(Path.Combine(PokebotLuaManager.PokebotLuaPath, "constants"));
        RunDependencyDir(Path.Combine(PokebotLuaManager.PokebotLuaPath, "methods"));
    }

    private bool TryLoadGameDependencies()
    {
        PokebotLuaManager.PrintDebug("Loading script dependencies...");

        try
        {
            LoadGameDependencies();
            PokebotLuaManager.PrintDebug("Done!...");
        }
        catch (Exception ex)
        {
            PokebotLuaManager.PrintError($"One or more dependencies of the script failed to load: {ex}");
            return false;
        }

        return true;
    }

    private void RunGameScript(string file)
    {
        // Run one frame before starting script to let pointers and state update
        lua.LuaLibraries.RunStringPersistent("update_pointers()");
        lua.LuaLibraries.RunStringPersistent("update_game_state()");

        PokebotLuaManager.PrintDebug($"Adding script {file} for execution...");

        var script = lua.AddScript(file);
        lua.RunScript(script);
        lua.LuaLibraries.ExecuteString("main()");
    }

    private void GetScriptConfigProperties(string file, Action<Tuple<string, bool>[]> callback)
    {
        lua.StopAllScripts();

        if (!TryLoadGameDependencies())
            return;

        // Load keys required by this script's dependencies
        var generalKeys = lua.LuaLibraries.GetDict("_CONFIG");
        var script = lua.AddScript(file);
        lua.RunScript(script);

        Action<string> evalProperties = null;

        evalProperties = (string file) =>
        {
            lua.LuaLibraries.OnExit -= evalProperties;

            var scriptKeys = lua.LuaLibraries.GetDict("_CONFIG");
            var properties = new List<Tuple<string, bool>>();

            properties = [.. scriptKeys.Select((p) => {
                var propertyName = p.Key.ToString();
                var isLocalProperty = !generalKeys.Contains(p);

                return new Tuple<string, bool>(propertyName, isLocalProperty);
            })];

            callback.Invoke([.. properties]);
        };

        lua.LuaLibraries.OnExit += evalProperties;
    }

    private void runScript_Click(object sender, EventArgs e)
    {
        var absolutePath = (string)selectedScripts.Tag;
        RunGameScript(absolutePath);
    }

    private void openFolder_Click(object sender, EventArgs e)
    {
        try
        {
            Process.Start(PokebotLuaManager.ScriptsPath);
        }
        catch (Exception ex)
        {
            PokebotLuaManager.PrintError($"Couldn't open the folder at {PokebotLuaManager.ScriptsPath}: {ex}");
        }
    }

    private void clearConsole_Click(object sender, EventArgs e)
    {
        PokebotLuaManager.Clear();
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
            var result = lua.LuaLibraries.RunStringPersistent(command);
            PokebotLuaManager.Print(result);
        }
        catch (Exception ex)
        {
            PokebotLuaManager.PrintError(ex);
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
}