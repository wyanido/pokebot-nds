using BizHawk.Client.Common;

namespace Wyanido.Pokebot.Games.Titles;

public sealed class Black2White2(ApiContainer apis) : Game(apis)
{
    public override int Generation { get; } = 5;
}
