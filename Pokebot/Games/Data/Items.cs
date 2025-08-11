using System.Drawing;
using System.IO;
using Wyanido.Pokebot.Games.Titles;

namespace Wyanido.Pokebot.Games.Data
{
    public class Items : GameDataCollection<Items>
    {
        public readonly string[] List;

        private readonly static Image FallbackIcon = Image.FromFile(Path.Combine([Pokebot.ImagesPath, "items", "unknown.png"]));

        public Items(IGame game)
        {
            Instance = this;

            List = game.Generation switch
            {
                4 => ParseItemList("gen-iv.json"),
                5 => ParseItemList("gen-v.json"),
                6 => ParseItemList((game is OmegaRubyAlphaSapphire) ? "oras.json" : "xy.json"),
                7 => ParseItemList((game is UltraSunUltraMoon) ? "usum.json" : "sm.json"),
                _ => []
            };
        }

        private string[] ParseItemList(string filename) => ParseDataJson<string[]>(["items", filename]);

        public static string GetName(int index) => index >= Instance.List.Length ? "???" : Instance.List[index];

        public static Image GetIcon(int index)
        {
            var name = GetName(index).ToLower();
            var path = Path.Combine([Pokebot.ImagesPath, "items", $"{name}.png"]);

            if (!File.Exists(path))
                return FallbackIcon;

            return Image.FromFile(path);
        }
    }
}