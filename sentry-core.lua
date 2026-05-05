-- =========================================================================
-- SENTRY: Tactical Combat UI
-- A robust, zero-dependency situational awareness tracker for Achaea and Mudlet.
-- Version: 1.0.0
-- =========================================================================
Sentry = Sentry or {}

Sentry.players = Sentry.players or {}
Sentry.denizens = Sentry.denizens or {}
Sentry.items = Sentry.items or {}
Sentry.furniture = Sentry.furniture or {}
Sentry.clothing = Sentry.clothing or {}
Sentry.effects = Sentry.effects or {} 
Sentry.config = Sentry.config or {}

Sentry.silentProbing = false
Sentry.probeQueue = {}
Sentry.silentRunelist = 0
Sentry.isGlanced = false

-- =========================================================================
-- Configuration
-- This is the only section of the script you should be editing, unless you
-- are confident you understand how things work and want to customize further!
-- =========================================================================

-- Command prefixes sent to the game when you click UI links. Include a trailing space!
Sentry.config.targetCmd = "settarget " 
Sentry.config.getCmd = "get "
Sentry.config.probeCmd = "probe "

-- Controls whether the Sentry UI window is visible on startup.
Sentry.config.visible = true

-- Set to true to utilize the Legacy package's NDB (Name Database) for player colors.
Sentry.config.useNDBColors = true

-- Set to true to highlight legendary mounts (dragons, griffons, pegasi) in purple.
Sentry.config.colorMounts = false

-- A dynamically populated table of your loyal companions. Do not edit manually. 
-- Type 'sentry loyals' in game to update this list.
Sentry.config.myLoyals = Sentry.config.myLoyals or {}

-- Keywords used to automatically filter static objects into the Furniture section.
Sentry.config.furnitureKeywords = {
    "bed", "dresser", "table", "statue", "chair", "desk", "rug", "tapestry",
    "cabinet", "sofa", "bench, stool", "shelf", "couch", "chandelier", "altar",
    "throne", "coffin", "fireplace",
}

-- Keywords used to automatically filter equippable items into the Clothing section.
Sentry.config.clothingKeywords = {
    "boots", "sandals", "shoes", "blouse", "shirt", "tunic",
    "trousers", "pants", "skirt", "bra", "panties", "underwear",
    "cloak", "cape", "robe", "gloves", "gauntlets", "hat", "helmet", "belt",
    "dress", "vest", "gown", "corset", "socks", "stockings", "jacket", "coat"
}

-- =========================================================================
-- RUNE & SIGIL DICTIONARIES
-- =========================================================================
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

-- Internal state variables for the runelist parser
Sentry.parsingRunes = false
Sentry.dashCount = 0

-- =========================================================================
-- 2. GEYSER UI CREATION
-- =========================================================================
Sentry.container = Sentry.container or Geyser.Container:new({
    name = "SentryContainer",
    x = 0, y = "-50%",
    width = "300px", height = "50%",
})

Sentry.console = Sentry.console or Geyser.MiniConsole:new({
    name = "SentryConsole",
    x = 0, y = 0,
    width = "100%", height = "100%",
    color = "black",
}, Sentry.container)

-- =========================================================================
-- 3. HELPER FUNCTIONS
-- =========================================================================
function Sentry.formatTarget(name, id)
    local cleanName = name:lower():gsub("^a ", ""):gsub("^an ", ""):gsub("^the ", "")
    local firstWord = cleanName:match("%a+") or "target"
    return firstWord .. id
end

