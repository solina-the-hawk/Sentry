-- =========================================================================
-- SENTRY: Tactical Combat UI (v1.2.0)
-- A robust, zero-dependency situational awareness tracker for Achaea.
-- Now featuring Self Status, Target Status, and Ship Info tracking!
-- =========================================================================
Sentry = Sentry or {}

Sentry.players = Sentry.players or {}
Sentry.denizens = Sentry.denizens or {}
Sentry.effects = Sentry.effects or {} 
Sentry.config = Sentry.config or {}

Sentry.silentProbing = false
Sentry.probeQueue = {}
Sentry.silentRunelist = 0
Sentry.isGlanced = false

-- Ship tracking variables
Sentry.isOnShip = false
Sentry.parsingShipInfo = false
Sentry.silentShipInfo = false
Sentry.shipData = Sentry.shipData or {}

-- =========================================================================
-- 1. CONFIGURATION
-- =========================================================================
Sentry.config.targetCmd = "settarget " 
Sentry.config.getCmd = "get "
Sentry.config.probeCmd = "probe "

-- UI Visibility States
Sentry.config.mainVisible = true
Sentry.config.selfVisible = true
Sentry.config.targetVisible = false
Sentry.config.shipVisible = false
-- UI Design Toggles
Sentry.config.showUIBorders = false  -- Set to false to hide the alignment borders

-- Anti-Spam / Collapsing Toggles
Sentry.config.collapseThreshold = 20  -- Auto-collapse if the room has >25 total things
Sentry.config.alwaysCollapse = false  -- If true, it will ALWAYS stack multiples

-- Ship Info Visibility Toggles (Set to false to hide from the UI)
Sentry.config.shipDisplay = {
    crew = false,
    harbour = true,
    arena = false,  -- Disabled by default
    buoy = true,
    float = true,  -- Disabled by default
    bell = false,   -- Disabled by default
    manoeuvres = true
}

Sentry.config.useNDBColors = true
Sentry.config.colorMounts = false
Sentry.config.myLoyals = Sentry.config.myLoyals or {}

Sentry.config.furnitureKeywords = {
    "chair", "bench", "throne", "stool", "rocker", "pew", "swing", "bed", 
    "hammock", "bunk", "cot", "couch", "ottoman", "seat", "settle", "bunkbed", 
    "pillow", "footstool", "table", "desk", "sheets", "runner", "rug", "sideboard",
    "bureau", "buffet", "lectern", "counter", "tapestry", "tub", "sink", "vanity",
    "arbour", "basin", "rail", "screen", "altar", "cushion", "grate", "sconce",
    "candelabra"
}

Sentry.config.containersKeywords = {
    "basket", "bookshelf", "bookcase", "dresser", "chest", "shelf", "pedestal",
    "cupboard", "wardrobe", "armoire", "pantry", "cabinet", "hutch", "trunk",
    "stand", "larder", "rack", "hamper",
    "knapsack", "box", "sack", "satchel", "purse", "handbag", "wallet", "pack"
}

Sentry.config.utilityFurnitureKeywords = {
    "range", "stove", "fireplace", "firepit", "trolley", "cask", "keg", "barrel"
}

Sentry.config.linensKeywords = {
    "blanket", "quilt", "handkerchief", "towel", "tablecloth", "napkin"
}

Sentry.config.artobjectKeywords = {
    "painting", "canvas", "chunk of wood", "piece of slate", "sheet of parchment",
    "length of silk", "mural", "sculpture", "statue", "statuette", "portrait",
    "vase"
}
-- paintings can be made on wood, slate, parchment, canvas, or silk. Need to confirm Item IDs of these pieces.
-- statuettes can be made on clay, stone, obsidian, wood, or ice, same re: item IDs

Sentry.config.clothingKeywords = {
    "hat", "beret", "bandana", "veil", "bonnet", "ribbon", "mask", "turban", 
    "headband", "headdress", "cap", "ruff", "kerchief", "wimple", "blindfold", 
    "cravat", "hood", "snood", "wig", "earmuffs", "tie", "vest", "jerkin", 
    "tunic", "blouse", "bodice", "shirt", "waistcoat", "sweater", "smock",
    "top", "jumper", "breeches", "trousers", "loincloth", "skirt", "kilt",
    "sarong", "hose", "pantaloons", "shorts", "boxer", "bra", "garterbelt",
    "socks", "stockings", "panties", "corset", "chemise", "petticoat", "nightgown",
    "slip", "undershirt", "camisole", "shift", "briefs", "swimsuit", "thong",
    "coat", "cloak", "jacket", "shawl", "doublet", "cape", "surcoat", "tabard",
    "poncho", "mantle", "cardigan", "gambeson", "dress", "stola", "gown", "cassock",
    "robes", "toga", "vestment", "sari", "robe", "shoes", "boots", "heels",
    "slippers", "sandals", "clogs", "mocassins", "pinafore", "gloves", "belt",
    "beard", "sash", "scarf", "tights", "apron", "stole", "mittens", "glove", 
    "suspenders", "overalls"
}

Sentry.config.jewelleryKeywords = {
    "ring", "band", "toering", "bracelet", "anklet", "armband", "cuff",
    "bangle", "crown", "diadem", "tiara", "circlet", "coronet", "medallion",
    "pendant", "necklace", "choker", "collar", "amulet", "chain", "locket", "torc",
    "brooch", "pin", "cameo", "clasp", "hairclip", "hairpin", "haircomb", "glasses",
    "monocle", "spectacles", "earring", "hoop", "stud", "nipplering",
    "navelring", "nosering", "tonguering", "lipring"
}

Sentry.config.foodKeywords = {
    "plate", "muffin", "bowl", "platter", "drumstick", "cake", "pastry",
    "pie", "pancake", "loaf", "skewer", "steak", "haunch", "salad", "sandwich",
    "tart", "wrap", "cupcake", "roll", "scone", "bagel", "cookie", "doughnut",
    "burger", "bag", "bun", "tin", "pot", "pan", "jar", "cauldron", "slice",
    "packet", "piece"
}

-- need to confirm keywords for things like cup, skull, skin, kawhepot
Sentry.config.drinkKeywords = {
    "mug", "cup", "glass", "flute", "bottle", "carafe", "snifter",
    "jar", "beaker", "tumbler", "stein", "chalice", "goblet",
    "drinking skin", "drinking skull", "flask", "teapot", "kawhepot"
}

Sentry.config.miscKeywords = {
    "plush", "game", "hollowed skull"
}

-- Need to check full list
Sentry.config.armourKeywords = {
    "halfplate", "fullplate", "scalemail", "leatherarmour", "clotharmour"
}

-- Need to check full list
Sentry.config.weaponKeywords = {
    "scimitar", "longsword", "dagger", "knife", "warhammer", "bastard sword"
}

-- Need to check full list
Sentry.config.shipEquipmentKeywords = {
    "thrower", "figurehead", "ballista", "flag"
}

-- Double check this list as we go
Sentry.config.readableKeywords = {
    "book", "scroll", "letter", "map", "note", "tome", "manuscript", "papyrus",
    "codex", "ledger", "diary", "journal", "newspaper", "magazine", "brochure",
    "pamphlet", "flyer", "poster", "sign", "notice", "billboard"
}

-- Need to check full list
Sentry.config.ingredientsKeywords = {
    "redink", "blueink", "yellowink", "greenink", "purpleink", "goldink", "blackink",
    "fat", "fish", "meat", "poultry", "flour", "grain", "sugar", "sugarcane", "nuts",
    "salt", "saltwater", "olives", "seeds", "spices", "cacao", "chocolate", "clay",
    "flakes", "horn", "lumicmoss", "scales", "tooth", "wyrmtongue", "redchitin",
    "yellowchitin", "inkbladder", "dust", "fibre", "rope", "cloth", "iron",
    "steel", "silver", "stone", "rawstone", "wood", "pitch", "shipcloth",
    "shipwood", "shiplines", "shipiron"
}

-- healing herbs and minerals
Sentry.config.herbandmineralKeywords = {
    "ash", "bayberry", "bellwort", "bloodroot", "cohosh", "echinacea", "elm",
    "ginger", "ginseng", "goldenseal", "hawthorn", "kelp", "kola", "kuzu", "lobelia",
    "moss", "myrrh", "pear", "sileris", "skullcap", "slipper", "valerian", "weed",
    "antimony", "argentum", "arsenic", "aurum", "azurite", "bisemutum", "calamine",
    "calcite", "cinnabar", "cuprum", "dolomite", "ferrum", "gypsum", "magnesium",
    "plumbum", "potash", "quartz", "quicksilver", "realgar", "stannum"
}

-- vials?
Sentry.config.remedyAndtoxinKeywords = {
    "vial"
}

