import math
from enum import IntEnum

monLanguage = ["none", "日本語", "English", "Français", "Italiano", "Deutsch", "Español", "한국어"]

monGender = ["Male", "Female", "Genderless"]

monNature = ["Hardy", "Lonely", "Brave", "Adamant", "Naughty",
			  "Bold", "Docile", "Relaxed", "Impish", "Lax",
			  "Timid", "Hasty", "Serious", "Jolly", "Naive",
			  "Modest", "Mild", "Quiet", "Bashful", "Rash",
			  "Calm", "Gentle", "Sassy", "Careful", "Quirky"]

monName = ["none", "Bulbasaur", "Ivysaur", "Venusaur", "Charmander", "Charmeleon", "Charizard",
			"Squirtle", "Wartortle", "Blastoise", "Caterpie", "Metapod", "Butterfree",
			"Weedle", "Kakuna", "Beedrill", "Pidgey", "Pidgeotto", "Pidgeot", "Rattata", "Raticate",
			"Spearow", "Fearow", "Ekans", "Arbok", "Pikachu", "Raichu", "Sandshrew", "Sandslash",
			"NidoranF", "Nidorina", "Nidoqueen", "NidoranM", "Nidorino", "Nidoking",
			"Clefairy", "Clefable", "Vulpix", "Ninetales", "Jigglypuff", "Wigglytuff",
			"Zubat", "Golbat", "Oddish", "Gloom", "Vileplume", "Paras", "Parasect", "Venonat", "Venomoth",
			"Diglett", "Dugtrio", "Meowth", "Persian", "Psyduck", "Golduck", "Mankey", "Primeape",
			"Growlithe", "Arcanine", "Poliwag", "Poliwhirl", "Poliwrath", "Abra", "Kadabra", "Alakazam",
			"Machop", "Machoke", "Machamp", "Bellsprout", "Weepinbell", "Victreebel", "Tentacool", "Tentacruel",
			"Geodude", "Graveler", "Golem", "Ponyta", "Rapidash", "Slowpoke", "Slowbro",
			"Magnemite", "Magneton", "Farfetch'd", "Doduo", "Dodrio", "Seel", "Dewgong", "Grimer", "Muk",
			"Shellder", "Cloyster", "Gastly", "Haunter", "Gengar", "Onix", "Drowzee", "Hypno",
			"Krabby", "Kingler", "Voltorb", "Electrode", "Exeggcute", "Exeggutor", "Cubone", "Marowak",
			"Hitmonlee", "Hitmonchan", "Lickitung", "Koffing", "Weezing", "Rhyhorn", "Rhydon", "Chansey",
			"Tangela", "Kangaskhan", "Horsea", "Seadra", "Goldeen", "Seaking", "Staryu", "Starmie",
			"Mr. Mime", "Scyther", "Jynx", "Electabuzz", "Magmar", "Pinsir", "Tauros", "Magikarp", "Gyarados",
			"Lapras", "Ditto", "Eevee", "Vaporeon", "Jolteon", "Flareon", "Porygon", "Omanyte", "Omastar",
			"Kabuto", "Kabutops", "Aerodactyl", "Snorlax", "Articuno", "Zapdos", "Moltres",
			"Dratini", "Dragonair", "Dragonite", "Mewtwo", "Mew",

			"Chikorita", "Bayleef", "Meganium", "Cyndaquil", "Quilava", "Typhlosion",
			"Totodile", "Croconaw", "Feraligatr", "Sentret", "Furret", "Hoothoot", "Noctowl",
			"Ledyba", "Ledian", "Spinarak", "Ariados", "Crobat", "Chinchou", "Lanturn", "Pichu", "Cleffa",
			"Igglybuff", "Togepi", "Togetic", "Natu", "Xatu", "Mareep", "Flaaffy", "Ampharos", "Bellossom",
			"Marill", "Azumarill", "Sudowoodo", "Politoed", "Hoppip", "Skiploom", "Jumpluff", "Aipom",
			"Sunkern", "Sunflora", "Yanma", "Wooper", "Quagsire", "Espeon", "Umbreon", "Murkrow", "Slowking",
			"Misdreavus", "Unown", "Wobbuffet", "Girafarig", "Pineco", "Forretress", "Dunsparce", "Gligar",
			"Steelix", "Snubbull", "Granbull", "Qwilfish", "Scizor", "Shuckle", "Heracross", "Sneasel",
			"Teddiursa", "Ursaring", "Slugma", "Magcargo", "Swinub", "Piloswine", "Corsola", "Remoraid", "Octillery",
			"Delibird", "Mantine", "Skarmory", "Houndour", "Houndoom", "Kingdra", "Phanpy", "Donphan",
			"Porygon2", "Stantler", "Smeargle", "Tyrogue", "Hitmontop", "Smoochum", "Elekid", "Magby", "Miltank",
			"Blissey", "Raikou", "Entei", "Suicune", "Larvitar", "Pupitar", "Tyranitar", "Lugia", "Ho-Oh", "Celebi",
			
			"Treecko", "Grovyle", "Sceptile", "Torchic", "Combusken", "Blaziken", "Mudkip", "Marshtomp", 
			"Swampert", "Poochyena", "Mightyena", "Zigzagoon", "Linoone", "Wurmple", "Silcoon", "Beautifly",
			"Cascoon", "Dustox", "Lotad", "Lombre", "Ludicolo", "Seedot", "Nuzleaf", "Shiftry", 
			"Taillow", "Swellow", "Wingull", "Pelipper", "Ralts", "Kirlia", "Gardevoir", "Surskit", 
			"Masquerain", "Shroomish", "Breloom", "Slakoth", "Vigoroth", "Slaking", "Nincada", "Ninjask", 
			"Shedinja", "Whismur", "Loudred", "Exploud", "Makuhita", "Hariyama", "Azurill", "Nosepass", 
			"Skitty", "Delcatty", "Sableye", "Mawile", "Aron", "Lairon", "Aggron", "Meditite", "Medicham",
			"Electrike", "Manectric", "Plusle", "Minun", "Volbeat", "Illumise", "Roselia", "Gulpin", 
			"Swalot", "Carvanha", "Sharpedo", "Wailmer", "Wailord", "Numel", "Camerupt", "Torkoal", 
			"Spoink", "Grumpig", "Spinda", "Trapinch", "Vibrava", "Flygon", "Cacnea", "Cacturne", "Swablu",
			"Altaria", "Zangoose", "Seviper", "Lunatone", "Solrock", "Barboach", "Whiscash", "Corphish",
			"Crawdaunt", "Baltoy", "Claydol", "Lileep", "Cradily", "Anorith", "Armaldo", "Feebas", 
			"Milotic", "Castform", "Kecleon", "Shuppet", "Banette", "Duskull", "Dusclops", "Tropius", 
			"Chimecho", "Absol", "Wynaut", "Snorunt", "Glalie", "Spheal", "Sealeo", "Walrein", "Clamperl",
			"Huntail", "Gorebyss", "Relicanth", "Luvdisc", "Bagon", "Shelgon", "Salamence", "Beldum", 
			"Metang", "Metagross", "Regirock", "Regice", "Registeel", "Latias", "Latios", "Kyogre", 
			"Groudon", "Rayquaza", "Jirachi", "Deoxys",
			
			"Turtwig", "Grotle", "Torterra", "Chimchar", "Monferno", "Infernape", "Piplup", "Prinplup", 
			"Empoleon", "Starly", "Staravia", "Staraptor", "Bidoof", "Bibarel", "Kricketot", "Kricketune", 
			"Shinx", "Luxio", "Luxray", "Budew", "Roserade", "Cranidos", "Rampardos", "Shieldon", "Bastiodon", 
			"Burmy", "Wormadam", "Mothim", "Combee", "Vespiquen", "Pachirisu", "Buizel", "Floatzel", "Cherubi", 
			"Cherrim", "Shellos", "Gastrodon", "Ambipom", "Drifloon", "Drifblim", "Buneary", "Lopunny", 
			"Mismagius", "Honchkrow", "Glameow", "Purugly", "Chingling", "Stunky", "Skuntank", "Bronzor", 
			"Bronzong", "Bonsly", "Mime Jr.", "Happiny", "Chatot", "Spiritomb", "Gible", "Gabite", "Garchomp", 
			"Munchlax", "Riolu", "Lucario", "Hippopotas", "Hippowdon", "Skorupi", "Drapion", "Croagunk", 
			"Toxicroak", "Carnivine", "Finneon", "Lumineon", "Mantyke", "Snover", "Abomasnow", "Weavile", 
			"Magnezone", "Lickilicky", "Rhyperior", "Tangrowth", "Electivire", "Magmortar", "Togekiss", 
			"Yanmega", "Leafeon", "Glaceon", "Gliscor", "Mamoswine", "Porygon-Z", "Gallade", "Probopass", 
			"Dusknoir", "Froslass", "Rotom", "Uxie", "Mesprit", "Azelf", "Dialga", "Palkia", "Heatran", 
			"Regigigas", "Giratina", "Cresselia", "Phione", "Manaphy", "Darkrai", "Shaymin", "Arceus",
			
			"Victini", "Snivy", "Servine", "Serperior", "Tepig", "Pignite", "Emboar", "Oshawott", "Dewott", "Samurott", "Patrat", "Watchog",
			"Lillipup", "Herdier", "Stoutland", "Purrloin", "Liepard", "Pansage", "Simisage", "Pansear", "Simisear", "Panpour", "Simipour",
			"Munna", "Musharna", "Pidove", "Tranquill", "Unfezant", "Blitzle", "Zebstrika", "Roggenrola", "Boldore", "Gigalith", "Woobat",
			"Swoobat", "Drilbur", "Excadrill", "Audino", "Timburr", "Gurdurr", "Conkeldurr", "Tympole", "Palpitoad", "Seismitoad", "Throh",
			"Sawk", "Sewaddle", "Swadloon", "Leavanny", "Venipede", "Whirlipede", "Scolipede", "Cottonee", "Whimsicott", "Petilil",
			"Lilligant", "Basculin", "Sandile", "Krokorok", "Krookodile", "Darumaka", "Darmanitan", "Maractus", "Dwebble", "Crustle",
			"Scraggy", "Scrafty", "Sigilyph", "Yamask", "Cofagrigus", "Tirtouga", "Carracosta", "Archen", "Archeops", "Trubbish",
			"Garbodor", "Zorua", "Zoroark", "Minccino", "Cinccino", "Gothita", "Gothorita", "Gothitelle", "Solosis", "Duosion",
			"Reuniclus", "Ducklett", "Swanna", "Vanillite", "Vanillish", "Vanilluxe", "Deerling", "Sawsbuck", "Emolga", "Karrablast",
			"Escavalier", "Foongus", "Amoonguss", "Frillish", "Jellicent", "Alomomola", "Joltik", "Galvantula", "Ferroseed",
			"Ferrothorn", "Klink", "Klang", "Klinklang", "Tynamo", "Eelektrik", "Eelektross", "Elgyem", "Beheeyem", "Litwick",
			"Lampent", "Chandelure", "Axew", "Fraxure", "Haxorus", "Cubchoo", "Beartic", "Cryogonal", "Shelmet", "Accelgor",
			"Stunfisk", "Mienfoo", "Mienshao", "Druddigon", "Golett", "Golurk", "Pawniard", "Bisharp", "Bouffalant", "Rufflet",
			"Braviary", "Vullaby", "Mandibuzz", "Heatmor", "Durant", "Deino", "Zweilous", "Hydreigon", "Larvesta", "Volcarona", "Cobalion", 
			"Terrakion", "Virizion", "Tornadus", "Thundurus", "Reshiram", "Zekrom", "Landorus", "Kyurem", "Keldeo", "Meloetta", "Genesect",
			
			"Pokémon Egg", "Manaphy Egg"]

