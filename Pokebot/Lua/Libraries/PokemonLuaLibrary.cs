using BizHawk.Client.Common;
using BizHawk.Common;
using BizHawk.Common.CollectionExtensions;
using System;
using System.Collections.Generic;
using Wyanido.Pokebot.Games.Data;
using Wyanido.Pokebot.Lua;
using Wyanido.Pokebot.Utils;

namespace Wyanido.Pokebot.LuaLibrary.Libraries
{
    public sealed class PokemonLuaLibrary(
        ILuaLibraries luaLibraries,
        ApiContainer apiContainer,
        Action<string> logOutputCallback) : LuaLibraryBase(
              luaLibraries,
              apiContainer,
              logOutputCallback)
    {
        public override string Name => "pokemon";

        private static readonly int[][] substruct = [
            [ 1, 2, 3, 4 ],
            [ 1, 2, 4, 3 ],
            [ 1, 3, 2, 4 ],
            [ 1, 4, 2, 3 ],
            [ 1, 3, 4, 2 ],
            [ 1, 4, 3, 2 ],
            [ 2, 1, 3, 4 ],
            [ 2, 1, 4, 3 ],
            [ 3, 1, 2, 4 ],
            [ 4, 1, 2, 3 ],
            [ 3, 1, 4, 2 ],
            [ 4, 1, 3, 2 ],
            [ 2, 3, 1, 4 ],
            [ 2, 4, 1, 3 ],
            [ 3, 2, 1, 4 ],
            [ 4, 2, 1, 3 ],
            [ 3, 4, 1, 2 ],
            [ 4, 3, 1, 2 ],
            [ 2, 3, 4, 1 ],
            [ 2, 4, 3, 1 ],
            [ 3, 2, 4, 1 ],
            [ 4, 2, 3, 1 ],
            [ 3, 4, 2, 1 ],
            [ 4, 3, 2, 1 ]
        ];

        /// <summary>
        /// Verifies the checksums of a Pokemon's data in memory to
        /// determine if the data represents a valid Pokemon instance.
        /// </summary>
        private bool VerifyChecksums(byte[] data, ushort checksum)
        {
            var sum = 0;

            for (int i = 0x09; i <= 0x88; i += 2)
                sum += data[i] + (data[i + 1] << 8);

            sum = sum & 0xFFFF;

            return sum == checksum && sum != 0;
        }

        private int BytesToReal(byte[] bytes)
        {
            var value = 0;

            for (int i = 0; i < bytes.Length; i++)
                value += bytes[i] << (i << 3);

            return value;
        }

        private uint Rand(uint seed) => 0x41C64E6D * seed + 0x6073;

        public byte[]? DecryptAndUnshuffleMon(long address, bool isUnencrypted = true)
        {
            var data = new BinaryBuffer();
            var bin = data.Writer;

            // Read unencrypted bytes
            var pid = APIs.Memory.ReadU32(address);
            bin.Write(pid);

            bin.Write((byte)0); // Unused
            bin.Write((byte)0); //

            var checksum = (ushort)APIs.Memory.ReadU16(address + 6);
            bin.Write(checksum);

            // Find intended order of the shuffled data blocks
            var substructIndex = ((pid & 0x3E000) >> 0xD) % 24;
            var order = substruct[substructIndex];

            // Decrypt blocks A,B,C,D and reshuffle according to the order
            var seed = (uint)checksum;
            var blocks = new byte[0x20][];

            byte[] DecryptBlock(long start, long end)
            {
                var block = new byte[end - start + 1];

                for (long i = start; i < end; i += 2)
                {
                    var word = APIs.Memory.ReadU16(address + i);

                    // Only decrypt bytes if the data isn't already unencrypted (only applies to Platinum statics)
                    if (!isUnencrypted)
                    {
                        seed = Rand(seed);
                        word = (word ^ seed >> 16) & 0xFFFF;
                    }

                    block[i] = (byte)(word & 0xFF);
                    block[i + 1] = (byte)(word >> 8 & 0xFF);
                }

                return block;
            }

            for (int i = 0; i < 4; i++)
            {
                var block = i * 0x20;
                blocks[i] = DecryptBlock(0x08 + block, 0x27 + block);
            }

            foreach (var index in order)
                bin.WriteByteBuffer(blocks[index]);

            // Recalculate checksum to verify data isn't garbage
            if (!VerifyChecksums(data.ToArray(), checksum))
                return null;

            // Status data (not applicable to boxed Pokemon)
            seed = pid;

            var statusBlock = DecryptBlock(0x88, 0xDB);
            bin.WriteByteBuffer([.. statusBlock]);

            if (Pokebot.CurrentGame.Generation == 4)
                for (int i = 0; i < 0x10; i++)
                    bin.Write((byte)0); // Write blank ball seal data

            return data.ToArray();
        }

        public Pokemon ParseMonData(byte[] data)
        {
            var mon = new Pokemon();
            var buffer = new BinaryBuffer(data);
            var bin = buffer.Reader;

            mon.PID = bin.ReadUInt32();
            mon.Checksum = bin.ReadUInt16();

            // Block A
            mon.SpeciesIndex = bin.ReadUInt16();
            mon.HeldItemIndex = bin.ReadUInt16();

            mon.OT = new()
            {
                TID = bin.ReadUInt16(),
                SID = bin.ReadUInt16()
            };

            mon.Experience = BytesToReal(bin.ReadBytes(3));
            mon.Friendship = bin.ReadByte();
            mon.AbilityIndex = bin.ReadByte();
            mon.Markings = bin.ReadByte();
            mon.OT.LanguageID = bin.ReadByte();

            mon.EVs = new()
            {
                HP = bin.ReadByte(),
                Attack = bin.ReadByte(),
                Defense = bin.ReadByte(),
                Speed = bin.ReadByte(),
                SpecialAttack = bin.ReadByte(),
                SpecialDefense = bin.ReadByte(),
            };

            mon.ContestStats = new()
            {
                Cool = bin.ReadByte(),
                Beauty = bin.ReadByte(),
                Cute = bin.ReadByte(),
                Smart = bin.ReadByte(),
                Tough = bin.ReadByte(),
                Sheen = bin.ReadByte(),
            };

            mon.Ribbons = new()
            {
                SinnohRibbonSet1 = bin.ReadUInt16(),
                UnovaRibbonSet = bin.ReadUInt16(),
            };

            mon.ShinyValue = (ushort)(mon.OT.TID ^ mon.OT.SID ^ mon.PID >> 16 & 0xFFFF ^ mon.PID & 0xFFFF);
            mon.IsShiny = mon.ShinyValue < 8;

            // Block B
            mon.Moves = [
                new Move(),
                new Move(),
                new Move(),
                new Move()
            ];

            for (int i = 0; i < 4; i++) mon.Moves[i].Index = bin.ReadUInt16();
            for (int i = 0; i < 4; i++) mon.Moves[i].PP = bin.ReadByte();
            for (int i = 0; i < 4; i++) mon.Moves[i].PPUps = bin.ReadByte();

            var value = BytesToReal(bin.ReadBytes(5));
            mon.IVs = new()
            {
                HP = (byte)(value & 0x1F),
                Attack = (byte)(value << 5 & 0x1F),
                Defense = (byte)(value << 10 & 0x1F),
                Speed = (byte)(value << 15 & 0x1F),
                SpecialAttack = (byte)(value << 20 & 0x1F),
                SpecialDefense = (byte)(value << 25 & 0x1F),
            };

            mon.IsEgg = (value >> 30 & 1) == 1;
            mon.IsNicknamed = (value >> 31 & 1) == 1;

            mon.Ribbons.HoennRibbonSet1 = bin.ReadUInt16();
            mon.Ribbons.HoennRibbonSet2 = bin.ReadUInt16();

            var value2 = bin.ReadByte();
            mon.FatefulEncounter = (value2 & 1) == 1;
            var genderValue = value2 >> 1 & 0x02;
            mon.Gender = (genderValue & 0b1) > 0 ? "Female" : ((genderValue & 0b01) > 0 ? "Genderless" : "Male");
            mon.AlternateForm = value2 >> 3 & 0x1F;

            var isGen4 = Pokebot.CurrentGame.Generation == 4;

            if (isGen4)
            {
                // Gen 4 calculates nature using PID instead of storing a separate value
                mon.NatureIndex = (mon.PID % 25);
                bin.BaseStream.Seek(2, System.IO.SeekOrigin.Current);
            }
            else
            {
                mon.NatureIndex = bin.ReadByte();

                var value3 = bin.ReadByte();
                mon.DreamWorldAbilityIndex = value3 & 1;
                mon.IsNsPokemon = (value3 >> 1 & 1) == 1;
            }

            // Block C
            mon.Nickname = GameString.BytesToString(bin.ReadBytes(0x1D), isGen4);
            mon.OriginGame = bin.ReadByte();
            mon.Ribbons.SinnohRibbonSet3 = bin.ReadUInt16();
            mon.Ribbons.SinnohRibbonSet4 = bin.ReadUInt16();

            // Block D
            mon.OT.Name = GameString.BytesToString(bin.ReadBytes(0x10), isGen4);
            mon.DateEggReceived = (uint)BytesToReal(bin.ReadBytes(3));
            mon.DateMet = (uint)BytesToReal(bin.ReadBytes(3));
            mon.EggLocationIndex = (uint)BytesToReal(bin.ReadBytes(3));
            mon.MetLocationIndex = bin.ReadUInt16();
            mon.Pokerus = bin.ReadByte();
            mon.PokeBallIndex = (PokeBall)bin.ReadByte();
            mon.EncounterType = bin.ReadByte();

            // Battle stats
            mon.Level = bin.ReadByte();
            mon.CapsuleIndex = bin.ReadByte();
            mon.CurrentHP = bin.ReadUInt16();

            mon.Stats = new()
            {
                HP = bin.ReadUInt16(),
                Attack = bin.ReadUInt16(),
                Defense = bin.ReadUInt16(),
                Speed = bin.ReadUInt16(),
                SpecialAttack = bin.ReadUInt16(),
                SpecialDefense = bin.ReadUInt16(),
            };

            mon.MailMessage = bin.ReadBytes(37);

            return mon;
        }

        [LuaMethodExample("pokemon.decrypt(address);")]
        public object? DecryptFromMemory(params object[] outputs)
        {
            var address = (long)outputs[0];
            var isUnencrypted = (bool)(outputs?[1] ?? true);
            var bytes = DecryptAndUnshuffleMon(address, isUnencrypted);

            if (bytes is null)
                return null;

            return ParseMonData(bytes);
        }

        [LuaMethodExample("pokemon.matches_ruleset(mon, ruleset);")]
        public bool MatchesRuleset(params object[] outputs)
        {
            var pokemon = (Pokemon)outputs[0];
            var rulesetCollection = (Dictionary<string, object>)outputs[1];

            if (rulesetCollection is null)
            {
                LuaLibraries.PrintDebug("Can't check Pokemon against an empty ruleset list");
                return false;
            }

            // Rulesets work by assuming the Pokemon is a target by default.
            // It will check each ruleset property against the Pokemon, and
            // only return false if there is any mismatch.
            for (var e = rulesetCollection.GetEnumerator(); e.MoveNext();)
            {
                var rulesetName = e.Current.Key as string;
                var ruleset = e.Current.Value as Dictionary<object, object>;

                for (var e2 = ruleset.GetEnumerator(); e2.MoveNext();)
                {
                    var propertyName = e2.Current.Key as string;
                    var propertyValue = e2.Current.Value;
                    var pokemonValue = typeof(Pokemon).GetProperty(propertyName)?.GetValue(pokemon);

                    if (pokemonValue is null)
                    {
                        LuaLibraries.PrintDebug($"WARNING: Invalid property {propertyName} in Catch Ruleset {rulesetName}. This has no effect, and should be removed.");
                        continue;
                    }

                    if (propertyValue is bool propertyBool)
                    {
                        if (pokemonValue is not bool pokemonBool)
                        {
                            LuaLibraries.PrintDebug($"WARNING: Expected type {pokemonValue.GetType()} for field {propertyName} in Catch Ruleset {rulesetName}, got bool.");
                            continue;
                        }

                        // Checking ruleset bool against Pokemon bool
                        // e.g. IsShiny = true
                        if (propertyBool != pokemonBool)
                            return false;

                        continue; // Value match, keep checking
                    }

                    LuaLibraries.PrintDebug($"WARNING: Unhandled property {propertyName} in Catch Ruleset {rulesetName} matching {propertyValue.GetType()} against {pokemonValue.GetType()}");
                }
            }

            return true;
        }

        [LuaMethodExample("pokemon.encounter_is_target(mon);")]
        [LuaMethod("encounter_is_target", "logs the pokemon to the dashboard and returns whether it matches the target_rulesets rules")]
        public bool EncounterIsTarget(params object[] outputs)
        {
            var pokemon = (Pokemon)outputs[0];

            if (pokemon is null)
            {
                LuaLibraries.PrintDebug("WARNING: Tried to log a non-existent Pokemon");
                return false;
            }

            Pokebot.PokebotConfig.Properties.TryGetValue("target_rulesets", out object catchRulesets);
            var isTarget = MatchesRuleset(pokemon, catchRulesets);

            if (isTarget)
            {
                LuaLibraries.PrintDebug("Pokemon was meant to be saved, but the functionality is unimplemented.");
            }

            LuaLibraries.PrintDebug("Pokemon was meant to be sent to the dashboard, but the functionality is unimplemented.");

            return isTarget;
        }

        [LuaMethodExample("pokemon.find_best_attacking_move(ally, foe);")]
        [LuaMethod("find_best_attacking_move", "logs the pokemon to the dashboard and returns whether it matches the target_rulesets rules")]
        public object FindBestAttackingMove(params object[] outputs)
        {
            var ally = (Pokemon)outputs[0];
            var foe = (Pokemon)outputs[1];
            var usingThief = (bool)(Pokebot.PokebotConfig.Properties.GetValueOrDefault("thief_wild_items", false) ?? false);

            var bestMoveIndex = 1;
            var bestMovePower = 0.0;

            for (var i = 0; i < 4; i++)
            {
                var moveData = ally.Moves[i];
                var move = Moves.Get(moveData.Index);

                if (move is null)
                    continue;

                // Don't waste Thief PP when trying to farm items
                if (usingThief && move.Name == "Thief")
                    continue;

                // Ignore depleted or non-damaging moves
                if (moveData.PP == 0 || move.Power == 0)
                    continue;

                var power = (double)move.Power;
                var matchups = TypeMatchups.GetMatchup(move.Type);
                var allySpecies = Species.Get(ally.SpeciesIndex);
                var foeSpecies = Species.Get(foe.SpeciesIndex);

                // Calculate type effectiveness
                foreach (var foeType in foeSpecies.Type)
                {
                    if (matchups.CantHitTypes.Contains(foeType))
                    {
                        power = 0;
                        break;
                    }

                    if (matchups.ResistedByTypes.Contains(foeType))
                    {
                        power *= 0.5;
                        continue;
                    }

                    if (matchups.SuperEffectiveAgainstTypes.Contains(foeType))
                        power *= 2;
                }

                // STAB
                if (allySpecies.Type.Contains(move.Type))
                    power *= 1.5;

                // Average power by accuracy to favour more accurate moves
                power *= move.Accuracy;

                if (power > bestMovePower)
                {
                    bestMovePower = power;
                    bestMoveIndex = i;
                }
            }

            return new Dictionary<string, object>
            {
                {"name", ally.Moves[bestMoveIndex] },
                {"index", bestMoveIndex},
                {"power", bestMovePower},
            };
        }

        [LuaMethodExample("pokemon.get_move_slot(mon, move_name);")]
        public int GetMoveSlot(params object[] outputs)
        {
            var pokemon = (Pokemon)outputs[0];
            var moveName = (string)outputs[1];

            for (var i = 0; i < 4; i++)
            {
                var moveData = pokemon.Moves[i];
                var move = Moves.Get(moveData.Index);

                if (move.Name == moveName)
                    return i + 1;
            }

            return 0;
        }

        [LuaMethodExample("pokemon.is_hatched_dud(mon);")]
        public bool IsHatchedDud(params object[] outputs)
        {
            var pokemon = (Pokemon)outputs[0];

            return pokemon.Level == 1 && !MatchesRuleset(pokemon, Pokebot.PokebotConfig.Properties["target_rulesets"]);
        }
    }
}