-- =========================================================================
-- DYNAMIC ITEM CATEGORIES MASTER MAP
-- Sorted by Hierarchy of Specificity (Base Nouns first, Materials/Adjectives last)
-- Right now our sorter goes in order, and can get confused if an item such as a chest
-- contains a descriptive word like 'band'. In the future, we'll look at a noun
-- extraction method that will solve this.
-- =========================================================================
-- 1. Create a custom color map linking descriptive names to Mudlet-safe RGB values
Sentry.config.customColors = {
    ["sentry_deepskyblue"]    = {0, 191, 255},
    ["sentry_chocolate"]      = {210, 105, 30},
    ["sentry_saddlebrown"]    = {139, 69, 19},
    ["sentry_firebrick"]      = {178, 34, 34},
    ["sentry_lightslategrey"] = {119, 136, 153},
    ["sentry_plum"]           = {221, 160, 221},
    ["sentry_hotpink"]        = {255, 105, 180},
    ["sentry_lightskyblue"]   = {135, 206, 250},
    ["sentry_mediumpurple"]   = {147, 112, 219},
    ["sentry_lightcyan"]      = {224, 255, 255},
    ["sentry_limegreen"]      = {50, 205, 50},
    ["sentry_darkkhaki"]      = {189, 183, 107},
}

-- 2. Inject custom colors into Mudlet's global color_table so cecho can use them natively
for name, rgb in pairs(Sentry.config.customColors) do
    color_table[name] = rgb
end

-- 3. Apply the registered colors to our Master Map
Sentry.config.itemCategories = {
    -- HIGH SPECIFICITY: Large structures, containers, and distinct equipment
    { id = "shipequipment", title = "SHIP EQUIPMENT", color = "sentry_deepskyblue", keywords = Sentry.config.shipEquipmentKeywords },
    { id = "containers", title = "CONTAINERS", color = "sentry_chocolate", keywords = Sentry.config.containersKeywords }, -- FIXED KEYWORD POINTER HERE
    { id = "utilityfurn", title = "UTILITY FURNITURE", color = "sentry_firebrick", keywords = Sentry.config.utilityFurnitureKeywords },
    { id = "furniture", title = "FURNITURE", color = "sentry_lightslategrey", keywords = Sentry.config.furnitureKeywords },
    
    -- MEDIUM SPECIFICITY: Wearables, weapons, and distinct held items
    { id = "weapons", title = "WEAPONS", color = "red", keywords = Sentry.config.weaponKeywords },
    { id = "armour", title = "ARMOUR", color = "orange", keywords = Sentry.config.armourKeywords },
    { id = "clothing", title = "CLOTHING", color = "sentry_plum", keywords = Sentry.config.clothingKeywords },
    { id = "jewellery", title = "JEWELLERY", color = "gold", keywords = Sentry.config.jewelleryKeywords },
    
    -- LOW SPECIFICITY: Consumables, art, and generic items
    { id = "art", title = "ART OBJECTS", color = "sentry_hotpink", keywords = Sentry.config.artobjectKeywords },
    { id = "readables", title = "READABLES", color = "sentry_lightskyblue", keywords = Sentry.config.readableKeywords },
    { id = "remedies", title = "REMEDIES & TOXINS", color = "sentry_mediumpurple", keywords = Sentry.config.remedyAndtoxinKeywords },
    { id = "drink", title = "DRINKS", color = "cyan", keywords = Sentry.config.drinkKeywords },
    { id = "food", title = "FOOD", color = "yellow", keywords = Sentry.config.foodKeywords },
    { id = "linens", title = "LINENS", color = "sentry_lightcyan", keywords = Sentry.config.linensKeywords },
    
    -- DANGER ZONE: Extremely broad adjectives, materials, and exact-word conflicts
    { id = "herbs", title = "HERBS & MINERALS", color = "sentry_limegreen", keywords = Sentry.config.herbandmineralKeywords },
    { id = "ingredients", title = "CRAFTING INGREDIENTS", color = "sentry_darkkhaki", keywords = Sentry.config.ingredientsKeywords },
    { id = "misc", title = "MISCELLANEOUS", color = "grey", keywords = Sentry.config.miscKeywords },
}

-- Initialize a master table to hold all sorted items
Sentry.categorizedItems = Sentry.categorizedItems or {}
for _, cat in ipairs(Sentry.config.itemCategories) do
    Sentry.categorizedItems[cat.id] = Sentry.categorizedItems[cat.id] or {}
end
-- Ensure we have a fallback 'items' bucket for anything that doesn't match a keyword
Sentry.categorizedItems["uncategorized"] = Sentry.categorizedItems["uncategorized"] or {}

-- =========================================================================
-- DEFENCE SORTING WEIGHTS
-- Lower numbers appear first in the Self Status UI. Unlisted items default to 99.
-- =========================================================================
Sentry.config.defenceWeights = {
    -- 1. Tactical Afflictions
    ["deafness"] = 1, ["blindness"] = 1, ["insomnia"] = 1,
    
    -- 2. Potion Buffs
    ["levitating"] = 2, ["speed"] = 2,
    
    -- 3. Herb / Mineral Defences
    ["fangbarrier"] = 3, ["kola"] = 3,
    
    -- 4. Vision Skills
    ["thirdeye"] = 4, ["nightsight"] = 4, ["skywatch"] = 4, ["groundwatch"] = 4,
    
    -- 5. Class Skills
    ["weathering"] = 5, ["blademastery"] = 5, ["gripping"] = 5
}

-- =========================================================================
-- DEFENCE & TATTOO TRACKING
-- Define which defences and tattoos you expect to maintain.
-- Expected items that drop will be highlighted in RED with a [!] warning.
-- =========================================================================
Sentry.config.expectedDefences = {
    "blindness", "deafness", "insomnia", "thirdeye", "nightsight"
}

Sentry.config.expectedTattoos = {
    "boartattoo", "moontattoo", "starburst", "mosstattoo", "belltattoo", "megalithtattoo", "oxtattoo", "mindseye"
}

-- Keywords to auto-filter unexpected/temporary tattoos into the Tattoo section
Sentry.config.tattooKeywords = {
    "tree", "moss", "boar", "moon", "shield", "chameleon", "crystal", 
    "tentacle", "hammer", "cloak", "starburst", "spider", "eye", "web", "belltattoo", "oxtattoo", "megalithtattoo"
}

Sentry.runeData = {
    ["nightmare"] = {name = "Kena", effect = "Fear"},
    ["lightning bolt"] = {name = "Uruz", effect = "Healing"},
    ["closed eye"] = {name = "Fehu", effect = "Sleep"},
    ["square box"] = {name = "Pithakhan", effect = "Damage Mana"},
    ["stickman"] = {name = "Inguz", effect = "Paralysis"},
    ["open eye"] = {name = "Wunjo", effect = "Restore Sight"},
    ["nail"] = {name = "Sowulu", effect = "Damage Health"},
    ["flurry of lightning bolts"] = {name = "Isaz", effect = "Disrupt Balance"},
    ["rising sun"] = {name = "Dagaz", effect = "Heal Afflictions"},
    ["horse"] = {name = "Raido", effect = "Return"},
    ["volcano"] = {name = "Thurisaz", effect = "Damage Nearby"},
    ["ball of ice"] = {name = "Hugalaz", effect = "Hailstorm"},
    ["leech"] = {name = "Nauthiz", effect = "Draing Nourishment"},
    ["bell"] = {name = "Mannaz", effect = "Restore Hearing"},
    ["mountain range"] = {name = "Othala", effect = "Flame Burst"},
    ["viper"] = {name = "Sleizak", effect = "Voyria"},
    ["upwards-pointing arrow"] = {name = "Tiwaz", effect = "Strip Defenses"},
    ["butterfly"] = {name = "Nairat", effect = "Entangle"},
    ["yew"] = {name = "Eihwaz", effect = "Dampen Vibrations"},
    ["apple core"] = {name = "Loshre", effect = "Anorexia"}
}

Sentry.sigilData = {
    ["cube"] = {effect = "Destroy Vibrations", color = "magenta"},
    ["eye"] = {effect = "Block Souls", color = "magenta"},
    ["key"] = {effect = "Lock Doors", color = "magenta"},
    ["monolith"] = {effect = "Block Teleport", color = "red"},
}

-- =========================================================================
-- 2. GEYSER UI CREATION
-- =========================================================================
Sentry.container = Geyser.Container:new({
    name = "SentryContainer",
    x = "2px", 
    y = "-42%",       -- A negative value anchors the top edge to the bottom of the screen
    width = "400px", 
    height = "42%",
})

Sentry.console = Geyser.MiniConsole:new({
    name = "SentryConsole",
    x = 0, y = 0,
    width = "100%", height = "100%",
    color = "black",
}, Sentry.container)

Sentry.selfContainer = Geyser.Container:new({
    name = "SentrySelfContainer",
    x = "2px", y = "30%",
    width = "400px", height = "30%",
})

Sentry.selfConsole = Geyser.MiniConsole:new({
    name = "SentrySelfConsole",
    x = 0, y = 0,
    width = "100%", height = "100%",
    color = "black",
}, Sentry.selfContainer)

Sentry.targetContainer = Geyser.Container:new({
    name = "SentryTargetContainer",
    x = "2px", y = "2px",
    width = "350px", height = "30%",
})

