using System.Drawing;
using System.IO;
using System.Windows.Forms;
using Wyanido.Pokebot.Games.Data;

namespace Wyanido.Pokebot.Forms.Controls;

public class PokemonRow : UserControl, IContainerControl
{
    private PictureBox itemIcon;
    private PictureBox genderIcon;
    private FlowLayoutPanel flowLayoutPanel1;
    private Label speciesName;
    private Label level;
    private PictureBox speciesIcon;

    public PokemonRow() : base()
    {
        InitializeComponent();
    }

    private void InitializeComponent()
    {
            speciesIcon = new PictureBox();
            itemIcon = new PictureBox();
            genderIcon = new PictureBox();
            flowLayoutPanel1 = new FlowLayoutPanel();
            speciesName = new Label();
            level = new Label();
            ((System.ComponentModel.ISupportInitialize)speciesIcon).BeginInit();
            ((System.ComponentModel.ISupportInitialize)itemIcon).BeginInit();
            ((System.ComponentModel.ISupportInitialize)genderIcon).BeginInit();
            flowLayoutPanel1.SuspendLayout();
            SuspendLayout();
            // 
            // speciesIcon
            // 
            speciesIcon.Anchor = AnchorStyles.None;
            speciesIcon.Location = new Point(3, 3);
            speciesIcon.MaximumSize = new Size(40, 30);
            speciesIcon.MinimumSize = new Size(40, 30);
            speciesIcon.Name = "speciesIcon";
            speciesIcon.Size = new Size(40, 30);
            speciesIcon.TabIndex = 0;
            speciesIcon.TabStop = false;
            speciesIcon.Click += new System.EventHandler(pictureBox1_Click);
            // 
            // itemIcon
            // 
            itemIcon.Dock = DockStyle.Left;
            itemIcon.Location = new Point(140, 3);
            itemIcon.Name = "itemIcon";
            itemIcon.Size = new Size(32, 30);
            itemIcon.TabIndex = 1;
            itemIcon.TabStop = false;
            // 
            // genderIcon
            // 
            genderIcon.Anchor = AnchorStyles.None;
            genderIcon.Location = new Point(127, 13);
            genderIcon.MaximumSize = new Size(7, 10);
            genderIcon.Name = "genderIcon";
            genderIcon.Size = new Size(7, 10);
            genderIcon.TabIndex = 2;
            genderIcon.TabStop = false;
            // 
            // flowLayoutPanel1
            // 
            flowLayoutPanel1.BorderStyle = BorderStyle.Fixed3D;
            flowLayoutPanel1.Controls.Add(speciesIcon);
            flowLayoutPanel1.Controls.Add(speciesName);
            flowLayoutPanel1.Controls.Add(level);
            flowLayoutPanel1.Controls.Add(genderIcon);
            flowLayoutPanel1.Controls.Add(itemIcon);
            flowLayoutPanel1.Dock = DockStyle.Fill;
            flowLayoutPanel1.Location = new Point(0, 0);
            flowLayoutPanel1.Name = "flowLayoutPanel1";
            flowLayoutPanel1.Size = new Size(328, 37);
            flowLayoutPanel1.TabIndex = 3;
            // 
            // speciesName
            // 
            speciesName.Anchor = AnchorStyles.None;
            speciesName.AutoSize = true;
            speciesName.Location = new Point(46, 11);
            speciesName.Margin = new Padding(0);
            speciesName.Name = "speciesName";
            speciesName.Size = new Size(41, 13);
            speciesName.TabIndex = 3;
            speciesName.Text = "Unown";
            speciesName.TextAlign = ContentAlignment.MiddleCenter;
            // 
            // level
            // 
            level.Anchor = AnchorStyles.None;
            level.AutoSize = true;
            level.Location = new Point(90, 11);
            level.Name = "level";
            level.Size = new Size(31, 13);
            level.TabIndex = 4;
            level.Text = "Lv. 1";
            level.Click += new System.EventHandler(level_Click);
            // 
            // PokemonPanel
            // 
            Controls.Add(flowLayoutPanel1);
            Name = "PokemonPanel";
            Size = new Size(328, 37);
            ((System.ComponentModel.ISupportInitialize)speciesIcon).EndInit();
            ((System.ComponentModel.ISupportInitialize)itemIcon).EndInit();
            ((System.ComponentModel.ISupportInitialize)genderIcon).EndInit();
            flowLayoutPanel1.ResumeLayout(false);
            flowLayoutPanel1.PerformLayout();
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

        genderIcon.Image = Image.FromFile(Path.Combine([Pokebot.ImagesPath, "female.png"]));

        itemIcon.Image = Items.GetIcon(pokemon.HeldItemIndex);

        level.Text = pokemon.Level.ToString();

        speciesName.Text = pokemon.Species.Name;
    }

    private void pictureBox1_Click(object sender, System.EventArgs e)
    {

    }

    private void level_Click(object sender, System.EventArgs e)
    {

    }
}
