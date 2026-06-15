-- =========================================================================
-- SENTRY: Tactical Combat UI (v1.1.0)
-- A robust, zero-dependency situational awareness tracker for Achaea.
-- Now featuring Self Status and Target Status tracking!
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
-- 1. CONFIGURATION
-- =========================================================================
Sentry.config.targetCmd = "settarget " 
Sentry.config.getCmd = "get "
Sentry.config.probeCmd = "probe "

-- UI Visibility States
Sentry.config.mainVisible = true
Sentry.config.selfVisible = false
Sentry.config.targetVisible = false

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
-- DEFENCE & TATTOO TRACKING
-- Define which defences and tattoos you expect to maintain.
-- Expected items that drop will be highlighted in RED with a [!] warning.
-- =========================================================================
Sentry.config.expectedDefences = {
    "blindness", "deafness", "insomnia", "thirdeye", "nightsight", "rebounding"
}

Sentry.config.expectedTattoos = {
    "boartattoo", "moontattoo", "starburst", "mosstattoo"
}

-- Keywords to auto-filter unexpected/temporary tattoos into the Tattoo section
Sentry.config.tattooKeywords = {
    "tree", "moss", "boar", "moon", "shield", "chameleon", "crystal", 
    "tentacle", "hammer", "cloak", "starburst", "spider", "eye", "web", "belltattoo", "oxtattoo", "megalithtattoo"
}

-- [Rune & Sigil Data truncated for brevity, assuming standard tables from core]
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
-- Main Room UI (Right side, default)
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

-- Self Status UI (Top Left)
Sentry.selfContainer = Sentry.selfContainer or Geyser.Container:new({
    name = "SentrySelfContainer",
    x = "5px", y = 0,
    width = "300px", height = "40%",
})

Sentry.selfConsole = Sentry.selfConsole or Geyser.MiniConsole:new({
    name = "SentrySelfConsole",
    x = 0, y = 0,
    width = "100%", height = "100%",
    color = "black",
}, Sentry.selfContainer)

-- Target Status UI (Mid Left)
Sentry.targetContainer = Sentry.targetContainer or Geyser.Container:new({
    name = "SentryTargetContainer",
    x = "5px", y = "42%",
    width = "300px", height = "35%",
})

Sentry.targetConsole = Sentry.targetConsole or Geyser.MiniConsole:new({
    name = "SentryTargetConsole",
    x = 0, y = 0,
    width = "100%", height = "100%",
    color = "black",
}, Sentry.targetContainer)


-- =========================================================================
-- 3. HELPER FUNCTIONS
-- =========================================================================
-- Used to align text in our MiniConsoles (ignores color tags!)
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
    -- [Sorting logic remains identical to original Sentry script]
    if item.attrib and item.attrib:find("m") and not item.attrib:find("d") then
        Sentry.denizens[item.id] = item
    else
        local nameLower = item.name:lower()
        local isSigil, isTotem = false, false
        
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

        local isFurniture, isClothing = false, false
        for _, kw in ipairs(Sentry.config.furnitureKeywords) do
            if nameLower:find("%f[%a]" .. kw .. "%f[%A]") then isFurniture = true; break end
        end
        if not isFurniture then
            for _, kw in ipairs(Sentry.config.clothingKeywords) do
                if nameLower:find("%f[%a]" .. kw .. "%f[%A]") then isClothing = true; break end
            end
        end

        if isFurniture then Sentry.furniture[item.id] = item
        elseif isClothing then Sentry.clothing[item.id] = item
        else Sentry.items[item.id] = item end
        
        if (nameLower:find("wall of") and not item.direction) or (nameLower:find("totem") and not item.runes) then
            local inQueue = false
            for _, queuedID in ipairs(Sentry.probeQueue) do if queuedID == item.id then inQueue = true; break end end
            if not inQueue then table.insert(Sentry.probeQueue, item.id) end
        end
    end
end

-- =========================================================================
-- 4. UI UPDATERS
-- =========================================================================

-- Main Room Awareness UI
function Sentry.updateRoomUI()
    if not Sentry.console then return end
    Sentry.console:clear()

    local function tableHasContents(t)
        for _ in pairs(t) do return true end
        return false
    end
    local isFirstSection = true

    if gmcp and gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.name then
        local headerText = gmcp.Room.Info.name
        if Sentry.isGlanced then headerText = headerText .. " <white>(Glanced)" end
        Sentry.console:cecho("<white>== Location ==<reset>\n")
        Sentry.console:cecho("<white><yellow>" .. headerText .."<white><reset>\n")
        isFirstSection = false
    end

    -- [Players, Denizens, Items, Clothing, Furniture, Effects loops remain identical to original Sentry]
    if tableHasContents(Sentry.players) then
        if not isFirstSection then Sentry.console:cecho("\n") end
        Sentry.console:cecho("<cyan>=== PLAYERS ===<reset>\n")
        for name, p in pairs(Sentry.players) do
            local tCmd = Sentry.config.targetCmd .. name
            local pCmd = Sentry.config.probeCmd .. name
            Sentry.console:cecho("<white>[")
            Sentry.console:cechoLink("<red>T", [[send("]]..tCmd..[[", false)]], "Target " .. name, true)
            if not Sentry.isGlanced then
                Sentry.console:cecho("<white>|")
                Sentry.console:cechoLink("<DodgerBlue>P", [[send("]]..pCmd..[[", false)]], "Probe " .. name, true)
            end
            Sentry.console:cecho("<white>] <cyan>" .. name .. "<reset>\n")
        end
        isFirstSection = false
    end

    -- ... (Copy over the rest of the Room UI logic from your sentry-core.lua here exactly as it was) ...
