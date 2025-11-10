using System.Windows.Forms;

namespace Wyanido.Pokebot.Forms;

public sealed partial class Dashboard
{
    private GroupBox groupBox3;
    private TableLayoutPanel tableLayoutPanel1;
    private GroupBox groupBox2;
    private GroupBox groupBox1;

    private void InitializeComponent()
    {
        this.groupBox1 = new System.Windows.Forms.GroupBox();
        this.groupBox3 = new System.Windows.Forms.GroupBox();
        this.tableLayoutPanel1 = new System.Windows.Forms.TableLayoutPanel();
        this.groupBox2 = new System.Windows.Forms.GroupBox();
        this.tableLayoutPanel1.SuspendLayout();
        this.SuspendLayout();
        // 
        // groupBox1
        // 
        this.groupBox1.Dock = System.Windows.Forms.DockStyle.Fill;
        this.groupBox1.Location = new System.Drawing.Point(3, 3);
        this.groupBox1.Name = "groupBox1";
        this.groupBox1.Size = new System.Drawing.Size(258, 111);
        this.groupBox1.TabIndex = 0;
        this.groupBox1.TabStop = false;
        this.groupBox1.Text = "Stats";
        // 
        // groupBox3
        // 
        this.groupBox3.Dock = System.Windows.Forms.DockStyle.Fill;
        this.groupBox3.Location = new System.Drawing.Point(267, 120);
        this.groupBox3.Name = "groupBox3";
        this.groupBox3.Size = new System.Drawing.Size(279, 329);
        this.groupBox3.TabIndex = 2;
        this.groupBox3.TabStop = false;
        this.groupBox3.Text = "Recent Targets";
        // 
        // tableLayoutPanel1
        // 
        this.tableLayoutPanel1.ColumnCount = 2;
        this.tableLayoutPanel1.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 48.08743F));
        this.tableLayoutPanel1.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 51.91257F));
        this.tableLayoutPanel1.Controls.Add(this.groupBox2, 0, 1);
        this.tableLayoutPanel1.Controls.Add(this.groupBox3, 1, 1);
        this.tableLayoutPanel1.Controls.Add(this.groupBox1, 0, 0);
        this.tableLayoutPanel1.Dock = System.Windows.Forms.DockStyle.Fill;
        this.tableLayoutPanel1.Location = new System.Drawing.Point(0, 0);
        this.tableLayoutPanel1.Name = "tableLayoutPanel1";
        this.tableLayoutPanel1.RowCount = 2;
        this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 25.88496F));
        this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 74.11504F));
        this.tableLayoutPanel1.Size = new System.Drawing.Size(549, 452);
        this.tableLayoutPanel1.TabIndex = 3;
        // 
        // groupBox2
        // 
        this.groupBox2.Location = new System.Drawing.Point(3, 120);
        this.groupBox2.Name = "groupBox2";
        this.groupBox2.Size = new System.Drawing.Size(258, 329);
        this.groupBox2.TabIndex = 3;
        this.groupBox2.TabStop = false;
        this.groupBox2.Text = "Recently Seen";
        // 
        // Dashboard
        // 
        this.Controls.Add(this.tableLayoutPanel1);
        this.Name = "Dashboard";
        this.Size = new System.Drawing.Size(549, 452);
        this.tableLayoutPanel1.ResumeLayout(false);
        this.ResumeLayout(false);
    }
}
