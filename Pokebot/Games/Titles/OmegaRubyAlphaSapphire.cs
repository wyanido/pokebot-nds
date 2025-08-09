using BizHawk.Client.Common;

namespace Wyanido.Pokebot.Games.Titles;

public sealed class OmegaRubyAlphaSapphire(ApiContainer apis) : Game(apis)
{
    public override int Generation { get; } = 6;
}
