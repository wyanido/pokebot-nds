using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Wyanido.Pokebot.Forms;

public sealed partial class ScriptConfig
{
    private System.Windows.Forms.FlowLayoutPanel flowLayoutPanel;

    private void InitializeComponent()
    {
        this.flowLayoutPanel = new System.Windows.Forms.FlowLayoutPanel();
        this.SuspendLayout();
        // 
        // flowLayoutPanel
        // 
        this.flowLayoutPanel.AutoScroll = true;
        this.flowLayoutPanel.Dock = System.Windows.Forms.DockStyle.Fill;
        this.flowLayoutPanel.FlowDirection = System.Windows.Forms.FlowDirection.TopDown;
        this.flowLayoutPanel.Location = new System.Drawing.Point(0, 0);
        this.flowLayoutPanel.Name = "flowLayoutPanel";
        this.flowLayoutPanel.Size = new System.Drawing.Size(329, 305);
        this.flowLayoutPanel.TabIndex = 0;
        this.flowLayoutPanel.WrapContents = false;
        // 
        // ConfigPage
        // 
        this.Controls.Add(this.flowLayoutPanel);
        this.Name = "ConfigPage";
        this.Size = new System.Drawing.Size(329, 305);
        this.ResumeLayout(false);

    }
}
