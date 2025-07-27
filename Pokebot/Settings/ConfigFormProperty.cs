using System;

namespace Wyanido.Pokebot.Settings
{
    /// <summary>
    /// Class definition for individual config properties. 
    /// This is only used in the construction of the config form.
    /// </summary>
    public class ConfigFormProperty(string key, Type propertyType, object defaultValue)
    {
        /// <summary>
        /// The property's key inside the config table.
        /// </summary>
        public readonly string Key = key;

        /// <summary>
        /// The C# type of the property's default value.
        /// </summary>
        public readonly Type PropertyType = propertyType;

        /// <summary>
        /// The default value assigned to the property by the config.
        /// </summary>
        public readonly object DefaultValue = defaultValue;
    }
}
