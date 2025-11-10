using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Wyanido.Pokebot.Forms.Controls;

namespace Wyanido.Pokebot.Forms
{
    public sealed partial class About
    {
        private FlowLayoutPanel flowLayoutPanel1;
        private Label label3;
        private FlowLayoutPanel flowLayoutPanel2;
        private FlowLayoutPanel flowLayoutPanel3;
        private PatronDisplay patronDisplay1;
        private Button button1;
        private Button button3;
        private PatronDisplay patronDisplay2;
        private PatronDisplay patronDisplay3;
        private PatronDisplay patronDisplay4;
        private PatronDisplay patronDisplay5;
        private PatronDisplay patronDisplay6;
        private PatronDisplay patronDisplay7;
        private PatronDisplay patronDisplay8;
        private PatronDisplay patronDisplay9;
        private Label label2;
        private FlowLayoutPanel flowLayoutPanel4;
        private Label label1;

        public void InitializeComponent()
        {
            this.label1 = new System.Windows.Forms.Label();
            this.flowLayoutPanel1 = new System.Windows.Forms.FlowLayoutPanel();
            this.label3 = new System.Windows.Forms.Label();
            this.flowLayoutPanel2 = new System.Windows.Forms.FlowLayoutPanel();
            this.flowLayoutPanel3 = new System.Windows.Forms.FlowLayoutPanel();
            this.button1 = new System.Windows.Forms.Button();
            this.button3 = new System.Windows.Forms.Button();
            this.label2 = new System.Windows.Forms.Label();
            this.flowLayoutPanel4 = new System.Windows.Forms.FlowLayoutPanel();
            this.patronDisplay1 = new Wyanido.Pokebot.Forms.Controls.PatronDisplay();
            this.patronDisplay2 = new Wyanido.Pokebot.Forms.Controls.PatronDisplay();
            this.patronDisplay3 = new Wyanido.Pokebot.Forms.Controls.PatronDisplay();
            this.patronDisplay4 = new Wyanido.Pokebot.Forms.Controls.PatronDisplay();
            this.patronDisplay5 = new Wyanido.Pokebot.Forms.Controls.PatronDisplay();
            this.patronDisplay6 = new Wyanido.Pokebot.Forms.Controls.PatronDisplay();
            this.patronDisplay7 = new Wyanido.Pokebot.Forms.Controls.PatronDisplay();
            this.patronDisplay8 = new Wyanido.Pokebot.Forms.Controls.PatronDisplay();
            this.patronDisplay9 = new Wyanido.Pokebot.Forms.Controls.PatronDisplay();
            this.flowLayoutPanel1.SuspendLayout();
            this.flowLayoutPanel2.SuspendLayout();
            this.flowLayoutPanel3.SuspendLayout();
            this.flowLayoutPanel4.SuspendLayout();
            this.SuspendLayout();
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(3, 27);
            this.label1.Margin = new System.Windows.Forms.Padding(3, 0, 3, 8);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(304, 26);
            this.label1.TabIndex = 0;
            this.label1.Text = "Special thanks to 40 Cakes, evandixon, Kaphotics, YoshiRulz, StoryZealot, Markitu" +
    "s95, and all the contributors of BizHawk!";
            // 
            // flowLayoutPanel1
            // 
            this.flowLayoutPanel1.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Left | System.Windows.Forms.AnchorStyles.Right)));
            this.flowLayoutPanel1.AutoScroll = true;
            this.flowLayoutPanel1.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.flowLayoutPanel1.Controls.Add(this.patronDisplay1);
            this.flowLayoutPanel1.Controls.Add(this.patronDisplay2);
            this.flowLayoutPanel1.Controls.Add(this.patronDisplay3);
            this.flowLayoutPanel1.Controls.Add(this.patronDisplay4);
            this.flowLayoutPanel1.Controls.Add(this.patronDisplay5);
            this.flowLayoutPanel1.Controls.Add(this.patronDisplay6);
            this.flowLayoutPanel1.Controls.Add(this.patronDisplay7);
            this.flowLayoutPanel1.Controls.Add(this.patronDisplay8);
            this.flowLayoutPanel1.Controls.Add(this.patronDisplay9);
            this.flowLayoutPanel1.Location = new System.Drawing.Point(3, 128);
            this.flowLayoutPanel1.Name = "flowLayoutPanel1";
            this.flowLayoutPanel1.Padding = new System.Windows.Forms.Padding(4);
            this.flowLayoutPanel1.Size = new System.Drawing.Size(323, 219);
            this.flowLayoutPanel1.TabIndex = 2;
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F);
            this.label3.Location = new System.Drawing.Point(3, 0);
            this.label3.Margin = new System.Windows.Forms.Padding(3, 0, 3, 10);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(198, 17);
            this.label3.TabIndex = 3;
            this.label3.Text = "Pokebot v1.3-beta by wyanido";
            // 
            // flowLayoutPanel2
            // 
            this.flowLayoutPanel2.AutoSize = true;
            this.flowLayoutPanel2.Controls.Add(this.label3);
            this.flowLayoutPanel2.Controls.Add(this.label1);
            this.flowLayoutPanel2.Controls.Add(this.flowLayoutPanel3);
            this.flowLayoutPanel2.Controls.Add(this.label2);
            this.flowLayoutPanel2.Dock = System.Windows.Forms.DockStyle.Fill;
            this.flowLayoutPanel2.FlowDirection = System.Windows.Forms.FlowDirection.TopDown;
            this.flowLayoutPanel2.Location = new System.Drawing.Point(3, 3);
            this.flowLayoutPanel2.Name = "flowLayoutPanel2";
            this.flowLayoutPanel2.Size = new System.Drawing.Size(317, 119);
            this.flowLayoutPanel2.TabIndex = 4;
            this.flowLayoutPanel2.WrapContents = false;
            // 
            // flowLayoutPanel3
            // 
            this.flowLayoutPanel3.Controls.Add(this.button1);
            this.flowLayoutPanel3.Controls.Add(this.button3);
            this.flowLayoutPanel3.Location = new System.Drawing.Point(3, 64);
            this.flowLayoutPanel3.Margin = new System.Windows.Forms.Padding(3, 3, 3, 8);
            this.flowLayoutPanel3.Name = "flowLayoutPanel3";
            this.flowLayoutPanel3.Size = new System.Drawing.Size(311, 31);
            this.flowLayoutPanel3.TabIndex = 5;
            // 
            // button1
            // 
            this.button1.Anchor = System.Windows.Forms.AnchorStyles.Left;
            this.button1.Image = global::Wyanido.Pokebot.Properties.Resources.github;
            this.button1.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.button1.Location = new System.Drawing.Point(3, 3);
            this.button1.Name = "button1";
            this.button1.Size = new System.Drawing.Size(93, 25);
            this.button1.TabIndex = 5;
            this.button1.Text = "Github";
            this.button1.UseVisualStyleBackColor = true;
            this.button1.Click += new System.EventHandler(this.button1_Click);
            // 
            // button3
            // 
            this.button3.Anchor = System.Windows.Forms.AnchorStyles.Left;
            this.button3.Image = global::Wyanido.Pokebot.Properties.Resources.patreon;
            this.button3.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.button3.Location = new System.Drawing.Point(102, 3);
            this.button3.Name = "button3";
            this.button3.Size = new System.Drawing.Size(91, 25);
            this.button3.TabIndex = 7;
            this.button3.Text = "Patreon";
            this.button3.UseVisualStyleBackColor = true;
            this.button3.Click += new System.EventHandler(this.button3_Click);
            // 
            // label2
            // 
            this.label2.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
            | System.Windows.Forms.AnchorStyles.Right)));
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(3, 103);
            this.label2.Margin = new System.Windows.Forms.Padding(3, 0, 3, 3);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(311, 13);
            this.label2.TabIndex = 6;
            this.label2.Text = "Patreon Supporters";
            this.label2.TextAlign = System.Drawing.ContentAlignment.TopCenter;
            // 
            // flowLayoutPanel4
            // 
            this.flowLayoutPanel4.Controls.Add(this.flowLayoutPanel2);
            this.flowLayoutPanel4.Controls.Add(this.flowLayoutPanel1);
            this.flowLayoutPanel4.Dock = System.Windows.Forms.DockStyle.Fill;
            this.flowLayoutPanel4.Location = new System.Drawing.Point(8, 8);
            this.flowLayoutPanel4.Name = "flowLayoutPanel4";
            this.flowLayoutPanel4.Size = new System.Drawing.Size(327, 354);
            this.flowLayoutPanel4.TabIndex = 7;
            // 
            // patronDisplay1
            // 
            this.patronDisplay1.Location = new System.Drawing.Point(7, 7);
            this.patronDisplay1.MaximumSize = new System.Drawing.Size(140, 38);
            this.patronDisplay1.Name = "patronDisplay1";
            this.patronDisplay1.PatronIcon = global::Wyanido.Pokebot.Properties.Resources.alexandrin;
            this.patronDisplay1.PatronName = "Alexandrin";
            this.patronDisplay1.Size = new System.Drawing.Size(140, 38);
            this.patronDisplay1.TabIndex = 0;
            // 
            // patronDisplay2
            // 
            this.patronDisplay2.Location = new System.Drawing.Point(153, 7);
            this.patronDisplay2.MaximumSize = new System.Drawing.Size(140, 38);
            this.patronDisplay2.Name = "patronDisplay2";
            this.patronDisplay2.PatronIcon = global::Wyanido.Pokebot.Properties.Resources.anon_me;
            this.patronDisplay2.PatronName = "Anon Me";
            this.patronDisplay2.Size = new System.Drawing.Size(140, 38);
            this.patronDisplay2.TabIndex = 1;
            // 
            // patronDisplay3
            // 
            this.patronDisplay3.Location = new System.Drawing.Point(7, 51);
            this.patronDisplay3.MaximumSize = new System.Drawing.Size(140, 38);
            this.patronDisplay3.Name = "patronDisplay3";
            this.patronDisplay3.PatronIcon = global::Wyanido.Pokebot.Properties.Resources.cluelesstatsu;
            this.patronDisplay3.PatronName = "cluelessTatsu";
            this.patronDisplay3.Size = new System.Drawing.Size(140, 38);
            this.patronDisplay3.TabIndex = 2;
            // 
            // patronDisplay4
            // 
            this.patronDisplay4.Location = new System.Drawing.Point(153, 51);
            this.patronDisplay4.MaximumSize = new System.Drawing.Size(140, 38);
            this.patronDisplay4.Name = "patronDisplay4";
            this.patronDisplay4.PatronIcon = global::Wyanido.Pokebot.Properties.Resources.dukmos;
            this.patronDisplay4.PatronName = "Dukmos";
            this.patronDisplay4.Size = new System.Drawing.Size(140, 38);
            this.patronDisplay4.TabIndex = 3;
            // 
            // patronDisplay5
            // 
            this.patronDisplay5.Location = new System.Drawing.Point(7, 95);
            this.patronDisplay5.MaximumSize = new System.Drawing.Size(140, 38);
            this.patronDisplay5.Name = "patronDisplay5";
            this.patronDisplay5.PatronIcon = global::Wyanido.Pokebot.Properties.Resources.javid_khan;
            this.patronDisplay5.PatronName = "javid khan";
            this.patronDisplay5.Size = new System.Drawing.Size(140, 38);
            this.patronDisplay5.TabIndex = 4;
            // 
            // patronDisplay6
            // 
            this.patronDisplay6.Location = new System.Drawing.Point(153, 95);
            this.patronDisplay6.MaximumSize = new System.Drawing.Size(140, 38);
            this.patronDisplay6.Name = "patronDisplay6";
            this.patronDisplay6.PatronIcon = global::Wyanido.Pokebot.Properties.Resources.pearl8520;
            this.patronDisplay6.PatronName = "Pearl8520";
            this.patronDisplay6.Size = new System.Drawing.Size(140, 38);
            this.patronDisplay6.TabIndex = 5;
            // 
            // patronDisplay7
            // 
            this.patronDisplay7.Location = new System.Drawing.Point(7, 139);
            this.patronDisplay7.MaximumSize = new System.Drawing.Size(140, 38);
            this.patronDisplay7.Name = "patronDisplay7";
            this.patronDisplay7.PatronIcon = global::Wyanido.Pokebot.Properties.Resources.sjduwjdx;
            this.patronDisplay7.PatronName = "Sjduwjdx";
            this.patronDisplay7.Size = new System.Drawing.Size(140, 38);
            this.patronDisplay7.TabIndex = 6;
            // 
            // patronDisplay8
            // 
            this.patronDisplay8.Location = new System.Drawing.Point(153, 139);
            this.patronDisplay8.MaximumSize = new System.Drawing.Size(140, 38);
            this.patronDisplay8.Name = "patronDisplay8";
            this.patronDisplay8.PatronIcon = global::Wyanido.Pokebot.Properties.Resources.storyzealot;
            this.patronDisplay8.PatronName = "Story Zealot";
            this.patronDisplay8.Size = new System.Drawing.Size(140, 38);
            this.patronDisplay8.TabIndex = 7;
            // 
            // patronDisplay9
            // 
            this.patronDisplay9.Location = new System.Drawing.Point(7, 183);
            this.patronDisplay9.MaximumSize = new System.Drawing.Size(140, 38);
            this.patronDisplay9.Name = "patronDisplay9";
            this.patronDisplay9.PatronIcon = global::Wyanido.Pokebot.Properties.Resources.tails_kitsune;
            this.patronDisplay9.PatronName = "Tails_Kitsune";
            this.patronDisplay9.Size = new System.Drawing.Size(140, 38);
            this.patronDisplay9.TabIndex = 8;
            // 
            // About
            // 
            this.ClientSize = new System.Drawing.Size(343, 370);
            this.Controls.Add(this.flowLayoutPanel4);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "About";
            this.Padding = new System.Windows.Forms.Padding(8);
            this.Text = "About Pokebot";
            this.flowLayoutPanel1.ResumeLayout(false);
            this.flowLayoutPanel2.ResumeLayout(false);
            this.flowLayoutPanel2.PerformLayout();
            this.flowLayoutPanel3.ResumeLayout(false);
            this.flowLayoutPanel4.ResumeLayout(false);
            this.flowLayoutPanel4.PerformLayout();
            this.ResumeLayout(false);
        }
    }
}
