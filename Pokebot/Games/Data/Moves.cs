using BizHawk.Common.CollectionExtensions;
using Newtonsoft.Json;
using Wyanido.Pokebot.Games.Collections;

namespace Wyanido.Pokebot.Games.Data
{
    public class PokemonMove
    {
        [JsonProperty("accuracy")]
        public readonly int Accuracy;

        [JsonProperty("power")]
        public readonly int Power;

        [JsonProperty("name")]
        public readonly string Name;

        [JsonProperty("type")]
        public readonly string Type;
    }

    public class Moves : GameDataCollection<Moves>
    {
        public readonly PokemonMove[] List;

        public Moves(IGame game)
        {
            Instance = this;

            List = GetMovesList(game)!;
        }

        private PokemonMove[] ParseMoveList(string filename) => ParseDataJson<PokemonMove[]>(["moves", filename]);

        private PokemonMove[] GetMovesList(IGame game)
        {
            switch (game.Generation)
            {
                case 4:
                    return ParseMoveList("gen-iv.json");
                case 5:
                    return ParseMoveList("gen-v.json");
                case 6:
                    {
                        var moves = ParseMoveList("xy.json");

                        if (game is OmegaRubyAlphaSapphire)
                        {
                            // Return with new ORAS moves appended to XY list
                            var newMoves = ParseMoveList("oras_new.json");
                            return moves.ConcatArray(newMoves);
                        }

                        return moves; // Base XY list
                    }
                case 7:
                    {
                        var moves = ParseMoveList("sm.json");

                        if (game is UltraSunUltraMoon)
                        {
                            // Return with new USUM moves appended to SM list
                            var newMoves = ParseMoveList("usum_new.json");
                            return moves.ConcatArray(newMoves);
                        }

                        return moves; // Base SM list
                    }
                default:
                    return [];
            }
        }

        public static PokemonMove Get(int moveIndex) => Instance.List[moveIndex];
    }
}