Sentry.targetConsole = Geyser.MiniConsole:new({
    name = "SentryTargetConsole",
    x = 0, y = 0,
    width = "100%", height = "100%",
    color = "black",
}, Sentry.targetContainer)

-- Ship UI occupies the exact same space as Target UI
Sentry.shipContainer = Geyser.Container:new({
    name = "SentryShipContainer",
    x = "2px", y = "2px",
    width = "350px", height = "20%",
})

Sentry.shipConsole = Geyser.MiniConsole:new({
    name = "SentryShipConsole",
    x = 0, y = 0,
    width = "100%", height = "100%",
    color = "black",
}, Sentry.shipContainer)

-- =========================================================================
-- APPLY UI STYLING (ALIGNMENT HIGHLIGHTS)
-- =========================================================================
if Sentry.config.showUIBorders then
    -- Tint the background to dark grey (R, G, B) to reveal container bounds
    Sentry.console:setColor(25, 25, 25)
    Sentry.selfConsole:setColor(25, 25, 25)
    Sentry.targetConsole:setColor(25, 25, 25)
    Sentry.shipConsole:setColor(25, 25, 25)
else
    -- Revert back to pure black/transparent
    Sentry.console:setColor(0, 0, 0)
    Sentry.selfConsole:setColor(0, 0, 0)
    Sentry.targetConsole:setColor(0, 0, 0)
    Sentry.shipConsole:setColor(0, 0, 0)
end

-- =========================================================================
-- 3. HELPER FUNCTIONS
-- =========================================================================
function Sentry.padText(text, coloredText, targetLength)
    local currentLen = string.len(text)
    local spaces = targetLength - currentLen
    if spaces < 0 then spaces = 0 end
    return coloredText .. string.rep(" ", spaces)
end

function Sentry.formatTarget(name, id)
    local cleanName = name:lower():gsub("^a ", ""):gsub("^an ", ""):gsub("^the ", "")
    local firstWord = cleanName:match("%a+") or "target"
    return firstWord .. id
end

function Sentry.addEffect(id, displayName, color, sourceItem, skipUpdate)
    color = color or "white"
    Sentry.effects[id] = { name = displayName, color = color, item = sourceItem }
    if not skipUpdate then Sentry.updateRoomUI() end
end

function Sentry.removeEffect(id, skipUpdate)
    Sentry.effects[id] = nil
    if not skipUpdate then Sentry.updateRoomUI() end
end

function Sentry.hasEffect(id)
    return Sentry.effects[id] ~= nil
end

