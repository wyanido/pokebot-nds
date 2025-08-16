using System;
using System.Drawing;
using System.IO;
using System.Windows.Forms;
using Wyanido.Pokebot.Games.Data;

namespace Wyanido.Pokebot.Forms.Controls;

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
            speciesIcon = new PictureBox();
            genderIcon = new PictureBox();
            level = new Label();
            tableLayoutPanel1 = new TableLayoutPanel();
            flowLayoutPanel2 = new FlowLayoutPanel();
            contextMenu = new ContextMenu();
            menuItem1 = new MenuItem();
            ((System.ComponentModel.ISupportInitialize)speciesIcon).BeginInit();
            ((System.ComponentModel.ISupportInitialize)genderIcon).BeginInit();
            tableLayoutPanel1.SuspendLayout();
            flowLayoutPanel2.SuspendLayout();
            SuspendLayout();
            // 
            // speciesIcon
            // 
            speciesIcon.Anchor = AnchorStyles.None;
            speciesIcon.Location = new Point(10, 0);
            speciesIcon.Margin = new Padding(0);
            speciesIcon.MaximumSize = new Size(40, 30);
            speciesIcon.MinimumSize = new Size(40, 30);
            speciesIcon.Name = "speciesIcon";
            speciesIcon.Size = new Size(40, 30);
            speciesIcon.TabIndex = 0;
            speciesIcon.TabStop = false;
            speciesIcon.Click += new EventHandler(pictureBox1_Click);
            // 
            // genderIcon
            // 
            genderIcon.Anchor = AnchorStyles.None;
            genderIcon.Location = new Point(40, 3);
            genderIcon.MaximumSize = new Size(7, 10);
            genderIcon.Name = "genderIcon";
            genderIcon.Size = new Size(7, 10);
            genderIcon.TabIndex = 2;
            genderIcon.TabStop = false;
            // 
            // level
            // 
            level.Anchor = AnchorStyles.Left | AnchorStyles.Right;
            level.AutoSize = true;
            level.Location = new Point(3, 1);
            level.Name = "level";
            level.Size = new Size(31, 13);
            level.TabIndex = 4;
            level.Text = "Lv. 1";
            level.Click += new EventHandler(level_Click);
            // 
            // tableLayoutPanel1
            // 
            tableLayoutPanel1.ColumnCount = 1;
            tableLayoutPanel1.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50F));
            tableLayoutPanel1.Controls.Add(speciesIcon, 0, 0);
            tableLayoutPanel1.Controls.Add(flowLayoutPanel2, 0, 1);
            tableLayoutPanel1.Dock = DockStyle.Fill;
            tableLayoutPanel1.Location = new Point(0, 0);
            tableLayoutPanel1.Name = "tableLayoutPanel1";
            tableLayoutPanel1.RowCount = 2;
            tableLayoutPanel1.RowStyles.Add(new RowStyle(SizeType.Percent, 50F));
            tableLayoutPanel1.RowStyles.Add(new RowStyle(SizeType.Absolute, 20F));
            tableLayoutPanel1.Size = new Size(60, 50);
            tableLayoutPanel1.TabIndex = 1;
            // 
            // flowLayoutPanel2
            // 
            flowLayoutPanel2.Anchor = AnchorStyles.None;
            flowLayoutPanel2.AutoSize = true;
            flowLayoutPanel2.Controls.Add(level);
            flowLayoutPanel2.Controls.Add(genderIcon);
            flowLayoutPanel2.Location = new Point(5, 33);
            flowLayoutPanel2.Name = "flowLayoutPanel2";
            flowLayoutPanel2.Size = new Size(50, 14);
            flowLayoutPanel2.TabIndex = 5;
            // 
            // contextMenu
            // 
            contextMenu.MenuItems.AddRange(new MenuItem[] {
            menuItem1});
            // 
            // menuItem1
            // 
            menuItem1.Index = 0;
            menuItem1.Text = "Save .pkx";
            menuItem1.Click += new EventHandler(menuItem1_Click);
            // 
            // PokemonPanel
            // 
            Controls.Add(tableLayoutPanel1);
            MinimumSize = new Size(60, 50);
            Name = "PokemonPanel";
            Size = new Size(60, 50);
            ((System.ComponentModel.ISupportInitialize)speciesIcon).EndInit();
            ((System.ComponentModel.ISupportInitialize)genderIcon).EndInit();
            tableLayoutPanel1.ResumeLayout(false);
            tableLayoutPanel1.PerformLayout();
            flowLayoutPanel2.ResumeLayout(false);
            flowLayoutPanel2.PerformLayout();
            ResumeLayout(false);

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

    private void pictureBox1_Click(object sender, EventArgs e)
    {

    }

    private void level_Click(object sender, EventArgs e)
    {

    }

    private void menuItem1_Click(object sender, EventArgs e)
    {
        if (Pokebot.CurrentGame is null)
            throw new Exception("Can't save Pokemon with no game loaded");

        string speciesId = displayedPokemon.SpeciesIndex.ToString("04");
        string shinyStar = displayedPokemon.IsShiny ? " ★" : "";
        string nickname = displayedPokemon.IsNicknamed ? displayedPokemon.Nickname : displayedPokemon.Species.Name;
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
