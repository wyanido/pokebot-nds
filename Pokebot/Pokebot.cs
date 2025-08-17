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
using Wyanido.Pokebot.Forms.Controls;
using Wyanido.Pokebot.Games;
using Wyanido.Pokebot.Games.Data;
using Wyanido.Pokebot.Utils;

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

    protected override string WindowTitleStatic => "Pokebot v1.3-beta";

    private RichTextBox consoleOutput;
    private MenuStrip optionsMenu;
    private ToolStripMenuItem aboutMenu;
    private SplitContainer splitContainer2;
    private Panel panel1;
    private TreeView scriptsTree;
    private TabControl tabControl1;
    private TabPage dashboardPage;
    private TabPage scriptPage;
    private Button buttonStop;
    private SplitContainer splitContainer1;
    private Button buttonRun;
    private DiscordRichPresence rpc;

    private bool wasRunningScripts = false;

    [RequiredService]
    private IEmulator Emulator { get; set; }

    private LuaLibraries lua;
    private bool gameDataPagePopulated = false;

    private int[] lastPartyChecksums = [];

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

        CurrentGame = GameManager.DetectGame(Game, APIs);
        RefreshScriptsList();

        rpc ??= new();

        if (CurrentGame is not null)
        {
            // Define constants for this game
            // This can be done with a direct object assignment, so improve it later
            lua.ExecuteString("_ROM = {}");
            lua.ExecuteString($"_ROM.offset = {CurrentGame.MemoryOffset}");
            lua.ExecuteString($"_ROM.version = \"{CurrentGame.GameCode}\"");
            lua.ExecuteString($"_ROM.language = \"{CurrentGame.LanguageCode}\"");
            lua.LoadScript(Path.Combine([DataPath, "core.lua"]), true);

            rpc.SetState($"{Game.Name}");
        }
        else
        {
            rpc.SetDefaultStatus();
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

        foreach (var typeName in CurrentGame.TypeMatchups.List.Keys.ToArray())
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

        var scripts = GameManager.GetGameScripts(CurrentGame);
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

    /// <summary>
    /// Updates the Dashboard Party display to show the current Party Pokemon while minimising form updates.
    /// </summary>
    private void DisplayCurrentParty()
    {
        const int MaxPartyCount = 6;

        // Display nothing if no game is loaded
        if (CurrentGame is null)
        {
            if (partyTable.Controls.Count > 0)
                partyTable.Controls.Clear();

            return;
        }

        Pokemon?[] party = CurrentGame.GetParty();

        // Display nothing if party is empty
        if (party.Length == 0)
        {
            if (partyTable.Controls.Count > 0)
                partyTable.Controls.Clear();

            return;
        }

        // Get each mon's checksum to compare against last update.
        // If the Pokemon is null because of a checksum fail, try to repeat last update's checksum 
        // to treat it as if the Pokemon is in the same state as it was last frame instead of null.
        int[] partyChecksum = [.. party.Select((x, i) => x?.Checksum ?? (i >= lastPartyChecksums.Length ? 0 : lastPartyChecksums[i]))];

        partyTable.SuspendLayout();

        for (int i = 0; i < MaxPartyCount; i++)
        {
            if (i >= party.Length)
            {
                // Remove displays of Pokemon beyond the party length, as if they were deposited into the PC
                var key = $"Party-{i}";
                partyTable.Controls.RemoveByKey(key);
                continue;
            }

            var pokemon = party[i];

            // Pokemon exists, but the checksum failed. This sometimes happens
            // during gameplay, so it shouldn't be treated as the Pokemon being removed
            // from the party; just keep the current PokemonPanel instead.
            if (pokemon is null)
                continue;

            // Pokemon changed if it was added to the end of the party, or the checksum is valid and different.
            var wasUpdated = i >= lastPartyChecksums.Length || partyChecksum[i] != lastPartyChecksums[i];

            if (wasUpdated)
            {
                // Remove existing display, if any
                string key = $"Party-{i}";
                partyTable.Controls.RemoveByKey(key);

                // Add updated Pokemon state to the corresponding column
                PokemonPanel panel = new();
                panel.DisplayPokemon(pokemon);
                panel.Name = key;
                partyTable.Controls.Add(panel, i, 0);
            }
        }

        partyTable.ResumeLayout();
        lastPartyChecksums = partyChecksum; // Store checksums to compare on next update
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

        if (CurrentGame is not null)
        {
            try
            {
                trainerName.Text = CurrentGame.GetTrainerName();
                trainerId.Text = CurrentGame.GetTrainerId().ToString("05");
                mapHeader.Text = CurrentGame.GetMapName();

                var position = CurrentGame.GetTrainerPosition();
                trainerPosition.Text = $"X: {position.X}, Y: {position.Y}, Z: {position.Z}";

                DisplayCurrentParty();

                //// Display battle state
                //var foe = CurrentGame.GetFoes();

                //if (foe.Length > 0)
                //    currentFoe.DisplayPokemon(foe[0]);
            }
            catch (Exception ex)
            {
                LuaLibraries.PrintError(ex);
            }
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

        GetScriptConfigFields(absolutePath, (properties) =>
        {
            configPage.SetLayoutFromProperties(properties);

            // Display current config on form, then copy the values back in
            // and save to default any missing properties the script may have.
            configPage.SetFromScriptConfig(ref PokebotConfig);
            configPage.CopyToScriptConfig(ref PokebotConfig);
            PokebotConfig.SaveToFile();

            lua.SetObjectToPath("config", PokebotConfig.Properties);
        });
    }

    /// <summary>
    /// Recursively runs lua files in the methods/ folder that correspond to the current game.
    /// </summary>
    private void LoadGameLuaDependencies()
    {
        if (CurrentGame is null)
            throw new Exception("No game is loaded. Couldn't determine which scripts to load.");

        var dir = Path.Combine(DataPath, "methods");
        var scripts = GameManager.GetGameScriptsFromDirectory(CurrentGame, dir);

        lua.LoadScript(Path.Combine([DataPath, "core.lua"]), true);

        foreach (var script in scripts)
            lua.LoadScript(script, true);
    }

    /// <summary>
    /// Runs the given script and all dependencies of the current game to evaluate
    /// the config properties specified by all the scripts by hint_config in lua.
    /// </summary>
    private void GetScriptConfigFields(string file, Action<ConfigFormProperty[]> callback)
    {
        lua.RemoveAllScripts();
        lua.ExecuteString("config = {}");

        // Re-evaluate lua scripts for config hints. This is the only reason to
        // ever reload this core.lua, as otherwise its values don't change.
        LoadGameLuaDependencies();
        var script = lua.LoadScript(file, true);

        // Create a callback for once the main script ends and its fields can be read.
        Action<LuaFile> onExit = null;

        onExit = (LuaFile luaFile) =>
        {
            // Ignore any other scripts that end besides the one specified
            if (luaFile != script)
                return;

            lua.OnExit -= onExit;

            var scriptKeys = lua.GetTableDict("config");
            var properties = new List<ConfigFormProperty>();

            properties = [.. scriptKeys.Select((p) => {
                var key = p.Key.ToString();
                var type = p.Value.GetType();
                var defaultValue = p.Value;

                return new ConfigFormProperty(key, type, defaultValue);
            })];

            // Pass the complete list of config properties to the callback
            callback.Invoke([.. properties]);
        };

        lua.OnExit += onExit;
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
            // Only populate data page once per restart, and only when page is opened to minimise performance impact
            if (gameDataPagePopulated)
                return;

            PopulateDataPage();
            gameDataPagePopulated = true;
        }
    }

    private void flowLayoutPanel1_Paint(object sender, PaintEventArgs e)
    {

    }

    private void Pokebot_Load(object sender, EventArgs e)
    {

    }

    private void aboutMenu_Click(object sender, EventArgs e)
    {
        var aboutForm = new About();
        aboutForm.ShowDialog();
    }
}