function Sentry.sortItem(item)
    if item.attrib and item.attrib:find("m") and not item.attrib:find("d") then
        Sentry.denizens[item.id] = item
    else
        local nameLower = item.name:lower()
        local isSigil, isTotem = false, false
        
        -- [Keep your existing Sigil and Totem parsing logic here exactly as it is...]
        if nameLower:find("sigil") then
            for sigilType, data in pairs(Sentry.sigilData) do
                if nameLower:find(sigilType .. " sigil") then
                    isSigil = true
                    Sentry.addEffect("sigil_" .. item.id, item.name .. " (" .. data.effect .. ")", data.color, item, true)
                    local inQueue = false
                    for _, queuedID in ipairs(Sentry.probeQueue) do if queuedID == item.id then inQueue = true; break end end
                    if not inQueue then table.insert(Sentry.probeQueue, item.id) end
                    break
                end
            end
        end
        
        if nameLower:find("totem") then
            isTotem = true
            Sentry.addEffect("totem_" .. item.id, item.name, "cyan", item, true)
            if not item.runes then
                local inQueue = false
                for _, queuedID in ipairs(Sentry.probeQueue) do if queuedID == item.id then inQueue = true; break end end
                if not inQueue then table.insert(Sentry.probeQueue, item.id) end
            end
        end
        
        if isSigil or isTotem then return end

        -- === DYNAMIC CATEGORY SORTER ===
        local matchedCategory = "uncategorized" -- Default fallback
        
        for _, category in ipairs(Sentry.config.itemCategories) do
            if category.keywords then
                for _, kw in ipairs(category.keywords) do
                    -- %f[%a] ensures we match whole words only (e.g., "box" won't match "boxer")
                    if nameLower:find("%f[%a]" .. kw .. "%f[%A]") then 
                        matchedCategory = category.id
                        break 
                    end
                end
            end
            if matchedCategory ~= "uncategorized" then break end -- Stop searching once categorized
        end
        
        -- Assign the item to its designated bucket
        Sentry.categorizedItems[matchedCategory][item.id] = item
        
        -- Probe checks for walls and unidentified totems
        if (nameLower:find("wall of") and not item.direction) or (nameLower:find("totem") and not item.runes) then
            local inQueue = false
            for _, queuedID in ipairs(Sentry.probeQueue) do if queuedID == item.id then inQueue = true; break end end
            if not inQueue then table.insert(Sentry.probeQueue, item.id) end
        end
    end
end

function Sentry.getColor(category, name, id, defaultColor)
    if category == "player" then
        if Sentry.config.useNDBColors and Legacy and Legacy.NDB and Legacy.NDB.color then
            local ndbColor = nil
            if type(Legacy.NDB.color) == "function" then
                ndbColor = Legacy.NDB.color(name:title())
            elseif type(Legacy.NDB.color) == "table" then
                ndbColor = Legacy.NDB.color[name:title()]
            end

            if ndbColor and ndbColor ~= "" then
                if not ndbColor:match("^<.*>$") then ndbColor = "<" .. ndbColor .. ">" end
                return ndbColor
            end
        end
        return defaultColor

    elseif category == "denizen" then
        if id and Sentry.config.myLoyals[tostring(id)] then return "<cyan>" end
        local nameLower = name:lower()
        local isLegendaryMount = nameLower:find("pegasus") or nameLower:find("griffon") or nameLower:find("dragon")
        if isLegendaryMount and Sentry.config.colorMounts then return "<purple>" end
        return defaultColor
    elseif category == "item" then
        return defaultColor
    end

    return defaultColor
end

-- Strips quotes to prevent Achaean apostrophes (like tsol'aa) from breaking Mudlet's HTML tooltips
function Sentry.stripQuotes(str)
    if not str then return "" end
    return str:gsub("'", ""):gsub('"', "")
end

-- =========================================================================
-- 4. UI UPDATERS
-- =========================================================================

function Sentry.updateRoomUI()
    if not Sentry.console then return end
    Sentry.console:clear()

    local function tableHasContents(t)
        if type(t) ~= "table" then return false end
        for _ in pairs(t) do return true end
        return false
    end
    
    -- Count everything to determine if we need to auto-collapse
    local totalEntities = 0
    local function countTable(t) 
        if type(t) == "table" then 
            for _ in pairs(t) do totalEntities = totalEntities + 1 end 
        end
    end
    
    countTable(Sentry.players) 
    countTable(Sentry.denizens) 
    countTable(Sentry.effects)
    
    -- Count all dynamically categorized items
    if type(Sentry.categorizedItems) == "table" then
        for _, categoryTable in pairs(Sentry.categorizedItems) do
            countTable(categoryTable)
        end
    end

    local shouldCollapse = Sentry.config.alwaysCollapse or (totalEntities >= Sentry.config.collapseThreshold)

    local isFirstSection = true

    if gmcp and gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.name then
        local headerText = gmcp.Room.Info.name
        if Sentry.isGlanced then headerText = headerText .. " <white>(Glanced)" end
        Sentry.console:cecho("\n<white><== MY LOCATION ==><reset>\n")
        Sentry.console:cecho("<white><yellow>" .. headerText .."<white><reset>\n")
        isFirstSection = false
    end

    if tableHasContents(Sentry.players) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<cyan>=== PLAYERS ===<reset>\n")
        
        local renderList, grouped = {}, {}
        for name, p in pairs(Sentry.players) do
            local key = shouldCollapse and name or tostring(name .. "_" .. math.random())
            if not grouped[key] then
                grouped[key] = { count = 1, name = name, item = p }
                table.insert(renderList, grouped[key])
            else grouped[key].count = grouped[key].count + 1 end
        end
        table.sort(renderList, function(a, b) return a.name < b.name end)

        for _, data in ipairs(renderList) do
            local name = data.name
            local countText = data.count > 1 and (" <white>(" .. data.count .. ")") or ""
            local tCmd = Sentry.config.targetCmd .. name
            local pCmd = Sentry.config.probeCmd .. name
            local pColor = Sentry.getColor("player", name, nil, "<cyan>")
            local safeName = Sentry.stripQuotes(name)
            
            Sentry.console:cecho("<white>[")
            Sentry.console:cechoLink("<red>T", [[send("]]..tCmd..[[", false)]], "Target " .. safeName, true)
            if not Sentry.isGlanced then
                Sentry.console:cecho("<white>|")
                Sentry.console:cechoLink("<DodgerBlue>P", [[send("]]..pCmd..[[", false)]], "Probe " .. safeName, true)
            end
            Sentry.console:cecho("<white>] " .. pColor .. name .. countText .. "<reset>\n")
        end
        isFirstSection = false
    end

    if tableHasContents(Sentry.denizens) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<yellow>=== DENIZENS ===<reset>\n")
        
        local renderList, grouped = {}, {}
        for id, d in pairs(Sentry.denizens) do
            local isLoyal = Sentry.config.myLoyals[tostring(id)]
            local loyalStr = isLoyal and "1" or "0"
            local key = shouldCollapse and (d.name .. "_" .. loyalStr) or tostring(id)

            if not grouped[key] then
                grouped[key] = { count = 1, id = id, item = d, isLoyal = isLoyal }
                table.insert(renderList, grouped[key])
            else grouped[key].count = grouped[key].count + 1 end
        end
        
        table.sort(renderList, function(a, b)
            if a.isLoyal and not b.isLoyal then return true end
            if b.isLoyal and not a.isLoyal then return false end
            return a.item.name < b.item.name
        end)

        for _, data in ipairs(renderList) do
            local d = data.item
            local countText = data.count > 1 and (" <white>(" .. data.count .. ")") or ""
            local readableTarget = Sentry.formatTarget(d.name, data.id)
            local tCmd = Sentry.config.targetCmd .. readableTarget
            local pCmd = Sentry.config.probeCmd .. readableTarget
            local dColor = Sentry.getColor("denizen", d.name, data.id, "<yellow>")
            local safeName = Sentry.stripQuotes(d.name)
            
            local suffix = ""
            if data.isLoyal then suffix = " <white>(Loyal)" end
            
            Sentry.console:cecho("<white>[")
            Sentry.console:cechoLink("<red>T", [[send("]]..tCmd..[[", false)]], "Target " .. safeName, true)
            if not Sentry.isGlanced then
                Sentry.console:cecho("<white>|")
                Sentry.console:cechoLink("<DodgerBlue>P", [[send("]]..pCmd..[[", false)]], "Probe " .. safeName, true)
            end
            Sentry.console:cecho("<white>] " .. dColor .. d.name .. countText .. suffix .. "<reset>\n")
        end
        isFirstSection = false
    end

    -- ==========================================================
    -- DYNAMIC CATEGORY RENDERER
    -- ==========================================================
    -- Helper to draw a specific category block
    local function renderCategory(title, color, itemsTable, defaultItemColor)
        if not tableHasContents(itemsTable) then return end
        
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho(string.format("<%s>=== %s ===<reset>\n", color, title))
        
        local renderList, grouped = {}, {}
        for id, item in pairs(itemsTable) do
            local dirStr = item.direction or "none"
            local key = shouldCollapse and (item.name .. "_" .. dirStr) or tostring(id)
            if not grouped[key] then
                grouped[key] = { count = 1, id = id, item = item }
                table.insert(renderList, grouped[key])
            else grouped[key].count = grouped[key].count + 1 end
        end
        table.sort(renderList, function(a, b) return a.item.name < b.item.name end)

        for _, data in ipairs(renderList) do
            local i = data.item
            local countText = data.count > 1 and (" <white>(" .. data.count .. ")") or ""
            local readableTarget = Sentry.formatTarget(i.name, data.id)
            local gCmd = Sentry.config.getCmd .. readableTarget
            local pCmd = Sentry.config.probeCmd .. readableTarget
            local iColor = Sentry.getColor("item", i.name, data.id, "<" .. defaultItemColor .. ">")
            local safeName = Sentry.stripQuotes(i.name)
            
            local suffix = ""
            if i.direction then suffix = " <white>(" .. i.direction:upper() .. ")" end
            
            if not Sentry.isGlanced then
                Sentry.console:cecho("<white>[")
                Sentry.console:cechoLink("<gold>G", [[send("]]..gCmd..[[", false)]], "Get " .. safeName, true)
                Sentry.console:cecho("<white>|")
                Sentry.console:cechoLink("<DodgerBlue>P", [[send("]]..pCmd..[[", false)]], "Probe " .. safeName, true)
                Sentry.console:cecho("<white>] ")
            else
                Sentry.console:cecho("<white>[<grey>-<white>] ")
            end
            Sentry.console:cecho(iColor .. i.name .. countText .. suffix .. "<reset>\n")
        end
        isFirstSection = false
    end

    -- 1. Render explicitly mapped categories
    for _, cat in ipairs(Sentry.config.itemCategories) do
        renderCategory(cat.title, cat.color, Sentry.categorizedItems[cat.id], cat.color)
    end
    
    -- 2. Render whatever didn't match any keywords as a fallback "ITEMS" section
    renderCategory("UNCATEGORIZED ITEMS", "green", Sentry.categorizedItems["uncategorized"], "green")

    if tableHasContents(Sentry.effects) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<magenta>=== EFFECTS ===<reset>\n")
        
        local renderList, grouped = {}, {}
        for id, data in pairs(Sentry.effects) do
            local runeStr = ""
            if data.item and data.item.runes then
                local rs = {}
                for r, c in pairs(data.item.runes) do table.insert(rs, c..r) end
                table.sort(rs)
                runeStr = table.concat(rs, ",")
            end
            
            local flmStr = data.flamed and "1" or "0"
            local key = shouldCollapse and (data.name .. "_" .. flmStr .. "_" .. runeStr) or tostring(id)
            
            if not grouped[key] then
                grouped[key] = { count = 1, id = id, data = data }
                table.insert(renderList, grouped[key])
            else grouped[key].count = grouped[key].count + 1 end
        end
        table.sort(renderList, function(a, b) return a.data.name < b.data.name end)

        for _, effData in ipairs(renderList) do
            local data = effData.data
            local countText = effData.count > 1 and (" <white>(" .. effData.count .. ")") or ""
            local suffix = ""
            
            if data.item and data.item.runes then
                local runeStrings = {}
                for runeName, count in pairs(data.item.runes) do
                    if count > 1 then table.insert(runeStrings, count .. " " .. runeName)
                    else table.insert(runeStrings, runeName) end
                end
                if #runeStrings > 0 then
                    table.sort(runeStrings)
                    suffix = " <cyan>(" .. table.concat(runeStrings, ", ") .. ")"
                end
            end
            
            if data.item and not Sentry.isGlanced then
                local readableTarget = Sentry.formatTarget(data.item.name, data.item.id)
                local safeName = Sentry.stripQuotes(data.item.name)
                
                if data.flamed then
                    Sentry.console:cecho("<white>[<red>X<white>] <" .. data.color .. ">" .. data.name .. countText .. suffix .. " <red>(Flamed)<reset>\n")
                else
                    local gCmd = Sentry.config.getCmd .. readableTarget
                    Sentry.console:cecho("<white>[")
                    Sentry.console:cechoLink("<gold>G", [[send("]]..gCmd..[[", false)]], "Get " .. safeName, true)
                    Sentry.console:cecho("<white>] <" .. data.color .. ">" .. data.name .. countText .. suffix .. "<reset>\n")
                end
            else
                Sentry.console:cecho("<white>[<" .. data.color .. ">~<white>] <" .. data.color .. ">" .. data.name .. countText .. suffix .. "<reset>\n")
            end
        end
    end
    raiseEvent("Sentry.RoomUpdated")
end

-- =========================================================================
-- SELF STATUS UI
-- =========================================================================
function Sentry.updateSelfUI()
    if not Sentry.selfConsole then return end
    Sentry.selfConsole:clear()

    Sentry.selfConsole:cecho("\n<white><== MY STATUS ==><reset>\n\n")

    local hasMindseye = false
    if Legacy and Legacy.Curing and Legacy.Curing.Defs and Legacy.Curing.Defs.current then
        local defs = Legacy.Curing.Defs.current
        if defs["mindseye"] or defs["thirdeye"] then
            hasMindseye = true
        end
    end

    -- 1. AFFLICTIONS
    Sentry.selfConsole:cecho("<red>=== CURRENT AFFLICTIONS ===<reset>\n")
    if gmcp and gmcp.Char and gmcp.Char.Afflictions and gmcp.Char.Afflictions.List then
        local activeAffs = {}
        for _, affData in ipairs(gmcp.Char.Afflictions.List) do
            local affNameLower = affData.name:lower()
            if hasMindseye and (affNameLower == "blindness" or affNameLower == "deafness") then
                -- Skip tactical defences
            elseif affNameLower == "insomnia" then
                -- Skip tactical defences
            else
                table.insert(activeAffs, affData.name:title())
            end
        end

        if #activeAffs == 0 then
            Sentry.selfConsole:cecho("<green>Clean!<reset>\n")
        else
            table.sort(activeAffs)
            for i = 1, #activeAffs, 2 do
                local c1 = activeAffs[i]
                local c2 = activeAffs[i+1] or ""
                local col1 = Sentry.padText("- " .. c1, "<white>- " .. c1, 20)
                local col2 = c2 ~= "" and ("<white>- " .. c2) or ""
                Sentry.selfConsole:cecho(col1 .. col2 .. "\n")
            end
        end
    else
        Sentry.selfConsole:cecho("<grey>Waiting for GMCP...<reset>\n")
    end

    -- 2. LIMBS
    Sentry.selfConsole:cecho("\n<green>=== LIMB DAMAGE ===<reset>\n")
    if Legacy and Legacy.SLC and Legacy.SLC.limbs then
        local limbs = Legacy.SLC.limbs
        local function getLimbString(displayName, dmg)
            dmg = tonumber(dmg) or 0
            local color = "<white>"
            if dmg >= 100 then color = "<red>"
            elseif dmg >= 66 then color = "<orange>"
            elseif dmg >= 33 then color = "<yellow>"
            end
            local raw = string.format("%s: %s%%", displayName, dmg)
            local colored = string.format("%s%s<reset>", color, raw)
            return raw, colored
        end

        local r1, c1 = getLimbString("Head", limbs["head"])
        local r2, c2 = getLimbString("Torso", limbs["torso"])
        Sentry.selfConsole:cecho(Sentry.padText(r1, c1, 20) .. c2 .. "\n")

        r1, c1 = getLimbString("L-Arm", limbs["left arm"])
        r2, c2 = getLimbString("R-Arm", limbs["right arm"])
        Sentry.selfConsole:cecho(Sentry.padText(r1, c1, 20) .. c2 .. "\n")

        r1, c1 = getLimbString("L-Leg", limbs["left leg"])
        r2, c2 = getLimbString("R-Leg", limbs["right leg"])
        Sentry.selfConsole:cecho(Sentry.padText(r1, c1, 20) .. c2 .. "\n")
    else
        Sentry.selfConsole:cecho("<grey>Waiting for Legacy Limbs...<reset>\n")
    end

    -- 3. DEFENCES & TATTOOS
    local activeDefs = {}
    local activeTattoos = {}

    if Legacy and Legacy.Curing and Legacy.Curing.Defs and Legacy.Curing.Defs.current then
        local currentDefs = Legacy.Curing.Defs.current
        
        local function isTattoo(name)
            local lowerName = name:lower()
            for _, kw in ipairs(Sentry.config.tattooKeywords) do
                if lowerName == kw then return true end
            end
            for _, kw in ipairs(Sentry.config.expectedTattoos) do
                if lowerName == kw then return true end
            end
            return false
        end

        for defName, isActive in pairs(currentDefs) do
            if isActive then
                if isTattoo(defName) then
                    activeTattoos[defName:title()] = { status = "active" }
                else
                    activeDefs[defName:title()] = { status = "active" }
                end
            end
        end
        
        for _, expected in ipairs(Sentry.config.expectedDefences) do
            local titleName = expected:title()
            if not activeDefs[titleName] then
                activeDefs[titleName] = { status = "missing" }
            end
        end
        
        for _, expected in ipairs(Sentry.config.expectedTattoos) do
            local titleName = expected:title()
            if not activeTattoos[titleName] then
                activeTattoos[titleName] = { status = "missing" }
            end
        end
        
        local function renderSection(title, color, dataTable)
            Sentry.selfConsole:cecho("\n<" .. color .. ">=== " .. title .. " ===<reset>\n")
            
            local sortedKeys = {}
            for k, _ in pairs(dataTable) do table.insert(sortedKeys, k) end
            
            -- Custom sorting logic: Weights first, Alphabetical second
            table.sort(sortedKeys, function(a, b)
                local weightA = Sentry.config.defenceWeights[a:lower()] or 99
                local weightB = Sentry.config.defenceWeights[b:lower()] or 99
                
                if weightA == weightB then
                    return a < b
                else
                    return weightA < weightB
                end
            end)
            
            if #sortedKeys == 0 then
                Sentry.selfConsole:cecho("<grey>None<reset>\n")
                return
            end
            
            for i = 1, #sortedKeys, 2 do
                local name1 = sortedKeys[i]
                local name2 = sortedKeys[i+1]
                
                local function formatItem(name)
                    if not name then return "", "" end
                    if dataTable[name].status == "missing" then
                        return "- " .. name .. " [!]", "<red>- " .. name .. " [!]<reset>"
                    else
                        return "- " .. name, "<white>- " .. name .. "<reset>"
                    end
                end
                
                local raw1, col1 = formatItem(name1)
                local raw2, col2 = formatItem(name2)
                
                local paddedCol1 = Sentry.padText(raw1, col1, 20)
                Sentry.selfConsole:cecho(paddedCol1 .. col2 .. "\n")
            end
        end
        
        renderSection("ACTIVE DEFENCES", "cyan", activeDefs)
        renderSection("TATTOOS", "DodgerBlue", activeTattoos)
        
    else
        Sentry.selfConsole:cecho("\n<cyan>=== ACTIVE DEFENCES ===<reset>\n")
        Sentry.selfConsole:cecho("<grey>Waiting for Legacy Defs...<reset>\n")
    end
end

-- =========================================================================
-- TARGET STATUS UI
-- =========================================================================
function Sentry.updateTargetUI()
    if not Sentry.targetConsole then return end
    Sentry.targetConsole:clear()

    local targetName = (Bladestorm and Bladestorm.pvp and Bladestorm.pvp.targetName) or "No Target"
    targetName = targetName:upper()

    -- 1. TARGET AFFLICTIONS
    Sentry.targetConsole:cecho(string.format("<orange>=== %s'S AFFLICTIONS ===<reset>\n", targetName))
    if ak and ak.score then
        local activeAffs = {}
        for affName, score in pairs(ak.score) do
            if (type(score) == "number" and score >= 100) or (type(score) == "boolean" and score == true) then
                table.insert(activeAffs, affName:title())
            end
        end

        if #activeAffs == 0 then
            Sentry.targetConsole:cecho("<green>Clean!<reset>\n")
        else
            table.sort(activeAffs)
            for i = 1, #activeAffs, 2 do
                local c1 = activeAffs[i]
                local c2 = activeAffs[i+1] or ""
                local col1 = Sentry.padText("- " .. c1, "<white>- " .. c1, 20)
                local col2 = c2 ~= "" and ("<white>- " .. c2) or ""
                Sentry.targetConsole:cecho(col1 .. col2 .. "\n")
            end
        end
    else
        Sentry.targetConsole:cecho("<grey>Waiting for AK data...<reset>\n")
    end

    -- 2. TARGET LIMBS
    Sentry.targetConsole:cecho(string.format("\n<magenta>=== %s'S LIMBS ===<reset>\n", targetName))
    if Bladestorm and Bladestorm.pvp and Bladestorm.pvp.targetName then
        local function getLimbString(displayName, queryName)
            local dmg = Bladestorm.getLimbDamage(queryName)
            local color = "<white>"
            if dmg >= 100 then color = "<red>"
            elseif dmg >= 66 then color = "<orange>"
            elseif dmg >= 33 then color = "<yellow>"
            end
            local raw = string.format("%s: %s%%", displayName, dmg)
            local colored = string.format("%s%s<reset>", color, raw)
            return raw, colored
        end

        local r1, c1 = getLimbString("Head", "head")
        local r2, c2 = getLimbString("Torso", "torso")
        Sentry.targetConsole:cecho(Sentry.padText(r1, c1, 20) .. c2 .. "\n")

        r1, c1 = getLimbString("L-Arm", "left arm")
        r2, c2 = getLimbString("R-Arm", "right arm")
        Sentry.targetConsole:cecho(Sentry.padText(r1, c1, 20) .. c2 .. "\n")

        r1, c1 = getLimbString("L-Leg", "left leg")
        r2, c2 = getLimbString("R-Leg", "right leg")
        Sentry.targetConsole:cecho(Sentry.padText(r1, c1, 20) .. c2 .. "\n")
    else
        Sentry.targetConsole:cecho("<grey>No target selected.<reset>\n")
    end
end


-- =========================================================================
-- SHIP STATUS UI
-- =========================================================================
function Sentry.updateShipUI()
    if not Sentry.shipConsole then return end
    Sentry.shipConsole:clear()

    local d = Sentry.shipData or {}
    local name = d.name or "Unknown Ship"

    Sentry.shipConsole:cecho(string.format("<DeepSkyBlue><== %s ==><reset>\n", name:upper()))
    
    -- Identification & Ownership
    Sentry.shipConsole:cecho(string.format("<cyan>Type:  <white>%s\n", d.type or "?"))
    Sentry.shipConsole:cecho(string.format("<cyan>Flag:  <white>%s\n", d.flag or "?"))
    Sentry.shipConsole:cecho(string.format("<cyan>Vis:   <white>%s\n", d.vis or "?"))
    Sentry.shipConsole:cecho(string.format("<cyan>Owner: <white>%s <cyan>| Capt: <white>%s\n\n", d.owner or "?", d.captain or "?"))

    -- Health Row
    local s_color = (tonumber(d.sails) or 100) < 50 and "<red>" or "<green>"
    local h_color = (tonumber(d.hull) or 100) < 50 and "<red>" or "<green>"
    local sea_col = (d.seaworthy == "Seaworthy") and "<green>" or "<red>"
    Sentry.shipConsole:cecho(string.format("<white>Sails: %s%s%% <white>| Hull: %s%s%% <white>| %s%s\n",
        s_color, d.sails or "?", h_color, d.hull or "?", sea_col, d.seaworthy or "?"))

    -- Hazards Row
    local leak_c = (d.leaking == "Yes") and "<red>" or "<green>"
    local fire_c = (d.fires == "Yes") and "<red>" or "<green>"
    local rig_c = (d.riggings == "Clear") and "<green>" or "<red>"
    Sentry.shipConsole:cecho(string.format("<white>Leaks: %s%s <white>| Fire: %s%s <white>| Rig: %s%s\n\n",
        leak_c, d.leaking or "?", fire_c, d.fires or "?", rig_c, d.riggings or "?"))

    -- Movement Row
    Sentry.shipConsole:cecho(string.format("<white>Course: <yellow>%s <white>| Sail: <yellow>%s <white>| Row: <yellow>%s\n",
        d.course or "?", d.sailing or "?", d.rowing or "?"))

    -- Access Row
    Sentry.shipConsole:cecho(string.format("<white>Anchor: <yellow>%s <white>| Plank: <yellow>%s <white>| Lads: <yellow>%s\n",
        d.anchored or "?", d.plank or "?", d.ladders or "?"))

    -- Status & Crew Row (Dynamic)
    local statusParts = {}
    if Sentry.config.shipDisplay.crew then table.insert(statusParts, string.format("<white>Crew: <yellow>%s", d.crew or "?")) end
    if Sentry.config.shipDisplay.harbour then table.insert(statusParts, string.format("<white>Harb: <yellow>%s", d.harbour or "?")) end
    if Sentry.config.shipDisplay.arena then table.insert(statusParts, string.format("<white>Arena: <yellow>%s", d.arena or "?")) end
    if #statusParts > 0 then Sentry.shipConsole:cecho(table.concat(statusParts, " <white>| ") .. "\n") end
        
    -- Equipment Row (Dynamic)
    local equipParts = {}
    if Sentry.config.shipDisplay.buoy then table.insert(equipParts, string.format("<white>Buoy: <yellow>%s", d.buoy or "?")) end
    if Sentry.config.shipDisplay.float then table.insert(equipParts, string.format("<white>Float: <yellow>%s", d.float or "?")) end
    if Sentry.config.shipDisplay.bell then 
        local bellStat = d.bell == "no diving bell" and "No" or (d.bell or "?")
        table.insert(equipParts, string.format("<white>Bell: <yellow>%s", bellStat)) 
    end
    if #equipParts > 0 then Sentry.shipConsole:cecho(table.concat(equipParts, " <white>| ") .. "\n") end
        
    -- Manoeuvres (Dynamic)
    if Sentry.config.shipDisplay.manoeuvres then
        Sentry.shipConsole:cecho(string.format("<white>Manoeuvres: <yellow>%s\n", d.manoeuvres or "?"))
    end

    -- Wind & Locale
    Sentry.shipConsole:cecho(string.format("\n<cyan>Wind: <white>%s\n", d.wind or "?"))
    Sentry.shipConsole:cecho(string.format("<cyan>Loc:  <white>%s\n", d.locale or "?"))
end

-- =========================================================================
-- 5. EVENT HANDLERS (GMCP & SYSTEM)
-- =========================================================================
function Sentry.handleCommand(event, command)
    local cmdLower = command:lower():gsub("^%s+", ""):gsub("%s+$", "")
    
    if cmdLower == "glance sky" or cmdLower == "glance up" or cmdLower == "glance ground" or cmdLower == "glance down" then
        Sentry.isGlanced = true
    elseif cmdLower:match("^glance") or cmdLower == "l" or cmdLower == "look" or cmdLower == "ql" or cmdLower == "quicklook" or cmdLower:match("^[nsewud]$") or cmdLower:match("^[nsew][eo]$") or cmdLower == "in" or cmdLower == "out" then
        Sentry.isGlanced = false
    end
end

function Sentry.handleRoomChange(event)
    if event == "gmcp.Room.Info" then
        local currentRoom = gmcp.Room.Info.num
        local env = gmcp.Room.Info.environment or ""
        
        -- Rock-solid ship detection via GMCP
        local isVessel = (env == "Vessel")
        
        -- If we enter a ship (or log in on one)
        if isVessel and not Sentry.isOnShip then
            Sentry.isOnShip = true
            Sentry.toggle("ship", true)
            Sentry.silentShipInfo = true
            send("ship info", false)
            
        -- If we leave a ship
        elseif not isVessel and Sentry.isOnShip then
            Sentry.isOnShip = false
            Sentry.toggle("ship", false)
        end

        if Sentry.lastRoom ~= currentRoom then
            Sentry.lastRoom = currentRoom
            Sentry.effects = {}
            Sentry.updateRoomUI()
            
            if not Sentry.isGlanced then
                if type(Sentry.silentRunelist) ~= "number" then Sentry.silentRunelist = 0 end
                Sentry.silentRunelist = Sentry.silentRunelist + 1
                send("runelist", false)
            end
        end
    end
end

function Sentry.handlePlayers(event)
    if event == "gmcp.Room.Players" then
        Sentry.players = {}
        for _, player in ipairs(gmcp.Room.Players) do
            Sentry.players[player.name] = player
        end
    elseif event == "gmcp.Room.AddPlayer" then
        local player = gmcp.Room.AddPlayer
        Sentry.players[player.name] = player
    elseif event == "gmcp.Room.RemovePlayer" then
        local playerName = gmcp.Room.RemovePlayer
        Sentry.players[playerName] = nil
    end
    Sentry.updateRoomUI()
end

function Sentry.handleItems(event)
    if event == "gmcp.Char.Items.List" then
        if gmcp.Char.Items.List.location == "room" then
            Sentry.denizens = {}
            -- Clear all dynamic categories
            Sentry.categorizedItems = { ["uncategorized"] = {} }
            for _, cat in ipairs(Sentry.config.itemCategories) do
                Sentry.categorizedItems[cat.id] = {}
            end
            
            for _, item in ipairs(gmcp.Char.Items.List.items) do
                Sentry.sortItem(item)
            end
        end
    elseif event == "gmcp.Char.Items.Add" then
        local item = gmcp.Char.Items.Add.item
        if gmcp.Char.Items.Add.location == "room" then
            Sentry.sortItem(item)
        end
    elseif event == "gmcp.Char.Items.Remove" then
        local item = gmcp.Char.Items.Remove.item
        if gmcp.Char.Items.Remove.location == "room" then
            Sentry.denizens[item.id] = nil
            
            -- Scrub it from whatever category it was sorted into
            for catID, itemTable in pairs(Sentry.categorizedItems) do
                itemTable[item.id] = nil
            end
            
            if Sentry.hasEffect("sigil_" .. item.id) then Sentry.removeEffect("sigil_" .. item.id, true) end
            if Sentry.hasEffect("totem_" .. item.id) then Sentry.removeEffect("totem_" .. item.id, true) end
        end
    end
    
    Sentry.updateRoomUI()
    
    if #Sentry.probeQueue > 0 then
        local probesToRun = Sentry.probeQueue
        local capturedRoom = Sentry.lastRoom
        Sentry.probeQueue = {} 
        
        if Sentry.probeTimer then killTimer(Sentry.probeTimer) end
        
        Sentry.probeTimer = tempTimer(0.25, function()
            if Sentry.lastRoom ~= capturedRoom then return end
            
            Sentry.silentProbing = true
            for _, id in ipairs(probesToRun) do
                send("probe " .. id, false)
            end
            
            if Sentry.gagTimer then killTimer(Sentry.gagTimer) end
            Sentry.gagTimer = tempTimer(2.0, function() Sentry.silentProbing = false end)
        end)
    end
end

-- =========================================================================
-- 6. DYNAMIC TRIGGERS
-- =========================================================================
Sentry.triggers = Sentry.triggers or {}

function Sentry.createTriggers()
    for _, id in ipairs(Sentry.triggers) do killTrigger(id) end
    Sentry.triggers = {}

    -- SHIP MOVEMENT
    table.insert(Sentry.triggers, tempRegexTrigger("^The ship (?:moves to|drifts toward) the (\\w+)\\.$", 
        [[
            if Sentry.isOnShip then
                Sentry.silentShipInfo = true
                send("ship info", false)
            end
        ]]
    ))

    -- SHIP INFO PARSER BLOCK
    table.insert(Sentry.triggers, tempRegexTrigger("^Ship Info for:\\s+(.*)$", 
        [[
            Sentry.parsingShipInfo = true
            Sentry.shipData = { name = matches[2] }
            if Sentry.silentShipInfo then deleteLine() end
            
            tempPromptTrigger(function()
                if Sentry.parsingShipInfo then
                    Sentry.parsingShipInfo = false
                    Sentry.silentShipInfo = false
                    Sentry.updateShipUI()
                end
            end, 1)
        ]]
    ))

    -- Dynamic matcher: Catches ANY line structured as "Key: Value" or "Key? Value"
    table.insert(Sentry.triggers, tempRegexTrigger("^([^:?]+)(:|\\?)\\s+(.*)$", 
        [[
            if Sentry.parsingShipInfo then
                if Sentry.silentShipInfo then deleteLine() end
                
                local key = matches[2]:lower()
                if matches[3] == "?" then key = key .. "?" end
                local val = matches[4]:gsub("%.$", "") 
                
                -- Assign ALL keys to our UI data table
                if key == "ship type" then Sentry.shipData.type = val
                elseif key == "ship flag" then Sentry.shipData.flag = val
                elseif key == "ship vis" then Sentry.shipData.vis = val
                elseif key == "owned by" then Sentry.shipData.owner = val
                elseif key == "captained by" then Sentry.shipData.captain = val
                elseif key == "seaworthiness" then Sentry.shipData.seaworthy = val
                elseif key == "sails health" then Sentry.shipData.sails = val:match("(%d+)%%")
                elseif key == "hull health" then Sentry.shipData.hull = val:match("(%d+)%%")
                elseif key == "leaking now?" then Sentry.shipData.leaking = val
                elseif key == "fires" then Sentry.shipData.fires = val
                elseif key == "riggings" then Sentry.shipData.riggings = val
                elseif key == "course" then Sentry.shipData.course = val
                elseif key == "sailing?" then Sentry.shipData.sailing = val
                elseif key == "rowing?" then Sentry.shipData.rowing = val
                elseif key == "in harbour?" then Sentry.shipData.harbour = val
                elseif key == "in ship arena?" then Sentry.shipData.arena = val
                elseif key == "locale" then Sentry.shipData.locale = val
                elseif key == "anchored?" then Sentry.shipData.anchored = val
                elseif key == "gangplank" then Sentry.shipData.plank = val
                elseif key == "rope ladders" then Sentry.shipData.ladders = val
                elseif key == "crewmates" then Sentry.shipData.crew = val
                elseif key == "manoeuvres" then Sentry.shipData.manoeuvres = val
                elseif key == "diving bell" then Sentry.shipData.bell = val
                elseif key == "buoy" then Sentry.shipData.buoy = val
                elseif key == "cargo float" then Sentry.shipData.float = val
                elseif key == "warn of low wages in strongbox" then Sentry.shipData.wages = val
                elseif key == "notify of changes in captaincy" then Sentry.shipData.notify = val
                elseif key == "wind from the" then Sentry.shipData.wind = val
                end
            end
        ]]
    ))

    -- Catch and gag the dividing dashes
    table.insert(Sentry.triggers, tempRegexTrigger("^\\-+$", 
        [[ if Sentry.parsingShipInfo and Sentry.silentShipInfo then deleteLine() end ]]
    ))
    
    -- Catch and gag the empty blank lines Achaea uses for spacing
    table.insert(Sentry.triggers, tempRegexTrigger("^\\s*$", 
        [[ if Sentry.parsingShipInfo and Sentry.silentShipInfo then deleteLine() end ]]
    ))

    -- Loyals Parser 
    table.insert(Sentry.triggers, tempRegexTrigger("^Your loyal companions are:", 
        [[ 
            Sentry.parsingLoyals = true 
            tempPromptTrigger([=[
                if Sentry.parsingLoyals then
                    Sentry.parsingLoyals = false
                    Sentry.updateRoomUI()
                    cecho("\n<SteelBlue>[Sentry]:<reset> <white>Loyal IDs successfully tracked!<reset>\n")
                end
            ]=], 1)
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^You have no loyal companions\\.", 
        [[ 
            Sentry.config.myLoyals = {} 
            Sentry.updateRoomUI()
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^(.*?)(\\d+) is ", 
        [[
            if Sentry.parsingLoyals then
                local id = matches[3]
                Sentry.config.myLoyals[tostring(id)] = true
            end
        ]]
    ))

    -- Smart Runelist Parser 
    table.insert(Sentry.triggers, tempRegexTrigger("Type.+Owner", 
        [[ 
            Sentry.parsingRunes = true
            Sentry.dashCount = 0
            for id in pairs(Sentry.effects) do
                if id:find("^rune_") then Sentry.effects[id] = nil end
            end
            if type(Sentry.silentRunelist) == "number" and Sentry.silentRunelist > 0 then deleteLine() end 
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("-{20,}", 
        [[
            if Sentry.parsingRunes then
                Sentry.dashCount = Sentry.dashCount + 1
                if type(Sentry.silentRunelist) == "number" and Sentry.silentRunelist > 0 then deleteLine() end
                if Sentry.dashCount == 2 then
                    Sentry.parsingRunes = false
                    if type(Sentry.silentRunelist) == "number" and Sentry.silentRunelist > 0 then Sentry.silentRunelist = Sentry.silentRunelist - 1 end
                end
            end
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^A rune (?:resembling|like|shaped like) a[n]? (.+?)\\s{2,}(\\w+)", 
        [[
            if Sentry.parsingRunes then
                if type(Sentry.silentRunelist) == "number" and Sentry.silentRunelist > 0 then deleteLine() end
                local object = matches[2]:lower()
                local owner = matches[3]
                local runeInfo = Sentry.runeData[object]
                local displayName = runeInfo and (runeInfo.name .. " (" .. runeInfo.effect .. ") - " .. owner) or (object:title() .. " - " .. owner)
                local cleanID = object:gsub("%s+", "_")
                Sentry.addEffect("rune_" .. cleanID .. "_" .. owner, displayName, "gold")
            end
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("You find no runes", 
        [[ 
            for id in pairs(Sentry.effects) do
                if id:find("^rune_") then Sentry.effects[id] = nil end
            end
            Sentry.updateRoomUI()
            if type(Sentry.silentRunelist) == "number" and Sentry.silentRunelist > 0 then 
                deleteLine(); Sentry.silentRunelist = Sentry.silentRunelist - 1 
            end 
        ]]
    ))

    -- Sketching & Smudging 
    table.insert(Sentry.triggers, tempRegexTrigger("^You begin sketching an? \\w+ rune on the ground\\.$", [[]]))
    table.insert(Sentry.triggers, tempRegexTrigger("^With a flourish, you finish sketching an? \\w+ rune\\.$", [[ Sentry.silentRunelist = Sentry.silentRunelist + 1; send("runelist", false) ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^You smudge the \\w+ rune off the ground\\.$", [[ Sentry.silentRunelist = Sentry.silentRunelist + 1; send("runelist", false) ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^(\\w+) sketches a rune.*$", [[ Sentry.silentRunelist = Sentry.silentRunelist + 1; send("runelist", false) ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^(\\w+) smudges a rune.*$", [[ Sentry.silentRunelist = Sentry.silentRunelist + 1; send("runelist", false) ]] ))

    -- Wall Spawn & Probe Parser
    table.insert(Sentry.triggers, tempRegexTrigger("^A wall of .* rises from the earth to block the exit to the (\\w+)\\.$", 
        [[
            local dir = matches[2]
            for id, item in pairs(Sentry.items) do
                if item.name:lower():find("wall of") and not item.direction then
                    Sentry.items[id].direction = dir; Sentry.updateRoomUI(); break
                end
            end
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^A (?:large )?wall of .* stands here, blocking passage to the (\\w+)\\.$", 
        [[
            local dir = matches[2]
            for id, item in pairs(Sentry.items) do
                if item.name:lower():find("wall of") and not item.direction then
                    Sentry.items[id].direction = dir; Sentry.updateRoomUI(); break
                end
            end
            if Sentry.silentProbing then deleteLine() end
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^A (?:large )?wall of .* is blocking passage to the (\\w+)\\.$", 
        [[
            local dir = matches[2]
            for id, item in pairs(Sentry.items) do
                if item.name:lower():find("wall of") and not item.direction then
                    Sentry.items[id].direction = dir; Sentry.updateRoomUI(); break
                end
            end
            if Sentry.silentProbing then deleteLine() end
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^This .* looks to be made of .*$", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^This .* wall is made of .*$", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^It towers above you.*$", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^It weighs about .* pounds\\.$", [[ if Sentry.silentProbing then deleteLine() end ]] ))

    -- Totem Probe Parser 
    table.insert(Sentry.triggers, tempRegexTrigger("^It has the following runes sketched upon it:$", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("is sketched in(?:to)? slot", 
        [[
            if Sentry.silentProbing then deleteLine() end
            local lineLower = line:lower()
            local runeName = nil
            for key, data in pairs(Sentry.runeData) do
                local searchKey = key
                if key == "stickman" then searchKey = "stick man" end
                if key == "upwards-pointing arrow" then searchKey = "upward-pointing arrow" end
                if lineLower:find(searchKey) then runeName = data.name; break end
            end
            if runeName then
                for id, effect in pairs(Sentry.effects) do
                    if id:find("^totem_") then
                        effect.item.runes = effect.item.runes or {}
                        effect.item.runes[runeName] = (effect.item.runes[runeName] or 0) + 1
                        Sentry.updateRoomUI()
                        break 
                    end
                end
            end
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^It is tuned against.*", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^It bears the distinctive mark of.*", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^You may use this item to parry with\\.", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^This totem is the property of.*", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^The totem is currently empowered.*", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^It has \\d+ months of usefulness left\\.", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    
    -- Sigil Probe Parser & Traps
    table.insert(Sentry.triggers, tempRegexTrigger("^There is a flame-shaped sigil attached\\.", 
        [[
            if Sentry.silentProbing then deleteLine() end
            for id, effect in pairs(Sentry.effects) do
                if id:find("^sigil_") and not effect.flamed then
                    Sentry.effects[id].flamed = true; Sentry.updateRoomUI(); break
                end
            end
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^You quickly pull your hand back as a flame sigil on an? (.*?) singes your fingers\\.$", 
        [[
            local targetName = matches[2]:lower()
            for id, effect in pairs(Sentry.effects) do
                if id:find("^sigil_") and effect.item.name:lower():find(targetName) then
                    Sentry.effects[id].flamed = true; Sentry.updateRoomUI(); break
                end
            end
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^Made (?:of|from) .*, .* sigil.*", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^It weighs \\d+ ounce\\(s\\)\\.$", [[ if Sentry.silentProbing then deleteLine() end ]] ))

    -- Environmental Effects
    table.insert(Sentry.triggers, tempRegexTrigger("^The air is filled with a humming vibration\\.$", [[ Sentry.addEffect("vibrations", "Humming Vibrations", "magenta") ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^The humming vibration in the air fades away\\.$", [[ Sentry.removeEffect("vibrations") ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^A roaring wall of fire erupts.*$", [[ Sentry.addEffect("fire", "Roaring Fire", "orange_red") ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^The wall of fire burns out and disappears\\.$", [[ Sentry.removeEffect("fire") ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^The area is flooded with water\\.$", [[ Sentry.addEffect("flood", "Flooded", "blue") ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^The floodwaters recede\\.$", [[ Sentry.removeEffect("flood") ]] ))
end

-- =========================================================================
-- 7. COMMAND INTERFACE & ALIASES
-- =========================================================================
function Sentry.toggle(uiName, forceState)
    -- Helper to apply force state if provided, otherwise toggle boolean
    local function applyState(currentState, force)
        if force ~= nil then return force else return not currentState end
    end

    if uiName == "main" then
        Sentry.config.mainVisible = applyState(Sentry.config.mainVisible, forceState)
        if Sentry.config.mainVisible then Sentry.container:show(); cecho("\n<SteelBlue>[Sentry]:<reset> <white>Main UI <gold>VISIBLE<white>.<reset>\n")
        else Sentry.container:hide(); cecho("\n<SteelBlue>[Sentry]:<reset> <white>Main UI <gold>HIDDEN<white>.<reset>\n") end
    
    elseif uiName == "self" then
        Sentry.config.selfVisible = applyState(Sentry.config.selfVisible, forceState)
        if Sentry.config.selfVisible then Sentry.selfContainer:show(); cecho("\n<SteelBlue>[Sentry]:<reset> <white>Self UI <gold>VISIBLE<white>.<reset>\n")
        else Sentry.selfContainer:hide(); cecho("\n<SteelBlue>[Sentry]:<reset> <white>Self UI <gold>HIDDEN<white>.<reset>\n") end
    
    elseif uiName == "target" then
        Sentry.config.targetVisible = applyState(Sentry.config.targetVisible, forceState)
        if Sentry.config.targetVisible then 
            Sentry.targetContainer:show()
            Sentry.shipContainer:hide() -- Ensure they don't overlap
            cecho("\n<SteelBlue>[Sentry]:<reset> <white>Target UI <gold>VISIBLE<white>.<reset>\n")
        else 
            Sentry.targetContainer:hide(); cecho("\n<SteelBlue>[Sentry]:<reset> <white>Target UI <gold>HIDDEN<white>.<reset>\n") 
        end
    
    elseif uiName == "collapse" then
        Sentry.config.alwaysCollapse = applyState(Sentry.config.alwaysCollapse, forceState)
        if Sentry.config.alwaysCollapse then cecho("\n<SteelBlue>[Sentry]:<reset> <white>Identical Item Grouping <green>ALWAYS ON<white>.<reset>\n")
        else cecho("\n<SteelBlue>[Sentry]:<reset> <white>Identical Item Grouping <red>AUTO-ONLY<white>.<reset>\n") end
        Sentry.updateRoomUI()
    
    elseif uiName == "ship" then
        Sentry.config.shipVisible = applyState(Sentry.config.shipVisible, forceState)
        if Sentry.config.shipVisible then 
            Sentry.shipContainer:show()
            Sentry.targetContainer:hide() -- Hide target UI automatically when boarding
            cecho("\n<SteelBlue>[Sentry]:<reset> <white>Ship UI <gold>VISIBLE<white>.<reset>\n")
        else 
            Sentry.shipContainer:hide()
            Sentry.targetContainer:show() -- Bring target back when disembarking
            cecho("\n<SteelBlue>[Sentry]:<reset> <white>Ship UI <gold>HIDDEN<white>.<reset>\n") 
        end
    end
end

function Sentry.showHelp()
    cecho("\n<SteelBlue>=======================================================================<reset>")
    cecho("\n<SteelBlue>                         S E N T R Y   H E L P                         <reset>")
    cecho("\n<SteelBlue>=======================================================================<reset>\n")
    cecho("\n<LightSkyBlue>In-Game Commands:<reset>")
    cecho("\n  <gold>sentry help<reset>          - Displays this help menu.")
    cecho("\n  <gold>sentry loyals<reset>        - Scans and tracks your loyal companions.")
    cecho("\n  <gold>sentry toggle main<reset>   - Toggles Room Awareness UI.")
    cecho("\n  <gold>sentry toggle self<reset>   - Toggles Self Status UI.")
    cecho("\n  <gold>sentry toggle target<reset> - Toggles Target Status UI.")
    cecho("\n  <gold>sentry toggle ship<reset>   - Toggles Ship Info UI manually.")
    cecho("\n  <gold>sentry toggle collapse<reset> - Toggles Identical Item Grouping.")
    cecho("\n<SteelBlue>=======================================================================<reset>\n")
end

function Sentry.handleUserCommand(args)
    local cmd = args:lower():match("^%s*(.-)%s*$")
    
    if cmd == "help" or cmd == "" then Sentry.showHelp()
    elseif cmd:find("^toggle") then
        local target = cmd:match("^toggle (%w+)") or "main"
        Sentry.toggle(target)
    elseif cmd == "loyals" then
        cecho("\n<SteelBlue>[Sentry]:<reset> <white>Updating loyal companions...<reset>\n")
        Sentry.config.myLoyals = {} 
        send("loyals", false) 
    else
        cecho("\n<SteelBlue>[Sentry]:<reset> <white>Unknown command. Type <gold>sentry help<white> for options.<reset>\n")
    end
end

if Sentry.aliasHandler then killAlias(Sentry.aliasHandler) end
Sentry.aliasHandler = tempAlias("^sentry(?: (.*))?$", [[
    local args = matches[2] or "help"
    Sentry.handleUserCommand(args)
]])

-- Apply initial visibility states
if Sentry.config.mainVisible then Sentry.container:show() else Sentry.container:hide() end
if Sentry.config.selfVisible then Sentry.selfContainer:show() else Sentry.selfContainer:hide() end
if Sentry.config.targetVisible then Sentry.targetContainer:show() else Sentry.targetContainer:hide() end
if Sentry.config.shipVisible then Sentry.shipContainer:show() else Sentry.shipContainer:hide() end

-- =========================================================================
-- 8. EVENT REGISTRATION
-- =========================================================================
Sentry.events = Sentry.events or {}

for _, handler in ipairs(Sentry.events) do
    killAnonymousEventHandler(handler)
end
Sentry.events = {}

-- Room UI Events
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Room.Info", "Sentry.handleRoomChange"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Room.Players", "Sentry.handlePlayers"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Room.AddPlayer", "Sentry.handlePlayers"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Room.RemovePlayer", "Sentry.handlePlayers"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Char.Items.List", "Sentry.handleItems"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Char.Items.Add", "Sentry.handleItems"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Char.Items.Remove", "Sentry.handleItems"))

-- Self Status Events
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Char.Afflictions", "Sentry.updateSelfUI"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Char.Vitals", "Sentry.updateSelfUI"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Char.Defences", "Sentry.updateSelfUI"))

-- Target Status / Master Command Events
table.insert(Sentry.events, registerAnonymousEventHandler("sysDataSendRequest", function(event, command)
    Sentry.handleCommand(event, command)
    Sentry.updateTargetUI()
end))

Sentry.createTriggers()
Sentry.updateRoomUI()
Sentry.updateSelfUI()
Sentry.updateTargetUI()
Sentry.updateShipUI()

-- =========================================================================
-- LIVE RELOAD NUDGE
-- Forces Geyser to redraw UIs when clicking "Save" in Mudlet
-- =========================================================================
local containersToNudge = {
    Sentry.container, Sentry.selfContainer, 
    Sentry.targetContainer, Sentry.shipContainer
}

for _, box in ipairs(containersToNudge) do
    if box then
        box:reposition()
        box:hide()
        box:show()
    end
end