monAbility = ["none", "Stench", "Drizzle", "Speed Boost", "Battle Armor", "Sturdy", "Damp", "Limber", "Sand Veil", "Static", "Volt Absorb", "Water Absorb", "Oblivious", "Cloud Nine",
			"Compound Eyes", "Insomnia", "Color Change", "Immunity", "Flash Fire", "Shield Dust", "Own Tempo", "Suction Cups", "Intimidate", "Shadow Tag", "Rough Skin", "Wonder Guard", "Levitate",
			"Effect Spore", "Synchronize", "Clear Body", "Natural Cure", "Lightning Rod", "Serene Grace", "Swift Swim", "Chlorophyll", "Illuminate", "Trace", "Huge Power", "Poison Point",
			"Inner Focus", "Magma Armor", "Water Veil", "Magnet Pull", "Soundproof", "Rain Dish", "Sand Stream", "Pressure", "Thick Fat", "Early Bird", "Flame Body", "Run Away", "Keen Eye",
			"Hyper Cutter", "Pickup", "Truant", "Hustle", "Cute Charm", "Plus", "Minus", "Forecast", "Sticky Hold", "Shed Skin", "Guts", "Marvel Scale", "Liquid Ooze", "Overgrow", "Blaze", "Torrent",
			"Swarm", "Rock Head", "Drought", "Arena Trap", "Vital Spirit", "White Smoke", "Pure Power", "Shell Armor", "Air Lock", "Tangled Feet", "Motor Drive", "Rivalry", "Steadfast", "Snow Cloak",
			"Gluttony", "Anger Point", "Unburden", "Heatproof", "Simple", "Dry Skin", "Download", "Iron Fist", "Poison Heal", "Adaptability", "Skill Link", "Hydration", "Solar Power", "Quick Feet",
			"Normalize", "Sniper", "Magic Guard", "No Guard", "Stall", "Technician", "Leaf Guard", "Klutz", "Mold Breaker", "Super Luck", "Aftermath", "Anticipation", "Forewarn", "Unaware", "Tinted Lens",
			"Filter", "Slow Start", "Scrappy", "Storm Drain", "Ice Body", "Solid Rock", "Snow Warning", "Honey Gather", "Frisk", "Reckless", "Multitype", "Flower Gift", "Bad Dreams",
			
			"Pickpocket", "Sheer Force", "Contrary", "Unnerve", "Defiant", "Defeatist", "Cursed Body", "Healer", "Friend Guard",
			"Weak Armor", "Heavy Metal", "Light Metal", "Multiscale", "Toxic Boost", "Flare Boost", "Harvest", "Telepathy", "Moody",
			"Overcoat", "Poison Touch", "Regenerator", "Big Pecks", "Sand Rush", "Wonder Skin", "Analytic", "Illusion", "Imposter",
			"Infiltrator", "Mummy", "Moxie", "Justified", "Rattled", "Magic Bounce", "Sap Sipper", "Prankster", "Sand Force",
			"Iron Barbs", "Zen Mode", "Victory Star", "Turboblaze", "Teravolt"]

