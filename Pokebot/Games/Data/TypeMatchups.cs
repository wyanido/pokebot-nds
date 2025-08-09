using Newtonsoft.Json;
using System.Collections.Generic;

namespace Wyanido.Pokebot.Games.Data
{
    public class TypeMatchup
    {
        [JsonProperty("cant_hit")]
        public readonly string[] CantHitTypes;

        [JsonProperty("super_effective_against")]
        public readonly string[] SuperEffectiveAgainstTypes;

        [JsonProperty("resisted_by")]
        public readonly string[] ResistedByTypes;
    }

    public class TypeMatchups : GameDataCollection<TypeMatchups>
    {
        public readonly Dictionary<string, TypeMatchup> List;

        public TypeMatchups(IGame game)
        {
            Instance = this;

            var filename = game.Generation < 6 ? "type_chart_ii.json" : "type_chart_vi.json";
            List = ParseDataJson<Dictionary<string, TypeMatchup>>([filename]);
        }

        public static TypeMatchup GetMatchup(string typeName) => Instance.List[typeName];
    }
}
