using System.Windows.Forms;

namespace Wyanido.Pokebot;

public class PokemonEncounter : UserControl, IContainerControl
{
    private PictureBox pictureBox1;

    public PokemonEncounter() : base()
    {
        InitializeComponent();
    }

    private void InitializeComponent()
    {
        this.pictureBox1 = new System.Windows.Forms.PictureBox();
        ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
        this.SuspendLayout();
        // 
        // pictureBox1
        // 
        this.pictureBox1.Dock = System.Windows.Forms.DockStyle.Left;
        this.pictureBox1.Image = global::Wyanido.Pokebot.Properties.Resources._001;
        this.pictureBox1.Location = new System.Drawing.Point(0, 0);
        this.pictureBox1.Name = "pictureBox1";
        this.pictureBox1.Size = new System.Drawing.Size(100, 43);
        this.pictureBox1.TabIndex = 0;
        this.pictureBox1.TabStop = false;
        this.pictureBox1.Click += new System.EventHandler(this.pictureBox1_Click);
        // 
        // ControlTest
        // 
        this.Controls.Add(this.pictureBox1);
        this.Name = "ControlTest";
        this.Size = new System.Drawing.Size(281, 43);
        ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
        this.ResumeLayout(false);

    }

    private void pictureBox1_Click(object sender, System.EventArgs e)
    {

    }
}
