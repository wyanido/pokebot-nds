using System.Drawing;
using Wyanido.Pokebot.Games.Collections;

namespace Wyanido.Pokebot.Games.Data
{
    public class Items : GameDataCollection<Items>
    {
        public readonly string[] List;

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

        public static string GetName(int index) => Instance.List[index];

        public static Image GetIcon(int index) => Image.FromFile("Resources/items/unknown.png");
    }
}