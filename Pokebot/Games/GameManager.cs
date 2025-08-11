using BizHawk.Client.Common;
using BizHawk.Emulation.Common;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Wyanido.Pokebot.Games.Titles;
using Wyanido.Pokebot.Lua;

namespace Wyanido.Pokebot.Games
{
    internal class GameManager
    {
        public static Game? DetectGame(IGameInfo gameInfo, ApiContainer APIs)
        {
            if (gameInfo.IsNullInstance() || gameInfo == null)
            {
                LuaLibraries.PrintDebug("GameInfo was a null instance");
                return null;
            }

            var classType = GetGameClass(APIs);
            var game = (Game)Activator.CreateInstance(classType, [APIs]);
            game.GameCode = GetGameCode(APIs);
            game.Language = GetLanguage(APIs);

            return game;
        }

        protected static string GetGameCode(ApiContainer APIs)
        {
            var address = 0x23FFE08;
            byte[] word = [(byte)APIs.Memory.ReadByte(address), (byte)APIs.Memory.ReadByte(address + 1)];
            return word[1] == 0 ? Encoding.UTF8.GetString([word[0]]) : Encoding.UTF8.GetString(word);
        }

        protected static Type GetGameClass(ApiContainer APIs)
        {
            return GetGameCode(APIs) switch
            {
                "D" or "P" => typeof(DiamondPearl),
                "PL" => typeof(Platinum),
                "B" or "W" => typeof(BlackWhite),
                "B2" or "W2" => typeof(Black2White2),

                // Method will likely have to change for future titles, so this code is a placeholder
                "X" or "Y" => typeof(XY),
                "OR" or "AS" => typeof(OmegaRubyAlphaSapphire),
                "S" or "M" => typeof(SunMoon),
                "US" or "UM" => typeof(UltraSunUltraMoon),
                _ => typeof(Game),
            };
        }

        protected static Language GetLanguage(ApiContainer APIs)
        {
            var code = APIs.Memory.ReadByte(0x23FFE0F);

            return code switch
            {
                0x4A => Language.Japanese,
                0x45 => Language.English, // Gen 4 only
                0x4F => Language.English, // Gen 5 only
                0x46 => Language.French,
                0x49 => Language.Italian,
                0x44 => Language.German,
                0x53 => Language.Spanish,
                _ => throw new Exception("Couldn't determine game language"),
            };
        }

        public static List<string> GetGameScripts(Game game)
        {
            var scripts = GetGameScriptsFromDirectory(game, LuaLibraries.ScriptsPath);
            var basenames = new List<string>();

            // Return the first (most context-specific) script of any given name to allow overrides
            return [.. scripts.Where(x =>
            {
                var basename = Path.GetFileName(x);

                if (basenames.Contains(basename))
                {
                    LuaLibraries.PrintDebug($"Skipped overriden script {basename}");
                    return false;
                }

                basenames.Add(basename);
                return true;
            })];
        }

        /// <summary>
        /// Searches through the folders in reverse order so that scripts written for more specific environments, e.g.
        /// a specific generation or game, are added first and override more generalised scripts of the same name.
        /// </summary>
        /// <returns>A list of paths to .lua files contained in the folders and subfolders of ExternalTools/lua/scripts.</returns>
        public static List<string> GetGameScriptsFromDirectory(Game game, string baseDir)
        {
            var scripts = new List<string>();
            var generationDir = Path.Combine(baseDir, $"gen{game.Generation}");
            var gameDir = Path.Combine(generationDir, game.GameCode.ToLower());

            // Game scripts (D, P, PL, B, etc.)
            if (Directory.Exists(gameDir))
                AppendScriptsFromDirectory(gameDir, ref scripts);

            // Game collection scripts, (DPPL, HGSS, BW, etc.)
            string? gameCollection = GetGameCollection(game.GameCode);

            if (gameCollection != null)
            {
                var collectionDir = Path.Combine(generationDir, gameCollection);

                if (Directory.Exists(collectionDir))
                    AppendScriptsFromDirectory(collectionDir, ref scripts);
            }

            // Generation scripts (4, 5, 6, 7)
            if (Directory.Exists(generationDir))
                AppendScriptsFromDirectory(generationDir, ref scripts);

            // Global (top-level) scripts
            if (Directory.Exists(baseDir))
                AppendScriptsFromDirectory(baseDir, ref scripts);

            return scripts;
        }

        private static string? GetGameCollection(string gameCode)
        {
            return gameCode switch
            {
                "D" or "P" or "PL" => "dppl",
                "HG" or "SS" => "hgss",
                "B" or "W" => "bw",
                "B2" or "W2" => "b2w2",
                "X" or "Y" => "xy",
                "OR" or "AS" => "oras",
                "S" or "M" => "sm",
                "US" or "UM" => "usum",
                _ => null
            };
        }

        /// <summary>
        /// Attempts to append the absolute paths of all files inside the directory to the scripts list.
        /// Scripts with the same basename as existing entries will be skipped.
        /// </summary>
        public static void AppendScriptsFromDirectory(string directory, ref List<string> scripts)
        {
            if (!Directory.Exists(directory))
            {
                LuaLibraries.PrintError($"Script directory {directory} doesn't exist");
                return;
            }

            var files = Directory.GetFiles(directory);
            var i = 0;

            foreach (var file in files)
            {
                scripts.Add(file);
                i++;
            }

            return;
        }
    }
}
