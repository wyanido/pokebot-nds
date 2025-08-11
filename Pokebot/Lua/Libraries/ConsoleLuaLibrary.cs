using BizHawk.Client.Common;
using System;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using Wyanido.Pokebot.Utils;

namespace Wyanido.Pokebot.Lua.Libraries
{
    public sealed class ConsoleLuaLibrary(
        ILuaLibraries luaLibraries,
        ApiContainer apiContainer,
        Action<string> logOutputCallback) : LuaLibraryBase(
              luaLibraries,
              apiContainer,
              logOutputCallback)
    {
        public RichTextBox? OutputBox { get; set; }
        public bool ShowDebug { get; set; } = true;

        public override string Name => "console";

        [LuaMethodExample("console.clear( );")]
        [LuaMethod("clear", "clears the output box of the Lua Console window")]
        public void Clear()
        {
            OutputBox?.Clear();
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
        public void Log(params object[] outputs) => AppendMessage(outputs, "\t", "\n");

        [LuaMethodExample("console.debug( \"New log.\" );")]
        [LuaMethod("debug", "Outputs the given object to the output box on the Lua Console dialog. Note: Can accept a LuaTable")]
        public void Debug(params object[] outputs) => LogDebug(outputs);

        [LuaMethodExample("console.warn( \"New log.\" );")]
        [LuaMethod("warn", "Outputs the given object to the output box on the Lua Console dialog. Note: Can accept a LuaTable")]
        public void Warn(params object[] outputs) => LogWarning(outputs);

        [LuaMethodExample("console.writeline( \"New log line.\" );")]
        [LuaMethod("writeline", "Outputs the given object to the output box on the Lua Console dialog. Note: Can accept a LuaTable")]
        public void WriteLine(params object[] outputs) => AppendMessage(outputs, "\n", "\n");

        [LuaMethodExample("console.write( \"New log message.\" );")]
        [LuaMethod("write", "Outputs the given object to the output box on the Lua Console dialog. Note: Can accept a LuaTable")]
        public void Write(params object[] outputs) => AppendMessage(outputs, "", "");

        /// <summary>
        /// Logs a message in gray text if ShowDebug is enabled.
        /// </summary>
        public void LogDebug(params object[] outputs)
        {
            if (ShowDebug) AppendMessage(["INFO", .. outputs], colour: Color.Gray);
        }

        /// <summary>
        /// Logs a message in orange text.
        /// </summary>
        public void LogWarning(params object[] outputs)
        {
            AppendMessage(["WARN", .. outputs], colour: Color.OrangeRed);
        }

        /// <summary>
        /// Logs a message in red text.
        /// </summary>
        public void LogError(params object[] outputs)
        {
            if (ShowDebug) AppendMessage(outputs, colour: Color.Red);
        }

        /// <summary>
        /// Base print function for appending text to the OutputBox.
        /// </summary>
        private void AppendMessage(object[] outputs, string separator = "\t", string terminator = "\n", Color? colour = null)
        {
            if (OutputBox is null)
                return;

            var message = LuaHelpers.SerialiseObjects(separator, terminator, outputs);

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

            ScrollToBottom();
        }

        /// <summary>
        /// Sets the caret position of the OutputBox to the last character, scrolling it to the end.
        /// </summary>
        private void ScrollToBottom()
        {
            if (OutputBox is null)
                return;

            OutputBox.SelectionStart = OutputBox.Text.Length;
            OutputBox.SelectionLength = 0;
            OutputBox.ScrollToCaret();
        }
    }
}