function Sentry.sortItem(item)
    if item.attrib and item.attrib:find("m") and not item.attrib:find("d") then
        Sentry.denizens[item.id] = item
    else
        local nameLower = item.name:lower()
        
        local isSigil = false
        if nameLower:find("sigil") then
            for sigilType, data in pairs(Sentry.sigilData) do
                if nameLower:find(sigilType .. " sigil") then
                    isSigil = true
                    Sentry.addEffect("sigil_" .. item.id, item.name .. " (" .. data.effect .. ")", data.color, item)
                    
                    local inQueue = false
                    for _, queuedID in ipairs(Sentry.probeQueue) do
                        if queuedID == item.id then inQueue = true; break end
                    end
                    if not inQueue then table.insert(Sentry.probeQueue, item.id) end
                    break
                end
            end
        end
        
        local isTotem = false
        if nameLower:find("totem") then
            isTotem = true
            Sentry.addEffect("totem_" .. item.id, item.name, "cyan", item)
            
            if not item.runes then
                local inQueue = false
                for _, queuedID in ipairs(Sentry.probeQueue) do
                    if queuedID == item.id then inQueue = true; break end
                end
                if not inQueue then table.insert(Sentry.probeQueue, item.id) end
            end
        end
        
        if isSigil or isTotem then return end

        local isFurniture = false
        local isClothing = false
        
        for _, kw in ipairs(Sentry.config.furnitureKeywords) do
            if nameLower:find("%f[%a]" .. kw .. "%f[%A]") then
                isFurniture = true; break
            end
        end

        if not isFurniture then
            for _, kw in ipairs(Sentry.config.clothingKeywords) do
                if nameLower:find("%f[%a]" .. kw .. "%f[%A]") then
                    isClothing = true; break
                end
            end
        end

        if isFurniture then
            Sentry.furniture[item.id] = item
        elseif isClothing then
            Sentry.clothing[item.id] = item
        else
            Sentry.items[item.id] = item
        end
        
        if (nameLower:find("wall of") and not item.direction) or (nameLower:find("totem") and not item.runes) then
            local inQueue = false
            for _, queuedID in ipairs(Sentry.probeQueue) do
                if queuedID == item.id then inQueue = true; break end
            end
            if not inQueue then
                table.insert(Sentry.probeQueue, item.id)
            end
        end
    end
end

function Sentry.addEffect(id, displayName, color, sourceItem)
    color = color or "white"
    Sentry.effects[id] = { name = displayName, color = color, item = sourceItem }
    Sentry.updateUI()
end

function Sentry.removeEffect(id)
    Sentry.effects[id] = nil
    Sentry.updateUI()
end

function Sentry.hasEffect(id)
    return Sentry.effects[id] ~= nil
end

-- =========================================================================
-- COLOR ROUTER
-- =========================================================================
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
        if id and Sentry.config.myLoyals[tostring(id)] then
            return "<cyan>" 
        end
        
        local nameLower = name:lower()
        local isLegendaryMount = nameLower:find("pegasus") or nameLower:find("griffon") or nameLower:find("dragon")
        
        if isLegendaryMount and Sentry.config.colorMounts then
            return "<purple>"
        end
        
        return defaultColor

    elseif category == "item" then
        return defaultColor
    end

    return defaultColor
end

