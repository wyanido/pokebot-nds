using Wyanido.Pokebot.Games.Titles;
using Wyanido.Pokebot.Games.Titles;

namespace Wyanido.Pokebot.Games.Data
{
    public class Maps : GameDataCollection<Maps>
    {
        public readonly string[] List;

        public Maps(IGame game)
        {
            Instance = this;

            var isHgss = game is HeartGoldSoulSilver;
            var isPlat = game is Platinum;
            var isB2w2 = game.GameCode == "B2" || game.GameCode == "W2";
            var isOras = game.GameCode == "OR" || game.GameCode == "AS";
            var isUsum = game.GameCode == "US" || game.GameCode == "UM";

            List = game.Generation switch
            {
                4 => ParseMapList(isHgss ? "hgss.json" : isPlat ? "pl.json" : "dp.json"),
                5 => ParseMapList(isB2w2 ? "b2w2.json" : "bw.json"),
                6 => ParseMapList(isOras ? "oras.json" : "xy.json"),
                7 => ParseMapList(isUsum ? "usum.json" : "sm.json"),
                _ => []
            };
        }

        private string[] ParseMapList(string filename) => ParseDataJson<string[]>(["maps", filename]);

        public static string GetName(int mapHeader) => Instance.List[mapHeader];
    }
}
