using System.Windows.Forms;

namespace Wyanido.Pokebot.Forms
{
    public sealed partial class About : Form
    {
        public About() : base()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, System.EventArgs e)
        {
            System.Diagnostics.Process.Start("https://github.com/wyanido/pokebot-nds");
        }

        private void button3_Click(object sender, System.EventArgs e)
        {
            System.Diagnostics.Process.Start("https://www.patreon.com/c/wyanido");
        }
    }
}
