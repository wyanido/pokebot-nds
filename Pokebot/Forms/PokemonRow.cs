using System.Drawing;
using System.IO;
using System.Windows.Forms;
using Wyanido.Pokebot.Games.Data;

namespace Wyanido.Pokebot.Forms;

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
            this.speciesIcon = new System.Windows.Forms.PictureBox();
            this.itemIcon = new System.Windows.Forms.PictureBox();
            this.genderIcon = new System.Windows.Forms.PictureBox();
            this.flowLayoutPanel1 = new System.Windows.Forms.FlowLayoutPanel();
            this.speciesName = new System.Windows.Forms.Label();
            this.level = new System.Windows.Forms.Label();
            ((System.ComponentModel.ISupportInitialize)(this.speciesIcon)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.itemIcon)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.genderIcon)).BeginInit();
            this.flowLayoutPanel1.SuspendLayout();
            this.SuspendLayout();
            // 
            // speciesIcon
            // 
            this.speciesIcon.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.speciesIcon.Location = new System.Drawing.Point(3, 3);
            this.speciesIcon.MaximumSize = new System.Drawing.Size(40, 30);
            this.speciesIcon.MinimumSize = new System.Drawing.Size(40, 30);
            this.speciesIcon.Name = "speciesIcon";
            this.speciesIcon.Size = new System.Drawing.Size(40, 30);
            this.speciesIcon.TabIndex = 0;
            this.speciesIcon.TabStop = false;
            this.speciesIcon.Click += new System.EventHandler(this.pictureBox1_Click);
            // 
            // itemIcon
            // 
            this.itemIcon.Dock = System.Windows.Forms.DockStyle.Left;
            this.itemIcon.Location = new System.Drawing.Point(140, 3);
            this.itemIcon.Name = "itemIcon";
            this.itemIcon.Size = new System.Drawing.Size(32, 30);
            this.itemIcon.TabIndex = 1;
            this.itemIcon.TabStop = false;
            // 
            // genderIcon
            // 
            this.genderIcon.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.genderIcon.Location = new System.Drawing.Point(127, 13);
            this.genderIcon.MaximumSize = new System.Drawing.Size(7, 10);
            this.genderIcon.Name = "genderIcon";
            this.genderIcon.Size = new System.Drawing.Size(7, 10);
            this.genderIcon.TabIndex = 2;
            this.genderIcon.TabStop = false;
            // 
            // flowLayoutPanel1
            // 
            this.flowLayoutPanel1.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.flowLayoutPanel1.Controls.Add(this.speciesIcon);
            this.flowLayoutPanel1.Controls.Add(this.speciesName);
            this.flowLayoutPanel1.Controls.Add(this.level);
            this.flowLayoutPanel1.Controls.Add(this.genderIcon);
            this.flowLayoutPanel1.Controls.Add(this.itemIcon);
            this.flowLayoutPanel1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.flowLayoutPanel1.Location = new System.Drawing.Point(0, 0);
            this.flowLayoutPanel1.Name = "flowLayoutPanel1";
            this.flowLayoutPanel1.Size = new System.Drawing.Size(328, 37);
            this.flowLayoutPanel1.TabIndex = 3;
            // 
            // speciesName
            // 
            this.speciesName.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.speciesName.AutoSize = true;
            this.speciesName.Location = new System.Drawing.Point(46, 11);
            this.speciesName.Margin = new System.Windows.Forms.Padding(0);
            this.speciesName.Name = "speciesName";
            this.speciesName.Size = new System.Drawing.Size(41, 13);
            this.speciesName.TabIndex = 3;
            this.speciesName.Text = "Unown";
            this.speciesName.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // level
            // 
            this.level.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.level.AutoSize = true;
            this.level.Location = new System.Drawing.Point(90, 11);
            this.level.Name = "level";
            this.level.Size = new System.Drawing.Size(31, 13);
            this.level.TabIndex = 4;
            this.level.Text = "Lv. 1";
            this.level.Click += new System.EventHandler(this.level_Click);
            // 
            // PokemonPanel
            // 
            this.Controls.Add(this.flowLayoutPanel1);
            this.Name = "PokemonPanel";
            this.Size = new System.Drawing.Size(328, 37);
            ((System.ComponentModel.ISupportInitialize)(this.speciesIcon)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.itemIcon)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.genderIcon)).EndInit();
            this.flowLayoutPanel1.ResumeLayout(false);
            this.flowLayoutPanel1.PerformLayout();
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

        genderIcon.Image = Image.FromFile(Path.Combine([Pokebot.ImagesPath, "female.png"]));

        itemIcon.Image = Items.GetIcon(pokemon.HeldItemIndex);

        level.Text = pokemon.Level.ToString();

        speciesName.Text = pokemon.Species;
    }

    private void pictureBox1_Click(object sender, System.EventArgs e)
    {

    }

    private void level_Click(object sender, System.EventArgs e)
    {

    }
}
