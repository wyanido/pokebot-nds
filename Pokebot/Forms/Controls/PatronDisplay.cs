using System.ComponentModel;
using System.Drawing;
using System.Windows.Forms;

namespace Wyanido.Pokebot.Forms.Controls;

public class PatronDisplay : UserControl
{
    private Label username;
    private PictureBox icon;

    [Description("Patron Name")]
    public string PatronName
    {
        get => username.Text;
        set => username.Text = value;
    }

    [Description("Patron Icon")]
    public Image PatronIcon
    {
        get => icon.Image;
        set => icon.Image = value;
    }

    public PatronDisplay() : base()
    {
        InitializeComponent();
    }

    public void InitializeComponent()
    {
            this.icon = new System.Windows.Forms.PictureBox();
            this.username = new System.Windows.Forms.Label();
            ((System.ComponentModel.ISupportInitialize)(this.icon)).BeginInit();
            this.SuspendLayout();
            // 
            // icon
            // 
            this.icon.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.icon.Location = new System.Drawing.Point(3, 3);
            this.icon.Name = "icon";
            this.icon.Size = new System.Drawing.Size(32, 32);
            this.icon.TabIndex = 0;
            this.icon.TabStop = false;
            // 
            // username
            // 
            this.username.AutoSize = true;
            this.username.Location = new System.Drawing.Point(41, 13);
            this.username.Name = "username";
            this.username.Size = new System.Drawing.Size(55, 13);
            this.username.TabIndex = 1;
            this.username.Text = "Username";
            // 
            // PatronDisplay
            // 
            this.Controls.Add(this.username);
            this.Controls.Add(this.icon);
            this.MaximumSize = new System.Drawing.Size(140, 38);
            this.Name = "PatronDisplay";
            this.Size = new System.Drawing.Size(111, 38);
            ((System.ComponentModel.ISupportInitialize)(this.icon)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

    }
}
