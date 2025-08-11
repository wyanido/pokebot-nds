using BizHawk.Client.Common;

namespace Wyanido.Pokebot.Games.Titles;

public sealed class HeartGoldSoulSilver(ApiContainer apis) : Game(apis)
{
    public override int Generation { get; } = 4;
}
