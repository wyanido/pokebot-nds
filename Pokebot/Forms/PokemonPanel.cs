using System;
using System.Drawing;
using System.IO;
using System.Windows.Forms;
using Wyanido.Pokebot.Games.Data;

namespace Wyanido.Pokebot.Forms;

public class PokemonPanel : UserControl, IContainerControl
{
    private PictureBox genderIcon;
    private Label level;
    private TableLayoutPanel tableLayoutPanel1;
    private FlowLayoutPanel flowLayoutPanel2;
    private System.ComponentModel.IContainer components;
    private ContextMenu contextMenu;
    private MenuItem menuItem1;
    private PictureBox speciesIcon;

    private Pokemon displayedPokemon;

    public PokemonPanel() : base()
    {
        InitializeComponent();

        ContextMenu = contextMenu;
    }

    private void InitializeComponent()
    {
            this.speciesIcon = new System.Windows.Forms.PictureBox();
            this.genderIcon = new System.Windows.Forms.PictureBox();
            this.level = new System.Windows.Forms.Label();
            this.tableLayoutPanel1 = new System.Windows.Forms.TableLayoutPanel();
            this.flowLayoutPanel2 = new System.Windows.Forms.FlowLayoutPanel();
            this.contextMenu = new System.Windows.Forms.ContextMenu();
            this.menuItem1 = new System.Windows.Forms.MenuItem();
            ((System.ComponentModel.ISupportInitialize)(this.speciesIcon)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.genderIcon)).BeginInit();
            this.tableLayoutPanel1.SuspendLayout();
            this.flowLayoutPanel2.SuspendLayout();
            this.SuspendLayout();
            // 
            // speciesIcon
            // 
            this.speciesIcon.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.speciesIcon.Location = new System.Drawing.Point(10, 0);
            this.speciesIcon.Margin = new System.Windows.Forms.Padding(0);
            this.speciesIcon.MaximumSize = new System.Drawing.Size(40, 30);
            this.speciesIcon.MinimumSize = new System.Drawing.Size(40, 30);
            this.speciesIcon.Name = "speciesIcon";
            this.speciesIcon.Size = new System.Drawing.Size(40, 30);
            this.speciesIcon.TabIndex = 0;
            this.speciesIcon.TabStop = false;
            this.speciesIcon.Click += new System.EventHandler(this.pictureBox1_Click);
            // 
            // genderIcon
            // 
            this.genderIcon.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.genderIcon.Location = new System.Drawing.Point(40, 3);
            this.genderIcon.MaximumSize = new System.Drawing.Size(7, 10);
            this.genderIcon.Name = "genderIcon";
            this.genderIcon.Size = new System.Drawing.Size(7, 10);
            this.genderIcon.TabIndex = 2;
            this.genderIcon.TabStop = false;
            // 
            // level
            // 
            this.level.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Left | System.Windows.Forms.AnchorStyles.Right)));
            this.level.AutoSize = true;
            this.level.Location = new System.Drawing.Point(3, 1);
            this.level.Name = "level";
            this.level.Size = new System.Drawing.Size(31, 13);
            this.level.TabIndex = 4;
            this.level.Text = "Lv. 1";
            this.level.Click += new System.EventHandler(this.level_Click);
            // 
            // tableLayoutPanel1
            // 
            this.tableLayoutPanel1.ColumnCount = 1;
            this.tableLayoutPanel1.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 50F));
            this.tableLayoutPanel1.Controls.Add(this.speciesIcon, 0, 0);
            this.tableLayoutPanel1.Controls.Add(this.flowLayoutPanel2, 0, 1);
            this.tableLayoutPanel1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tableLayoutPanel1.Location = new System.Drawing.Point(0, 0);
            this.tableLayoutPanel1.Name = "tableLayoutPanel1";
            this.tableLayoutPanel1.RowCount = 2;
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 50F));
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 20F));
            this.tableLayoutPanel1.Size = new System.Drawing.Size(60, 50);
            this.tableLayoutPanel1.TabIndex = 1;
            // 
            // flowLayoutPanel2
            // 
            this.flowLayoutPanel2.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.flowLayoutPanel2.AutoSize = true;
            this.flowLayoutPanel2.Controls.Add(this.level);
            this.flowLayoutPanel2.Controls.Add(this.genderIcon);
            this.flowLayoutPanel2.Location = new System.Drawing.Point(5, 33);
            this.flowLayoutPanel2.Name = "flowLayoutPanel2";
            this.flowLayoutPanel2.Size = new System.Drawing.Size(50, 14);
            this.flowLayoutPanel2.TabIndex = 5;
            // 
            // contextMenu
            // 
            this.contextMenu.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
            this.menuItem1});
            // 
            // menuItem1
            // 
            this.menuItem1.Index = 0;
            this.menuItem1.Text = "Save .pkx";
            this.menuItem1.Click += new System.EventHandler(this.menuItem1_Click);
            // 
            // PokemonPanel
            // 
            this.Controls.Add(this.tableLayoutPanel1);
            this.MinimumSize = new System.Drawing.Size(60, 50);
            this.Name = "PokemonPanel";
            this.Size = new System.Drawing.Size(60, 50);
            ((System.ComponentModel.ISupportInitialize)(this.speciesIcon)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.genderIcon)).EndInit();
            this.tableLayoutPanel1.ResumeLayout(false);
            this.tableLayoutPanel1.PerformLayout();
            this.flowLayoutPanel2.ResumeLayout(false);
            this.flowLayoutPanel2.PerformLayout();
            this.ResumeLayout(false);

    }

    public void DisplayPokemon(Pokemon? pokemon)
    {
        if (pokemon is null)
        {
            Visible = false;
            return;
        }

        Visible = true;

        speciesIcon.Image = Species.GetIcon(pokemon);

        genderIcon.Image = Image.FromFile(Path.Combine([Pokebot.ImagesPath, $"{pokemon.Gender.ToLower()}.png"]));

        level.Text = $"Lv {pokemon.Level}";

        displayedPokemon = pokemon;
    }

    private void pictureBox1_Click(object sender, System.EventArgs e)
    {

    }

    private void level_Click(object sender, System.EventArgs e)
    {

    }

    private void menuItem1_Click(object sender, System.EventArgs e)
    {
        if (Pokebot.CurrentGame is null)
            throw new Exception("Can't save Pokemon with no game loaded");

        string speciesId = displayedPokemon.SpeciesIndex.ToString("04");
        string shinyStar = displayedPokemon.IsShiny ? " ★" : "";
        string nickname = displayedPokemon.IsNicknamed ? displayedPokemon.Nickname : displayedPokemon.Species;
        string checksum = displayedPokemon.Checksum.ToString("X4");
        string pid = displayedPokemon.PID.ToString("X8");
        string extension = $".pk{Pokebot.CurrentGame.Generation}";
        string filename = $"{speciesId}{shinyStar} - {nickname} - {checksum}{pid}{extension}";

        SaveFileDialog dialog = new()
        {
            Title = "Save Pokemon to File",
            FileName = filename
        };

        if (dialog.ShowDialog() == DialogResult.OK)
        {
            var path = dialog.FileName;
            File.WriteAllBytes(path, displayedPokemon.Raw);
        }
    }
}
