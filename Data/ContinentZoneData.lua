local AddonName, ns = ...

-- Structure:
-- "Continent"           -> outdoor/world zones (matched to GetRealZoneText()).
-- "Continent Dungeons"  -> instance names that are dungeons in that continent.
-- "Continent Raids"     -> instance names that are raids in that continent.
--
-- This is not an exhaustive list; add/remove as you like. Names must match the
-- instance tooltip names you see in-game (the same strings that appear in LFG).
ns.ContinentZones = {
  -- =======================
  -- KALIMDOR
  -- =======================
  ["Kalimdor"] = {
    "Durotar","Mulgore","Teldrassil","Ashenvale","Azshara","Desolace","Dustwallow Marsh",
    "Felwood","Feralas","Moonglade","Silithus","Stonetalon Mountains","Tanaris",
    "Thousand Needles","Un'Goro Crater","Winterspring","Northern Barrens","Southern Barrens",
    "Mount Hyjal","Uldum","Darkshore",
  },
  ["Kalimdor Dungeons"] = {
    "Ragefire Chasm","Wailing Caverns","Blackfathom Deeps","Razorfen Kraul",
    "Razorfen Downs","Maraudon","Dire Maul","Zul'Farrak","The Vortex Pinnacle","Halls of Origination",
  },
  ["Kalimdor Raids"] = {
    "Onyxia's Lair","Ruins of Ahn'Qiraj","Temple of Ahn'Qiraj","Firelands",
  },

  -- =======================
  -- EASTERN KINGDOMS
  -- =======================
  ["Eastern Kingdoms"] = {
    "Elwynn Forest","Duskwood","Westfall","Redridge Mountains","Loch Modan","Dun Morogh",
    "Searing Gorge","Burning Steppes","Badlands","Swamp of Sorrows","Blasted Lands",
    "Hillsbrad Foothills","Arathi Highlands","The Hinterlands","Wetlands",
    "Silverpine Forest","Tirisfal Glades","Western Plaguelands","Eastern Plaguelands",
    "Eversong Woods","Ghostlands","Deadwind Pass","Cape of Stranglethorn","Northern Stranglethorn",
    "Tol Barad","Tol Barad Peninsula",
  },
  ["Eastern Kingdoms Dungeons"] = {
    "The Deadmines","The Stockade","Shadowfang Keep","Scarlet Monastery","Scarlet Halls",
    "Scholomance","Stratholme","Uldaman","Blackrock Depths","Lower Blackrock Spire","Upper Blackrock Spire",
    "The Bastion of Twilight","Grim Batol","The Stonecore","Magisters' Terrace",
  },
  ["Eastern Kingdoms Raids"] = {
    "Molten Core","Blackwing Lair","Zul'Gurub","Karazhan",
    "Blackwing Descent","Bastion of Twilight","Throne of the Four Winds",
  },

  -- =======================
  -- OUTLAND
  -- =======================
  ["Outland"] = {
    "Hellfire Peninsula","Zangarmarsh","Terokkar Forest","Nagrand",
    "Blade's Edge Mountains","Netherstorm","Shadowmoon Valley",
  },
  ["Outland Dungeons"] = {
    "Hellfire Ramparts","The Blood Furnace","The Shattered Halls",
    "The Slave Pens","The Underbog","The Steamvault",
    "Mana-Tombs","Auchenai Crypts","Sethekk Halls","Shadow Labyrinth",
    "Old Hillsbrad Foothills","The Black Morass",
    "The Mechanar","The Botanica","The Arcatraz",
  },
  ["Outland Raids"] = {
    "Gruul's Lair","Magtheridon's Lair","Serpentshrine Cavern",
    "Tempest Keep","Black Temple","Hyjal Summit","Sunwell Plateau",
  },

  -- =======================
  -- NORTHREND
  -- =======================
  ["Northrend"] = {
    "Borean Tundra","Howling Fjord","Dragonblight","Grizzly Hills","Zul'Drak",
    "Sholazar Basin","The Storm Peaks","Icecrown","Crystalsong Forest","Wintergrasp",
  },
  ["Northrend Dungeons"] = {
    "Utgarde Keep","Utgarde Pinnacle","The Nexus","The Oculus","The Violet Hold",
    "Azjol-Nerub","Ahn'kahet: The Old Kingdom","Drak'Tharon Keep",
    "Gundrak","Halls of Stone","Halls of Lightning","Trial of the Champion",
    "Pit of Saron","The Forge of Souls","Halls of Reflection",
  },
  ["Northrend Raids"] = {
    "Naxxramas","The Eye of Eternity","The Obsidian Sanctum",
    "Ulduar","Trial of the Crusader","Onyxia's Lair (WotLK revamp)",
    "Icecrown Citadel","Vault of Archavon","Ruby Sanctum",
  },

  -- =======================
  -- PANDARIA (MoP)
  -- =======================
  ["Pandaria"] = {
    "The Jade Forest","Valley of the Four Winds","Krasarang Wilds","Kun-Lai Summit",
    "Townlong Steppes","Dread Wastes","Vale of Eternal Blossoms","Isle of Thunder","Timeless Isle",
  },
  ["Pandaria Dungeons"] = {
    "Temple of the Jade Serpent","Stormstout Brewery","Shado-Pan Monastery",
    "Mogu'shan Palace","Gate of the Setting Sun","Siege of Niuzao Temple",
    -- Scenarios exist but are not counted here
  },
  ["Pandaria Raids"] = {
    "Mogu'shan Vaults","Heart of Fear","Terrace of Endless Spring",
    "Throne of Thunder","Siege of Orgrimmar",
  },
}