-- =========================================================================
-- 4. UI UPDATER
-- =========================================================================
function Sentry.updateUI()
    if not Sentry.console then return end
    Sentry.console:clear()

    local function tableHasContents(t)
        for _ in pairs(t) do return true end
        return false
    end

    local isFirstSection = true

    -- SECTION 0: ROOM NAME
    if gmcp and gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.name then
        local headerText = gmcp.Room.Info.name
        if Sentry.isGlanced then headerText = headerText .. " <white>(Glanced)" end
        
        Sentry.console:cecho("<white>== Location ==<reset>\n")
        Sentry.console:cecho("<white><yellow>" .. headerText .."<white><reset>\n")
        isFirstSection = false
    end

    -- SECTION 1: PLAYERS
    if tableHasContents(Sentry.players) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<cyan>=== PLAYERS ===<reset>\n")
        for name, p in pairs(Sentry.players) do
            local tCmd = Sentry.config.targetCmd .. name
            local pCmd = Sentry.config.probeCmd .. name
            local pColor = Sentry.getColor("player", name, nil, "<cyan>")
            
            Sentry.console:cecho("<white>[")
            Sentry.console:cechoLink("<red>T", [[send("]]..tCmd..[[", false)]], "Target " .. name, true)
            if not Sentry.isGlanced then
                Sentry.console:cecho("<white>|")
                Sentry.console:cechoLink("<DodgerBlue>P", [[send("]]..pCmd..[[", false)]], "Probe " .. name, true)
            end
            Sentry.console:cecho("<white>] " .. pColor .. name .. "<reset>\n")
        end
        isFirstSection = false
    end

    -- SECTION 2: DENIZENS
    if tableHasContents(Sentry.denizens) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<yellow>=== DENIZENS ===<reset>\n")
        
        local sortedDenizens = {}
        for id, d in pairs(Sentry.denizens) do table.insert(sortedDenizens, d) end
        table.sort(sortedDenizens, function(a, b)
            local aLoyal = Sentry.config.myLoyals[tostring(a.id)] == true
            local bLoyal = Sentry.config.myLoyals[tostring(b.id)] == true
            if aLoyal and not bLoyal then return true end
            if bLoyal and not aLoyal then return false end
            return a.name < b.name
        end)

        for _, d in ipairs(sortedDenizens) do
            local readableTarget = Sentry.formatTarget(d.name, d.id)
            local tCmd = Sentry.config.targetCmd .. readableTarget
            local pCmd = Sentry.config.probeCmd .. readableTarget
            local dColor = Sentry.getColor("denizen", d.name, d.id, "<yellow>")
            
            local suffix = ""
            if Sentry.config.myLoyals[tostring(d.id)] then suffix = " <white>(Loyal)" end
            
            Sentry.console:cecho("<white>[")
            Sentry.console:cechoLink("<red>T", [[send("]]..tCmd..[[", false)]], "Target " .. d.name, true)
            if not Sentry.isGlanced then
                Sentry.console:cecho("<white>|")
                Sentry.console:cechoLink("<DodgerBlue>P", [[send("]]..pCmd..[[", false)]], "Probe " .. d.name, true)
            end
            Sentry.console:cecho("<white>] " .. dColor .. d.name .. suffix .. "<reset>\n")
        end
        isFirstSection = false
    end

    -- SECTION 3: ITEMS
    if tableHasContents(Sentry.items) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<green>=== ITEMS ===<reset>\n")
        
        local sortedItems = {}
        for id, i in pairs(Sentry.items) do table.insert(sortedItems, i) end
        table.sort(sortedItems, function(a, b) return a.name < b.name end)

        for _, i in ipairs(sortedItems) do
            local readableTarget = Sentry.formatTarget(i.name, i.id)
            local gCmd = Sentry.config.getCmd .. readableTarget
            local pCmd = Sentry.config.probeCmd .. readableTarget
            local iColor = Sentry.getColor("item", i.name, i.id, "<green>")
            
            local suffix = ""
            if i.direction then suffix = " <white>(" .. i.direction:upper() .. ")" end
            
            if not Sentry.isGlanced then
                Sentry.console:cecho("<white>[")
                Sentry.console:cechoLink("<gold>G", [[send("]]..gCmd..[[", false)]], "Get " .. i.name, true)
                Sentry.console:cecho("<white>|")
                Sentry.console:cechoLink("<DodgerBlue>P", [[send("]]..pCmd..[[", false)]], "Probe " .. i.name, true)
                Sentry.console:cecho("<white>] ")
            else
                Sentry.console:cecho("<white>[<grey>-<white>] ")
            end
            Sentry.console:cecho(iColor .. i.name .. suffix .. "<reset>\n")
        end
        isFirstSection = false
    end

    -- SECTION 4: CLOTHING
    if tableHasContents(Sentry.clothing) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<plum>=== CLOTHING ===<reset>\n")
        
        local sortedClothing = {}
        for id, c in pairs(Sentry.clothing) do table.insert(sortedClothing, c) end
        table.sort(sortedClothing, function(a, b) return a.name < b.name end)

        for _, c in ipairs(sortedClothing) do
            local readableTarget = Sentry.formatTarget(c.name, c.id)
            local gCmd = Sentry.config.getCmd .. readableTarget
            local pCmd = Sentry.config.probeCmd .. readableTarget
            
            if not Sentry.isGlanced then
                Sentry.console:cecho("<white>[")
                Sentry.console:cechoLink("<gold>G", [[send("]]..gCmd..[[", false)]], "Get " .. c.name, true)
                Sentry.console:cecho("<white>|")
                Sentry.console:cechoLink("<DodgerBlue>P", [[send("]]..pCmd..[[", false)]], "Probe " .. c.name, true)
                Sentry.console:cecho("<white>] ")
            else
                Sentry.console:cecho("<white>[<grey>-<white>] ")
            end
            Sentry.console:cecho("<plum>" .. c.name .. "<reset>\n")
        end
        isFirstSection = false
    end

    -- SECTION 5: FURNITURE
    if tableHasContents(Sentry.furniture) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<grey>=== FURNITURE ===<reset>\n")
        
        local sortedFurn = {}
        for id, f in pairs(Sentry.furniture) do table.insert(sortedFurn, f) end
        table.sort(sortedFurn, function(a, b) return a.name < b.name end)

        for _, f in ipairs(sortedFurn) do
            local readableTarget = Sentry.formatTarget(f.name, f.id)
            local pCmd = Sentry.config.probeCmd .. readableTarget
            
            if not Sentry.isGlanced then
                Sentry.console:cecho("<white>[")
                Sentry.console:cechoLink("<DodgerBlue>P", [[send("]]..pCmd..[[", false)]], "Probe " .. f.name, true)
                Sentry.console:cecho("<white>] ")
            else
                Sentry.console:cecho("<white>[<grey>-<white>] ")
            end
            Sentry.console:cecho("<LightSlateGrey>" .. f.name .. "<reset>\n")
        end
        isFirstSection = false
    end

    -- SECTION 6: EFFECTS
    if tableHasContents(Sentry.effects) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<magenta>=== EFFECTS ===<reset>\n")
        
        local sortedEffects = {}
        for id, data in pairs(Sentry.effects) do table.insert(sortedEffects, {id = id, data = data}) end
        table.sort(sortedEffects, function(a, b) return a.data.name < b.data.name end)

        for _, effect in ipairs(sortedEffects) do
            local data = effect.data
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
                if data.flamed then
                    Sentry.console:cecho("<white>[<red>X<white>] <" .. data.color .. ">" .. data.name .. suffix .. " <red>(Flamed)<reset>\n")
                else
                    local gCmd = Sentry.config.getCmd .. readableTarget
                    Sentry.console:cecho("<white>[")
                    Sentry.console:cechoLink("<gold>G", [[send("]]..gCmd..[[", false)]], "Get " .. data.item.name, true)
                    Sentry.console:cecho("<white>] <" .. data.color .. ">" .. data.name .. suffix .. "<reset>\n")
                end
            else
                Sentry.console:cecho("<white>[<" .. data.color .. ">~<white>] <" .. data.color .. ">" .. data.name .. suffix .. "<reset>\n")
            end
        end
    end
    raiseEvent("Sentry.RoomUpdated")
