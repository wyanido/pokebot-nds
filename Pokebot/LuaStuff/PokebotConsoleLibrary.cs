using BizHawk.Client.Common;
using BizHawk.Common.CollectionExtensions;
using NLua;
using System;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace Wyanido.Pokebot.LuaStuff
{
    public sealed class PokebotConsoleLibrary : LuaLibraryBase
    {
        public RichTextBox OutputBox { get; set; }
        public bool ShowDebug { get; set; } = true;

        public PokebotConsoleLibrary(ILuaLibraries luaLibsImpl, ApiContainer apiContainer, Action<string> logOutputCallback)
            : base(luaLibsImpl, apiContainer, logOutputCallback) { }

        public override string Name => "console";

        [LuaMethodExample("console.clear( );")]
        [LuaMethod("clear", "clears the output box of the Lua Console window")]
        public void Clear()
        {
            OutputBox.Clear();
        }

        [LuaMethodExample("local stconget = console.getluafunctionslist( );")]
        [LuaMethod("getluafunctionslist", "returns a list of implemented functions")]
        public string GetLuaFunctionsList()
        {
            var list = new StringBuilder();
            foreach (var function in _luaLibsImpl.Docs)
            {
                list.AppendLine(function.Name);
            }

            return list.ToString();
        }

        [LuaMethodExample("console.log( \"New log.\" );")]
        [LuaMethod("log", "Outputs the given object to the output box on the Lua Console dialog. Note: Can accept a LuaTable")]
        public void Log(params object[] outputs)
        {
            LogWithSeparator("\t", "\n", outputs);
        }

        [LuaMethodExample("console.writeline( \"New log line.\" );")]
        [LuaMethod("writeline", "Outputs the given object to the output box on the Lua Console dialog. Note: Can accept a LuaTable")]
        public void WriteLine(params object[] outputs)
        {
            LogWithSeparator("\n", "\n", outputs);
        }

        [LuaMethodExample("console.write( \"New log message.\" );")]
        [LuaMethod("write", "Outputs the given object to the output box on the Lua Console dialog. Note: Can accept a LuaTable")]
        public void Write(params object[] outputs)
        {
            LogWithSeparator("", "", outputs);
        }

        private static string SerializeTable(LuaTable lti)
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

        private void SerializeAndWrite(ref StringBuilder stringBuilder, object output)
        {
            stringBuilder.Append(output switch
            {
                null => "nil",
                LuaTable table => SerializeTable(table),
                _ => output.ToString(),
            });
        }

        private string ParseOutputs(string separator, string terminator, params object[] outputs)
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

        // Outputs the given object to the output box on the Lua Console dialog. Note: Can accept a LuaTable
        private void LogWithSeparator(string separator, string terminator, params object[] outputs)
        {
            var output = ParseOutputs(separator, terminator, outputs);
            Print(output, false);
        }

        public void Print(string message, bool newLine = true, Color? colour = null)
        {
            if (OutputBox is null)
                return;

            if (colour.HasValue)
            {
                OutputBox.SelectionColor = colour.Value;
                OutputBox.AppendText(message);
                OutputBox.SelectionColor = OutputBox.ForeColor;
            }
            else
            {
                OutputBox.AppendText(message);
            }

            if (newLine) OutputBox.AppendText(Environment.NewLine);

            ScrollToBottom();
        }

        public void LogDebug(params object[] outputs)
        {
            if (!ShowDebug)
                return;

            var output = ParseOutputs("\t", "\n", outputs);
            Print(output, false, Color.Gray);
        }

        public void LogError(params object[] outputs)
        {
            var output = ParseOutputs("\t", "\n", outputs);
            Print(output, false, Color.Red);
        }

        private void ScrollToBottom()
        {
            OutputBox.SelectionStart = OutputBox.Text.Length;
            OutputBox.SelectionLength = 0;
            OutputBox.ScrollToCaret();
        }
    }
}
