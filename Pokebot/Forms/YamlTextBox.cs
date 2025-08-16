using System.Windows.Forms;

namespace Wyanido.Pokebot.Forms;

public class YamlTextBox : RichTextBox
{
    private readonly int tabSize = 2;

    public YamlTextBox() : base()
    {
        InitializeComponent();
    }

    private void InitializeComponent()
    {
        this.SuspendLayout();
        // 
        // YamlTextBox
        // 
        this.KeyDown += new System.Windows.Forms.KeyEventHandler(this.YamlTextBox_KeyDown);
        this.PreviewKeyDown += new System.Windows.Forms.PreviewKeyDownEventHandler(this.YamlTextBox_PreviewKeyDown);

        this.ResumeLayout(false);
    }

    private void YamlTextBox_PreviewKeyDown(object sender, PreviewKeyDownEventArgs e)
    {
        if (e.KeyCode == Keys.Tab)
        {
            e.IsInputKey = true;
        }
    }

    private void YamlTextBox_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.KeyCode == Keys.Tab)
        {
            SelectedText = new string(' ', tabSize);
            e.Handled = true;
            e.SuppressKeyPress = true;
        }
    }
}
