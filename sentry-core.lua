-- =========================================================================
-- 1. NAMESPACE, VARIABLES & CONFIG
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

-- =========================================================================
-- 1. CONFIGURATION
-- =========================================================================
Sentry.config.targetCmd = "settarget " 
Sentry.config.getCmd = "get "
Sentry.config.probeCmd = "probe "
Sentry.config.visible = true

Sentry.config.useNDBColors = true
Sentry.config.colorMounts = false
Sentry.config.myLoyals = Sentry.config.myLoyals or {}

Sentry.config.furnitureKeywords = {
    "bed", "dresser", "table", "statue", "chair", "desk", "rug", "tapestry",
    "cabinet", "sofa", "bench, stool", "shelf", "couch", "chandelier", "altar",
    "throne", "coffin", "fireplace",
}

Sentry.config.clothingKeywords = {
    "boots", "sandals", "shoes", "blouse", "shirt", "tunic",
    "trousers", "pants", "skirt", "bra", "panties", "underwear",
    "cloak", "cape", "robe", "gloves", "gauntlets", "hat", "helmet", "belt",
    "dress", "vest", "gown", "corset", "socks", "stockings", "jacket", "coat"
}

-- =========================================================================
-- RUNE DICTIONARY
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

-- State variables for the runelist parser
Sentry.parsingRunes = false
Sentry.dashCount = 0

