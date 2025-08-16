using BizHawk.Client.Common;
using System;
using Wyanido.Pokebot.Games.Data;

namespace Wyanido.Pokebot.Lua.Libraries
{
    internal sealed class GameLuaLibrary(
        ILuaLibraries luaLibraries,
        ApiContainer apiContainer,
        Action<string> logOutputCallback) : LuaLibraryBase(
              luaLibraries,
              apiContainer,
              logOutputCallback)
    {
        public override string Name => "game";

        [LuaMethod("party", "Returns an array of the current party Pokemon")]
        public Pokemon?[] GetParty() => Pokebot.CurrentGame.GetParty();

        [LuaMethod("map_name", "Returns the name of the current map header, or nil if not applicable.")]
        public string? GetMapName() => Pokebot.CurrentGame.GetMapName();

        [LuaMethod("map_header", "Returns the current map header.")]
        public uint GetMapHeader() => Pokebot.CurrentGame.GetMapHeader();

        [LuaMethod("item_name", "Returns the name of the provided item index.")]
        public string? GetItemName(uint index) => Items.GetName(index);

        [LuaMethod("in_battle", "Returns whether the game is currently in a battle.")]
        public bool InBattle() => Pokebot.CurrentGame.IsInBattle();

        [LuaMethod("save_file_loaded", "Returns whether a save file has been loaded and the game can be played.")]
        // This isn't foolproof, but it catches most cases of it being treated as loaded before it actually is.
        public bool InGame() => GetMapName() is not null;
    }
}
