using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using Wyanido.Pokebot.Games.Data;
using YamlDotNet.Serialization;

namespace Wyanido.Pokebot.Utils;

public class UserData
{
    public Action<object> Log { get; set; }

    public Dictionary<string, object> Config = [];

    private static readonly string UserDir = Path.Combine(Pokebot.DataPath, "user");
    private static readonly string ConfigPath = Path.Combine(Pokebot.DataPath, "config.yaml");
    private static readonly string EncountersPath = Path.Combine(UserDir, "encounters.json");
    private static readonly string StatsPath = Path.Combine(UserDir, "stats.json");
    private static readonly string TargetsPath = Path.Combine(UserDir, "target_log.json");

    private Pokemon[] encounterLog = [];
    private Pokemon[] targetLog = [];
    private Stats stats = new();
    private Dictionary<object, object> config = [];

    // YAML serailisation for config file
    private readonly ISerializer serialiser = new SerializerBuilder().Build();
    private readonly IDeserializer deserialiser = new DeserializerBuilder().Build();

    public void Initialise()
    {
        if (!Directory.Exists(UserDir))
        {
            Directory.CreateDirectory(UserDir);
            Print($"Created new user directory at {UserDir}");
            SaveConfig(); // Save empty config
            return;
        }

        try
        {
            stats = File.Exists(StatsPath) ? DeserialiseFile<Stats>(StatsPath) : new();
            encounterLog = File.Exists(EncountersPath) ? DeserialiseFile<Pokemon[]>(EncountersPath) : [];
            targetLog = File.Exists(TargetsPath) ? DeserialiseFile<Pokemon[]>(TargetsPath) : [];
        }
        catch (Exception ex)
        {
            Print($"Failed to load user data: {ex.Message}");
        }

        if (File.Exists(ConfigPath))
        {
            LoadConfig(ConfigPath);
        }
        else
        {
            Print($"Created new config file at {ConfigPath}");
            SaveConfig(); // Save empty config
        }
    }

    /// <summary>
    /// Serialises the config object as YAML and writes it to disk.
    /// </summary>
    public void SaveConfig()
    {
        var directory = Path.GetDirectoryName(ConfigPath);

        if (!Directory.Exists(directory))
            throw new FileNotFoundException($"Couldn't create config file at nonexistent directory {directory}.");

        var configYamlString = serialiser.Serialize(Config);

        var stream = File.CreateText(ConfigPath);
        stream.Write(configYamlString);
        stream.Close();
    }

    /// <summary>
    /// Loads and deserialises a YAML config object from disk.
    /// </summary>
    private void LoadConfig(string path)
    {
        var configYamlString = File.ReadAllText(path);
        var configObject = deserialiser.Deserialize(configYamlString);

        // Dynamically add config fields into the dictionary instead of
        // relying on JsonProperty, as individual .lua scripts need to
        // add their own config options without recompiling the .dll.
        if (configObject is Dictionary<object, object> configDictionary)
        {
            for (var e = configDictionary.GetEnumerator(); e.MoveNext();)
            {
                var key = (string)e.Current.Key;
                var value = e.Current.Value;

                Config.Add(key, value);
            }
            return;
        }

        // If the config file is any type other than a dictionary, it's
        // usually empty and can't properly be deserialised, so do nothing here.
        Print($"Config file at {path} is formatted incorrectly and could not be loaded.");
    }

    /// <summary>
    /// Deserailises a .json file as the given type.
    /// </summary>
    private T? DeserialiseFile<T>(string path)
    {
        string file = File.ReadAllText(path);
        return JsonConvert.DeserializeObject<T>(file);

    }

    /// <summary>
    /// Shorthand for safely invoking the log method if assigned.
    /// </summary>
    private void Print(object outputs) => Log?.Invoke(outputs);
}
