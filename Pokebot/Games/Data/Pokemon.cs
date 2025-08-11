namespace Wyanido.Pokebot.Games.Data
{
    public struct OriginalTrainer
    {
        public string Name;
        public int LanguageID;
        public ushort TID;
        public ushort SID;
    }

    public struct Stats
    {
        public ushort HP;
        public ushort Attack;
        public ushort Defense;
        public ushort Speed;
        public ushort SpecialAttack;
        public ushort SpecialDefense;

        public readonly int Sum => HP + Attack + Defense + Speed + SpecialAttack + SpecialDefense;
    }

    public struct ContestStats
    {
        public byte Cool;
        public byte Beauty;
        public byte Cute;
        public byte Smart;
        public byte Tough;
        public byte Sheen;
    }

    public struct Move
    {
        public ushort Index;
        public byte PP;
        public byte PPUps;
    }

    public struct Ribbons
    {
        public ushort HoennRibbonSet1;
        public ushort HoennRibbonSet2;
        public ushort SinnohRibbonSet1;
        public ushort SinnohRibbonSet2;
        public ushort SinnohRibbonSet3;
        public ushort SinnohRibbonSet4;
        public ushort UnovaRibbonSet;
    }

    public enum PokeBall
    {
        MasterBall,
        UltraBall,
        GreatBall,
        PokéBall,
        SafariBall,
        NetBall,
        DiveBall,
        NestBall,
        RepeatBall,
        TimerBall,
        LuxuryBall,
        PremierBall,
        DuskBall,
        HealBall,
        QuickBall,
        CherishBall,
    }

    public enum HiddenPowerType
    {
        Fighting,
        Flying,
        Poison,
        Ground,
        Rock,
        Bug,
        Ghost,
        Steel,
        Fire,
        Water,
        Grass,
        Electric,
        Psychic,
        Ice,
        Dragon,
        Dark
    }

    public class Pokemon
    {
        public uint SpeciesIndex;
        public PokemonSpecies? Species => Data.Species.Get(SpeciesIndex);

        public uint HeldItemIndex;
        public string? HeldItem => Items.GetName(HeldItemIndex);

        public uint AbilityIndex;
        public string? Ability => Abilities.GetName(AbilityIndex);

        public bool IsNicknamed;
        public string Nickname;

        public uint NatureIndex;
        public string Nature => Natures.GetName((int)NatureIndex);

        public string Gender;

        public uint PID;
        public ushort Checksum;
        public uint Experience;
        public uint Friendship;
        public int Markings;
        public ushort ShinyValue;
        public bool IsShiny;
        public bool IsEgg;

        public OriginalTrainer OT;
        public Stats IVs;
        public Stats EVs;
        public Stats Stats;
        public ContestStats ContestStats;
        public Ribbons Ribbons;

        public Move[] Moves;

        public bool FatefulEncounter;

        public bool IsNsPokemon;
        public int DreamWorldAbilityIndex;

        public int AlternateFormIndex;
        public string AlternateForm
        {
            get
            {
                switch (Species.Name)
                {
                    case "Unown":
                        return AlternateFormIndex switch
                        {
                            0x00 => "A",
                            0x38 => "H",
                            0x70 => "O",
                            0xA8 => "V",
                            0x08 => "B",
                            0x40 => "I",
                            0x78 => "P",
                            0xB0 => "W",
                            0x10 => "C",
                            0x48 => "J",
                            0x80 => "Q",
                            0xB8 => "X",
                            0x18 => "D",
                            0x50 => "K",
                            0x88 => "R",
                            0xC0 => "Y",
                            0x20 => "E",
                            0x58 => "L",
                            0x90 => "S",
                            0xC8 => "Z",
                            0x28 => "F",
                            0x60 => "M",
                            0x98 => "T",
                            0xD0 => "Exclamation",
                            0x30 => "G",
                            0x68 => "N",
                            0xA0 => "U",
                            0xD8 => "Question",
                            _ => ""
                        };
                    case "Deoxys":
                        return AlternateFormIndex switch
                        {
                            0x00 => "Normal",
                            0x08 => "Attack",
                            0x10 => "Defense",
                            0x18 => "Speed",
                            _ => ""
                        };
                    case "Burmy":
                    case "Wormadam":
                        return AlternateFormIndex switch
                        {
                            0x00 => "Plant",
                            0x08 => "Sandy",
                            0x10 => "Trash",
                            _ => ""
                        };
                    case "Shellos":
                    case "Gastrodon":
                        return AlternateFormIndex switch
                        {
                            0x00 => "West",
                            0x08 => "East",
                            _ => ""
                        };
                    case "Rotom":
                        return AlternateFormIndex switch
                        {
                            0x00 => "Normal",
                            0x08 => "Heat",
                            0x10 => "Wash",
                            0x18 => "Frost",
                            0x20 => "Fan",
                            0x28 => "Cut",
                            _ => ""
                        };
                    case "Giratina":
                        return AlternateFormIndex switch
                        {
                            0x00 => "Altered",
                            0x08 => "Origin",
                            _ => ""
                        };
                    case "Shaymin":
                        return AlternateFormIndex switch
                        {
                            0x00 => "Land",
                            0x08 => "Sky",
                            _ => ""
                        };
                    case "Arceus":
                        return AlternateFormIndex switch
                        {
                            0x00 => "Normal",
                            0x30 => "Bug",
                            0x60 => "Electric",
                            0x08 => "Fighting",
                            0x38 => "Ghost",
                            0x68 => "Psychic",
                            0x10 => "Flying",
                            0x40 => "Steel",
                            0x70 => "Ice",
                            0x18 => "Poison",
                            0x48 => "Fire",
                            0x78 => "Dragon",
                            0x20 => "Ground",
                            0x50 => "Water",
                            0x80 => "Dark",
                            0x28 => "Rock",
                            0x58 => "Grass",
                            0x4C => "Unknown",
                            _ => ""
                        };
                    default:
                        return "";
                }
            }
        }

        public int OriginGame;
        public uint DateEggReceived;
        public uint DateMet;
        public uint EggLocationIndex;
        public uint MetLocationIndex;
        public byte EncounterType;
        public byte CapsuleIndex;

        public int Pokerus;
        public PokeBall PokeBallIndex;

        public int Level;
        public ushort CurrentHP;

        public HiddenPowerType HiddenPowerTypeIndex;
        public int HiddenPowerPower;

        public byte[] Raw;
    }
}
