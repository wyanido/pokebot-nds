namespace Wyanido.Pokebot.Games.Data
{
    public static class Natures
    {
        public static readonly string[] List = [
            "Hardy",
            "Lonely",
            "Brave",
            "Adamant",
            "Naughty",
            "Bold",
            "Docile",
            "Relaxed",
            "Impish",
            "Lax",
            "Timid",
            "Hasty",
            "Serious",
            "Jolly",
            "Naive",
            "Modest",
            "Mild",
            "Quiet",
            "Bashful",
            "Rash",
            "Calm",
            "Gentle",
            "Sassy",
            "Careful",
            "Quirk",
        ];

        public static string GetName(int natureIndex) => List[natureIndex];
    }
}
