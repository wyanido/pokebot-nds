using System.ComponentModel;
using System.Drawing;
using System.Windows.Forms;

namespace Wyanido.Pokebot.Forms.Controls;

public class PatronDisplay : UserControl
{
    private Label label1;
    private PictureBox pictureBox1;

    [Description("Patron Name")]
    public string PatronName
    {
        get => label1.Text;
        set => label1.Text = value;
    }

    [Description("Patron Icon")]
    public Image PatronIcon
    {
        get => pictureBox1.Image;
        set => pictureBox1.Image = value;
    }

    public PatronDisplay() : base()
    {
        InitializeComponent();
    }

    public void InitializeComponent()
    {
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.label1 = new System.Windows.Forms.Label();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
            this.SuspendLayout();
            // 
            // pictureBox1
            // 
            this.pictureBox1.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.pictureBox1.Location = new System.Drawing.Point(3, 3);
            this.pictureBox1.Name = "pictureBox1";
            this.pictureBox1.Size = new System.Drawing.Size(32, 32);
            this.pictureBox1.TabIndex = 0;
            this.pictureBox1.TabStop = false;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(41, 13);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(35, 13);
            this.label1.TabIndex = 1;
            this.label1.Text = "label1";
            // 
            // PatronDisplay
            // 
            this.Controls.Add(this.label1);
            this.Controls.Add(this.pictureBox1);
            this.MaximumSize = new System.Drawing.Size(140, 38);
            this.Name = "PatronDisplay";
            this.Size = new System.Drawing.Size(111, 38);
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

    }
}
