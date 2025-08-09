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
        public int SpeciesIndex;
        public string? Species => Data.Species.GetName(SpeciesIndex);

        public int HeldItemIndex;
        public string? HeldItem => "";

        public int AbilityIndex;
        public string? Ability => Abilities.GetName(AbilityIndex);

        public bool IsNicknamed;
        public string Nickname;

        public uint NatureIndex;
        public string Nature => Natures.GetName((int)NatureIndex);

        public string Gender;

        public uint PID;
        public ushort Checksum;
        public int Experience;
        public int Friendship;
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

        public int AlternateForm;

        public int OriginGame;
        public uint DateEggReceived;
        public uint DateMet;
        public uint EggLocationIndex;
        public uint MetLocationIndex;
        public byte EncounterType;
        public byte CapsuleIndex;
        public byte[] MailMessage;

        public int Pokerus;
        public PokeBall PokeBallIndex;

        public int Level;
        public ushort CurrentHP;

        public HiddenPowerType HiddenPowerTypeIndex;
        public int HiddenPowerPower;

        public byte[] Raw;
    }
}
