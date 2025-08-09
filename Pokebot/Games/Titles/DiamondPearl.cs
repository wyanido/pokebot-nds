using BizHawk.Client.Common;
using System;
using System.Numerics;
using Wyanido.Pokebot.Games.Data;
using Wyanido.Pokebot.Lua;
using Wyanido.Pokebot.Utils;

namespace Wyanido.Pokebot.Games.Titles;

public sealed class DiamondPearl : Game
{
    public override int Generation { get; } = 4;

    public DiamondPearl(ApiContainer apis) : base(apis)
    {
        MemoryOffset = Language switch
        {
            Language.Japanese => 0x1860,
            Language.French => 0x180,
            Language.Italian => 0xE0,
            Language.German => 0x140,
            Language.Spanish => 0x1A0,
            _ => 0x0,
        };
    }

    /// <summary>
    /// A commonly used address for finding important data in memory by relative offsets.
    /// </summary>
    private long Anchor => Memory.ReadU32(0x21C489C + MemoryOffset);

    /// <summary>
    /// The size of this game's Pokemon constructor in bytes.
    /// </summary>
    private const int MonByteLength = 220;

    public override Vector3 GetTrainerPosition()
    {
        var address = 0x21CEF70 + MemoryOffset;

        return new Vector3(
            Memory.ReadS32(address),
            Memory.ReadS32(address + 4),
            Memory.ReadS32(address + 8)
        );
    }

    public override ushort GetTrainerId() => (ushort)Memory.ReadU16(Anchor - 0x12);

    public override string GetTrainerName() => GameString.ReadString4(APIs, Anchor - 0x22, 12);

    public override Tuple<uint, uint>[] GetBagItems()
    {
        const int ItemsPocketSize = 0x294;
        const int KeyItemsPocketSize = 0xC8;
        const int TmsHmsPocketSize = 0x1C0;
        const int MedicinePocketSize = 0xA0;
        const int BerriesPocketSize = 0x100;

        var bag = Memory.ReadU32(0x21C489C + MemoryOffset) + 0x59E;

        long[] pockets = [
            bag,                        // items
            bag + ItemsPocketSize,      // key items
            bag + KeyItemsPocketSize,   // tms hms
            bag + TmsHmsPocketSize,     // medicine
            bag + MedicinePocketSize,   // berries
            bag + BerriesPocketSize,    // poke balls
        ];


        return [];
    }

    public override Pokemon[] GetParty()
    {
        var partyCount = Memory.ReadByte(Anchor + 0xE);
        var partyAddress = Memory.ReadByte(Anchor + 0x12);
        var party = new Pokemon[partyCount];

        for (var i = 0; i < partyCount; i++)
        {
            var monAddress = partyAddress + i * MonByteLength;
            var result = PokemonLibrary.DecryptFromMemory(monAddress);

            if (result is not Pokemon mon)
            {
                LuaLibraries.PrintDebug($"Party checksum failed at slot {i}");
                continue;
            }

            party[i] = mon;
        }

        return party;
    }

    public override Pokemon[] GetFoes()
    {
        var foeAddress = Memory.ReadU16(Anchor + 0x226FE) - 0x2B74;
        var foeCount = Memory.ReadByte(foeAddress - 4);
        var foes = new Pokemon[foeCount];

        for (var i = 0; i < foeCount; i++)
        {
            var monAddress = foeAddress + i * MonByteLength;
            var result = PokemonLibrary.DecryptFromMemory(monAddress);

            if (result is not Pokemon mon)
            {
                LuaLibraries.PrintDebug($"Foe checksum failed at slot {i}");
                continue;
            }

            foes[i] = mon;
        }

        return foes;
    }
}