end

-- =========================================================================
-- 5. EVENT HANDLERS (GMCP & SYSTEM)
-- =========================================================================
function Sentry.handleCommand(event, command)
    local cmdLower = command:lower():gsub("^%s+", ""):gsub("%s+$", "")
    
    if cmdLower:match("^glance%s+.+") then
        Sentry.isGlanced = true
    elseif cmdLower == "l" or cmdLower == "look" or cmdLower == "glance" or cmdLower == "ql" or cmdLower == "quicklook" or cmdLower:match("^[nsewud]$") or cmdLower:match("^[nsew][eo]$") or cmdLower == "in" or cmdLower == "out" then
        Sentry.isGlanced = false
    end
end

function Sentry.handleRoomChange(event)
    if event == "gmcp.Room.Info" then
        local currentRoom = gmcp.Room.Info.num
        
        if Sentry.lastRoom ~= currentRoom then
            Sentry.lastRoom = currentRoom
            Sentry.effects = {}
            Sentry.updateUI()
            
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
    Sentry.updateUI()
end

function Sentry.handleItems(event)
    if event == "gmcp.Char.Items.List" then
        if gmcp.Char.Items.List.location == "room" then
            Sentry.denizens = {}
            Sentry.items = {}
            Sentry.furniture = {}
            Sentry.clothing = {}
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
            Sentry.items[item.id] = nil
            Sentry.furniture[item.id] = nil
            Sentry.clothing[item.id] = nil 
            
            if Sentry.hasEffect("sigil_" .. item.id) then Sentry.removeEffect("sigil_" .. item.id) end
            if Sentry.hasEffect("totem_" .. item.id) then Sentry.removeEffect("totem_" .. item.id) end
        end
    end
    Sentry.updateUI()
    
    if Sentry.isGlanced then 
        Sentry.probeQueue = {}
        return 
    end
    
    if #Sentry.probeQueue > 0 then
        Sentry.activeProbes = Sentry.probeQueue
        Sentry.probeQueue = {} 
        
        tempTimer(0.25, function()
            Sentry.silentProbing = true
            for _, id in ipairs(Sentry.activeProbes) do
                send("probe " .. id, false)
            end
            Sentry.activeProbes = {}
            
            tempTimer(0.5, function() Sentry.silentProbing = false end)
        end)
    end
