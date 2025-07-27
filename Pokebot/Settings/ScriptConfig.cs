using System;
using System.Collections.Generic;
using System.IO;
using Wyanido.Pokebot.LuaLibrary;
using YamlDotNet.Serialization;

namespace Wyanido.Pokebot.Settings
{
    public class ScriptConfig
    {
        public static string DefaultConfigPath = Path.Combine(PokebotLuaLibraries.PokebotDataPath, "config.yaml");

        public Dictionary<string, object> Properties = [];

        private readonly ISerializer serializer = new SerializerBuilder().Build();
        private readonly IDeserializer deserializer = new DeserializerBuilder().Build();
        private string originalPath = DefaultConfigPath;

        /// <summary>
        /// Attemps to load a config file from disk, returning an empty ScriptConfig if it fails for any reason.
        /// </summary>
        public static ScriptConfig LoadOrEmpty(string path)
        {
            try
            {
                return LoadFromFile(path);
            }
            catch
            {
                PokebotLuaLibraries.PrintDebug($"Created new config file at {DefaultConfigPath}");

                var scriptConfig = new ScriptConfig();
                scriptConfig.SaveToFile();
                return scriptConfig;
            }
        }

        /// <summary>
        /// Loads and deserialises a YAML config object from disk.
        /// </summary>
        public static ScriptConfig LoadFromFile(string path)
        {
            var config = new ScriptConfig();

            if (!File.Exists(path))
                throw new FileNotFoundException($"Couldn't find the config file at {path}.");

            var configYamlString = File.ReadAllText(path);
            var configObject = config.deserializer.Deserialize(configYamlString);

            // No properties to iterate
            if (configObject is null)
                return new ScriptConfig();

            // Config file shouldn be key-value pairs that deserialise to a dictionary.
            // This would only happen if it was improperly written by the user to be a YAML array.
            if (configObject is List<object>)
                throw new Exception("Config file was improperly written. It contains a list, not key-value pairs.");

            // I don't expect any other collection types, so catch them all here.
            if (configObject is not Dictionary<object, object> configDictionary)
                throw new Exception($"Unexpected config type '{configObject.GetType()}'");

            for (var e = configDictionary.GetEnumerator(); e.MoveNext();)
            {
                var key = (string)e.Current.Key;
                var value = e.Current.Value;

                config.Properties.Add(key, value);
            }

            config.originalPath = path;

            return config;
        }

        /// <summary>
        /// Serialises the config object as YAML and writes it to disk.
        /// </summary>
        public void SaveToFile(string? path = null)
        {
            if (path is null)
                path = originalPath;

            var directory = Path.GetDirectoryName(path);

            if (!Directory.Exists(directory))
                throw new FileNotFoundException($"Couldn't create config file at nonexistent directory {directory}.");

            var configYamlString = serializer.Serialize(Properties);

            var stream = File.CreateText(path);
            stream.Write(configYamlString);
            stream.Close();
        }
    }
}