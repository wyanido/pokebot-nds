using BizHawk.Client.Common;
using BizHawk.Client.EmuHawk;
using BizHawk.Common.PathExtensions;
using BizHawk.Emulation.Common;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using Wyanido.Pokebot.Forms;
using Wyanido.Pokebot.Games;

namespace Wyanido.Pokebot;

using LuaLibraries = Lua.LuaLibraries;

[ExternalTool("Pokebot")]
public sealed partial class Pokebot : ToolFormBase, IExternalToolForm
{
    public static string DataPath => Path.Combine([PathUtils.DataDirectoryPath, "ExternalTools", "Pokebot"]);
    public static string ImagesPath => Path.Combine([DataPath, "images"]);

    public static Game? CurrentGame;
    public static ScriptConfig PokebotConfig;

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
    
    private bool wasRunningScripts = false;

    [RequiredService]
    private IEmulator Emulator { get; set; }

    private LuaLibraries lua;
    private bool gameDataPagePopulated = false;

    public Pokebot()
    {
        InitializeComponent();

        buttonRun.Image = Image.FromFile(Path.Combine([ImagesPath, "pokemon", "snivy.png"]));
        buttonStop.Image = Image.FromFile(Path.Combine([ImagesPath, "pokemon", "tepig.png"]));
        buttonRefresh.Image = Image.FromFile(Path.Combine([ImagesPath, "pokemon", "oshawott.png"]));

        Closing += (o, e) => lua?.Close();
    }

    public override void Restart()
    {
        LuaFileList newScripts = new(lua?.ScriptList, onChanged: SessionChangedCallback);
        LuaFunctionList registeredFuncList = new(onChanged: UpdateRegisteredFunctionsDialog);
        lua = new LuaLibraries(newScripts, registeredFuncList, Emulator.ServiceProvider, (MainForm)MainForm, DisplayManager, InputManager, Config, Emulator, Game, consoleOutput);

        CurrentGame = GameDetector.DetectGame(Game);
        RefreshScriptsList();

        if (CurrentGame is not null)
        {
            // Define constants for this game
            // This can be done with a direct object assignment, so improve it later
            lua.ExecuteString("_ROM = {}");
            lua.ExecuteString($"_ROM.offset = {CurrentGame.MemoryOffset}");
            lua.ExecuteString($"_ROM.version = \"{CurrentGame.GameCode}\"");
            lua.ExecuteString($"_ROM.language = \"{CurrentGame.LanguageCode}\"");
            lua.LoadScript(Path.Combine([DataPath, "core.lua"]), true);
        }

        PopulateDataPage();

        PokebotConfig = ScriptConfig.LoadOrEmpty(ScriptConfig.DefaultConfigPath);
    }

    private void UpdateRegisteredFunctionsDialog()
    {
        LuaLibraries.PrintDebug("Registered functions updated");
    }

    private void SessionChangedCallback()
    {
        LuaLibraries.PrintDebug("Session changed");
    }

    /// <summary>
    /// Updates the form's Data tab with info from the currently loaded game.
    /// </summary>
    private void PopulateDataPage()
    {
        abilitiesList.Controls.Clear();
        itemsList.Controls.Clear();
        mapsList.Controls.Clear();
        movesList.Controls.Clear();
        typesList.Controls.Clear();
        speciesList.Controls.Clear();

        // Leave lists empty if no game loaded
        if (CurrentGame is null)
            return;

        // Populate lists with game data
        foreach (var abilityName in CurrentGame.Abilities.List)
            abilitiesList.Items.Add(abilityName);

        foreach (var itemName in CurrentGame.Items.List)
            itemsList.Items.Add(itemName);

        foreach (var mapName in CurrentGame.Maps.List)
            mapsList.Items.Add(mapName);

        foreach (var move in CurrentGame.Moves.List)
            movesList.Items.Add(move.Name);

        foreach (var typeName in CurrentGame.Types)
            typesList.Items.Add(typeName);

        foreach (var species in CurrentGame.Species.List)
            speciesList.Items.Add(species.Name);

        abilitiesList.SelectedIndex = 0;
        itemsList.SelectedIndex = 0;
        mapsList.SelectedIndex = 0;
        movesList.SelectedIndex = 0;
        typesList.SelectedIndex = 0;
        speciesList.SelectedIndex = 0;
    }

