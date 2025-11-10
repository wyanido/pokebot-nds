using Newtonsoft.Json;
using System.Collections.Generic;

namespace Wyanido.Pokebot.Utils;

/// <summary>
/// Cumulative stats for all games and sessions.
/// </summary>
public struct GlobalStats
{
    [JsonProperty("max_iv_sum")]
    public int maxIVSum;

    [JsonProperty("min_iv_sum")]
    public int minIVSum;

    [JsonProperty("shiny")]
    public int shinySeen;

    [JsonProperty("seen")]
    public int seen;
}

/// <summary>
/// Accumulated stats since the last target was encountered.
/// </summary>
public struct PhaseStats
{
    [JsonProperty("lowest_sv")]
    public int minShinyValue;

    [JsonProperty("seen")]
    public int seen;
}

/// <summary>
/// Stats for a single session instance.
/// </summary>
public struct SessionStats
{
    public Dictionary<string, int> speciesSeen;
}

/// <summary>
/// Deserialised stats.json file.
/// </summary>
public struct Stats
{
    [JsonProperty("total")]
    public GlobalStats total;

    [JsonProperty("phase")]
    public PhaseStats phase;
}
