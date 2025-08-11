using BizHawk.Client.Common;
using BizHawk.Common;
using BizHawk.Common.CollectionExtensions;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Wyanido.Pokebot.Games.Data;
using Wyanido.Pokebot.Utils;

namespace Wyanido.Pokebot.Lua.Libraries
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

            for (int i = 0x08; i < 0x87; i += 2)
                sum += data[i] + (data[i + 1] << 8);

            return (ushort)(sum & 0xFFFF) == checksum && sum != 0;
        }

        private int BytesToReal(byte[] bytes)
        {
            var value = 0;

            for (int i = 0; i < bytes.Length; i++)
                value += bytes[i] << (i << 3);

            return value;
        }

        private uint Rand(uint seed) => 0x41C64E6D * seed + 0x6073;

        public byte[]? DecryptPokemon(long address, bool isUnencrypted = false)
        {
            if (Pokebot.CurrentGame is null)
                throw new Exception("Can't decrypt Pokemon data with no game loaded");

            // Read in the entire encrypted Pokemon struct to minimise API calls
            var structLength = Pokebot.CurrentGame.MonByteLength;

            var inData = (byte[])APIs.Memory.ReadByteRange(address, structLength);
            var inStream = new MemoryStream(inData);
            var data = new BinaryReader(inStream);

            var outStream = new MemoryStream();
            var outData = new BinaryWriter(outStream);

            // Read unencrypted bytes
            var pid = data.ReadUInt32();
            inStream.Seek(6, SeekOrigin.Begin);
            var checksum = data.ReadUInt16();

            outData.Write(pid);
            outData.Write((byte)0); // Unused
            outData.Write((byte)0); // Unused
            outData.Write(checksum);

            // Find intended order of the shuffled data blocks
            var substructIndex = ((pid & 0x3E000) >> 0xD) % 24;
            var order = substruct[substructIndex];
            var seed = (uint)checksum;

            void DecryptBlock(uint length)
            {
                for (long i = 0; i < length; i += 2)
                {
                    var word = data.ReadUInt16();

                    // Only decrypt bytes if the data isn't already unencrypted (only applies to Platinum statics)
                    if (!isUnencrypted)
                    {
                        seed = Rand(seed);
                        word = (ushort)((word ^ seed >> 16) & 0xFFFF);
                    }

                    outData.Write(word);
                }
            }

            // Decrypt blocks A,B,C,D and reshuffle according to the order
            for (int i = 1; i <= 4; i++)
            {
                var block = order.IndexOf(i) * 0x20;
                outData.Seek(0x8 + block, SeekOrigin.Begin);
                DecryptBlock(0x20);
            }

            // Recalculate checksum to verify data isn't garbage
            if (!VerifyChecksums(outStream.ToArray(), checksum))
                return null;

            // Status data (not applicable to boxed Pokemon)
            seed = pid;
            outData.Seek(0x88, SeekOrigin.Begin);
            DecryptBlock(0x4B);

            if (Pokebot.CurrentGame.Generation == 4)
            {
                outData.Write(data.ReadBytes(0x18)); // Write ball seal data
                //outData.Write((byte)0); // One extra byte to push length to 236 so PKHeX will accept it
            }

            return outStream.ToArray();
        }

        public Pokemon ParseMonData(byte[] data)
        {
            if (Pokebot.CurrentGame is null)
                throw new Exception("Can't parse Pokemon data with no game loaded");

            var mon = new Pokemon();
            var stream = new MemoryStream(data);
            var reader = new BinaryReader(stream);

            mon.PID = reader.ReadUInt32();
            stream.Seek(2, SeekOrigin.Current); // Skip unused bytes
            mon.Checksum = reader.ReadUInt16();

            mon.ShinyValue = (ushort)(mon.OT.TID ^ mon.OT.SID ^ mon.PID >> 16 & 0xFFFF ^ mon.PID & 0xFFFF);
            mon.IsShiny = mon.ShinyValue < 8;

            // Block A
            mon.SpeciesIndex = reader.ReadUInt16();
            mon.HeldItemIndex = reader.ReadUInt16();

            mon.OT = new();
            mon.OT.TID = reader.ReadUInt16();
            mon.OT.SID = reader.ReadUInt16();

            mon.Experience = reader.ReadUInt32();
            mon.Friendship = reader.ReadByte();
            mon.AbilityIndex = reader.ReadByte();
            mon.Markings = reader.ReadByte();
            mon.OT.LanguageID = reader.ReadByte();

            mon.EVs = new();
            mon.EVs.HP = reader.ReadByte();
            mon.EVs.Attack = reader.ReadByte();
            mon.EVs.Defense = reader.ReadByte();
            mon.EVs.Speed = reader.ReadByte();
            mon.EVs.SpecialAttack = reader.ReadByte();
            mon.EVs.SpecialDefense = reader.ReadByte();

            mon.ContestStats = new();
            mon.ContestStats.Cool = reader.ReadByte();
            mon.ContestStats.Beauty = reader.ReadByte();
            mon.ContestStats.Cute = reader.ReadByte();
            mon.ContestStats.Smart = reader.ReadByte();
            mon.ContestStats.Tough = reader.ReadByte();
            mon.ContestStats.Sheen = reader.ReadByte();

            mon.Ribbons = new();
            mon.Ribbons.SinnohRibbonSet1 = reader.ReadUInt16();
            mon.Ribbons.UnovaRibbonSet = reader.ReadUInt16();

            // Block B
            mon.Moves = [
                new Move(),
                new Move(),
                new Move(),
                new Move()
            ];

            for (int i = 0; i < 4; i++) mon.Moves[i].Index = reader.ReadUInt16();
            for (int i = 0; i < 4; i++) mon.Moves[i].PP = reader.ReadByte();
            for (int i = 0; i < 4; i++) mon.Moves[i].PPUps = reader.ReadByte();

            var value = reader.ReadUInt32();
            mon.IVs = new();
            mon.IVs.HP = (byte)(value & 0x1F);
            mon.IVs.Attack = (byte)(value << 5 & 0x1F);
            mon.IVs.Defense = (byte)(value << 10 & 0x1F);
            mon.IVs.Speed = (byte)(value << 15 & 0x1F);
            mon.IVs.SpecialAttack = (byte)(value << 20 & 0x1F);
            mon.IVs.SpecialDefense = (byte)(value << 25 & 0x1F);

            mon.IsEgg = (value >> 30 & 1) == 1;
            mon.IsNicknamed = (value >> 31 & 1) == 1;

            mon.Ribbons.HoennRibbonSet1 = reader.ReadUInt16();
            mon.Ribbons.HoennRibbonSet2 = reader.ReadUInt16();

            var value2 = reader.ReadByte();
            mon.FatefulEncounter = (value2 & 1) == 1;
            var genderValue = value2 >> 1 & 0x02;
            mon.Gender = (genderValue & 0b1) > 0 ? "Female" : (genderValue & 0b01) > 0 ? "Genderless" : "Male";
            mon.AlternateFormIndex = value2 >> 3 & 0x1F;

            var isGen4 = Pokebot.CurrentGame.Generation == 4;

            if (isGen4)
            {
                // Gen 4 calculates nature using PID instead of storing a separate value
                mon.NatureIndex = mon.PID % 25;
                stream.Seek(2, System.IO.SeekOrigin.Current);
            }
            else
            {
                mon.NatureIndex = reader.ReadByte();

                var value3 = reader.ReadByte();
                mon.DreamWorldAbilityIndex = value3 & 1;
                mon.IsNsPokemon = (value3 >> 1 & 1) == 1;
            }

            // Block C
            mon.Nickname = GameString.BytesToString(reader.ReadBytes(0x1D), isGen4);
            mon.OriginGame = reader.ReadByte();
            mon.Ribbons.SinnohRibbonSet3 = reader.ReadUInt16();
            mon.Ribbons.SinnohRibbonSet4 = reader.ReadUInt16();

            // Block D
            mon.OT.Name = GameString.BytesToString(reader.ReadBytes(0x10), isGen4);
            mon.DateEggReceived = (uint)BytesToReal(reader.ReadBytes(3));
            mon.DateMet = (uint)BytesToReal(reader.ReadBytes(3));
            mon.EggLocationIndex = reader.ReadUInt16();
            mon.MetLocationIndex = reader.ReadUInt16();
            mon.Pokerus = reader.ReadByte();
            mon.PokeBallIndex = (PokeBall)reader.ReadByte();
            mon.EncounterType = reader.ReadByte();

            // Battle stats
            stream.Seek(0x8C, SeekOrigin.Begin); // Skip Status and unknown flags
            mon.Level = reader.ReadByte();
            mon.CapsuleIndex = reader.ReadByte();
            mon.CurrentHP = reader.ReadUInt16();

            mon.Stats = new();
            mon.Stats.HP = reader.ReadUInt16();
            mon.Stats.Attack = reader.ReadUInt16();
            mon.Stats.Defense = reader.ReadUInt16();
            mon.Stats.Speed = reader.ReadUInt16();
            mon.Stats.SpecialAttack = reader.ReadUInt16();
            mon.Stats.SpecialDefense = reader.ReadUInt16();

            // Save a copy of the raw bytes for .pkx export
            mon.Raw = data;

            return mon;
        }

        [LuaMethod("parse_data", "Returns a decrypted and parsed Pokemon from memory, or nil if the checksum fails.")]
        public object? DecryptAndParse(long address, bool isUnencrypted = false)
        {
            var bytes = DecryptPokemon(address, isUnencrypted);

            if (bytes is null)
                return null;

            return ParseMonData(bytes);
        }

        [LuaMethod("matches_ruleset", "Returns whether the given Pokemon matches the given ruleset.")]
        public bool MatchesRuleset(Pokemon pokemon, Dictionary<object, object> rulesetCollection)
        {
            if (rulesetCollection is null)
            {
                LuaLibraries.PrintWarn("Pokemon was checked against an empty ruleset collection. It may ignore targets!");
                return false;
            }

            var fields = typeof(Pokemon).GetFields().Select(f => f.Name);

            // Rulesets work by assuming the Pokemon is a target by default.
            // It will check each ruleset property against the Pokemon, and
            // only return false if there is any mismatch.
            for (var e = rulesetCollection.GetEnumerator(); e.MoveNext();)
            {
                string rulesetName = (string)e.Current.Key;
                var ruleset = (Dictionary<object, object>)e.Current.Value;

                for (var e2 = ruleset.GetEnumerator(); e2.MoveNext();)
                {
                    string key = (string)e2.Current.Key;
                    var value = e2.Current.Value;
                    var pokemonValue = typeof(Pokemon).GetField(key)?.GetValue(pokemon);

                    // Rulesets come from YAML, so the original boolean type is lost.
                    if (value is string stringValue)
                    {
                        var success = bool.TryParse(stringValue, out bool boolValue);

                        if (success)
                            value = boolValue;
                    }

                    if (!fields.Contains(key) || pokemonValue is null)
                    {
                        // Property doesn't exist on the Pokemon
                        LuaLibraries.PrintWarn($"Invalid field '{key}' in ruleset '{rulesetName}'. This field has no effect, and should be removed.");
                        continue;
                    }

                    if (value is bool propertyBool)
                    {
                        if (pokemonValue is not bool pokemonBool)
                        {
                            LuaLibraries.PrintWarn($"Expected type {pokemonValue.GetType()} for field '{key}' in ruleset '{rulesetName}', got bool.");
                            continue;
                        }

                        // Checking ruleset bool against Pokemon bool
                        // e.g. IsShiny = true
                        if (propertyBool != pokemonBool)
                            return false;

                        continue; // Value match, keep checking
                    }

                    LuaLibraries.PrintWarn($"Unhandled property {key} in Catch Ruleset {rulesetName} matching {value.GetType()} against {pokemonValue.GetType()}");
                }
            }

            return true;
        }

        [LuaMethod("is_target", "Returns whether the given Pokemon matches any of the target rulesets.")]
        public bool EncounterIsTarget(Pokemon pokemon)
        {
            if (pokemon is null)
            {
                LuaLibraries.PrintDebug("Tried to log a non-existent Pokemon");
                return false;
            }

            Pokebot.PokebotConfig.Properties.TryGetValue("target_rulesets", out object catchRulesets);

            return MatchesRuleset(pokemon, (Dictionary<object, object>)catchRulesets);
        }

        [LuaMethod("find_best_attacking_move", "Returns the name, index, and power of the most optimal damaging move against the given target.")]
        public object FindBestAttackingMove(Pokemon ally, Pokemon foe)
        {
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

        [LuaMethod("get_move_slot", "Returns the index of a given move inside the Pokemon's moveset from 1-4, or 0 if not present.")]
        public int GetMoveSlot(Pokemon pokemon, string moveName)
        {
            for (var i = 0; i < 4; i++)
            {
                var moveData = pokemon.Moves[i];
                var move = Moves.Get(moveData.Index);

                if (move.Name == moveName)
                    return i + 1;
            }

            return 0;
        }

        [LuaMethod("is_hatched_dud", "Returns whether the Pokemon is both Level 1 and doesn't match the target rulesets.")]
        public bool IsHatchedDud(Pokemon pokemon)
        {
            return pokemon.Level == 1 && !MatchesRuleset(pokemon, (Dictionary<object, object>)Pokebot.PokebotConfig.Properties["target_rulesets"]);
        }

        [LuaMethod("log_encounter", "Logs the Pokemon to the Dashboard.")]
        public void LogEncounter(Pokemon pokemon)
        {
            // TODO log this;
        }
    }
}
