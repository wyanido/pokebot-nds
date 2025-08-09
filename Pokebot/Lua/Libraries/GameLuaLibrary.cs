using BizHawk.Client.Common;
using System;

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

        [LuaMethodExample("game.( );")]
        public void Clear()
        {
            OutputBox?.Clear();
        }
    }
}