monItem = ["none", "Master Ball", "Ultra Ball", "Great Ball", "Poké Ball", "Safari Ball", "Net Ball", "Dive Ball",
		"Nest Ball", "Repeat Ball", "Timer Ball", "Luxury Ball", "Premier Ball", "Dusk Ball", "Heal Ball", "Quick Ball",
		"Cherish Ball", "Potion", "Antidote", "Burn Heal", "Ice Heal", "Awakening", "Parlyz Heal", "Full Restore",
		"Max Potion", "Hyper Potion", "Super Potion", "Full Heal", "Revive", "Max Revive", "Fresh Water", "Soda Pop",
		 "Lemonade", "Moomoo Milk", "EnergyPowder", "Energy Root", "Heal Powder", "Revival Herb", "Ether", "Max Ether", "Elixir",
		 "Max Elixir", "Lava Cookie", "Berry Juice", "Sacred Ash", "HP Up", "Protein", "Iron", "Carbos", "Calcium", "Rare Candy",
		 "PP Up", "Zinc", "PP Max", "Old Gateau", "Guard Spec.", "Dire Hit", "X Attack", "X Defend", "X Speed", "X Accuracy", "X Special",
		 "X Sp. Def", "Poké Doll", "Fluffy Tail", "Blue Flute", "Yellow Flute", "Red Flute", "Black Flute", "White Flute", "Shoal Salt",
		 "Shoal Shell", "Red Shard", "Blue Shard", "Yellow Shard", "Green Shard", "Super Repel", "Max Repel", "Escape Rope", "Repel", "Sun Stone",
		 "Moon Stone", "Fire Stone", "Thunder Stone", "Water Stone", "Leaf Stone", "TinyMushroom", "Big Mushroom", "Pearl", "Big Pearl",
		 "Stardust", "Star Piece", "Nugget", "Heart Scale", "Honey", "Growth Mulch", "Damp Mulch", "Stable Mulch", "Gooey Mulch",
		 "Root Fossil", "Claw Fossil", "Helix Fossil", "Dome Fossil", "Old Amber", "Armor Fossil", "Skull Fossil", "Rare Bone", "Shiny Stone",
		 "Dusk Stone", "Dawn Stone", "Oval Stone", "Odd Keystone", "Griseous Orb", "unknown", "unknown", "unknown", "Douse Drive",
		 "Shock Drive", "Burn Drive", "Chill Drive",
		 
		 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
		 "unknown", "unknown", "unknown", "unknown",
		 
		 "Sweet Heart", "Adamant Orb", "Lustrous Orb", "Greet Mail",
		 "Favored Mail", "RSVP Mail", "Thanks Mail", "Inquiry Mail", "Like Mail", "Reply Mail", "BridgeMail S", "BridgeMail D", "BridgeMail T",
		 "BridgeMail V", "BridgeMail M", "Cheri Berry", "Chesto Berry", "Pecha Berry", "Rawst Berry", "Aspear Berry", "Leppa Berry",
		 "Oran Berry", "Persim Berry", "Lum Berry", "Sitrus Berry", "Figy Berry", "Wiki Berry", "Mago Berry", "Aguav Berry", "Iapapa Berry",
		 "Razz Berry", "Bluk Berry", "Nanab Berry", "Wepear Berry", "Pinap Berry", "Pomeg Berry", "Kelpsy Berry", "Qualot Berry",
		 "Hondew Berry", "Grepa Berry", "Tamato Berry", "Cornn Berry", "Magost Berry", "Rabuta Berry", "Nomel Berry", "Spelon Berry",
		 "Pamtre Berry", "Watmel Berry", "Durin Berry", "Belue Berry", "Occa Berry", "Passho Berry", "Wacan Berry", "Rindo Berry",
		 "Yache Berry", "Chople Berry", "Kebia Berry", "Shuca Berry", "Coba Berry", "Payapa Berry", "Tanga Berry", "Charti Berry",
		 "Kasib Berry", "Haban Berry", "Colbur Berry", "Babiri Berry", "Chilan Berry", "Liechi Berry", "Ganlon Berry", "Salac Berry",
		 "Petaya Berry", "Apicot Berry", "Lansat Berry", "Starf Berry", "Enigma Berry", "Micle Berry", "Custap Berry", "Jaboca Berry",
		 "Rowap Berry", "BrightPowder", "White Herb", "Macho Brace", "Exp. Share", "Quick Claw", "Soothe Bell", "Mental Herb", "Choice Band",
		 "King's Rock", "SilverPowder", "Amulet Coin", "Cleanse Tag", "Soul Dew", "DeepSeaTooth", "DeepSeaScale", "Smoke Ball", "Everstone",
		 "Focus Band", "Lucky Egg", "Scope Lens", "Metal Coat", "Leftovers", "Dragon Scale", "Light Ball", "Soft Sand", "Hard Stone", "Miracle Seed",
		 "BlackGlasses", "Black Belt", "Magnet", "Mystic Water", "Sharp Beak", "Poison Barb", "NeverMeltIce", "Spell Tag", "TwistedSpoon",
		 "Charcoal", "Dragon Fang", "Silk Scarf", "Up-Grade", "Shell Bell", "Sea Incense", "Lax Incense", "Lucky Punch", "Metal Powder",
		 "Thick Club", "Stick", "Red Scarf", "Blue Scarf", "Pink Scarf", "Green Scarf", "Yellow Scarf", "Wide Lens", "Muscle Band", "Wise Glasses",
		 "Expert Belt", "Light Clay", "Life Orb", "Power Herb", "Toxic Orb", "Flame Orb", "Quick Powder", "Focus Sash", "Zoom Lens", "Metronome",
		 "Iron Ball", "Lagging Tail", "Destiny Knot", "Black Sludge", "Icy Rock", "Smooth Rock", "Heat Rock", "Damp Rock", "Grip Claw",
		 "Choice Scarf", "Sticky Barb", "Power Bracer", "Power Belt", "Power Lens", "Power Band", "Power Anklet", "Power Weight", "Shed Shell",
		 "Big Root", "Choice Specs", "Flame Plate", "Splash Plate", "Zap Plate", "Meadow Plate", "Icicle Plate", "Fist Plate", "Toxic Plate",
		 "Earth Plate", "Sky Plate", "Mind Plate", "Insect Plate", "Stone Plate", "Spooky Plate", "Draco Plate", "Dread Plate", "Iron Plate",
		 "Odd Incense", "Rock Incense", "Full Incense", "Wave Incense", "Rose Incense", "Luck Incense", "Pure Incense", "Protector", "Electirizer",
		 "Magmarizer", "Dubious Disc", "Reaper Cloth", "Razor Claw", "Razor Fang", "TM01", "TM02", "TM03", "TM04", "TM05", "TM06", "TM07",
		 "TM08", "TM09", "TM10", "TM11", "TM12", "TM13", "TM14", "TM15", "TM16", "TM17", "TM18", "TM19", "TM20", "TM21", "TM22", "TM23", "TM24",
		 "TM25", "TM26", "TM27", "TM28", "TM29", "TM30", "TM31", "TM32", "TM33", "TM34", "TM35", "TM36", "TM37", "TM38", "TM39", "TM40", "TM41",
		 "TM42", "TM43", "TM44", "TM45", "TM46", "TM47", "TM48", "TM49", "TM50", "TM51", "TM52", "TM53", "TM54", "TM55", "TM56", "TM57", "TM58",
		 "TM59", "TM60", "TM61", "TM62", "TM63", "TM64", "TM65", "TM66", "TM67", "TM68", "TM69", "TM70", "TM71", "TM72", "TM73", "TM74", "TM75",
		 "TM76", "TM77", "TM78", "TM79", "TM80", "TM81", "TM82", "TM83", "TM84", "TM85", "TM86", "TM87", "TM88", "TM89", "TM90", "TM91", "TM92",
		 "HM01", "HM02", "HM03", "HM04", "HM05", "HM06", "unknown", "unknown", "Explorer Kit", "Loot Sack", "Rule Book", "Poké Radar", "Point Card",
		 "Journal", "Seal Case", "Fashion Case", "Seal Bag", "Pal Pad", "Works Key", "Old Charm", "Galactic Key", "Red Chain", "Town Map",
		 "Vs. Seeker", "Coin Case", "Old Rod", "Good Rod", "Super Rod", "Sprayduck", "Poffin Case", "Bicycle", "Suite Key", "Oak's Letter",
		 "Lunar Wing", "Member Card", "Azure Flute", "S.S. Ticket", "Contest Pass", "Magma Stone", "Parcel", "Coupon 1", "Coupon 2", "Coupon 3",
		 "Storage Key", "SecretPotion", "Vs. Recorder", "Gracidea", "Secret Key", "Apricorn Box", "Unown Report", "Berry Pots", "Dowsing MCHN",
		 "Blue Card", "SlowpokeTail", "Clear Bell", "Card Key", "Basement Key", "SquirtBottle", "Red Scale", "Lost Item", "Pass", "Machine Part",
		 "Silver Wing", "Rainbow Wing", "Mystery Egg", "Red Apricorn", "Ylw Apricorn", "Blu Apricorn", "Grn Apricorn", "Pnk Apricorn", "Wht Apricorn",
		 "Blk Apricorn", "Fast Ball", "Level Ball", "Lure Ball", "Heavy Ball", "Love Ball", "Friend Ball", "Moon Ball", "Sport Ball", "Park Ball", "Photo Album",
		 "GB Sounds", "Tidal Bell", "RageCandyBar", "Data Card 01", "Data Card 02", "Data Card 03", "Data Card 04", "Data Card 05", "Data Card 06", "Data Card 07",
		 "Data Card 08", "Data Card 09", "Data Card 10", "Data Card 11", "Data Card 12", "Data Card 13", "Data Card 14", "Data Card 15", "Data Card 16", "Data Card 17",
		 "Data Card 18", "Data Card 19", "Data Card 20", "Data Card 21", "Data Card 22", "Data Card 23", "Data Card 24", "Data Card 25", "Data Card 26", "Data Card 27",
		 "Jade Orb", "Lock Capsule", "Red Orb", "Blue Orb", "Enigma Stone", "Prism Scale", "Eviolite", "Float Stone", "Rocky Helmet", "Air Balloon", "Red Card",
		 "Ring Target", "Binding Band", "Absorb Bulb", "Cell Battery", "Eject Button", "Fire Gem", "Water Gem", "Electric Gem", "Grass Gem", "Ice Gem", "Fighting Gem",
		 "Poison Gem", "Ground Gem", "Flying Gem", "Psychic Gem", "Bug Gem", "Rock Gem", "Ghost Gem", "Dragon Gem", "Dark Gem", "Steel Gem", "Normal Gem", "Health Wing",
		 "Muscle Wing", "Resist Wing", "Genius Wing", "Clever Wing", "Swift Wing", "Pretty Wing", "Cover Fossil", "Plume Fossil", "Liberty Pass", "Pass Orb", "Dream Ball",
		 "Poké Toy", "Prop Case", "Dragon Skull", "BalmMushroom", "Big Nugget", "Pearl String", "Comet Shard", "Relic Copper", "Relic Silver", "Relic Gold", "Relic Vase",
		 "Relic Band", "Relic Statue", "Relic Crown", "Casteliacone", "Dire Hit 2", "X Speed 2", "X Special 2", "X Sp. Def 2", "X Defend 2", "X Attack 2", "X Accuracy 2",
		 "X Speed 3", "X Special 3", "X Sp. Def 3", "X Defend 3", "X Attack 3", "X Accuracy 3", "X Speed 6", "X Special 6", "X Sp. Def 6", "X Defend 6", "X Attack 6", "X Accuracy 6",
		 "Ability Urge", "Item Drop", "Item Urge", "Reset Urge", "Dire Hit 3", "Light Stone", "Dark Stone", "TM93", "TM94", "TM95", "Xtransceiver", "God Stone", "Gram 1",
		 "Gram 2", "Gram 3", "Xtransceiver", "Medal Box", "DNA Splicers", "DNA Splicers", "Permit", "Oval Charm", "Shiny Charm", "Plasma Card", "Grubby Hanky", "Colress MCHN",
		 "Dropped Item", "Dropped Item", "Reveal Glass"]

