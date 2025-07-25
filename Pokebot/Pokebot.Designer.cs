using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Wyanido.Pokebot.LuaStuff;

namespace Wyanido.Pokebot
{
    public partial class Pokebot
    {
        private void InitializeComponent()
        {
            this.consoleOutput = new System.Windows.Forms.RichTextBox();
            this.framerateLabel = new System.Windows.Forms.Label();
            this.loadedGameLabel = new System.Windows.Forms.Label();
            this.optionsMenu = new System.Windows.Forms.MenuStrip();
            this.aboutMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.tabs = new System.Windows.Forms.TabControl();
            this.party = new System.Windows.Forms.TabPage();
            this.tableLayoutPanel1 = new System.Windows.Forms.TableLayoutPanel();
            this.splitContainer2 = new System.Windows.Forms.SplitContainer();
            this.groupBox3 = new System.Windows.Forms.GroupBox();
            this.scriptsTree = new System.Windows.Forms.TreeView();
            this.buttonRefresh = new System.Windows.Forms.Button();
            this.groupBox2 = new System.Windows.Forms.GroupBox();
            this.selectedScripts = new System.Windows.Forms.TextBox();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.containerControl2 = new System.Windows.Forms.ContainerControl();
            this.consoleInput = new System.Windows.Forms.TextBox();
            this.button2 = new System.Windows.Forms.Button();
            this.splitContainer1 = new System.Windows.Forms.SplitContainer();
            this.panel1 = new System.Windows.Forms.Panel();
            this.tabControl1 = new System.Windows.Forms.TabControl();
            this.scriptPage = new System.Windows.Forms.TabPage();
            this.scriptActions = new System.Windows.Forms.TableLayoutPanel();
            this.buttonRun = new System.Windows.Forms.Button();
            this.buttonStop = new System.Windows.Forms.Button();
            this.buttonOpenFolder = new System.Windows.Forms.Button();
            this.buttonClear = new System.Windows.Forms.Button();
            this.dashboardPage = new System.Windows.Forms.TabPage();
            this.splitContainer3 = new System.Windows.Forms.SplitContainer();
            this.splitContainer4 = new System.Windows.Forms.SplitContainer();
            this.groupBox5 = new System.Windows.Forms.GroupBox();
            this.groupBox4 = new System.Windows.Forms.GroupBox();
            this.recentEncountersTable = new System.Windows.Forms.TableLayoutPanel();
            this.configPage = new System.Windows.Forms.TabPage();
            this.headerStatus = new System.Windows.Forms.FlowLayoutPanel();
            this.optionsMenu.SuspendLayout();
            this.tabs.SuspendLayout();
            this.party.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer2)).BeginInit();
            this.splitContainer2.Panel1.SuspendLayout();
            this.splitContainer2.Panel2.SuspendLayout();
            this.splitContainer2.SuspendLayout();
            this.groupBox3.SuspendLayout();
            this.groupBox2.SuspendLayout();
            this.groupBox1.SuspendLayout();
            this.containerControl2.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).BeginInit();
            this.splitContainer1.SuspendLayout();
            this.panel1.SuspendLayout();
            this.tabControl1.SuspendLayout();
            this.scriptPage.SuspendLayout();
            this.scriptActions.SuspendLayout();
            this.dashboardPage.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer3)).BeginInit();
            this.splitContainer3.Panel1.SuspendLayout();
            this.splitContainer3.Panel2.SuspendLayout();
            this.splitContainer3.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer4)).BeginInit();
            this.splitContainer4.Panel1.SuspendLayout();
            this.splitContainer4.Panel2.SuspendLayout();
            this.splitContainer4.SuspendLayout();
            this.groupBox4.SuspendLayout();
            this.headerStatus.SuspendLayout();
            this.SuspendLayout();
            // 
            // consoleOutput
            // 
            this.consoleOutput.Cursor = System.Windows.Forms.Cursors.IBeam;
            this.consoleOutput.Dock = System.Windows.Forms.DockStyle.Fill;
            this.consoleOutput.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.consoleOutput.Location = new System.Drawing.Point(3, 16);
            this.consoleOutput.Name = "consoleOutput";
            this.consoleOutput.ReadOnly = true;
            this.consoleOutput.Size = new System.Drawing.Size(357, 341);
            this.consoleOutput.TabIndex = 1;
            this.consoleOutput.Text = "";
            // 
            // framerateLabel
            // 
            this.framerateLabel.AutoSize = true;
            this.framerateLabel.Dock = System.Windows.Forms.DockStyle.Left;
            this.framerateLabel.ImageAlign = System.Drawing.ContentAlignment.TopLeft;
            this.framerateLabel.Location = new System.Drawing.Point(3, 0);
            this.framerateLabel.Name = "framerateLabel";
            this.framerateLabel.Size = new System.Drawing.Size(54, 13);
            this.framerateLabel.TabIndex = 3;
            this.framerateLabel.Text = "Framerate";
            this.framerateLabel.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // loadedGameLabel
            // 
            this.loadedGameLabel.AutoSize = true;
            this.loadedGameLabel.Dock = System.Windows.Forms.DockStyle.Right;
            this.loadedGameLabel.Location = new System.Drawing.Point(63, 0);
            this.loadedGameLabel.Name = "loadedGameLabel";
            this.loadedGameLabel.Size = new System.Drawing.Size(77, 13);
            this.loadedGameLabel.TabIndex = 4;
            this.loadedGameLabel.Text = "Loaded Game:";
            this.loadedGameLabel.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // optionsMenu
            // 
            this.optionsMenu.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.aboutMenu});
            this.optionsMenu.Location = new System.Drawing.Point(0, 0);
            this.optionsMenu.Name = "optionsMenu";
            this.optionsMenu.Size = new System.Drawing.Size(558, 24);
            this.optionsMenu.TabIndex = 5;
            this.optionsMenu.Text = "menuStrip1";
            // 
            // aboutMenu
            // 
            this.aboutMenu.Name = "aboutMenu";
            this.aboutMenu.Size = new System.Drawing.Size(52, 20);
            this.aboutMenu.Text = "About";
            // 
            // tabs
            // 
            this.tabs.Controls.Add(this.party);
            this.tabs.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tabs.Location = new System.Drawing.Point(0, 0);
            this.tabs.Name = "tabs";
            this.tabs.SelectedIndex = 0;
            this.tabs.Size = new System.Drawing.Size(188, 428);
            this.tabs.TabIndex = 7;
            // 
            // party
            // 
            this.party.Controls.Add(this.tableLayoutPanel1);
            this.party.Location = new System.Drawing.Point(4, 22);
            this.party.Name = "party";
            this.party.Padding = new System.Windows.Forms.Padding(3);
            this.party.Size = new System.Drawing.Size(180, 402);
            this.party.TabIndex = 1;
            this.party.Text = "Party";
            this.party.UseVisualStyleBackColor = true;
            // 
            // tableLayoutPanel1
            // 
            this.tableLayoutPanel1.ColumnCount = 2;
            this.tableLayoutPanel1.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 50F));
            this.tableLayoutPanel1.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 50F));
            this.tableLayoutPanel1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tableLayoutPanel1.Location = new System.Drawing.Point(3, 3);
            this.tableLayoutPanel1.Name = "tableLayoutPanel1";
            this.tableLayoutPanel1.RowCount = 3;
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 33.33333F));
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 33.33333F));
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 33.33333F));
            this.tableLayoutPanel1.Size = new System.Drawing.Size(174, 396);
            this.tableLayoutPanel1.TabIndex = 0;
            // 
            // splitContainer2
            // 
            this.splitContainer2.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer2.Location = new System.Drawing.Point(3, 48);
            this.splitContainer2.Name = "splitContainer2";
            // 
            // splitContainer2.Panel1
            // 
            this.splitContainer2.Panel1.Controls.Add(this.groupBox3);
            this.splitContainer2.Panel1.Controls.Add(this.groupBox2);
            // 
            // splitContainer2.Panel2
            // 
            this.splitContainer2.Panel2.Controls.Add(this.groupBox1);
            this.splitContainer2.Size = new System.Drawing.Size(528, 383);
            this.splitContainer2.SplitterDistance = 161;
            this.splitContainer2.TabIndex = 0;
            // 
            // groupBox3
            // 
            this.groupBox3.Controls.Add(this.scriptsTree);
            this.groupBox3.Controls.Add(this.buttonRefresh);
            this.groupBox3.Dock = System.Windows.Forms.DockStyle.Fill;
            this.groupBox3.Location = new System.Drawing.Point(0, 39);
            this.groupBox3.Name = "groupBox3";
            this.groupBox3.Size = new System.Drawing.Size(161, 344);
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
            this.scriptsTree.Size = new System.Drawing.Size(155, 284);
            this.scriptsTree.TabIndex = 15;
            this.scriptsTree.AfterSelect += new System.Windows.Forms.TreeViewEventHandler(this.scriptsTree_AfterSelect);
            // 
            // buttonRefresh
            // 
            this.buttonRefresh.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.buttonRefresh.Image = global::Wyanido.Pokebot.Properties.Resources._113;
            this.buttonRefresh.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.buttonRefresh.Location = new System.Drawing.Point(3, 300);
            this.buttonRefresh.Name = "buttonRefresh";
            this.buttonRefresh.Size = new System.Drawing.Size(155, 41);
            this.buttonRefresh.TabIndex = 21;
            this.buttonRefresh.Text = "Refresh List";
            this.buttonRefresh.UseVisualStyleBackColor = true;
            this.buttonRefresh.Click += new System.EventHandler(this.button1_Click);
            // 
            // groupBox2
            // 
            this.groupBox2.AutoSize = true;
            this.groupBox2.AutoSizeMode = System.Windows.Forms.AutoSizeMode.GrowAndShrink;
            this.groupBox2.Controls.Add(this.selectedScripts);
            this.groupBox2.Dock = System.Windows.Forms.DockStyle.Top;
            this.groupBox2.Location = new System.Drawing.Point(0, 0);
            this.groupBox2.Name = "groupBox2";
            this.groupBox2.Size = new System.Drawing.Size(161, 39);
            this.groupBox2.TabIndex = 22;
            this.groupBox2.TabStop = false;
            this.groupBox2.Text = "Selected Script";
            // 
            // selectedScripts
            // 
            this.selectedScripts.Dock = System.Windows.Forms.DockStyle.Top;
            this.selectedScripts.Location = new System.Drawing.Point(3, 16);
            this.selectedScripts.Name = "selectedScripts";
            this.selectedScripts.ReadOnly = true;
            this.selectedScripts.Size = new System.Drawing.Size(155, 20);
            this.selectedScripts.TabIndex = 17;
            this.selectedScripts.Text = "None";
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.consoleOutput);
            this.groupBox1.Controls.Add(this.containerControl2);
            this.groupBox1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.groupBox1.Location = new System.Drawing.Point(0, 0);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(363, 383);
            this.groupBox1.TabIndex = 19;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Console";
            // 
            // containerControl2
            // 
            this.containerControl2.Controls.Add(this.consoleInput);
            this.containerControl2.Controls.Add(this.button2);
            this.containerControl2.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.containerControl2.Location = new System.Drawing.Point(3, 357);
            this.containerControl2.Name = "containerControl2";
            this.containerControl2.Size = new System.Drawing.Size(357, 23);
            this.containerControl2.TabIndex = 18;
            this.containerControl2.Text = "containerControl2";
            // 
            // consoleInput
            // 
            this.consoleInput.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.consoleInput.Location = new System.Drawing.Point(0, 3);
            this.consoleInput.Name = "consoleInput";
            this.consoleInput.Size = new System.Drawing.Size(282, 20);
            this.consoleInput.TabIndex = 16;
            this.consoleInput.KeyDown += new System.Windows.Forms.KeyEventHandler(this.consoleInput_KeyDown);
            // 
            // button2
            // 
            this.button2.Dock = System.Windows.Forms.DockStyle.Right;
            this.button2.Location = new System.Drawing.Point(282, 0);
            this.button2.Name = "button2";
            this.button2.Size = new System.Drawing.Size(75, 23);
            this.button2.TabIndex = 17;
            this.button2.Text = "Submit";
            this.button2.UseVisualStyleBackColor = true;
            this.button2.Click += new System.EventHandler(this.button2_Click);
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
            this.panel1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.panel1.Location = new System.Drawing.Point(0, 35);
            this.panel1.Name = "panel1";
            this.panel1.Padding = new System.Windows.Forms.Padding(8);
            this.panel1.Size = new System.Drawing.Size(558, 476);
            this.panel1.TabIndex = 2;
            // 
            // tabControl1
            // 
            this.tabControl1.Controls.Add(this.scriptPage);
            this.tabControl1.Controls.Add(this.dashboardPage);
            this.tabControl1.Controls.Add(this.configPage);
            this.tabControl1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tabControl1.Location = new System.Drawing.Point(8, 8);
            this.tabControl1.Name = "tabControl1";
            this.tabControl1.SelectedIndex = 0;
            this.tabControl1.Size = new System.Drawing.Size(542, 460);
            this.tabControl1.TabIndex = 0;
            // 
            // scriptPage
            // 
            this.scriptPage.Controls.Add(this.splitContainer2);
            this.scriptPage.Controls.Add(this.scriptActions);
            this.scriptPage.Location = new System.Drawing.Point(4, 22);
            this.scriptPage.Name = "scriptPage";
            this.scriptPage.Padding = new System.Windows.Forms.Padding(3);
            this.scriptPage.Size = new System.Drawing.Size(534, 434);
            this.scriptPage.TabIndex = 1;
            this.scriptPage.Text = "Script Manager";
            this.scriptPage.UseVisualStyleBackColor = true;
            // 
            // scriptActions
            // 
            this.scriptActions.ColumnCount = 4;
            this.scriptActions.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.scriptActions.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.scriptActions.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.scriptActions.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.scriptActions.Controls.Add(this.buttonRun, 0, 0);
            this.scriptActions.Controls.Add(this.buttonStop, 1, 0);
            this.scriptActions.Controls.Add(this.buttonOpenFolder, 2, 0);
            this.scriptActions.Controls.Add(this.buttonClear, 3, 0);
            this.scriptActions.Dock = System.Windows.Forms.DockStyle.Top;
            this.scriptActions.Location = new System.Drawing.Point(3, 3);
            this.scriptActions.Name = "scriptActions";
            this.scriptActions.RowCount = 1;
            this.scriptActions.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.scriptActions.Size = new System.Drawing.Size(528, 45);
            this.scriptActions.TabIndex = 21;
            // 
            // buttonRun
            // 
            this.buttonRun.AutoSize = true;
            this.buttonRun.Dock = System.Windows.Forms.DockStyle.Fill;
            this.buttonRun.Image = global::Wyanido.Pokebot.Properties.Resources._495;
            this.buttonRun.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.buttonRun.Location = new System.Drawing.Point(3, 3);
            this.buttonRun.Name = "buttonRun";
            this.buttonRun.Size = new System.Drawing.Size(126, 39);
            this.buttonRun.TabIndex = 20;
            this.buttonRun.Text = "Run Script";
            this.buttonRun.TextImageRelation = System.Windows.Forms.TextImageRelation.ImageBeforeText;
            this.buttonRun.UseVisualStyleBackColor = true;
            this.buttonRun.Click += new System.EventHandler(this.runScript_Click);
            // 
            // buttonStop
            // 
            this.buttonStop.AutoSize = true;
            this.buttonStop.Dock = System.Windows.Forms.DockStyle.Fill;
            this.buttonStop.Enabled = false;
            this.buttonStop.Image = global::Wyanido.Pokebot.Properties.Resources._498;
            this.buttonStop.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.buttonStop.Location = new System.Drawing.Point(135, 3);
            this.buttonStop.Name = "buttonStop";
            this.buttonStop.Size = new System.Drawing.Size(126, 39);
            this.buttonStop.TabIndex = 16;
            this.buttonStop.Text = "Stop Script";
            this.buttonStop.TextImageRelation = System.Windows.Forms.TextImageRelation.ImageBeforeText;
            this.buttonStop.UseVisualStyleBackColor = true;
            this.buttonStop.Click += new System.EventHandler(this.buttonStop_Click);
            // 
            // buttonOpenFolder
            // 
            this.buttonOpenFolder.AutoSize = true;
            this.buttonOpenFolder.Dock = System.Windows.Forms.DockStyle.Fill;
            this.buttonOpenFolder.Image = global::Wyanido.Pokebot.Properties.Resources._501;
            this.buttonOpenFolder.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.buttonOpenFolder.Location = new System.Drawing.Point(267, 3);
            this.buttonOpenFolder.Name = "buttonOpenFolder";
            this.buttonOpenFolder.Size = new System.Drawing.Size(126, 39);
            this.buttonOpenFolder.TabIndex = 18;
            this.buttonOpenFolder.Text = "Open Folder";
            this.buttonOpenFolder.TextImageRelation = System.Windows.Forms.TextImageRelation.ImageBeforeText;
            this.buttonOpenFolder.UseVisualStyleBackColor = true;
            this.buttonOpenFolder.Click += new System.EventHandler(this.openFolder_Click);
            // 
            // buttonClear
            // 
            this.buttonClear.AutoSize = true;
            this.buttonClear.Dock = System.Windows.Forms.DockStyle.Fill;
            this.buttonClear.Image = global::Wyanido.Pokebot.Properties.Resources._494;
            this.buttonClear.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.buttonClear.Location = new System.Drawing.Point(399, 3);
            this.buttonClear.Name = "buttonClear";
            this.buttonClear.Size = new System.Drawing.Size(126, 39);
            this.buttonClear.TabIndex = 19;
            this.buttonClear.Text = "Clear Console";
            this.buttonClear.TextImageRelation = System.Windows.Forms.TextImageRelation.ImageBeforeText;
            this.buttonClear.UseVisualStyleBackColor = true;
            this.buttonClear.Click += new System.EventHandler(this.clearConsole_Click);
            // 
            // dashboardPage
            // 
            this.dashboardPage.Controls.Add(this.splitContainer3);
            this.dashboardPage.Location = new System.Drawing.Point(4, 22);
            this.dashboardPage.Name = "dashboardPage";
            this.dashboardPage.Padding = new System.Windows.Forms.Padding(3);
            this.dashboardPage.Size = new System.Drawing.Size(534, 434);
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
            this.splitContainer3.Panel1.Controls.Add(this.tabs);
            // 
            // splitContainer3.Panel2
            // 
            this.splitContainer3.Panel2.Controls.Add(this.splitContainer4);
            this.splitContainer3.Size = new System.Drawing.Size(528, 428);
            this.splitContainer3.SplitterDistance = 188;
            this.splitContainer3.TabIndex = 0;
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
            this.splitContainer4.Size = new System.Drawing.Size(336, 428);
            this.splitContainer4.SplitterDistance = 116;
            this.splitContainer4.TabIndex = 0;
            // 
            // groupBox5
            // 
            this.groupBox5.Dock = System.Windows.Forms.DockStyle.Fill;
            this.groupBox5.Location = new System.Drawing.Point(0, 0);
            this.groupBox5.Name = "groupBox5";
            this.groupBox5.Size = new System.Drawing.Size(336, 116);
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
            this.groupBox4.Size = new System.Drawing.Size(336, 308);
            this.groupBox4.TabIndex = 0;
            this.groupBox4.TabStop = false;
            this.groupBox4.Text = "Recent Encounters";
            // 
            // recentEncountersTable
            // 
            this.recentEncountersTable.ColumnCount = 1;
            this.recentEncountersTable.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle());
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
            this.recentEncountersTable.Size = new System.Drawing.Size(330, 289);
            this.recentEncountersTable.TabIndex = 0;
            // 
            // configPage
            // 
            this.configPage.Location = new System.Drawing.Point(4, 22);
            this.configPage.Name = "configPage";
            this.configPage.Padding = new System.Windows.Forms.Padding(3);
            this.configPage.Size = new System.Drawing.Size(534, 434);
            this.configPage.TabIndex = 2;
            this.configPage.Text = "Configuration";
            this.configPage.UseVisualStyleBackColor = true;
            // 
            // headerStatus
            // 
            this.headerStatus.AutoSizeMode = System.Windows.Forms.AutoSizeMode.GrowAndShrink;
            this.headerStatus.Controls.Add(this.framerateLabel);
            this.headerStatus.Controls.Add(this.loadedGameLabel);
            this.headerStatus.Dock = System.Windows.Forms.DockStyle.Top;
            this.headerStatus.Location = new System.Drawing.Point(0, 24);
            this.headerStatus.Name = "headerStatus";
            this.headerStatus.Size = new System.Drawing.Size(558, 11);
            this.headerStatus.TabIndex = 16;
            // 
            // Pokebot
            // 
            this.ClientSize = new System.Drawing.Size(558, 511);
            this.Controls.Add(this.panel1);
            this.Controls.Add(this.headerStatus);
            this.Controls.Add(this.optionsMenu);
            this.MainMenuStrip = this.optionsMenu;
            this.MinimumSize = new System.Drawing.Size(520, 350);
            this.Name = "Pokebot";
            this.optionsMenu.ResumeLayout(false);
            this.optionsMenu.PerformLayout();
            this.tabs.ResumeLayout(false);
            this.party.ResumeLayout(false);
            this.splitContainer2.Panel1.ResumeLayout(false);
            this.splitContainer2.Panel1.PerformLayout();
            this.splitContainer2.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer2)).EndInit();
            this.splitContainer2.ResumeLayout(false);
            this.groupBox3.ResumeLayout(false);
            this.groupBox2.ResumeLayout(false);
            this.groupBox2.PerformLayout();
            this.groupBox1.ResumeLayout(false);
            this.containerControl2.ResumeLayout(false);
            this.containerControl2.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).EndInit();
            this.splitContainer1.ResumeLayout(false);
            this.panel1.ResumeLayout(false);
            this.tabControl1.ResumeLayout(false);
            this.scriptPage.ResumeLayout(false);
            this.scriptActions.ResumeLayout(false);
            this.scriptActions.PerformLayout();
            this.dashboardPage.ResumeLayout(false);
            this.splitContainer3.Panel1.ResumeLayout(false);
            this.splitContainer3.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer3)).EndInit();
            this.splitContainer3.ResumeLayout(false);
            this.splitContainer4.Panel1.ResumeLayout(false);
            this.splitContainer4.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer4)).EndInit();
            this.splitContainer4.ResumeLayout(false);
            this.groupBox4.ResumeLayout(false);
            this.headerStatus.ResumeLayout(false);
            this.headerStatus.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        private Button buttonRefresh;
        private TextBox consoleInput;
        private ContainerControl containerControl2;
        private TabPage configPage;
        private GroupBox groupBox1;
        private Button button2;
        private GroupBox groupBox3;
        private GroupBox groupBox2;
        private SplitContainer splitContainer3;
        private GroupBox groupBox5;
        private GroupBox groupBox4;
        private SplitContainer splitContainer4;
        private TableLayoutPanel recentEncountersTable;
        private TableLayoutPanel tableLayoutPanel1;
    }
}
