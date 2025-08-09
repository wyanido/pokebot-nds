using BizHawk.Common.PathExtensions;
using Newtonsoft.Json;
using System.IO;

namespace Wyanido.Pokebot.Games.Data
{
    public abstract class GameDataCollection<T>
    {
        public static T Instance { get; protected set; }

        /// <summary>
        /// Returns the full path for a relative filename inside the Pokebot data directory.
        /// </summary>
        protected string GetDataPath(string[] paths)
        {
            string[] fullPath = [PathUtils.DataDirectoryPath, "ExternalTools", "Pokebot", "data", .. paths];
            return Path.Combine(fullPath);
        }

        /// <summary>
        /// Parses a Json file inside the Pokebot data directory using a relative path or filename.
        /// </summary>
        protected T1 ParseDataJson<T1>(string[] paths)
        {
            var fullPath = GetDataPath(paths);
            var jsonString = File.ReadAllText(fullPath);
            return JsonConvert.DeserializeObject<T1>(jsonString);
        }
    }
}