    private void RefreshScriptsList()
    {
        if (CurrentGame == null)
        {
            LuaLibraries.Print("Couldn't find any scripts, because no game is loaded!");
            return;
        }

        LuaLibraries.PrintDebug("Searching for available scripts...");
        scriptsTree.Nodes.Clear();

        var scripts = Games.Game.GetGameScripts(CurrentGame);
        var count = scripts.Count();
        if (count == 0)
        {
            LuaLibraries.Print($"Couldn't find any .lua scripts for this game! Did you copy the Pokebot/ folder into BizHawk/ExternalTools?");
            return;
        }

        PopulateScriptsTree(scripts);
        LuaLibraries.PrintDebug($"Found {count} scripts for this game");
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
            var path = absolutePath.Replace(LuaLibraries.ScriptsPath + separator, "");
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
        LuaLibraries.PrintDebug($"Preloading script {filename} to get config values...");

        GetScriptConfigProperties(absolutePath, (properties) =>
        {
            configPage.SetLayoutFromProperties(properties);

            // Display current config on form, then copy the values back in
            // and save to default any missing properties the script may have.
            configPage.SetFromScriptConfig(ref PokebotConfig);
            configPage.CopyToScriptConfig(ref PokebotConfig);
            PokebotConfig.SaveToFile();

            lua.SetObjectToPath("_CONFIG", PokebotConfig.Properties);
        });
    }

    private void RunDependencyDir(string dir)
    {
        var files = Games.Game.GetGameScriptsFromDirectory(CurrentGame, dir);

        foreach (var file in files)
            lua.LoadScript(file, true);
    }

    private void LoadGameDependencies()
    {
        if (CurrentGame == null)
            throw new Exception("No game is loaded. Couldn't determine which scripts to load.");

        RunDependencyDir(Path.Combine(DataPath, "methods"));
    }

    private bool TryLoadGameDependencies()
    {
        LuaLibraries.PrintDebug("Loading script dependencies...");

        try
        {
            LoadGameDependencies();
            LuaLibraries.PrintDebug("Done!...");
        }
        catch (Exception ex)
        {
            LuaLibraries.PrintError($"One or more dependencies of the script failed to load: {ex}");
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
        var mainPath = Path.Combine([DataPath, "main.lua"]);
        lua.LoadScript(mainPath, true);
    }

    private void openFolder_Click(object sender, EventArgs e)
    {

    }

    private void clearConsole_Click(object sender, EventArgs e)
    {
        LuaLibraries.Clear();
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
            LuaLibraries.Print(result);
        }
        catch (Exception ex)
        {
            LuaLibraries.PrintError(ex);
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
        LuaLibraries.Clear();
    }

    private void openFolderToolStripMenuItem_Click(object sender, EventArgs e)
    {
        try
        {
            Process.Start(LuaLibraries.ScriptsPath);
        }
        catch (Exception ex)
        {
            LuaLibraries.PrintError($"Couldn't open the folder at {LuaLibraries.ScriptsPath}: {ex}");
        }
    }

    private void saveConfigChanges_Click(object sender, EventArgs e)
    {
        // Update the config values from the form and write to disk
        configPage.CopyToScriptConfig(ref PokebotConfig);
        PokebotConfig.SaveToFile(ScriptConfig.DefaultConfigPath);
    }

    private void resetConfig_Click(object sender, EventArgs e)
    {
        // Reset the config form back to the last saved state
        configPage.SetFromScriptConfig(ref PokebotConfig);
    }

    private void openFolderToolStripMenuItem1_Click(object sender, EventArgs e)
    {
        try
        {
            Process.Start(DataPath);
        }
        catch (Exception ex)
        {
            LuaLibraries.PrintError($"Couldn't open the folder at {LuaLibraries.ScriptsPath}: {ex}");
        }
    }

    private void tabControl1_TabIndexChanged(object sender, EventArgs e)
    {
        if (tabControl1.SelectedTab == gameDataPage)
        {
            // Only populate data page once per ROM,
            // and only when page is opened to minimise performance impact
            if (gameDataPagePopulated)
                return;

            PopulateDataPage();
            gameDataPagePopulated = true;
        }
    }

    private void flowLayoutPanel1_Paint(object sender, PaintEventArgs e)
    {

    }
}