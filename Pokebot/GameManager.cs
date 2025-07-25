using BizHawk.Client.Common;
using BizHawk.Emulation.Common;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Wyanido.Pokebot.LuaStuff;

namespace Wyanido.Pokebot
{
    public class GameManager(ApiContainer APIs)
    {
        private ApiContainer APIs { set; get; } = APIs;

        public static List<string> GetGameScripts(GameDefinition game)
        {
            var scripts = GetGameScriptsFromDirectory(game, PokebotLuaLibraries.ScriptsPath);
            var basenames = new List<string>();

            // Return the first (most context-specific) script of any given name to allow overrides
            return [.. scripts.Where(x =>
            {
                var basename = Path.GetFileName(x);

                if (basenames.Contains(basename))
                {
                    PokebotLuaLibraries.PrintDebug($"Skipped overriden script {basename}");
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
        public static List<string> GetGameScriptsFromDirectory(GameDefinition game, string baseDir)
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

        /// <summary>
        /// Attempts to append the absolute paths of all files inside the directory to the scripts list.
        /// Scripts with the same basename as existing entries will be skipped.
        /// </summary>
        public static void AppendScriptsFromDirectory(string directory, ref List<string> scripts)
        {
            if (!Directory.Exists(directory))
            {
                PokebotLuaLibraries.PrintError($"Script directory {directory} doesn't exist");
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
        public GameDefinition? DetectGame()
        {
            var gameInfo = APIs.Emulation.GetGameInfo();

            if (gameInfo.IsNullInstance() || gameInfo == null)
            {
                PokebotLuaLibraries.PrintDebug("GameInfo was a null instance");
                return null;
            }

            var languageCode = GetLanguageCode();

            if (languageCode == null)
            {
                PokebotLuaLibraries.PrintDebug("Could not determine language code");
                return null;
            }

            var gameCode = GetGameCode();
            var generation = GetGameCodeGeneration(gameCode);

            if (!generation.HasValue)
            {
                PokebotLuaLibraries.PrintDebug("Could not determine ROM generation");
                return null;
            }

            var offset = GetGameMemoryOffset(gameCode, languageCode);

            if (!offset.HasValue)
            {
                PokebotLuaLibraries.PrintDebug("Could not determine ROM memory offset");
                return null;
            }

            return new()
            {
                Title = gameInfo.Name,
                Generation = generation.Value,
                GameCode = GetGameCode(),
                LanguageCode = languageCode,
                MemoryOffset = offset.Value
            };
        }

        private string GetGameCode()
        {
            var address = 0x023FFE08;
            byte[] word = { (byte)APIs.Memory.ReadByte(address), (byte)APIs.Memory.ReadByte(address + 1) };

            if (word[1] == 0)
            {
                // Game code is a single letter, e.g. B, W, D, P
                return Encoding.UTF8.GetString([word[0]]);
            }
            else
            {
                // Code is 2 letters, e.g. PL, B2, W2
                return Encoding.UTF8.GetString(word);
            }
        }

        private string? GetLanguageCode()
        {
            var code = APIs.Memory.ReadByte(0x023FFE0F);

            return code switch
            {
                0x4A => "JP",
                0x45 => "EN", // Gen 4 only
                0x4F => "EN", // Gen 5 only
                0x46 => "FR",
                0x49 => "IT",
                0x44 => "DE",
                0x53 => "ES",
                _ => null,
            };
        }

        private int? GetGameCodeGeneration(string gameCode)
        {
            return gameCode switch
            {
                "D" or "P" or "PL" or "HG" or "SS" => 4,
                "B" or "W" or "B2" or "W2" => 5,
                "X" or "Y" or "OR" or "AS" => 6,
                "S" or "M" or "US" or "UM" => 7,
                _ => null,
            };
        }

        private int? GetGameMemoryOffset(string gameCode, string languageCode)
        {
            switch (gameCode)
            {
                // Diamond and Pearl have the same offsets
                case "D":
                case "P":
                    return languageCode switch
                    {
                        "JP" => 0x1860,
                        "EN" => 0x0,
                        "FR" => 0x180,
                        "IT" => 0xE0,
                        "DE" => 0x140,
                        "ES" => 0x1A0,
                        _ => null,
                    };
                case "PL":
                    return languageCode switch
                    {
                        "JP" => -0xC00,
                        "EN" => 0x0,
                        "FR" => 0x1E0,
                        "IT" => 0x160,
                        "DE" => 0x1A0,
                        "ES" => 0x200,
                        _ => null,
                    };
                // Only the offset for Spanish games differs in HGSS
                case "HG":
                case "SS":
                    return languageCode switch
                    {
                        "JP" => -0x3B08,
                        "EN" => 0x0,
                        "FR" => 0x20,
                        "IT" => -0x60,
                        "DE" => -0x20,
                        "ES" => gameCode == "HG" ? 0x20 : 0x40,
                        _ => null
                    };
                // Black and White generally differs by 0x20, with two exceptions
                case "B":
                case "W":
                    var offset = gameCode == "W" ? 0x20 : 0;

                    return languageCode switch
                    {
                        "JP" => gameCode == "B" ? -0x1A0 : -0x180,
                        "EN" => 0x0 + offset,
                        "FR" => -0x80 + offset,
                        "IT" => -0x100 + offset,
                        "DE" => -0xC0 + offset,
                        "ES" => -0x40,
                        _ => null,
                    };
                case "B2":
                    return languageCode switch
                    {
                        "JP" => -0x660,
                        "EN" => 0x0,
                        "FR" => 0x20,
                        "IT" => -0x100,
                        "DE" => -0xC0,
                        "ES" => -0x40,
                        _ => null,
                    };
                case "W2":
                    return languageCode switch
                    {
                        "JP" => -0x640,
                        "EN" => 0x40,
                        "FR" => 0x40,
                        "IT" => -0xE0,
                        "DE" => -0xA0,
                        "ES" => -0x20,
                        _ => null,
                    };
                default:
                    return null;
            }
        }
    }
}