end

-- =========================================================================
-- 6. DYNAMIC TRIGGERS (Effects & Runes)
-- =========================================================================
Sentry.triggers = Sentry.triggers or {}

function Sentry.createTriggers()
    for _, id in ipairs(Sentry.triggers) do killTrigger(id) end
    Sentry.triggers = {}

    -- ==========================================
    -- LOYALS PARSER 
    -- ==========================================
    table.insert(Sentry.triggers, tempRegexTrigger("^Your loyal companions are:$", 
        [[ Sentry.parsingLoyals = true ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^You have no loyal companions\\.$", 
        [[ 
            Sentry.config.myLoyals = {} 
            Sentry.updateUI()
        ]]
    ))

    table.insert(Sentry.triggers, tempPromptTrigger(
        [[
            if Sentry.parsingLoyals then
                Sentry.parsingLoyals = false
                cecho("\n<SteelBlue>[Sentry]:<reset> <white>Loyal IDs successfully tracked!<reset>\n")
            end
        ]], 1
    ))

    table.insert(Sentry.triggers, tempPromptTrigger(
        [[
            if Sentry.parsingLoyals then
                Sentry.parsingLoyals = false
                cecho("\n<green>Sentry:<reset> Loyal IDs successfully tracked!\n")
            end
        ]], 1
    ))

    -- ==========================================
    -- SMART RUNELIST PARSER 
    -- ==========================================
    table.insert(Sentry.triggers, tempRegexTrigger("Type.+Owner", 
        [[ 
            Sentry.parsingRunes = true
            Sentry.dashCount = 0
            
            for id in pairs(Sentry.effects) do
                if id:find("^rune_") then Sentry.effects[id] = nil end
            end
            
            if type(Sentry.silentRunelist) == "number" and Sentry.silentRunelist > 0 then 
                deleteLine() 
            end 
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("-{20,}", 
        [[
            if Sentry.parsingRunes then
                Sentry.dashCount = Sentry.dashCount + 1
                
                if type(Sentry.silentRunelist) == "number" and Sentry.silentRunelist > 0 then 
                    deleteLine() 
                end
                
                if Sentry.dashCount == 2 then
                    Sentry.parsingRunes = false
                    if type(Sentry.silentRunelist) == "number" and Sentry.silentRunelist > 0 then
                        Sentry.silentRunelist = Sentry.silentRunelist - 1
                    end
                end
            end
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^A rune (?:resembling|like|shaped like) a[n]? (.+?)\\s{2,}(\\w+)", 
        [[
            if Sentry.parsingRunes then
                if type(Sentry.silentRunelist) == "number" and Sentry.silentRunelist > 0 then 
                    deleteLine() 
                end
                
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
            Sentry.updateUI()
            
            if type(Sentry.silentRunelist) == "number" and Sentry.silentRunelist > 0 then 
                deleteLine()
                Sentry.silentRunelist = Sentry.silentRunelist - 1 
            end 
        ]]
    ))

    -- ==========================================
    -- SKETCHING & SMUDGING (Live Updates)
    -- ==========================================
    table.insert(Sentry.triggers, tempRegexTrigger("^You begin sketching an? \\w+ rune on the ground\\.$", [[]]))

    table.insert(Sentry.triggers, tempRegexTrigger("^With a flourish, you finish sketching an? \\w+ rune\\.$", 
        [[ Sentry.silentRunelist = Sentry.silentRunelist + 1; send("runelist", false) ]]
    ))
    
    table.insert(Sentry.triggers, tempRegexTrigger("^You smudge the \\w+ rune off the ground\\.$", 
        [[ Sentry.silentRunelist = Sentry.silentRunelist + 1; send("runelist", false) ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^(\\w+) sketches a rune.*$", 
        [[ Sentry.silentRunelist = Sentry.silentRunelist + 1; send("runelist", false) ]]
    ))
    table.insert(Sentry.triggers, tempRegexTrigger("^(\\w+) smudges a rune.*$", 
        [[ Sentry.silentRunelist = Sentry.silentRunelist + 1; send("runelist", false) ]]
    ))

    -- ==========================================
    -- WALL SPAWN & PROBE PARSER
    -- ==========================================
    table.insert(Sentry.triggers, tempRegexTrigger("^A wall of .* rises from the earth to block the exit to the (\\w+)\\.$", 
        [[
            local dir = matches[2]
            for id, item in pairs(Sentry.items) do
                if item.name:lower():find("wall of") and not item.direction then
                    Sentry.items[id].direction = dir
                    Sentry.updateUI()
                    break
                end
            end
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^A (?:large )?wall of .* stands here, blocking passage to the (\\w+)\\.$", 
        [[
            local dir = matches[2]
            for id, item in pairs(Sentry.items) do
                if item.name:lower():find("wall of") and not item.direction then
                    Sentry.items[id].direction = dir
                    Sentry.updateUI()
                    break
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
                    Sentry.items[id].direction = dir
                    Sentry.updateUI()
                    break
                end
            end
            if Sentry.silentProbing then deleteLine() end
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^This .* looks to be made of .*$", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^This .* wall is made of .*$", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^It towers above you.*$", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^It weighs about .* pounds\\.$", [[ if Sentry.silentProbing then deleteLine() end ]] ))

    -- ==========================================
    -- TOTEM PROBE PARSER 
    -- ==========================================
    table.insert(Sentry.triggers, tempRegexTrigger("^It has the following runes sketched upon it:$", 
        [[ if Sentry.silentProbing then deleteLine() end ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("is sketched in(?:to)? slot", 
        [[
            if Sentry.silentProbing then deleteLine() end
            
            local lineLower = line:lower()
            local runeName = nil
            
            for key, data in pairs(Sentry.runeData) do
                local searchKey = key
                if key == "stickman" then searchKey = "stick man" end
                if key == "upwards-pointing arrow" then searchKey = "upward-pointing arrow" end
                
                if lineLower:find(searchKey) then
                    runeName = data.name
                    break
                end
            end
            
            if runeName then
                for id, effect in pairs(Sentry.effects) do
                    if id:find("^totem_") then
                        effect.item.runes = effect.item.runes or {}
                        effect.item.runes[runeName] = (effect.item.runes[runeName] or 0) + 1
                        Sentry.updateUI()
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
    
    -- ==========================================
    -- SIGIL PROBE PARSER & TRAPS
    -- ==========================================
    table.insert(Sentry.triggers, tempRegexTrigger("^There is a flame-shaped sigil attached\\.", 
        [[
            if Sentry.silentProbing then deleteLine() end
            
            for id, effect in pairs(Sentry.effects) do
                if id:find("^sigil_") and not effect.flamed then
                    Sentry.effects[id].flamed = true
                    Sentry.updateUI()
                    break
                end
            end
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^You quickly pull your hand back as a flame sigil on an? (.*?) singes your fingers\\.$", 
        [[
            local targetName = matches[2]:lower()
            for id, effect in pairs(Sentry.effects) do
                if id:find("^sigil_") and effect.item.name:lower():find(targetName) then
                    Sentry.effects[id].flamed = true
                    Sentry.updateUI()
                    break
                end
            end
        ]]
    ))

    table.insert(Sentry.triggers, tempRegexTrigger("^Made (?:of|from) .*, .* sigil.*", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^It weighs \\d+ ounce\\(s\\)\\.$", [[ if Sentry.silentProbing then deleteLine() end ]] ))

    -- ==========================================
    -- ENVIRONMENTAL EFFECTS
    -- ==========================================
    table.insert(Sentry.triggers, tempRegexTrigger("^The air is filled with a humming vibration\\.$", 
        [[ Sentry.addEffect("vibrations", "Humming Vibrations", "magenta") ]]
    ))
    table.insert(Sentry.triggers, tempRegexTrigger("^The humming vibration in the air fades away\\.$", 
        [[ Sentry.removeEffect("vibrations") ]]
    ))
    table.insert(Sentry.triggers, tempRegexTrigger("^A roaring wall of fire erupts.*$", 
        [[ Sentry.addEffect("fire", "Roaring Fire", "orange_red") ]]
    ))
    table.insert(Sentry.triggers, tempRegexTrigger("^The wall of fire burns out and disappears\\.$", 
        [[ Sentry.removeEffect("fire") ]]
    ))
    table.insert(Sentry.triggers, tempRegexTrigger("^The area is flooded with water\\.$", 
        [[ Sentry.addEffect("flood", "Flooded", "blue") ]]
    ))
    table.insert(Sentry.triggers, tempRegexTrigger("^The floodwaters recede\\.$", 
        [[ Sentry.removeEffect("flood") ]]
    ))
end

-- =========================================================================
-- 7. COMMAND INTERFACE & ALIASES
-- =========================================================================
function Sentry.toggle()
    Sentry.config.visible = not Sentry.config.visible
    
    if Sentry.config.visible then
        Sentry.container:show()
        cecho("\n<SteelBlue>[Sentry]:<reset> <white>GUI is now <gold>VISIBLE<white>.<reset>\n")
    else
        Sentry.container:hide()
        cecho("\n<SteelBlue>[Sentry]:<reset> <white>GUI is now <gold>HIDDEN<white>.<reset>\n")
    end
end

function Sentry.showHelp()
    cecho("\n<SteelBlue>=======================================================================<reset>")
    cecho("\n<SteelBlue>                         S E N T R Y   H E L P                         <reset>")
    cecho("\n<SteelBlue>=======================================================================<reset>\n")
    cecho("\n<white>Sentry is a tactical combat and situational awareness UI. It filters<reset>")
    cecho("\n<white>and organizes room data, providing interactive links while silencing<reset>")
    cecho("\n<white>spammy environment and hazard descriptions.<reset>\n")

    cecho("\n<LightSkyBlue>In-Game Commands:<reset>")
    cecho("\n  <gold>sentry help<reset>    - Displays this help menu.")
    cecho("\n  <gold>sentry toggle<reset>  - Toggles hiding or showing the Sentry UI window.")
    cecho("\n  <gold>sentry loyals<reset>  - Scans and tracks your loyal companions (adds cyan tint).")
    
    cecho("\n\n<LightSkyBlue>Configuration:<reset>")
    cecho("\n  <white>Most permanent changes (like adding new clothing or furniture sorting<reset>")
    cecho("\n  <white>keywords, changing command prefixes, or toggling NDB colors) are made<reset>")
    cecho("\n  <white>by editing the <gold>Sentry.config<white> block at the top of the script.<reset>\n")

    cecho("\n<SteelBlue>=======================================================================<reset>\n")
end

function Sentry.handleUserCommand(args)
    local cmd = args:lower():match("^%s*(.-)%s*$")
    
    if cmd == "help" or cmd == "" then
        Sentry.showHelp()
    elseif cmd == "toggle" then
        Sentry.toggle()
    elseif cmd == "loyals" then
        cecho("\n<SteelBlue>[Sentry]:<reset> <white>Updating loyal companions...<reset>\n")
        Sentry.config.myLoyals = {} 
        send("loyals", false) 
    else
        cecho("\n<SteelBlue>[Sentry]:<reset> <white>Unknown command. Type <gold>sentry help<white> for options.<reset>\n")
    end
end

-- Master Alias: Route all user commands to the handler
if Sentry.aliasHandler then killAlias(Sentry.aliasHandler) end
Sentry.aliasHandler = tempAlias("^sentry(?: (.*))?$", [[
    local args = matches[2] or "help"
    Sentry.handleUserCommand(args)
]])

-- Ensure the UI matches the initial config state when the script first loads
if Sentry.config.visible then
    Sentry.container:show()
else
    Sentry.container:hide()
end

-- =========================================================================
-- 8. EVENT REGISTRATION
-- =========================================================================
Sentry.events = Sentry.events or {}

for _, handler in ipairs(Sentry.events) do
    killAnonymousEventHandler(handler)
end
Sentry.events = {}

table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Room.Info", "Sentry.handleRoomChange"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Room.Players", "Sentry.handlePlayers"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Room.AddPlayer", "Sentry.handlePlayers"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Room.RemovePlayer", "Sentry.handlePlayers"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Char.Items.List", "Sentry.handleItems"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Char.Items.Add", "Sentry.handleItems"))
table.insert(Sentry.events, registerAnonymousEventHandler("gmcp.Char.Items.Remove", "Sentry.handleItems"))
table.insert(Sentry.events, registerAnonymousEventHandler("sysDataSendRequest", "Sentry.handleCommand"))

Sentry.createTriggers()
Sentry.updateUI()