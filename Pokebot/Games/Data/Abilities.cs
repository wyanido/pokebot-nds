using Wyanido.Pokebot.Games.Titles;

namespace Wyanido.Pokebot.Games.Data
{
    public class Abilities : GameDataCollection<Abilities>
    {
        public readonly string[] List;

        public Abilities(IGame game)
        {
            Instance = this;

            List = game.Generation switch
            {
                4 => ParseAbilityList("gen-iv.json"),
                5 => ParseAbilityList("gen-v.json"),
                6 => ParseAbilityList((game is OmegaRubyAlphaSapphire) ? "oras.json" : "xy.json"),
                7 => ParseAbilityList((game is UltraSunUltraMoon) ? "usum.json" : "sm.json"),
                _ => []
            };
        }

        private string[] ParseAbilityList(string filename) => ParseDataJson<string[]>(["abilities", filename]);

        public static string GetName(int abilityIndex) => Instance.List[abilityIndex];
    }
}
