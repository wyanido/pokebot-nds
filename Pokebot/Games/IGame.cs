using BizHawk.Client.Common;
using System;
using System.Numerics;
using Wyanido.Pokebot.Games.Data;

namespace Wyanido.Pokebot.Games
{
    public enum Language
    {
        Japanese,
        English,
        French,
        Italian,
        German,
        Spanish
    }

    public interface IGame
    {
        public int Generation { get; }
        public Language Language { set; get; }
        public int MemoryOffset { set; get; }

        public Species Species { set; get; }
        public Items Items { set; get; }
        public Abilities Abilities { set; get; }
        public Maps Maps { set; get; }
        public Moves Moves { set; get; }
        public TypeMatchups TypeMatchups { set; get; }

        public ApiContainer APIs { set; get; }

        public Vector3 GetTrainerPosition();

        public UInt16 GetTrainerId();

        public string GetTrainerName();

        public int GetMapHeader();

        public bool IsInBattle();
    }
}
