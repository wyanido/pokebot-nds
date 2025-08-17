using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Wyanido.Pokebot.Forms.Controls;

namespace Wyanido.Pokebot
{
    public partial class Pokebot
    {
        private void InitializeComponent()
        {
            this.consoleOutput = new System.Windows.Forms.RichTextBox();
            this.optionsMenu = new System.Windows.Forms.MenuStrip();
            this.scriptsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.openFolderToolStripMenuItem1 = new System.Windows.Forms.ToolStripMenuItem();
            this.openFolderToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.consoleToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.clearLuaConsoleToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.aboutMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.partyTable = new System.Windows.Forms.TableLayoutPanel();
            this.splitContainer2 = new System.Windows.Forms.SplitContainer();
            this.groupBox3 = new System.Windows.Forms.GroupBox();
            this.scriptsTree = new System.Windows.Forms.TreeView();
            this.buttonRefresh = new System.Windows.Forms.Button();
            this.tabControl2 = new System.Windows.Forms.TabControl();
            this.tabConsole = new System.Windows.Forms.TabPage();
            this.containerControl2 = new System.Windows.Forms.ContainerControl();
            this.consoleInput = new System.Windows.Forms.TextBox();
            this.button2 = new System.Windows.Forms.Button();
            this.tabScriptConfig = new System.Windows.Forms.TabPage();
            this.containerControl1 = new System.Windows.Forms.ContainerControl();
            this.configPage = new Wyanido.Pokebot.ConfigPage();
            this.tableLayoutPanel2 = new System.Windows.Forms.TableLayoutPanel();
            this.saveConfigChanges = new System.Windows.Forms.Button();
            this.resetConfig = new System.Windows.Forms.Button();
            this.splitContainer1 = new System.Windows.Forms.SplitContainer();
            this.panel1 = new System.Windows.Forms.Panel();
            this.tabControl1 = new System.Windows.Forms.TabControl();
            this.scriptPage = new System.Windows.Forms.TabPage();
            this.dashboardPage = new System.Windows.Forms.TabPage();
            this.splitContainer3 = new System.Windows.Forms.SplitContainer();
            this.groupBox12 = new System.Windows.Forms.GroupBox();
            this.currentFoe = new Wyanido.Pokebot.Forms.Controls.PokemonRow();
            this.splitContainer4 = new System.Windows.Forms.SplitContainer();
            this.groupBox5 = new System.Windows.Forms.GroupBox();
            this.groupBox4 = new System.Windows.Forms.GroupBox();
            this.recentEncountersTable = new System.Windows.Forms.TableLayoutPanel();
            this.pokemonEncounter1 = new Wyanido.Pokebot.Forms.Controls.PokemonRow();
            this.gameDataPage = new System.Windows.Forms.TabPage();
            this.flowLayoutPanel1 = new System.Windows.Forms.FlowLayoutPanel();
            this.groupBox2 = new System.Windows.Forms.GroupBox();
            this.abilitiesList = new System.Windows.Forms.ComboBox();
            this.groupBox8 = new System.Windows.Forms.GroupBox();
            this.movesList = new System.Windows.Forms.ComboBox();
            this.groupBox9 = new System.Windows.Forms.GroupBox();
            this.typesList = new System.Windows.Forms.ComboBox();
            this.groupBox6 = new System.Windows.Forms.GroupBox();
            this.itemsList = new System.Windows.Forms.ComboBox();
            this.groupBox7 = new System.Windows.Forms.GroupBox();
            this.mapsList = new System.Windows.Forms.ComboBox();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.speciesList = new System.Windows.Forms.ComboBox();
            this.partyGroupBox = new System.Windows.Forms.GroupBox();
            this.groupBox10 = new System.Windows.Forms.GroupBox();
            this.trainerName = new System.Windows.Forms.Label();
            this.trainerId = new System.Windows.Forms.Label();
            this.scriptActions = new System.Windows.Forms.TableLayoutPanel();
            this.buttonRun = new System.Windows.Forms.Button();
            this.buttonStop = new System.Windows.Forms.Button();
            this.groupSelectedScript = new System.Windows.Forms.GroupBox();
            this.selectedScript = new System.Windows.Forms.TextBox();
            this.settingsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.tableLayoutPanel1 = new System.Windows.Forms.TableLayoutPanel();
            this.mapHeader = new System.Windows.Forms.Label();
            this.trainerPosition = new System.Windows.Forms.Label();
            this.optionsMenu.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer2)).BeginInit();
            this.splitContainer2.Panel1.SuspendLayout();
            this.splitContainer2.Panel2.SuspendLayout();
            this.splitContainer2.SuspendLayout();
            this.groupBox3.SuspendLayout();
            this.tabControl2.SuspendLayout();
            this.tabConsole.SuspendLayout();
            this.containerControl2.SuspendLayout();
            this.tabScriptConfig.SuspendLayout();
            this.containerControl1.SuspendLayout();
            this.tableLayoutPanel2.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).BeginInit();
            this.splitContainer1.SuspendLayout();
            this.panel1.SuspendLayout();
            this.tabControl1.SuspendLayout();
            this.scriptPage.SuspendLayout();
            this.dashboardPage.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer3)).BeginInit();
            this.splitContainer3.Panel1.SuspendLayout();
            this.splitContainer3.Panel2.SuspendLayout();
            this.splitContainer3.SuspendLayout();
            this.groupBox12.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer4)).BeginInit();
            this.splitContainer4.Panel1.SuspendLayout();
            this.splitContainer4.Panel2.SuspendLayout();
            this.splitContainer4.SuspendLayout();
            this.groupBox4.SuspendLayout();
            this.recentEncountersTable.SuspendLayout();
            this.gameDataPage.SuspendLayout();
            this.flowLayoutPanel1.SuspendLayout();
            this.groupBox2.SuspendLayout();
            this.groupBox8.SuspendLayout();
            this.groupBox9.SuspendLayout();
            this.groupBox6.SuspendLayout();
            this.groupBox7.SuspendLayout();
            this.groupBox1.SuspendLayout();
            this.partyGroupBox.SuspendLayout();
            this.groupBox10.SuspendLayout();
            this.scriptActions.SuspendLayout();
            this.groupSelectedScript.SuspendLayout();
            this.tableLayoutPanel1.SuspendLayout();
            this.SuspendLayout();
            // 
            // consoleOutput
            // 
            this.consoleOutput.Cursor = System.Windows.Forms.Cursors.IBeam;
            this.consoleOutput.Dock = System.Windows.Forms.DockStyle.Fill;
            this.consoleOutput.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.consoleOutput.Location = new System.Drawing.Point(3, 3);
            this.consoleOutput.Name = "consoleOutput";
            this.consoleOutput.ReadOnly = true;
            this.consoleOutput.Size = new System.Drawing.Size(311, 322);
            this.consoleOutput.TabIndex = 1;
            this.consoleOutput.Text = "";
            // 
            // optionsMenu
            // 
            this.optionsMenu.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.scriptsToolStripMenuItem,
            this.settingsToolStripMenuItem,
            this.consoleToolStripMenuItem,
            this.aboutMenu});
            this.optionsMenu.Location = new System.Drawing.Point(8, 8);
            this.optionsMenu.Name = "optionsMenu";
            this.optionsMenu.Size = new System.Drawing.Size(486, 24);
            this.optionsMenu.TabIndex = 5;
            this.optionsMenu.Text = "menuStrip1";
            // 
            // scriptsToolStripMenuItem
            // 
            this.scriptsToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.openFolderToolStripMenuItem1,
            this.openFolderToolStripMenuItem});
            this.scriptsToolStripMenuItem.Name = "scriptsToolStripMenuItem";
            this.scriptsToolStripMenuItem.Size = new System.Drawing.Size(37, 20);
            this.scriptsToolStripMenuItem.Text = "File";
            // 
            // openFolderToolStripMenuItem1
            // 
            this.openFolderToolStripMenuItem1.Name = "openFolderToolStripMenuItem1";
            this.openFolderToolStripMenuItem1.Size = new System.Drawing.Size(186, 22);
            this.openFolderToolStripMenuItem1.Text = "Open Pokebot Folder";
            this.openFolderToolStripMenuItem1.Click += new System.EventHandler(this.openFolderToolStripMenuItem1_Click);
            // 
            // openFolderToolStripMenuItem
            // 
            this.openFolderToolStripMenuItem.Name = "openFolderToolStripMenuItem";
            this.openFolderToolStripMenuItem.Size = new System.Drawing.Size(186, 22);
            this.openFolderToolStripMenuItem.Text = "Open Scripts Folder";
            this.openFolderToolStripMenuItem.Click += new System.EventHandler(this.openFolderToolStripMenuItem_Click);
            // 
            // consoleToolStripMenuItem
            // 
            this.consoleToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.clearLuaConsoleToolStripMenuItem});
            this.consoleToolStripMenuItem.Name = "consoleToolStripMenuItem";
            this.consoleToolStripMenuItem.Size = new System.Drawing.Size(62, 20);
            this.consoleToolStripMenuItem.Text = "Console";
            // 
            // clearLuaConsoleToolStripMenuItem
            // 
            this.clearLuaConsoleToolStripMenuItem.Name = "clearLuaConsoleToolStripMenuItem";
            this.clearLuaConsoleToolStripMenuItem.Size = new System.Drawing.Size(169, 22);
            this.clearLuaConsoleToolStripMenuItem.Text = "Clear Lua Console";
            this.clearLuaConsoleToolStripMenuItem.Click += new System.EventHandler(this.clearLuaConsoleToolStripMenuItem_Click);
            // 
            // aboutMenu
            // 
            this.aboutMenu.Name = "aboutMenu";
            this.aboutMenu.Size = new System.Drawing.Size(52, 20);
            this.aboutMenu.Text = "About";
            this.aboutMenu.Click += new System.EventHandler(this.aboutMenu_Click);
            // 
            // partyTable
            // 
            this.partyTable.ColumnCount = 6;
            this.partyTable.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 16.66667F));
            this.partyTable.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 16.66667F));
            this.partyTable.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 16.66667F));
            this.partyTable.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 16.66667F));
            this.partyTable.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 16.66667F));
            this.partyTable.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 16.66667F));
            this.partyTable.Dock = System.Windows.Forms.DockStyle.Fill;
            this.partyTable.Location = new System.Drawing.Point(3, 16);
            this.partyTable.Name = "partyTable";
            this.partyTable.RowCount = 1;
            this.partyTable.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.partyTable.Size = new System.Drawing.Size(480, 57);
            this.partyTable.TabIndex = 0;
            // 
            // splitContainer2
            // 
            this.splitContainer2.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer2.Location = new System.Drawing.Point(3, 3);
            this.splitContainer2.Name = "splitContainer2";
            // 
            // splitContainer2.Panel1
            // 
            this.splitContainer2.Panel1.Controls.Add(this.groupBox3);
            // 
            // splitContainer2.Panel2
            // 
            this.splitContainer2.Panel2.Controls.Add(this.tabControl2);
            this.splitContainer2.Size = new System.Drawing.Size(472, 377);
            this.splitContainer2.SplitterDistance = 143;
            this.splitContainer2.TabIndex = 0;
            // 
            // groupBox3
            // 
            this.groupBox3.Controls.Add(this.scriptsTree);
            this.groupBox3.Controls.Add(this.buttonRefresh);
            this.groupBox3.Dock = System.Windows.Forms.DockStyle.Fill;
            this.groupBox3.Location = new System.Drawing.Point(0, 0);
            this.groupBox3.Name = "groupBox3";
            this.groupBox3.Size = new System.Drawing.Size(143, 377);
            this.groupBox3.TabIndex = 23;
            this.groupBox3.TabStop = false;
            this.groupBox3.Text = "Available Scripts";
            // 
            // scriptsTree
            // 
            this.scriptsTree.Dock = System.Windows.Forms.DockStyle.Fill;
            this.scriptsTree.Indent = 16;
            this.scriptsTree.Location = new System.Drawing.Point(3, 16);
            this.scriptsTree.Name = "scriptsTree";
            this.scriptsTree.ShowRootLines = false;
            this.scriptsTree.Size = new System.Drawing.Size(137, 319);
            this.scriptsTree.TabIndex = 15;
            this.scriptsTree.AfterSelect += new System.Windows.Forms.TreeViewEventHandler(this.scriptsTree_AfterSelect);
            // 
            // buttonRefresh
            // 
            this.buttonRefresh.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.buttonRefresh.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.buttonRefresh.Location = new System.Drawing.Point(3, 335);
            this.buttonRefresh.Name = "buttonRefresh";
            this.buttonRefresh.Size = new System.Drawing.Size(137, 39);
            this.buttonRefresh.TabIndex = 21;
            this.buttonRefresh.Text = "Refresh List";
            this.buttonRefresh.UseVisualStyleBackColor = true;
            this.buttonRefresh.Click += new System.EventHandler(this.button1_Click);
            // 
            // tabControl2
            // 
            this.tabControl2.Controls.Add(this.tabConsole);
            this.tabControl2.Controls.Add(this.tabScriptConfig);
            this.tabControl2.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tabControl2.Location = new System.Drawing.Point(0, 0);
            this.tabControl2.Name = "tabControl2";
            this.tabControl2.SelectedIndex = 0;
            this.tabControl2.Size = new System.Drawing.Size(325, 377);
            this.tabControl2.TabIndex = 19;
            // 
            // tabConsole
            // 
            this.tabConsole.Controls.Add(this.consoleOutput);
            this.tabConsole.Controls.Add(this.containerControl2);
            this.tabConsole.Location = new System.Drawing.Point(4, 22);
            this.tabConsole.Name = "tabConsole";
            this.tabConsole.Padding = new System.Windows.Forms.Padding(3);
            this.tabConsole.Size = new System.Drawing.Size(317, 351);
            this.tabConsole.TabIndex = 0;
            this.tabConsole.Text = "Lua Console";
            this.tabConsole.UseVisualStyleBackColor = true;
            // 
            // containerControl2
            // 
            this.containerControl2.Controls.Add(this.consoleInput);
            this.containerControl2.Controls.Add(this.button2);
            this.containerControl2.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.containerControl2.Location = new System.Drawing.Point(3, 325);
            this.containerControl2.Name = "containerControl2";
            this.containerControl2.Size = new System.Drawing.Size(311, 23);
            this.containerControl2.TabIndex = 18;
            this.containerControl2.Text = "containerControl2";
            // 
            // consoleInput
            // 
            this.consoleInput.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.consoleInput.Location = new System.Drawing.Point(0, 3);
            this.consoleInput.Name = "consoleInput";
            this.consoleInput.Size = new System.Drawing.Size(236, 20);
            this.consoleInput.TabIndex = 16;
            this.consoleInput.KeyDown += new System.Windows.Forms.KeyEventHandler(this.consoleInput_KeyDown);
            // 
            // button2
            // 
            this.button2.Dock = System.Windows.Forms.DockStyle.Right;
            this.button2.Location = new System.Drawing.Point(236, 0);
            this.button2.Name = "button2";
            this.button2.Size = new System.Drawing.Size(75, 23);
            this.button2.TabIndex = 17;
            this.button2.Text = "Submit";
            this.button2.UseVisualStyleBackColor = true;
            this.button2.Click += new System.EventHandler(this.button2_Click);
            // 
            // tabScriptConfig
            // 
            this.tabScriptConfig.Controls.Add(this.containerControl1);
            this.tabScriptConfig.Controls.Add(this.tableLayoutPanel2);
            this.tabScriptConfig.Location = new System.Drawing.Point(4, 22);
            this.tabScriptConfig.Name = "tabScriptConfig";
            this.tabScriptConfig.Padding = new System.Windows.Forms.Padding(3);
            this.tabScriptConfig.Size = new System.Drawing.Size(317, 351);
            this.tabScriptConfig.TabIndex = 1;
            this.tabScriptConfig.Text = "Script Config";
            this.tabScriptConfig.UseVisualStyleBackColor = true;
            // 
            // containerControl1
            // 
            this.containerControl1.Controls.Add(this.configPage);
            this.containerControl1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.containerControl1.Location = new System.Drawing.Point(3, 3);
            this.containerControl1.Name = "containerControl1";
            this.containerControl1.Size = new System.Drawing.Size(311, 306);
            this.containerControl1.TabIndex = 1;
            this.containerControl1.Text = "containerControl1";
            // 
            // configPage
            // 
            this.configPage.BackColor = System.Drawing.Color.Transparent;
            this.configPage.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.configPage.Dock = System.Windows.Forms.DockStyle.Fill;
            this.configPage.Location = new System.Drawing.Point(0, 0);
            this.configPage.Name = "configPage";
            this.configPage.Size = new System.Drawing.Size(311, 306);
            this.configPage.TabIndex = 0;
            // 
            // tableLayoutPanel2
            // 
            this.tableLayoutPanel2.ColumnCount = 2;
            this.tableLayoutPanel2.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 50F));
            this.tableLayoutPanel2.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 50F));
            this.tableLayoutPanel2.Controls.Add(this.saveConfigChanges, 0, 0);
            this.tableLayoutPanel2.Controls.Add(this.resetConfig, 1, 0);
            this.tableLayoutPanel2.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.tableLayoutPanel2.Location = new System.Drawing.Point(3, 309);
            this.tableLayoutPanel2.Name = "tableLayoutPanel2";
            this.tableLayoutPanel2.RowCount = 1;
            this.tableLayoutPanel2.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 50F));
            this.tableLayoutPanel2.Size = new System.Drawing.Size(311, 39);
            this.tableLayoutPanel2.TabIndex = 1;
            // 
            // saveConfigChanges
            // 
            this.saveConfigChanges.Dock = System.Windows.Forms.DockStyle.Fill;
            this.saveConfigChanges.Location = new System.Drawing.Point(3, 3);
            this.saveConfigChanges.Name = "saveConfigChanges";
            this.saveConfigChanges.Size = new System.Drawing.Size(149, 33);
            this.saveConfigChanges.TabIndex = 0;
            this.saveConfigChanges.Text = "Save and Apply Config";
            this.saveConfigChanges.UseVisualStyleBackColor = true;
            this.saveConfigChanges.Click += new System.EventHandler(this.saveConfigChanges_Click);
            // 
            // resetConfig
            // 
            this.resetConfig.Dock = System.Windows.Forms.DockStyle.Fill;
            this.resetConfig.Location = new System.Drawing.Point(158, 3);
            this.resetConfig.Name = "resetConfig";
            this.resetConfig.Size = new System.Drawing.Size(150, 33);
            this.resetConfig.TabIndex = 1;
            this.resetConfig.Text = "Reset Changes";
            this.resetConfig.UseVisualStyleBackColor = true;
            this.resetConfig.Click += new System.EventHandler(this.resetConfig_Click);
            // 
            // splitContainer1
            // 
            this.splitContainer1.Location = new System.Drawing.Point(0, 0);
            this.splitContainer1.Name = "splitContainer1";
            this.splitContainer1.Size = new System.Drawing.Size(150, 100);
            this.splitContainer1.TabIndex = 0;
            // 
            // panel1
            // 
            this.panel1.AutoSizeMode = System.Windows.Forms.AutoSizeMode.GrowAndShrink;
            this.panel1.Controls.Add(this.tabControl1);
            this.panel1.Controls.Add(this.partyGroupBox);
            this.panel1.Controls.Add(this.groupBox10);
            this.panel1.Controls.Add(this.scriptActions);
            this.panel1.Controls.Add(this.optionsMenu);
            this.panel1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.panel1.Location = new System.Drawing.Point(0, 0);
            this.panel1.Name = "panel1";
            this.panel1.Padding = new System.Windows.Forms.Padding(8);
            this.panel1.Size = new System.Drawing.Size(502, 611);
            this.panel1.TabIndex = 2;
            // 
            // tabControl1
            // 
            this.tabControl1.Controls.Add(this.scriptPage);
            this.tabControl1.Controls.Add(this.dashboardPage);
            this.tabControl1.Controls.Add(this.gameDataPage);
            this.tabControl1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tabControl1.Location = new System.Drawing.Point(8, 194);
            this.tabControl1.Name = "tabControl1";
            this.tabControl1.SelectedIndex = 0;
            this.tabControl1.Size = new System.Drawing.Size(486, 409);
            this.tabControl1.TabIndex = 0;
            this.tabControl1.TabIndexChanged += new System.EventHandler(this.tabControl1_TabIndexChanged);
            // 
            // scriptPage
            // 
            this.scriptPage.Controls.Add(this.splitContainer2);
            this.scriptPage.Location = new System.Drawing.Point(4, 22);
            this.scriptPage.Name = "scriptPage";
            this.scriptPage.Padding = new System.Windows.Forms.Padding(3);
            this.scriptPage.Size = new System.Drawing.Size(478, 383);
            this.scriptPage.TabIndex = 1;
            this.scriptPage.Text = "Script Manager";
            this.scriptPage.UseVisualStyleBackColor = true;
            // 
            // dashboardPage
            // 
            this.dashboardPage.Controls.Add(this.splitContainer3);
            this.dashboardPage.Location = new System.Drawing.Point(4, 22);
            this.dashboardPage.Name = "dashboardPage";
            this.dashboardPage.Padding = new System.Windows.Forms.Padding(3);
            this.dashboardPage.Size = new System.Drawing.Size(192, 74);
            this.dashboardPage.TabIndex = 0;
            this.dashboardPage.Text = "Dashboard";
            this.dashboardPage.UseVisualStyleBackColor = true;
            // 
            // splitContainer3
            // 
            this.splitContainer3.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer3.Location = new System.Drawing.Point(3, 3);
            this.splitContainer3.Name = "splitContainer3";
            // 
            // splitContainer3.Panel1
            // 
            this.splitContainer3.Panel1.Controls.Add(this.groupBox12);
            // 
            // splitContainer3.Panel2
            // 
            this.splitContainer3.Panel2.Controls.Add(this.splitContainer4);
            this.splitContainer3.Size = new System.Drawing.Size(186, 68);
            this.splitContainer3.SplitterDistance = 64;
            this.splitContainer3.TabIndex = 0;
            // 
            // groupBox12
            // 
            this.groupBox12.Controls.Add(this.currentFoe);
            this.groupBox12.Location = new System.Drawing.Point(7, 33);
            this.groupBox12.Name = "groupBox12";
            this.groupBox12.Size = new System.Drawing.Size(158, 48);
            this.groupBox12.TabIndex = 5;
            this.groupBox12.TabStop = false;
            this.groupBox12.Text = "Opponent";
            // 
            // currentFoe
            // 
            this.currentFoe.Dock = System.Windows.Forms.DockStyle.Fill;
            this.currentFoe.Location = new System.Drawing.Point(3, 16);
            this.currentFoe.Name = "currentFoe";
            this.currentFoe.Size = new System.Drawing.Size(152, 29);
            this.currentFoe.TabIndex = 0;
            // 
            // splitContainer4
            // 
            this.splitContainer4.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer4.Location = new System.Drawing.Point(0, 0);
            this.splitContainer4.Name = "splitContainer4";
            this.splitContainer4.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer4.Panel1
            // 
            this.splitContainer4.Panel1.Controls.Add(this.groupBox5);
            // 
            // splitContainer4.Panel2
            // 
            this.splitContainer4.Panel2.Controls.Add(this.groupBox4);
            this.splitContainer4.Size = new System.Drawing.Size(118, 68);
            this.splitContainer4.SplitterDistance = 25;
            this.splitContainer4.TabIndex = 0;
            // 
            // groupBox5
            // 
            this.groupBox5.Dock = System.Windows.Forms.DockStyle.Fill;
            this.groupBox5.Location = new System.Drawing.Point(0, 0);
            this.groupBox5.Name = "groupBox5";
            this.groupBox5.Size = new System.Drawing.Size(118, 25);
            this.groupBox5.TabIndex = 1;
            this.groupBox5.TabStop = false;
            this.groupBox5.Text = "Session Stats";
            // 
            // groupBox4
            // 
            this.groupBox4.Controls.Add(this.recentEncountersTable);
            this.groupBox4.Dock = System.Windows.Forms.DockStyle.Fill;
            this.groupBox4.Location = new System.Drawing.Point(0, 0);
            this.groupBox4.Name = "groupBox4";
            this.groupBox4.Size = new System.Drawing.Size(118, 39);
            this.groupBox4.TabIndex = 0;
            this.groupBox4.TabStop = false;
            this.groupBox4.Text = "Recent Encounters";
            // 
            // recentEncountersTable
            // 
            this.recentEncountersTable.ColumnCount = 1;
            this.recentEncountersTable.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle());
            this.recentEncountersTable.Controls.Add(this.pokemonEncounter1, 0, 0);
            this.recentEncountersTable.Dock = System.Windows.Forms.DockStyle.Fill;
            this.recentEncountersTable.Location = new System.Drawing.Point(3, 16);
            this.recentEncountersTable.Name = "recentEncountersTable";
            this.recentEncountersTable.RowCount = 7;
            this.recentEncountersTable.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 14.28571F));
            this.recentEncountersTable.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 14.28571F));
            this.recentEncountersTable.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 14.28571F));
            this.recentEncountersTable.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 14.28571F));
            this.recentEncountersTable.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 14.28571F));
            this.recentEncountersTable.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 14.28571F));
            this.recentEncountersTable.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 14.28571F));
            this.recentEncountersTable.Size = new System.Drawing.Size(112, 20);
            this.recentEncountersTable.TabIndex = 0;
            // 
            // pokemonEncounter1
            // 
            this.pokemonEncounter1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.pokemonEncounter1.Location = new System.Drawing.Point(3, 3);
            this.pokemonEncounter1.Name = "pokemonEncounter1";
            this.pokemonEncounter1.Size = new System.Drawing.Size(324, 1);
            this.pokemonEncounter1.TabIndex = 0;
            // 
            // gameDataPage
            // 
            this.gameDataPage.Controls.Add(this.flowLayoutPanel1);
            this.gameDataPage.Location = new System.Drawing.Point(4, 22);
            this.gameDataPage.Name = "gameDataPage";
            this.gameDataPage.Padding = new System.Windows.Forms.Padding(3);
            this.gameDataPage.Size = new System.Drawing.Size(478, 383);
            this.gameDataPage.TabIndex = 2;
            this.gameDataPage.Text = "Game Data";
            this.gameDataPage.UseVisualStyleBackColor = true;
            // 
            // flowLayoutPanel1
            // 
            this.flowLayoutPanel1.Controls.Add(this.groupBox2);
            this.flowLayoutPanel1.Controls.Add(this.groupBox8);
            this.flowLayoutPanel1.Controls.Add(this.groupBox9);
            this.flowLayoutPanel1.Controls.Add(this.groupBox6);
            this.flowLayoutPanel1.Controls.Add(this.groupBox7);
            this.flowLayoutPanel1.Controls.Add(this.groupBox1);
            this.flowLayoutPanel1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.flowLayoutPanel1.FlowDirection = System.Windows.Forms.FlowDirection.TopDown;
            this.flowLayoutPanel1.Location = new System.Drawing.Point(3, 3);
            this.flowLayoutPanel1.Name = "flowLayoutPanel1";
            this.flowLayoutPanel1.Size = new System.Drawing.Size(472, 377);
            this.flowLayoutPanel1.TabIndex = 1;
            this.flowLayoutPanel1.Paint += new System.Windows.Forms.PaintEventHandler(this.flowLayoutPanel1_Paint);
            // 
            // groupBox2
            // 
            this.groupBox2.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.groupBox2.Controls.Add(this.abilitiesList);
            this.groupBox2.Location = new System.Drawing.Point(3, 3);
            this.groupBox2.Name = "groupBox2";
            this.groupBox2.Size = new System.Drawing.Size(473, 48);
            this.groupBox2.TabIndex = 6;
            this.groupBox2.TabStop = false;
            this.groupBox2.Text = "Abilities";
            // 
            // abilitiesList
            // 
            this.abilitiesList.Dock = System.Windows.Forms.DockStyle.Left;
            this.abilitiesList.FormattingEnabled = true;
            this.abilitiesList.Location = new System.Drawing.Point(3, 16);
            this.abilitiesList.Name = "abilitiesList";
            this.abilitiesList.Size = new System.Drawing.Size(230, 21);
            this.abilitiesList.TabIndex = 0;
            // 
            // groupBox8
            // 
            this.groupBox8.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.groupBox8.Controls.Add(this.movesList);
            this.groupBox8.Location = new System.Drawing.Point(3, 57);
            this.groupBox8.Name = "groupBox8";
            this.groupBox8.Size = new System.Drawing.Size(473, 48);
            this.groupBox8.TabIndex = 9;
            this.groupBox8.TabStop = false;
            this.groupBox8.Text = "Moves";
            // 
            // movesList
            // 
            this.movesList.Dock = System.Windows.Forms.DockStyle.Left;
            this.movesList.FormattingEnabled = true;
            this.movesList.Location = new System.Drawing.Point(3, 16);
            this.movesList.Name = "movesList";
            this.movesList.Size = new System.Drawing.Size(219, 21);
            this.movesList.TabIndex = 0;
            // 
            // groupBox9
            // 
            this.groupBox9.Controls.Add(this.typesList);
            this.groupBox9.Location = new System.Drawing.Point(3, 111);
            this.groupBox9.Name = "groupBox9";
            this.groupBox9.Size = new System.Drawing.Size(473, 85);
            this.groupBox9.TabIndex = 10;
            this.groupBox9.TabStop = false;
            this.groupBox9.Text = "Types";
            // 
            // typesList
            // 
            this.typesList.Dock = System.Windows.Forms.DockStyle.Left;
            this.typesList.FormattingEnabled = true;
            this.typesList.Location = new System.Drawing.Point(3, 16);
            this.typesList.Name = "typesList";
            this.typesList.Size = new System.Drawing.Size(186, 21);
            this.typesList.TabIndex = 0;
            // 
            // groupBox6
            // 
            this.groupBox6.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.groupBox6.Controls.Add(this.itemsList);
            this.groupBox6.Location = new System.Drawing.Point(3, 202);
            this.groupBox6.Name = "groupBox6";
            this.groupBox6.Size = new System.Drawing.Size(473, 47);
            this.groupBox6.TabIndex = 7;
            this.groupBox6.TabStop = false;
            this.groupBox6.Text = "Items";
            // 
            // itemsList
            // 
            this.itemsList.Dock = System.Windows.Forms.DockStyle.Left;
            this.itemsList.FormattingEnabled = true;
            this.itemsList.Location = new System.Drawing.Point(3, 16);
            this.itemsList.Name = "itemsList";
            this.itemsList.Size = new System.Drawing.Size(230, 21);
            this.itemsList.TabIndex = 0;
            // 
            // groupBox7
            // 
            this.groupBox7.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.groupBox7.Controls.Add(this.mapsList);
            this.groupBox7.Location = new System.Drawing.Point(3, 255);
            this.groupBox7.Name = "groupBox7";
            this.groupBox7.Size = new System.Drawing.Size(473, 47);
            this.groupBox7.TabIndex = 8;
            this.groupBox7.TabStop = false;
            this.groupBox7.Text = "Maps";
            // 
            // mapsList
            // 
            this.mapsList.Dock = System.Windows.Forms.DockStyle.Left;
            this.mapsList.FormattingEnabled = true;
            this.mapsList.Location = new System.Drawing.Point(3, 16);
            this.mapsList.Name = "mapsList";
            this.mapsList.Size = new System.Drawing.Size(215, 21);
            this.mapsList.TabIndex = 0;
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.speciesList);
            this.groupBox1.Location = new System.Drawing.Point(482, 3);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(473, 88);
            this.groupBox1.TabIndex = 5;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Species";
            // 
            // speciesList
            // 
            this.speciesList.Dock = System.Windows.Forms.DockStyle.Left;
            this.speciesList.FormattingEnabled = true;
            this.speciesList.Location = new System.Drawing.Point(3, 16);
            this.speciesList.Name = "speciesList";
            this.speciesList.Size = new System.Drawing.Size(186, 21);
            this.speciesList.TabIndex = 0;
            // 
            // partyGroupBox
            // 
            this.partyGroupBox.Controls.Add(this.partyTable);
            this.partyGroupBox.Dock = System.Windows.Forms.DockStyle.Top;
            this.partyGroupBox.Location = new System.Drawing.Point(8, 118);
            this.partyGroupBox.Name = "partyGroupBox";
            this.partyGroupBox.Size = new System.Drawing.Size(486, 76);
            this.partyGroupBox.TabIndex = 4;
            this.partyGroupBox.TabStop = false;
            this.partyGroupBox.Text = "Party";
            // 
            // groupBox10
            // 
            this.groupBox10.Controls.Add(this.tableLayoutPanel1);
            this.groupBox10.Dock = System.Windows.Forms.DockStyle.Top;
            this.groupBox10.Location = new System.Drawing.Point(8, 77);
            this.groupBox10.Name = "groupBox10";
            this.groupBox10.Size = new System.Drawing.Size(486, 41);
            this.groupBox10.TabIndex = 11;
            this.groupBox10.TabStop = false;
            this.groupBox10.Text = "Trainer";
            // 
            // trainerName
            // 
            this.trainerName.AutoSize = true;
            this.trainerName.Dock = System.Windows.Forms.DockStyle.Left;
            this.trainerName.Location = new System.Drawing.Point(3, 0);
            this.trainerName.Name = "trainerName";
            this.trainerName.Size = new System.Drawing.Size(35, 22);
            this.trainerName.TabIndex = 1;
            this.trainerName.Text = "Name";
            // 
            // trainerId
            // 
            this.trainerId.AutoSize = true;
            this.trainerId.Dock = System.Windows.Forms.DockStyle.Left;
            this.trainerId.Location = new System.Drawing.Point(123, 0);
            this.trainerId.Name = "trainerId";
            this.trainerId.Size = new System.Drawing.Size(54, 22);
            this.trainerId.TabIndex = 3;
            this.trainerId.Text = "Trainer ID";
            // 
            // scriptActions
            // 
            this.scriptActions.ColumnCount = 3;
            this.scriptActions.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 33.33333F));
            this.scriptActions.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 33.33333F));
            this.scriptActions.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 33.33333F));
            this.scriptActions.Controls.Add(this.buttonRun, 1, 0);
            this.scriptActions.Controls.Add(this.buttonStop, 2, 0);
            this.scriptActions.Controls.Add(this.groupSelectedScript, 0, 0);
            this.scriptActions.Dock = System.Windows.Forms.DockStyle.Top;
            this.scriptActions.Location = new System.Drawing.Point(8, 32);
            this.scriptActions.Name = "scriptActions";
            this.scriptActions.RowCount = 1;
            this.scriptActions.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.scriptActions.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 20F));
            this.scriptActions.Size = new System.Drawing.Size(486, 45);
            this.scriptActions.TabIndex = 0;
            // 
            // buttonRun
            // 
            this.buttonRun.AutoSize = true;
            this.buttonRun.Dock = System.Windows.Forms.DockStyle.Fill;
            this.buttonRun.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.buttonRun.Location = new System.Drawing.Point(165, 3);
            this.buttonRun.Name = "buttonRun";
            this.buttonRun.Size = new System.Drawing.Size(156, 39);
            this.buttonRun.TabIndex = 20;
            this.buttonRun.Text = "Run Selected";
            this.buttonRun.TextImageRelation = System.Windows.Forms.TextImageRelation.ImageBeforeText;
            this.buttonRun.UseVisualStyleBackColor = true;
            this.buttonRun.Click += new System.EventHandler(this.runScript_Click);
            // 
            // buttonStop
            // 
            this.buttonStop.AutoSize = true;
            this.buttonStop.Dock = System.Windows.Forms.DockStyle.Fill;
            this.buttonStop.Enabled = false;
            this.buttonStop.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.buttonStop.Location = new System.Drawing.Point(327, 3);
            this.buttonStop.Name = "buttonStop";
            this.buttonStop.Size = new System.Drawing.Size(156, 39);
            this.buttonStop.TabIndex = 16;
            this.buttonStop.Text = "Stop Active";
            this.buttonStop.TextImageRelation = System.Windows.Forms.TextImageRelation.ImageBeforeText;
            this.buttonStop.UseVisualStyleBackColor = true;
            this.buttonStop.Click += new System.EventHandler(this.buttonStop_Click);
            // 
            // groupSelectedScript
            // 
            this.groupSelectedScript.Controls.Add(this.selectedScript);
            this.groupSelectedScript.Dock = System.Windows.Forms.DockStyle.Fill;
            this.groupSelectedScript.Location = new System.Drawing.Point(3, 3);
            this.groupSelectedScript.Name = "groupSelectedScript";
            this.groupSelectedScript.Size = new System.Drawing.Size(156, 39);
            this.groupSelectedScript.TabIndex = 0;
            this.groupSelectedScript.TabStop = false;
            this.groupSelectedScript.Text = "Selected Script";
            // 
            // selectedScript
            // 
            this.selectedScript.Dock = System.Windows.Forms.DockStyle.Fill;
            this.selectedScript.Location = new System.Drawing.Point(3, 16);
            this.selectedScript.Multiline = true;
            this.selectedScript.Name = "selectedScript";
            this.selectedScript.ReadOnly = true;
            this.selectedScript.Size = new System.Drawing.Size(150, 20);
            this.selectedScript.TabIndex = 17;
            this.selectedScript.Text = "None";
            // 
            // settingsToolStripMenuItem
            // 
            this.settingsToolStripMenuItem.Name = "settingsToolStripMenuItem";
            this.settingsToolStripMenuItem.Size = new System.Drawing.Size(61, 20);
            this.settingsToolStripMenuItem.Text = "Settings";
            // 
            // tableLayoutPanel1
            // 
            this.tableLayoutPanel1.ColumnCount = 4;
            this.tableLayoutPanel1.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.tableLayoutPanel1.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.tableLayoutPanel1.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.tableLayoutPanel1.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.tableLayoutPanel1.Controls.Add(this.trainerName, 0, 0);
            this.tableLayoutPanel1.Controls.Add(this.trainerId, 1, 0);
            this.tableLayoutPanel1.Controls.Add(this.trainerPosition, 2, 0);
            this.tableLayoutPanel1.Controls.Add(this.mapHeader, 3, 0);
            this.tableLayoutPanel1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tableLayoutPanel1.Location = new System.Drawing.Point(3, 16);
            this.tableLayoutPanel1.Name = "tableLayoutPanel1";
            this.tableLayoutPanel1.RowCount = 1;
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tableLayoutPanel1.Size = new System.Drawing.Size(480, 22);
            this.tableLayoutPanel1.TabIndex = 7;
            // 
            // mapHeader
            // 
            this.mapHeader.AutoSize = true;
            this.mapHeader.Dock = System.Windows.Forms.DockStyle.Left;
            this.mapHeader.Location = new System.Drawing.Point(363, 0);
            this.mapHeader.Name = "mapHeader";
            this.mapHeader.Size = new System.Drawing.Size(28, 22);
            this.mapHeader.TabIndex = 6;
            this.mapHeader.Text = "Map";
            // 
            // trainerPosition
            // 
            this.trainerPosition.AutoSize = true;
            this.trainerPosition.Dock = System.Windows.Forms.DockStyle.Left;
            this.trainerPosition.Location = new System.Drawing.Point(243, 0);
            this.trainerPosition.Name = "trainerPosition";
            this.trainerPosition.Size = new System.Drawing.Size(48, 22);
            this.trainerPosition.TabIndex = 2;
            this.trainerPosition.Text = "Location";
            // 
            // Pokebot
            // 
            this.ClientSize = new System.Drawing.Size(502, 611);
            this.Controls.Add(this.panel1);
            this.MainMenuStrip = this.optionsMenu;
            this.MinimumSize = new System.Drawing.Size(400, 350);
            this.Name = "Pokebot";
            this.Load += new System.EventHandler(this.Pokebot_Load);
            this.optionsMenu.ResumeLayout(false);
            this.optionsMenu.PerformLayout();
            this.splitContainer2.Panel1.ResumeLayout(false);
            this.splitContainer2.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer2)).EndInit();
            this.splitContainer2.ResumeLayout(false);
            this.groupBox3.ResumeLayout(false);
            this.tabControl2.ResumeLayout(false);
            this.tabConsole.ResumeLayout(false);
            this.containerControl2.ResumeLayout(false);
            this.containerControl2.PerformLayout();
            this.tabScriptConfig.ResumeLayout(false);
            this.containerControl1.ResumeLayout(false);
            this.tableLayoutPanel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).EndInit();
            this.splitContainer1.ResumeLayout(false);
            this.panel1.ResumeLayout(false);
            this.panel1.PerformLayout();
            this.tabControl1.ResumeLayout(false);
            this.scriptPage.ResumeLayout(false);
            this.dashboardPage.ResumeLayout(false);
            this.splitContainer3.Panel1.ResumeLayout(false);
            this.splitContainer3.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer3)).EndInit();
            this.splitContainer3.ResumeLayout(false);
            this.groupBox12.ResumeLayout(false);
            this.splitContainer4.Panel1.ResumeLayout(false);
            this.splitContainer4.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer4)).EndInit();
            this.splitContainer4.ResumeLayout(false);
            this.groupBox4.ResumeLayout(false);
            this.recentEncountersTable.ResumeLayout(false);
            this.gameDataPage.ResumeLayout(false);
            this.flowLayoutPanel1.ResumeLayout(false);
            this.groupBox2.ResumeLayout(false);
            this.groupBox8.ResumeLayout(false);
            this.groupBox9.ResumeLayout(false);
            this.groupBox6.ResumeLayout(false);
            this.groupBox7.ResumeLayout(false);
            this.groupBox1.ResumeLayout(false);
            this.partyGroupBox.ResumeLayout(false);
            this.groupBox10.ResumeLayout(false);
            this.scriptActions.ResumeLayout(false);
            this.scriptActions.PerformLayout();
            this.groupSelectedScript.ResumeLayout(false);
            this.groupSelectedScript.PerformLayout();
            this.tableLayoutPanel1.ResumeLayout(false);
            this.tableLayoutPanel1.PerformLayout();
            this.ResumeLayout(false);

        }

        private Button buttonRefresh;
        private TextBox consoleInput;
        private ContainerControl containerControl2;
        private Button button2;
        private GroupBox groupBox3;
        private SplitContainer splitContainer3;
        private GroupBox groupBox5;
        private GroupBox groupBox4;
        private SplitContainer splitContainer4;
        private TableLayoutPanel recentEncountersTable;
        private TableLayoutPanel partyTable;
        private TabControl tabControl2;
        private TabPage tabConsole;
        private TabPage tabScriptConfig;
        private ConfigPage configPage;
        private PokemonRow pokemonEncounter1;
        private ToolStripMenuItem scriptsToolStripMenuItem;
        private ToolStripMenuItem openFolderToolStripMenuItem;
        private ToolStripMenuItem consoleToolStripMenuItem;
        private ToolStripMenuItem clearLuaConsoleToolStripMenuItem;
        private TextBox selectedScript;
        private TableLayoutPanel scriptActions;
        private GroupBox groupSelectedScript;
        private TableLayoutPanel tableLayoutPanel2;
        private Button saveConfigChanges;
        private Button resetConfig;
        private ContainerControl containerControl1;
        private ToolStripMenuItem openFolderToolStripMenuItem1;
        private TabPage gameDataPage;
        private GroupBox groupBox1;
        private ComboBox speciesList;
        private GroupBox groupBox2;
        private ComboBox abilitiesList;
        private GroupBox groupBox6;
        private ComboBox itemsList;
        private GroupBox groupBox9;
        private ComboBox typesList;
        private GroupBox groupBox8;
        private ComboBox movesList;
        private GroupBox groupBox7;
        private ComboBox mapsList;
        private FlowLayoutPanel flowLayoutPanel1;
        private GroupBox groupBox10;
        private Label trainerName;
        private Label trainerId;
        private GroupBox groupBox12;
        private GroupBox partyGroupBox;
        private PokemonRow currentFoe;
        private ToolStripMenuItem settingsToolStripMenuItem;
        private TableLayoutPanel tableLayoutPanel1;
        private Label trainerPosition;
        private Label mapHeader;
    }
}
