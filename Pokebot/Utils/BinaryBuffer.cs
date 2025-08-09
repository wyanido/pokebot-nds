using System;
using System.IO;

namespace Wyanido.Pokebot.Utils
{
    /// <summary>
    /// Helper class for a BinaryWriter that is automatically set up with an expandable MemoryStream
    /// for convenience, and the ability to be converted into an array.
    /// </summary>
    public class BinaryBuffer : IDisposable
    {
        public readonly MemoryStream Stream;
        public readonly BinaryWriter Writer;
        public readonly BinaryReader Reader;

        /// <summary>
        /// Creates a writeable, expandable MemoryStream with empty data.
        /// </summary>
        public BinaryBuffer()
        {
            Stream = new();
            Writer = new(Stream);
        }

        /// <summary>
        /// Creates a read-only MemoryStream using the provided buffer.
        /// </summary>
        public BinaryBuffer(byte[] buffer)
        {
            Stream = new(buffer, false);
            Reader = new(Stream);
        }

        public byte[] ToArray() => Stream.ToArray();

        public void Dispose()
        {
            Stream.Dispose();
            Reader?.Dispose();
            Writer?.Dispose();
        }
    }
}