end


-- =========================================================================
-- SELF STATUS UI
-- =========================================================================
function Sentry.updateSelfUI()
    if not Sentry.selfConsole then return end
    Sentry.selfConsole:clear()

    -- 1. AFFLICTIONS
    Sentry.selfConsole:cecho("<red>=== CURRENT AFFLICTIONS ===<reset>\n")
    if gmcp and gmcp.Char and gmcp.Char.Afflictions and gmcp.Char.Afflictions.List then
        local activeAffs = {}
        for _, affData in ipairs(gmcp.Char.Afflictions.List) do
            table.insert(activeAffs, affData.name:title())
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

        -- Row 1: Head / Torso
        local r1, c1 = getLimbString("Head", limbs["head"])
        local r2, c2 = getLimbString("Torso", limbs["torso"])
        Sentry.selfConsole:cecho(Sentry.padText(r1, c1, 20) .. c2 .. "\n")

        -- Row 2: Arms
        r1, c1 = getLimbString("L-Arm", limbs["left arm"])
        r2, c2 = getLimbString("R-Arm", limbs["right arm"])
        Sentry.selfConsole:cecho(Sentry.padText(r1, c1, 20) .. c2 .. "\n")

        -- Row 3: Legs
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
        
        -- Helper function to determine if a defence is actually a tattoo
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

        -- Step A: Sort everything currently active into Defs or Tattoos
        for defName, isActive in pairs(currentDefs) do
            if isActive then
                if isTattoo(defName) then
                    activeTattoos[defName:title()] = { status = "active" }
                else
                    activeDefs[defName:title()] = { status = "active" }
                end
            end
        end
        
        -- Step B: Check for expected but missing Defences
        for _, expected in ipairs(Sentry.config.expectedDefences) do
            local titleName = expected:title()
            if not activeDefs[titleName] then
                activeDefs[titleName] = { status = "missing" }
            end
        end
        
        -- Step C: Check for expected but missing Tattoos
        for _, expected in ipairs(Sentry.config.expectedTattoos) do
            local titleName = expected:title()
            if not activeTattoos[titleName] then
                activeTattoos[titleName] = { status = "missing" }
            end
        end
        
        -- Step D: Reusable rendering function for our 2-column layout
        local function renderSection(title, color, dataTable)
            Sentry.selfConsole:cecho("\n<" .. color .. ">=== " .. title .. " ===<reset>\n")
            
            local sortedKeys = {}
            for k, _ in pairs(dataTable) do table.insert(sortedKeys, k) end
            table.sort(sortedKeys)
            
            if #sortedKeys == 0 then
                Sentry.selfConsole:cecho("<grey>None<reset>\n")
                return
            end
            
            for i = 1, #sortedKeys, 2 do
                local name1 = sortedKeys[i]
                local name2 = sortedKeys[i+1]
                
                -- Formats the item based on whether it is active or missing
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
                
                -- Pad the first column so the second column aligns perfectly
                local paddedCol1 = Sentry.padText(raw1, col1, 20)
                Sentry.selfConsole:cecho(paddedCol1 .. col2 .. "\n")
            end
        end
        
        -- Render the two distinct sections
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
    Sentry.selfConsole:cecho(string.format("<orange>=== %s'S AFFLICTIONS ===<reset>\n", targetName))
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
-- 7. COMMAND INTERFACE & ALIASES
-- =========================================================================
function Sentry.toggle(uiName)
    if uiName == "main" then
        Sentry.config.mainVisible = not Sentry.config.mainVisible
        if Sentry.config.mainVisible then Sentry.container:show(); cecho("\n<SteelBlue>[Sentry]:<reset> <white>Main UI <gold>VISIBLE<white>.<reset>\n")
        else Sentry.container:hide(); cecho("\n<SteelBlue>[Sentry]:<reset> <white>Main UI <gold>HIDDEN<white>.<reset>\n") end
    
    elseif uiName == "self" then
        Sentry.config.selfVisible = not Sentry.config.selfVisible
        if Sentry.config.selfVisible then Sentry.selfContainer:show(); cecho("\n<SteelBlue>[Sentry]:<reset> <white>Self UI <gold>VISIBLE<white>.<reset>\n")
        else Sentry.selfContainer:hide(); cecho("\n<SteelBlue>[Sentry]:<reset> <white>Self UI <gold>HIDDEN<white>.<reset>\n") end
    
    elseif uiName == "target" then
        Sentry.config.targetVisible = not Sentry.config.targetVisible
        if Sentry.config.targetVisible then Sentry.targetContainer:show(); cecho("\n<SteelBlue>[Sentry]:<reset> <white>Target UI <gold>VISIBLE<white>.<reset>\n")
        else Sentry.targetContainer:hide(); cecho("\n<SteelBlue>[Sentry]:<reset> <white>Target UI <gold>HIDDEN<white>.<reset>\n") end
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
    Sentry.handleCommand(event, command) -- From core
    Sentry.updateTargetUI()              -- From legacy target UI
end))

-- Triggers initialization left identical to Sentry core
Sentry.createTriggers()
Sentry.updateRoomUI()
Sentry.updateSelfUI()
Sentry.updateTargetUI()