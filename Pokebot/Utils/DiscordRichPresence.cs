using DiscordRPC;
using DiscordRPC.Logging;
using System;
using System.Windows.Forms;
using Button = DiscordRPC.Button;

namespace Wyanido.Pokebot.Utils
{
    public class DiscordRichPresence : IDisposable
    {
        public RichPresence presence;

        private const string applicationID = "1406680584834781185";
        private const string version = "v1.3-beta";

        private readonly DiscordRpcClient client;

        public DiscordRichPresence()
        {
            client = new(applicationID)
            {
                Logger = new ConsoleLogger() { Level = LogLevel.Warning }
            };

            client.OnReady += (sender, e) =>
            {
                Console.WriteLine("Received Ready from user {0}", e.User.Username);
            };

            client.OnPresenceUpdate += (sender, e) =>
            {
                Console.WriteLine("Received Update! {0}", e.Presence);
            };

            client.Initialize();
            SetDefaultStatus();
        }

        public void SetDefaultStatus()
        {
            Set(new RichPresence()
            {
                State = "No game loaded!",
                Details = $"Running {version}",
                Timestamps = null,
                Buttons = [
                    new Button()
                    {
                        Label = "View on GitHub",
                        Url = "https://github.com/wyanido/pokebot-nds",
                    }
                ]
            });
        }

        public void SetState(string state)
        {
            presence.State = state;
            Update();
        }

        public void Set(RichPresence presence)
        {
            this.presence = presence;
            Update();
        }

        public void Update()
        {
            try
            {
                client.SetPresence(presence);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error setting Discord presence",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        public void Clear()
        {
            try
            {
                client.ClearPresence();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error setting Discord presence",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        public void Dispose()
        {
            Clear();
        }
    }
}