-- =========================================================================
-- 2. GEYSER UI CREATION
-- =========================================================================
Sentry.container = Sentry.container or Geyser.Container:new({
    name = "SentryContainer",
    x = 0, y = "-50%",                  -- Anchored to the bottom left
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
        local isFurniture = false
        local isClothing = false
        local nameLower = item.name:lower()
        
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
        
        -- UPDATED: Added 'not item.runes' to prevent infinite totem probing
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

function Sentry.addEffect(id, displayName, color)
    color = color or "white"
    Sentry.effects[id] = { name = displayName, color = color }
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
-- UPDATED: Added 'id' argument to check against our loyals list
function Sentry.getColor(category, name, id, defaultColor)
    -- PLAYERS
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

    -- DENIZENS
    elseif category == "denizen" then
        -- Check if it's one of your specific loyals first
        if id and Sentry.config.myLoyals[tostring(id)] then
            return "<cyan>" -- Gives your loyals a friendly blue color
        end
        
        local nameLower = name:lower()
        local isLegendaryMount = nameLower:find("pegasus") or nameLower:find("griffon") or nameLower:find("dragon")
        
        if isLegendaryMount and Sentry.config.colorMounts then
            return "<purple>"
        end
        
        return defaultColor

    -- ITEMS
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
        Sentry.console:cecho("<white>== Location ==<reset>\n")
        Sentry.console:cecho("<white><yellow>" .. gmcp.Room.Info.name .."<white><reset>\n")
        isFirstSection = false
    end

    -- SECTION 1: PLAYERS
    if tableHasContents(Sentry.players) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<cyan>=== PLAYERS ===<reset>\n")
        for name, p in pairs(Sentry.players) do
            local tCmd = Sentry.config.targetCmd .. name
            local pCmd = Sentry.config.probeCmd .. name
            
            -- Pass nil for ID since players don't use them here
            local pColor = Sentry.getColor("player", name, nil, "<cyan>")
            
            Sentry.console:cechoLink("<white>[<red>T<white>]", [[send("]]..tCmd..[[", false)]], "Target " .. name, true)
            Sentry.console:cechoLink("<white>[<DodgerBlue>P<white>]", [[send("]]..pCmd..[[", false)]], "Probe " .. name, true)
            Sentry.console:cecho(" " .. pColor .. name .. "<reset>\n")
        end
        isFirstSection = false
    end

    -- SECTION 2: DENIZENS (UPDATED FOR LOYALS)
    if tableHasContents(Sentry.denizens) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<yellow>=== DENIZENS ===<reset>\n")
        
        -- Convert to array for sorting
        local sortedDenizens = {}
        for id, d in pairs(Sentry.denizens) do
            table.insert(sortedDenizens, d)
        end
        
        -- Sort: Loyals first, then alphabetical
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
            
            -- Pass the ID to the color router
            local dColor = Sentry.getColor("denizen", d.name, d.id, "<yellow>")
            
            -- Append a text tag so they stand out clearly
            local suffix = ""
            if Sentry.config.myLoyals[tostring(d.id)] then
                suffix = " <white>(Loyal)"
            end
            
            Sentry.console:cechoLink("<white>[<red>T<white>]", [[send("]]..tCmd..[[", false)]], "Target " .. d.name, true)
            Sentry.console:cechoLink("<white>[<DodgerBlue>P<white>]", [[send("]]..pCmd..[[", false)]], "Probe " .. d.name, true)
            Sentry.console:cecho(" " .. dColor .. d.name .. suffix .. "<reset>\n")
        end
        isFirstSection = false
    end

    -- SECTION 3: ITEMS
    if tableHasContents(Sentry.items) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<green>=== ITEMS ===<reset>\n")
        
        local sortedItems = {}
        for id, i in pairs(Sentry.items) do
            table.insert(sortedItems, i)
        end
        
        table.sort(sortedItems, function(a, b)
            local aMono = a.name:lower():find("monolith") ~= nil
            local bMono = b.name:lower():find("monolith") ~= nil
            if aMono and not bMono then return true end
            if bMono and not aMono then return false end
            return a.name < b.name
        end)

        for _, i in ipairs(sortedItems) do
            local readableTarget = Sentry.formatTarget(i.name, i.id)
            local gCmd = Sentry.config.getCmd .. readableTarget
            local pCmd = Sentry.config.probeCmd .. readableTarget
            
            local iColor = Sentry.getColor("item", i.name, i.id, "<green>")
            if i.name:lower():find("monolith") then iColor = "<red>" end
            
            local suffix = ""
            
            -- Direction Suffix (for walls)
            if i.direction then 
                suffix = suffix .. " <white>(" .. i.direction:upper() .. ")" 
            end
            
            -- Rune Suffix (for totems)
            if i.runes then
                local runeStrings = {}
                for runeName, count in pairs(i.runes) do
                    if count > 1 then
                        table.insert(runeStrings, runeName .. "x" .. count)
                    else
                        table.insert(runeStrings, runeName)
                    end
                end
                
                if #runeStrings > 0 then
                    table.sort(runeStrings) -- Alphabetize the runes for quick reading
                    suffix = suffix .. " <cyan>(" .. table.concat(runeStrings, ", ") .. ")"
                end
            end
            
            Sentry.console:cechoLink("<white>[<gold>G<white>]", [[send("]]..gCmd..[[", false)]], "Get " .. i.name, true)
            Sentry.console:cechoLink("<white>[<DodgerBlue>P<white>]", [[send("]]..pCmd..[[", false)]], "Probe " .. i.name, true)
            Sentry.console:cecho(" " .. iColor .. i.name .. suffix .. "<reset>\n")
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
            
            -- We KEEP the Get button because dropped clothing can be picked up
            Sentry.console:cechoLink("<white>[<gold>G<white>]", [[send("]]..gCmd..[[", false)]], "Get " .. c.name, true)
            Sentry.console:cechoLink("<white>[<DodgerBlue>P<white>]", [[send("]]..pCmd..[[", false)]], "Probe " .. c.name, true)
            Sentry.console:cecho(" <plum>" .. c.name .. "<reset>\n")
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
            
            -- We skip the Get button because furniture cannot be picked up
            Sentry.console:cechoLink("<white>[<DodgerBlue>P<white>]", [[send("]]..pCmd..[[", false)]], "Probe " .. f.name, true)
            Sentry.console:cecho(" <LightSlateGrey>" .. f.name .. "<reset>\n")
        end
        isFirstSection = false
    end

    -- SECTION 6: EFFECTS
    if tableHasContents(Sentry.effects) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<magenta>=== EFFECTS ===<reset>\n")
        for id, data in pairs(Sentry.effects) do
            Sentry.console:cecho("<white>[<" .. data.color .. ">~<white>] <" .. data.color .. ">" .. data.name .. "<reset>\n")
        end
    end
end

-- =========================================================================
-- 5. EVENT HANDLERS (GMCP)
-- =========================================================================
function Sentry.handleRoomChange(event)
    if event == "gmcp.Room.Info" then
        local currentRoom = gmcp.Room.Info.num
        
        -- Only wipe effects and check runes if we ACTUALLY changed rooms
        if Sentry.lastRoom ~= currentRoom then
            Sentry.lastRoom = currentRoom
            
            Sentry.effects = {}
            Sentry.updateUI()
            
            if type(Sentry.silentRunelist) ~= "number" then Sentry.silentRunelist = 0 end
            Sentry.silentRunelist = Sentry.silentRunelist + 1
            send("runelist", false)
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
            Sentry.furniture = {} -- Clear furniture on room load
            Sentry.clothing = {} -- Clear clothing on room load
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
            Sentry.furniture[item.id] = nil -- Remove furniture if destroyed
            Sentry.clothing[item.id] = nil -- Remove clothing if destroyed/taken
        end
    end
    Sentry.updateUI()
    
    -- Process the probe queue SAFELY after the room prompt clears
    if #Sentry.probeQueue > 0 then
        -- Copy the queue into a temporary table so we can clear the main one
        Sentry.activeProbes = Sentry.probeQueue
        Sentry.probeQueue = {} 
        
        tempTimer(0.25, function()
            Sentry.silentProbing = true
            for _, id in ipairs(Sentry.activeProbes) do
                send("probe " .. id, false)
            end
            Sentry.activeProbes = {}
            
            -- Turn it off when the NEXT prompt (the probe response) arrives
            tempPromptTrigger(function() Sentry.silentProbing = false end, 1)
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
    -- LOYALS PARSER (Manual/Login update)
    -- ==========================================
    -- Catch the header to turn on the parser
    table.insert(Sentry.triggers, tempRegexTrigger("^Your loyal companions are:$", 
        [[ Sentry.parsingLoyals = true ]]
    ))

    -- Catch the "empty" response just in case
    table.insert(Sentry.triggers, tempRegexTrigger("^You have no loyal companions\\.$", 
        [[ 
            Sentry.config.myLoyals = {} 
            Sentry.updateUI()
        ]]
    ))

    -- Parse the individual loyal lines
    -- Matches: "a pristine white falcon481629 is at (house) Private sleeping quarters."
    table.insert(Sentry.triggers, tempRegexTrigger("^(.*?)(\\d+) is at .*\\.$", 
        [[
            if Sentry.parsingLoyals then
                -- matches[3] is the ID (the digits)
                local id = matches[3]
                Sentry.config.myLoyals[tostring(id)] = true
                
                -- Force a UI update so they immediately turn cyan if they are in the room!
                Sentry.updateUI()
            end
        ]]
    ))

    -- Use the prompt to close the parser
    table.insert(Sentry.triggers, tempPromptTrigger(
        [[
            if Sentry.parsingLoyals then
                Sentry.parsingLoyals = false
                cecho("\n<green>Sentry:<reset> Loyal IDs successfully tracked!\n")
            end
        ]], 1
    ))

    -- ==========================================
    -- SMART RUNELIST PARSER (Debug Mode)
    -- ==========================================
    -- 1. Catch the Header (Stripped anchors)
    table.insert(Sentry.triggers, tempRegexTrigger("Type.+Owner", 
        [[ 
            Sentry.parsingRunes = true
            Sentry.dashCount = 0
            if type(Sentry.silentRunelist) == "number" and Sentry.silentRunelist > 0 then 
                deleteLine() 
            end 
        ]]
    ))

    -- 2. Catch the Dashes
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

    -- 3. Catch and Parse the Rune Line (Fixed greedy match)
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

    -- 4. Catch the "Empty" Runelist Response (Stripped anchors)
    table.insert(Sentry.triggers, tempRegexTrigger("You find no runes", 
        [[ 
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
    
    table.insert(Sentry.triggers, tempRegexTrigger("^(\\w+) sketches a rune.*$", 
        [[ Sentry.silentRunelist = Sentry.silentRunelist + 1; send("runelist", false) ]]
    ))
    table.insert(Sentry.triggers, tempRegexTrigger("^(\\w+) smudges a rune.*$", 
        [[ Sentry.silentRunelist = Sentry.silentRunelist + 1; send("runelist", false) ]]
    ))

    -- ==========================================
    -- WALL SPAWN & PROBE PARSER
    -- ==========================================
    -- INSTANT DIRECTION: Catch the wall rising and immediately assign it
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

    -- BACKUP DIRECTION: Catch direction via Look/Probe
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

    -- GAGS: Stone Wall, Ice Wall, Weight, and Description Strings
    table.insert(Sentry.triggers, tempRegexTrigger("^This .* looks to be made of .*$", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^This .* wall is made of .*$", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^It towers above you.*$", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^It weighs about .* pounds\\.$", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempPromptTrigger([[ Sentry.silentProbing = false ]], 1))

    -- ==========================================
    -- TOTEM PROBE PARSER (Native Achaea Text)
    -- ==========================================
    -- 1. Catch the native header
    table.insert(Sentry.triggers, tempRegexTrigger("^It has the following runes sketched upon it:$", 
        [[ if Sentry.silentProbing then deleteLine() end ]]
    ))

    -- 2. Catch the native slot lines and count them
    table.insert(Sentry.triggers, tempRegexTrigger("is sketched into slot", 
        [[
            -- Gag it immediately if we are silently probing
            if Sentry.silentProbing then deleteLine() end
            
            local lineLower = line:lower()
            local runeName = nil
            
            -- Scan the raw line against our rune dictionary
            for key, data in pairs(Sentry.runeData) do
                -- Account for slight text variations between your runelist and totem descriptions
                local searchKey = key
                if key == "stickman" then searchKey = "stick man" end
                if key == "upwards-pointing arrow" then searchKey = "upward-pointing arrow" end
                
                if lineLower:find(searchKey) then
                    runeName = data.name
                    break
                end
            end
            
            if runeName then
                for id, item in pairs(Sentry.items) do
                    if item.name:lower():find("totem") then
                        Sentry.items[id].runes = Sentry.items[id].runes or {}
                        Sentry.items[id].runes[runeName] = (Sentry.items[id].runes[runeName] or 0) + 1
                        Sentry.updateUI()
                        break 
                    end
                end
            end
        ]]
    ))

    -- 3. Gag all the extra ownership and status spam
    table.insert(Sentry.triggers, tempRegexTrigger("^It is tuned against.*", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^It bears the distinctive mark of.*", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^You may use this item to parry with\\.", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^This totem is the property of.*", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^The totem is currently empowered.*", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    table.insert(Sentry.triggers, tempRegexTrigger("^It has \\d+ months of usefulness left\\.", [[ if Sentry.silentProbing then deleteLine() end ]] ))
    
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
-- 7. VISIBILITY TOGGLE & ALIAS
-- =========================================================================
function Sentry.toggle()
    Sentry.config.visible = not Sentry.config.visible
    
    if Sentry.config.visible then
        Sentry.container:show()
        cecho("\n<green>Sentry:<reset> GUI is now <green>VISIBLE<reset>.\n")
    else
        Sentry.container:hide()
        cecho("\n<green>Sentry:<reset> GUI is now <red>HIDDEN<reset>.\n")
    end
end

-- Create the dynamic alias
if Sentry.toggleAlias then killAlias(Sentry.toggleAlias) end
Sentry.toggleAlias = tempAlias("^sentry toggle$", [[ Sentry.toggle() ]])

-- NEW: Create the dynamic alias for updating loyals
if Sentry.loyalsAlias then killAlias(Sentry.loyalsAlias) end
Sentry.loyalsAlias = tempAlias("^sentry loyals$", 
    [[ 
        cecho("\n<green>Sentry:<reset> Updating loyal companions...\n")
        Sentry.config.myLoyals = {} -- Clear the old list
        send("loyals") 
    ]]
)

-- Ensure the UI matches the initial config state when the script first loads
if Sentry.config.visible then
    Sentry.container:show()
else
    Sentry.container:hide()
end

-- =========================================================================
--8. EVENT REGISTRATION
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

Sentry.createTriggers()

Sentry.updateUI()