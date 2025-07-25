using BizHawk.Common.CollectionExtensions;
using NLua;
using System;
using System.Linq;
using System.Text;

namespace Wyanido.Pokebot.LuaLibrary
{
    internal static class LuaHelpers
    {
        /// <summary>
        /// Serialises a LuaTable as a readable string.
        /// </summary>
        public static string ParseTable(LuaTable lti)
        {
            var keyObjs = lti.Keys;
            var valueObjs = lti.Values;

            if (keyObjs.Count != valueObjs.Count)
                throw new ArgumentException(message: "each value must be paired with one key, they differ in number", paramName: nameof(lti));

            var values = new object[keyObjs.Count];
            var kvpIndex = 0;

            foreach (var valueObj in valueObjs)
                values[kvpIndex++] = valueObj;

            return string.Concat(keyObjs.Cast<object>()
                .Select((kObj, i) => $"\"{kObj}\": \"{values[i]}\"\n")
                .Order());
        }

        /// <summary>
        /// Serialises the object based on type and appends it to the StringBuilder.
        /// </summary>
        private static void SerializeAndWrite(ref StringBuilder stringBuilder, object output)
        {
            stringBuilder.Append(output switch
            {
                null => "nil",
                LuaTable table => ParseTable(table),
                _ => output.ToString(),
            });
        }

        /// <summary>
        /// Parses a list of objects to a readable string. Intended for parsing Lua objects.
        /// </summary>
        public static string ParseObjects(string separator, string terminator, params object[] outputs)
        {
            if (outputs == null || outputs.Length == 0 || outputs.Length == 1 && outputs[0] is null)
                return $"(no return){terminator}";

            var stringBuilder = new StringBuilder();
            SerializeAndWrite(ref stringBuilder, outputs[0]);

            for (int outIndex = 1, indexAfterLast = outputs.Length; outIndex != indexAfterLast; outIndex++)
            {
                stringBuilder.Append(separator);
                SerializeAndWrite(ref stringBuilder, outputs[outIndex]);
            }

            if (!string.IsNullOrEmpty(terminator))
                stringBuilder.Append(terminator);

            return stringBuilder.ToString();
        }
    }
}
