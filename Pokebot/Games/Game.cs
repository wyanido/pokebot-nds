using BizHawk.Client.Common;
using System;
using System.Numerics;
using Wyanido.Pokebot.Games.Data;
using Wyanido.Pokebot.Lua;
using Wyanido.Pokebot.Lua.Libraries;

namespace Wyanido.Pokebot.Games
{
    /// <summary>
    /// Base template for a Game title or collection. Its main purpose
    /// is to provide default functions that throw errors when a game
    /// is missing an implementation of a required method.
    /// </summary>
    public abstract class Game : IGame
    {
        public virtual int Generation { get; }
        public virtual Language Language { set; get; }
        public virtual int MemoryOffset { set;  get; }

        /// <summary>
        /// The size of this game's Pokemon constructor in bytes.
        /// </summary>
        public virtual int MonByteLength { get; }

        // Lua compatibility properties. These should be removed soon.
        public string GameCode { set; get; }
        public string LanguageCode { set; get; }

        protected PokemonLuaLibrary PokemonLibrary => (PokemonLuaLibrary)LuaLibraries.Libs[typeof(PokemonLuaLibrary)];

        public Species Species { set; get; }
        public Items Items { set; get; }
        public Abilities Abilities { set; get; }
        public Maps Maps { set; get; }
        public Moves Moves { set; get; }
        public TypeMatchups TypeMatchups { set; get; }
        public ApiContainer APIs { set; get; }
        public IMemoryApi Memory { set; get; }

        public Game(ApiContainer apis)
        {
            APIs = apis;
            Memory = APIs.Memory;

            Species = new(this);
            Items = new(this);
            Abilities = new(this);
            Maps = new(this);
            Moves = new(this);
            TypeMatchups = new(this);
        }

        /// <summary>
        /// Returns the internal index of the current map.
        /// </summary>
        public virtual int GetMapHeader() => throw new NotImplementedException();

        /// <summary>
        /// Returns the 3D position of the player character.
        /// </summary>
        public virtual Vector3 GetTrainerPosition() => throw new NotImplementedException();

        /// <summary>
        /// Returns the player's TID.
        /// </summary>
        public virtual ushort GetTrainerId() => throw new NotImplementedException();

        /// <summary>
        /// Returns the player's name as seen on the trainer card.
        /// </summary>
        public virtual string GetTrainerName() => throw new NotImplementedException();

        /// <summary>
        /// Returns whether the player is currently engaged in a battle.
        /// </summary>
        public virtual bool IsInBattle() => throw new NotImplementedException();

        /// <summary>
        /// Returns an array of items in the bag across all pockets as a tuple where
        /// the first item is the item index, and the second is the quantity.
        /// </summary>
        public virtual Tuple<uint, uint>[] GetBagItems() => throw new NotImplementedException();

        /// <summary>
        /// Returns an array of Pokemon currently in the party.
        /// </summary>
        public virtual Pokemon?[] GetParty() => throw new NotImplementedException();

        /// <summary>
        /// Returns the sum of all checksums in the party, or null if at least one Pokemon fails checksum validation.
        /// The returned checksum is required for the Dashboard to know whether the party data is valid and/or has changed.
        /// </summary>
        public virtual int[] GetPartyChecksums() => throw new NotImplementedException();

        /// <summary>
        /// Returns an array containing the current battle opponents.
        /// </summary>
        public virtual Pokemon[] GetFoes() => throw new NotImplementedException();
    }
}
