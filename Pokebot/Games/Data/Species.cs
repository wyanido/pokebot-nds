using BizHawk.Common.CollectionExtensions;
using Newtonsoft.Json;
using System;
using System.Drawing;
using Wyanido.Pokebot.Games.Collections;

namespace Wyanido.Pokebot.Games.Data
{
    public class PokemonSpecies
    {
        [JsonProperty("name")]
        public readonly string Name;

        [JsonProperty("type")]
        public readonly string[] Type;
    }

    public class Species : GameDataCollection<Species>
    {
        public readonly PokemonSpecies[] List;

        public Species(IGame game)
        {
            Instance = this;

            List = GetSpeciesList(game)!;
        }

        private PokemonSpecies[] ParseSpeciesList(string filename) => ParseDataJson<PokemonSpecies[]>(["species", filename]);

        private PokemonSpecies[] GetSpeciesList(IGame game)
        {
            switch (game.Generation)
            {
                case 4:
                    return ParseSpeciesList("gen-iv.json");
                case 5:
                    return ParseSpeciesList("gen-v.json");
                case 6:
                    {
                        var moves = ParseSpeciesList("xy.json");

                        if (game is OmegaRubyAlphaSapphire)
                        {
                            // Return with new ORAS moves appended to XY list
                            var newMoves = ParseSpeciesList("oras_new.json");
                            return moves.ConcatArray(newMoves);
                        }

                        return moves; // Base XY list
                    }
                case 7:
                    {
                        var moves = ParseSpeciesList("sm.json");

                        if (game is UltraSunUltraMoon)
                        {
                            // Return with new USUM moves appended to SM list
                            var newMoves = ParseSpeciesList("usum_new.json");
                            return moves.ConcatArray(newMoves);
                        }

                        return moves; // Base SM list
                    }

                default:
                    throw new Exception("Invalid Game instance");
            }
        }

        public static PokemonSpecies Get(int speciesIndex) => Instance.List[speciesIndex];

        public static string GetName(int speciesIndex) => Instance.List[speciesIndex].Name;

        /// <summary>
        /// Retrieves a drawable icon for the Pokemon.
        /// </summary>
        public static Image GetIcon(Pokemon pokemon)
        {
            return Image.FromFile("Resources/pokemon/unown.png");
        }
    }
}
