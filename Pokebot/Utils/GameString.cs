using BizHawk.Client.Common;
using System.Collections.Generic;
using System.Text;

namespace Wyanido.Pokebot.Utils
{
    public static class GameString
    {
        /// <summary>
        /// The character map used in gen 4 string encoding.
        /// </summary>
        private static readonly string[] Charmap = [
            "　", "ぁ", "あ", "ぃ", "い", "ぅ", "う", "ぇ", "え", "ぉ", "お", "か", "が", "き", "ぎ",
            "く", "ぐ", "け", "げ", "こ", "ご", "さ", "ざ", "し", "じ", "す", "ず", "せ", "ぜ", "そ", "ぞ",
            "た", "だ", "ち", "ぢ", "っ", "つ", "づ", "て", "で", "と", "ど", "な", "に", "ぬ", "ね", "の",
            "は", "ば", "ぱ", "ひ", "び", "ぴ", "ふ", "ぶ", "ぷ", "へ", "べ", "ぺ", "ほ", "ぼ", "ぽ", "ま",
            "み", "む", "め", "も", "ゃ", "や", "ゅ", "ゆ", "ょ", "よ", "ら", "り", "る", "れ", "ろ", "わ",
            "を", "ん", "ァ", "ア", "ィ", "イ", "ゥ", "ウ", "ェ", "エ", "ォ", "オ", "カ", "ガ", "キ", "ギ",
            "ク", "グ", "ケ", "ゲ", "コ", "ゴ", "サ", "ザ", "シ", "ジ", "ス", "ズ", "セ", "ゼ", "ソ", "ゾ",
            "タ", "ダ", "チ", "ヂ", "ッ", "ツ", "ヅ", "テ", "デ", "ト", "ド", "ナ", "ニ", "ヌ", "ネ", "ノ",
            "ハ", "バ", "パ", "ヒ", "ビ", "ピ", "フ", "ブ", "プ", "ヘ", "ベ", "ペ", "ホ", "ボ", "ポ", "マ",
            "ミ", "ム", "メ", "モ", "ャ", "ヤ", "ュ", "ユ", "ョ", "ヨ", "ラ", "リ", "ル", "レ", "ロ", "ワ",
            "ヲ", "ン", "０", "１", "２", "３", "４", "５", "６", "７", "８", "９", "Ａ", "Ｂ", "Ｃ", "Ｄ",
            "Ｅ", "Ｆ", "Ｇ", "Ｈ", "Ｉ", "Ｊ", "Ｋ", "Ｌ", "Ｍ", "Ｎ", "Ｏ", "Ｐ", "Ｑ", "Ｒ", "Ｓ", "Ｔ",
            "Ｕ", "Ｖ", "Ｗ", "Ｘ", "Ｙ", "Ｚ", "ａ", "ｂ", "ｃ", "ｄ", "ｅ", "ｆ", "ｇ", "ｈ", "ｉ", "ｊ",
            "ｋ", "ｌ", "ｍ", "ｎ", "ｏ", "ｐ", "ｑ", "ｒ", "ｓ", "ｔ", "ｕ", "ｖ", "ｗ", "ｘ", "ｙ", "ｚ",
            "",   "！", "？", "、", "。", "…", "・", "／", "「", "」", "『", "』", "（", "）", "♂", "♀",
            "＋", "ー", "×", "÷", "＝", "～", "：", "；", "．", "，", "♠", "♣", "♥", "♦", "★", "◎",
            "○", "□", "△", "◇", "＠", "♪", "％", "☀", "☁", "☂", "☃", "😑", "☺", "☹", "😠", "⤴︎",
            "⤵︎", "💤", "円", "💰", "🗝️", "💿", "✉️", "💊", "🍓", "◓", "💥", "←", "↑", "↓", "→", "►",
            "＆", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E",
            "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U",
            "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
            "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "À",
            "Á", "Â", "Ã", "Ä", "Å", "Æ", "Ç", "È", "É", "Ê", "Ë", "Ì", "Í", "Î", "Ï", "Ð",
            "Ñ", "Ò", "Ó", "Ô", "Õ", "Ö", "×", "Ø", "Ù", "Ú", "Û", "Ü", "Ý", "Þ", "ß", "à",
            "á", "â", "ã", "ä", "å", "æ", "ç", "è", "é", "ê", "ë", "ì", "í", "î", "ï", "ð",
            "ñ", "ò", "ó", "ô", "õ", "ö", "÷", "ø", "ù", "ú", "û", "ü", "ý", "þ", "ÿ", "Œ",
            "œ", "Ş", "ş", "ª", "º", "er", "re", "r", "₽", "¡", "¿", "!", "?", ",", ".", "…",
            "･", "/", "‘", "’", "“", "”", "„", "«", "»", "(", ")", "♂", "♀", "+", "-", "*",
            "#", "=", "&", "~", ":", ";", "♠", "♣", "♥", "♦", "★", "◎", "○", "□", "△", "◇",
            "@", "♪", "%", "☀", "☁", "☂", "☃", "😑", "☺", "☹", "😠", "⤴︎", "⤵︎", "💤", " ", "e",
            "PK", "MN", " ", " ", " ", "", " ", " ", "°", "_", "＿", "․", "‥"
        ];

        /// <summary>
        /// Converts a collection of bytes to a readable string, optionally using the 
        /// gen 4 character map instead of UTF8 encoding as used in later titles.
        /// </summary>
        public static string BytesToString(IReadOnlyList<byte> bytes, bool useCharmap)
        {
            var text = "";

            for (int i = 0; i < bytes.Count; i++)
            {
                var word = bytes[i] + (bytes[i + 1] << 8);

                if (word == 0xFFFF || word == 0) // Null terminator
                    break;

                var character = useCharmap ? Charmap?[word] : Encoding.UTF8.GetString([(byte)word]);
                text += character ?? "?";
            }

            return text;
        }

        public static string ReadString4(ApiContainer apis, long addr, int length)
        {
            var bytes = apis.Memory.ReadByteRange(addr, length);
            return BytesToString(bytes, true);
        }

        public static string ReadString(ApiContainer apis, long addr, int length)
        {
            var bytes = apis.Memory.ReadByteRange(addr, length);
            return BytesToString(bytes, false);
        }
    }
}