monMove = [ "--" , "Pound", "Karate Chop", "Double Slap", "Comet Punch", "Mega Punch", "Pay Day", "Fire Punch", "Ice Punch", "Thunder Punch", 
			"Scratch", "Vice Grip", "Guillotine", "Razor Wind", "Swords Dance", "Cut", "Gust", "Wing Attack", "Whirlwind", "Fly", 
			"Bind", "Slam", "Vine Whip", "Stomp", "Double Kick", "Mega Kick", "Jump Kick", "Rolling Kick", "Sand Attack", "Headbutt", 
			"Horn Attack", "Fury Attack", "Horn Drill", "Tackle", "Body Slam", "Wrap", "Take Down", "Thrash", "Double-Edge",
			"Tail Whip", "Poison Sting", "Twineedle", "Pin Missile", "Leer", "Bite", "Growl", "Roar", "Sing", "Supersonic", "Sonic Boom", 
			"Disable", "Acid", "Ember", "Flamethrower", "Mist", "Water Gun", "Hydro Pump", "Surf", "Ice Beam", "Blizzard", "Psybeam", 
			"Bubble Beam", "Aurora Beam", "Hyper Beam", "Peck", "Drill Peck", "Submission", "Low Kick", "Counter", "Seismic Toss", 
			"Strength", "Absorb", "Mega Drain", "Leech Seed", "Growth", "Razor Leaf", "Solar Beam", "Poison Powder", "Stun Spore", 
			"Sleep Powder", "Petal Dance", "String Shot", "Dragon Rage", "Fire Spin", "Thunder Shock", "Thunderbolt", "Thunder Wave", 
			"Thunder", "Rock Throw", "Earthquake", "Fissure", "Dig", "Toxic", "Confusion", "Psychic", "Hypnosis", "Meditate", 
			"Agility", "Quick Attack", "Rage", "Teleport", "Night Shade", "Mimic", "Screech", "Double Team", "Recover", "Harden", 
			"Minimize", "Smokescreen", "Confuse Ray", "Withdraw", "Defense Curl", "Barrier", "Light Screen", "Haze", "Reflect",
			"Focus Energy", "Bide", "Metronome", "Mirror Move", "Self-Destruct", "Egg Bomb", "Lick", "Smog", "Sludge", "Bone Club",
			"Fire Blast", "Waterfall", "Clamp", "Swift", "Skull Bash", "Spike Cannon", "Constrict", "Amnesia", "Kinesis", "Soft-Boiled", 
			"High Jump Kick", "Glare", "Dream Eater", "Poison Gas", "Barrage", "Leech Life", "Lovely Kiss", "Sky Attack", "Transform", 
			"Bubble", "Dizzy Punch", "Spore", "Flash", "Psywave", "Splash", "Acid Armor", "Crabhammer", "Explosion", "Fury Swipes", 
			"Bonemerang", "Rest", "Rock Slide", "Hyper Fang", "Sharpen", "Conversion", "Tri Attack", "Super Fang", "Slash", 
			"Substitute", "Struggle", "Sketch", "Triple Kick", "Thief", "Spider Web", "Mind Reader", "Nightmare", "Flame Wheel", 
			"Snore", "Curse", "Flail", "Conversion 2", "Aeroblast", "Cotton Spore", "Reversal", "Spite", "Powder Snow", "Protect", 
			"Mach Punch", "Scary Face", "Feint Attack", "Sweet Kiss", "Belly Drum", "Sludge Bomb", "Mud-Slap", "Octazooka", "Spikes", 
			"Zap Cannon", "Foresight", "Destiny Bond", "Perish Song", "Icy Wind", "Detect", "Bone Rush", "Lock-On", "Outrage", 
			"Sandstorm", "Giga Drain", "Endure", "Charm", "Rollout", "False Swipe", "Swagger", "Milk Drink", "Spark", "Fury Cutter", 
			"Steel Wing", "Mean Look", "Attract", "Sleep Talk", "Heal Bell", "Return", "Present", "Frustration", "Safeguard",
			"Pain Split", "Sacred Fire", "Magnitude", "Dynamic Punch", "Megahorn", "Dragon Breath", "Baton Pass", "Encore", "Pursuit",
			"Rapid Spin", "Sweet Scent", "Iron Tail", "Metal Claw", "Vital Throw", "Morning Sun", "Synthesis", "Moonlight", "Hidden Power", 
			"Cross Chop", "Twister", "Rain Dance", "Sunny Day", "Crunch", "Mirror Coat", "Psych Up", "Extreme Speed", "Ancient Power", 
			"Shadow Ball", "Future Sight", "Rock Smash", "Whirlpool", "Beat Up", "Fake Out", "Uproar", "Stockpile", "Spit Up", 
			"Swallow", "Heat Wave", "Hail", "Torment", "Flatter", "Will-O-Wisp", "Memento", "Facade", "Focus Punch", "Smelling Salts", 
			"Follow Me", "Nature Power", "Charge", "Taunt", "Helping Hand", "Trick", "Role Play", "Wish", "Assist", "Ingrain", 
			"Superpower", "Magic Coat", "Recycle", "Revenge", "Brick Break", "Yawn", "Knock Off", "Endeavor", "Eruption", "Skill Swap", 
			"Imprison", "Refresh", "Grudge", "Snatch", "Secret Power", "Dive", "Arm Thrust", "Camouflage", "Tail Glow", "Luster Purge", 
			"Mist Ball", "Feather Dance", "Teeter Dance", "Blaze Kick", "Mud Sport", "Ice Ball", "Needle Arm", "Slack Off",
			"Hyper Voice", "Poison Fang", "Crush Claw", "Blast Burn", "Hydro Cannon", "Meteor Mash", "Astonish", "Weather Ball", 
			"Aromatherapy", "Fake Tears", "Air Cutter", "Overheat", "Odor Sleuth", "Rock Tomb", "Silver Wind", "Metal Sound",
			"Grass Whistle", "Tickle", "Cosmic Power", "Water Spout", "Signal Beam", "Shadow Punch", "Extrasensory", "Sky Uppercut",
			"Sand Tomb", "Sheer Cold", "Muddy Water", "Bullet Seed", "Aerial Ace", "Icicle Spear", "Iron Defense", "Block", "Howl",
			"Dragon Claw", "Frenzy Plant", "Bulk Up", "Bounce", "Mud Shot", "Poison Tail", "Covet", "Volt Tackle", "Magical Leaf",
			"Water Sport", "Calm Mind", "Leaf Blade", "Dragon Dance", "Rock Blast", "Shock Wave", "Water Pulse", "Doom Desire",
			"Psycho Boost", "Roost", "Gravity", "Miracle Eye", "Wake-Up Slap", "Hammer Arm", "Gyro Ball", "Healing Wish", "Brine",
			"Natural Gift", "Feint", "Pluck", "Tailwind", "Acupressure", "Metal Burst", "U-turn", "Close Combat", "Payback", "Assurance", 
			"Embargo", "Fling", "Psycho Shift", "Trump Card", "Heal Block", "Wring Out", "Power Trick", "Gastro Acid", "Lucky Chant", 
			"Me First", "Copycat", "Power Swap", "Guard Swap", "Punishment", "Last Resort", "Worry Seed", "Sucker Punch", "Toxic Spikes",
			"Heart Swap", "Aqua Ring", "Magnet Rise", "Flare Blitz", "Force Palm", "Aura Sphere", "Rock Polish", "Poison Jab", 
			"Dark Pulse", "Night Slash", "Aqua Tail", "Seed Bomb", "Air Slash", "X-Scissor", "Bug Buzz", "Dragon Pulse", "Dragon Rush", 
			"Power Gem", "Drain Punch", "Vacuum Wave", "Focus Blast", "Energy Ball", "Brave Bird", "Earth Power", "Switcheroo",
			"Giga Impact", "Nasty Plot", "Bullet Punch", "Avalanche", "Ice Shard", "Shadow Claw", "Thunder Fang", "Ice Fang", "Fire Fang", 
			"Shadow Sneak", "Mud Bomb", "Psycho Cut", "Zen Headbutt", "Mirror Shot", "Flash Cannon", "Rock Climb", "Defog",
			"Trick Room", "Draco Meteor", "Discharge", "Lava Plume", "Leaf Storm", "Power Whip", "Rock Wrecker", "Cross Poison", "Gunk Shot", 
			"Iron Head", "Magnet Bomb", "Stone Edge", "Captivate", "Stealth Rock", "Grass Knot", "Chatter", "Judgment", "Bug Bite", 
			"Charge Beam", "Wood Hammer", "Aqua Jet", "Attack Order", "Defend Order", "Heal Order", "Head Smash", "Double Hit",
			"Roar of Time", "Spacial Rend", "Lunar Dance", "Crush Grip", "Magma Storm", "Dark Void", "Seed Flare", "Ominous Wind", "Shadow Force",
			
			"Hone Claws", "Wide Guard", "Guard Split", "Power Split", "Wonder Room", "Psyshock", "Venoshock", "Autotomize", "Rage Powder",
			"Telekinesis", "Magic Room", "Smack Down", "Storm Throw", "Flame Burst", "Sludge Wave", "Quiver Dance", "Heavy Slam",
			"Synchronoise", "Electro Ball", "Soak", "Flame Charge", "Coil", "Low Sweep", "Acid Spray", "Foul Play", "Simple Beam",
			"Entrainment", "After You", "Round", "Echoed Voice", "Chip Away", "Clear Smog", "Stored Power", "Quick Guard", "Ally Switch",
			"Scald", "Shell Smash", "Heal Pulse", "Hex", "Sky Drop", "Shift Gear", "Circle Throw", "Incinerate", "Quash", "Acrobatics",
			"Reflect Type", "Retaliate", "Final Gambit", "Bestow", "Inferno", "Water Pledge", "Fire Pledge", "Grass Pledge",
			"Volt Switch", "Struggle Bug", "Bulldoze", "Frost Breath", "Dragon Tail", "Work Up", "Electroweb", "Wild Charge",
			"Drill Run", "Dual Chop", "Heart Stamp", "Horn Leech", "Sacred Sword", "Razor Shell", "Heat Crash", "Leaf Tornado",
			"Steamroller", "Cotton Guard", "Night Daze", "Psystrike", "Tail Slap", "Hurricane", "Head Charge", "Gear Grind",
			"Searing Shot", "Techno Blast", "Relic Song", "Secret Sword", "Glaciate", "Bolt Strike", "Blue Flare", "Fiery Dance",
			"Freeze Shock", "Ice Burn", "Snarl", "Icicle Crash", "V-create", "Fusion Flare", "Fusion Bolt"]

@staticmethod
def get_raised_stat(nature_id: int):
    stats = ["Attack", "Defense", "Speed", "Sp. Attack", "Sp. Defense"]

    return stats[math.floor(nature_id / 5)]

@staticmethod
def get_lowered_stat(nature_id: int):
    stats = ["Attack", "Defense", "Speed", "Sp. Attack", "Sp. Defense"]

    return stats[nature_id % 5]

def enrich_mon_data(pokemon: dict):
	pokemon["otLanguage"] = monLanguage[pokemon["otLanguage"]]
	pokemon["shiny"] = pokemon["shinyValue"] < 8
	pokemon["ability"] = monAbility[pokemon["ability"]]
	
	nature = pokemon["nature"]
	pokemon["raisedStat"] = get_raised_stat(nature)
	pokemon["loweredStat"] = get_lowered_stat(nature)
	pokemon["nature"] = monNature[nature]
	
	pokemon["name"] = monName[pokemon["species"]]
	pokemon["heldItem"] = monItem[pokemon["heldItem"]]
	pokemon["gender"] = monGender[pokemon["gender"]] 
	pokemon["moves"] = [monMove[move] for move in pokemon["moves"]]
	    
	return pokemon
