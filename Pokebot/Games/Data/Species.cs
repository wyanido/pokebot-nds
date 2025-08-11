using BizHawk.Common.CollectionExtensions;
using Newtonsoft.Json;
using System;
using System.Drawing;
using System.IO;
using Wyanido.Pokebot.Games.Titles;

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

        private static readonly Image FallbackIcon = Image.FromFile(GetIconPath("unown-question"));

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

        public static PokemonSpecies? Get(uint speciesIndex) => speciesIndex < Instance.List.Length ? Instance.List[speciesIndex] : null;

        public static string? GetName(uint speciesIndex) => speciesIndex < Instance.List.Length ? Instance.List[speciesIndex].Name : null;

        /// <summary>
        /// Prepends the filename with the pokemon images folder, and appends the .png suffix to it.
        /// </summary>
        private static string GetIconPath(string filename) => Path.Combine([Pokebot.ImagesPath, "pokemon", $"{filename}.png"]);

        /// <summary>
        /// Retrieves a drawable icon for the Pokemon.
        /// </summary>
        public static Image GetIcon(Pokemon pokemon)
        {
            var species = pokemon.Species;

            // First check if an image exists for the Pokemon's alternate form, e.g.
            // Unown A, B, C... Arceus Steel, Flying...
            var form = pokemon.AlternateForm;
            var alternateFormPath = GetIconPath($"{species}-{form}".ToLower());

            if (File.Exists(alternateFormPath))
                return Image.FromFile(alternateFormPath);

            // Otherwise check for female sprite variants for female Pokemon
            var femalePath = GetIconPath($"{species}-female");
            if (pokemon.Gender == "Female" && File.Exists(femalePath))
                return Image.FromFile(femalePath);

            // Check for the most basic representation of the Pokemon in its default state
            var defaultPath = GetIconPath(species.Name);
            if (File.Exists(defaultPath))
                return Image.FromFile(defaultPath);

            // If for any reason an image for the Pokemon can't be found, use unown-question
            return FallbackIcon;
        }
    }
}
