
-- Char.Info.name is server-authoritative and properly cased; getCharacterName()
-- reflects whatever the user typed in Mudlet's profile dialog. Capitalize the
-- profile-name fallback so the multiplay window doesn't render lowercased rows
-- before Char.Info arrives.
local function capitalizeFirst(s)
    if not s or s == "" then return nil end
    return s:sub(1, 1):upper() .. s:sub(2)
end

local classToCode = {
    Warrior = "WAR",
    Cleric  = "CLE",
    Mage    = "MAG",
    Thief   = "THI",
}

MultiPlay = {
    myPlayerName = capitalizeFirst(getCharacterName()) or "<Unknown>",
    myClass = "<Unknown>",
    myLevel = -1,
    myGroups = {},
    myForm = {},
    myVitals = {
        hp = -1,
        maxHp = -1,
        mana = -1,
        maxMana = -1,
        br = -1,
        mv = -1,
        maxMv = -1
    },
    myBuffs = {
        sanc = 0,
        ice = 0,
        fire = 0,
    },
    -- Buff-only broadcasts can arrive before the matching full MPInfoResponse
    -- row. Keep them here and merge them into the row as soon as the full
    -- info arrives.
    pendingBuffs = {},
    eventHandlerIDs = {},
    -- Snapshot of the last broadcast payload; sendMyInfo skips the global
    -- event when nothing has changed to keep N profiles from producing N^2
    -- vitals broadcasts per round.
    lastSent = nil
}

-- Tell all others to execute a command
function MultiPlay.tellAll(command)
    echo(MultiPlay.myPlayerName .. " > All >> " .. command .. "\n")
    raiseGlobalEvent("MPTell", command)
    --raiseEvent("MPTell", command, getProfileName())
    -- could just send() it to ourself
    expandAlias(command)
end

function MultiPlay.tellPlayer(player, command)
    echo(MultiPlay.myPlayerName .. " > " .. player .. " >> " .. command .. "\n")
    raiseGlobalEvent("MPTellPlayer", player, command)
    raiseEvent("MPTellPlayer", player, command, getProfileName())
end

function MultiPlay.tellGroup(group, command)
    if MultiPlay.myGroups[group] then
        echo(MultiPlay.myPlayerName .. " > Grp:" .. group .. " >> " .. command .. "\n")
        for _, player in ipairs(MultiPlay.myGroups[group]) do
            raiseGlobalEvent("MPTellPlayer", player, command)
            raiseEvent("MPTellPlayer", player, command, getProfileName())
        end
    end
end

-- The TellOthers alias regex (^\-(.*)$) also matches class-prefix lines like
-- "-m stat", so Mudlet fires both TellClass and TellOthers for the same input.
-- TellClass runs first (earlier in aliases.json) and sets this flag; tellOthers
-- clears it and bails out so the class command isn't double-sent to everyone.
function MultiPlay.tellOthers(command)
    if MultiPlay._suppressTellOthers then
        MultiPlay._suppressTellOthers = false
        return
    end
    echo(MultiPlay.myPlayerName .. " > Others >> " .. command .. "\n")
    raiseGlobalEvent("MPTell", command)
end

function MultiPlay.tellClass(class, command)
    local classStr
    if class == "w" then
        classStr = "Warrior"
    elseif class == "m" then
        classStr = "Mage"
    elseif class == "t" then
        classStr = "Thief"
    else
        classStr = "Cleric"
    end
    echo(MultiPlay.myPlayerName .. " > " .. classStr .. " >> " .. command .. "\n")
    raiseGlobalEvent("MPTellClass", classStr, command)
    MultiPlay._suppressTellOthers = true
end

function MultiPlay.requestInfo()
    raiseGlobalEvent("MPRequestInfo")
end

local function persistGroups()
    if MedUI and MedUI.saveOptions and MedUI.options and MedUI.options.mpGroups then
        MedUI.saveOptions(true)
    end
end

function MultiPlay.addGroup(group)
    if not MultiPlay.myGroups[group] then
        MultiPlay.myGroups[group] = {}
        persistGroups()
    end
end

function MultiPlay.addToGroup(group, player)
    MultiPlay.addGroup(group)
    if not player or player == "" then return end

    -- Store names in canonical (capitalized) form. Evict any differently-cased
    -- entry for the same player so a row added pre-Char.Info doesn't linger.
    local canonical = capitalizeFirst(player) or player
    local list = MultiPlay.myGroups[group]
    local key = canonical:lower()
    for i = #list, 1, -1 do
        if list[i]:lower() == key then
            table.remove(list, i)
        end
    end
    table.insert(list, canonical)
    persistGroups()
end

function MultiPlay.removeFromGroup(group, player)
    local list = MultiPlay.myGroups[group]
    if not list or not player then return false end
    local key = player:lower()
    for i = #list, 1, -1 do
        if list[i]:lower() == key then
            table.remove(list, i)
            persistGroups()
            return true
        end
    end
    return false
end

function MultiPlay.showGroups()
    for group, players in pairs(MultiPlay.myGroups) do
        echo("Group: " .. group .. "\n")
        for _, player in ipairs(players) do
            echo("  - " .. player .. "\n")
        end
    end
end


-- Track the three high-value defensive affects for MultiPlay. GMCP delivers
-- names with inconsistent casing depending on the message:
--   Add/Remove: "Iceshield" (TitleCase)
--   List:      "ICESHIELD" (UPPERCASE, often equipment-sourced)
-- so we key the lookup by lowercased name.
local buffNameToKey = {
    sanctuary = "sanc",
    iceshield = "ice",
    fireshield = "fire",
}

local function buffKeyForName(name)
    if type(name) ~= "string" then return nil end
    return buffNameToKey[name:lower()]
end

local function normalizeBuffTicks(ticks)
    ticks = tonumber(ticks) or 0
    if ticks < 1 then return 0 end
    if ticks > 35 then return 35 end
    return ticks
end

-- Equipment-sourced buffs report ticks as a non-numeric string like
-- "From Equipment". Treat any present entry as active by clamping to the max
-- tick value when we couldn't parse a number out of it.
local function ticksFromListEntry(rawTicks)
    local n = normalizeBuffTicks(rawTicks)
    if n > 0 then return n end
    return 35
end

local function buffActiveFlag(ticks)
    return normalizeBuffTicks(ticks) > 0 and 1 or 0
end

local function getPlayerKey(name)
    return name and tostring(name):lower() or ""
end

function MultiPlay.applyAfflictionAdd()
    if not gmcp or not gmcp.Char or not gmcp.Char.Afflictions then return false end
    local added = gmcp.Char.Afflictions.Add
    if not added then return false end

    local key = buffKeyForName(added.name)
    if not key then return false end

    local ticks = normalizeBuffTicks(added.ticks)
    if MultiPlay.myBuffs[key] == ticks then return false end
    MultiPlay.myBuffs[key] = ticks
    return true
end

function MultiPlay.applyAfflictionRemove()
    if not gmcp or not gmcp.Char or not gmcp.Char.Afflictions then return false end
    local removed = gmcp.Char.Afflictions.Remove
    if not removed then return false end

    local key = buffKeyForName(removed)
    if not key or MultiPlay.myBuffs[key] == 0 then return false end
    MultiPlay.myBuffs[key] = 0
    return true
end

-- Shared post-change path for all three Afflictions paths (Add/Remove/List).
-- Clears the dedup snapshot so the next sendMyInfo broadcasts, fans the
-- update out to other profiles, and queues a local repaint.
function MultiPlay.onBuffsChanged()
    MultiPlay.lastSent = nil
    if MedUI and MedUI.options.enableMultiPlay then
        MultiPlay.sendMyInfo()
        MultiPlay.sendMyBuffs()
    end
    raiseEvent("MultiPlayConsoleUpdate")
end

-- Full-list snapshot (gmcp.Char.Afflictions.List). Authoritative: anything
-- not in the list is treated as inactive. Typically fires on login.
function MultiPlay.applyAfflictionsList()
    if not gmcp or not gmcp.Char or not gmcp.Char.Afflictions
        or not gmcp.Char.Afflictions.List then
        return false
    end

    local entries = gmcp.Char.Afflictions.List.afflictions
    if type(entries) ~= "table" then return false end

    local newState = {sanc = 0, ice = 0, fire = 0}
    for _, entry in ipairs(entries) do
        local key = entry and buffKeyForName(entry.name)
        if key then
            newState[key] = ticksFromListEntry(entry.ticks)
        end
    end

    local changed = false
    for k, v in pairs(newState) do
        if MultiPlay.myBuffs[k] ~= v then
            MultiPlay.myBuffs[k] = v
            changed = true
        end
    end
    return changed
end

function MultiPlay.getBuffFlags()
    return {
        sanc = buffActiveFlag(MultiPlay.myBuffs.sanc),
        ice = buffActiveFlag(MultiPlay.myBuffs.ice),
        fire = buffActiveFlag(MultiPlay.myBuffs.fire),
    }
end

function MultiPlay.applyBuffFlagsToPlayer(player, sanc, ice, fire)
    if not player then return end
    player.sanc = tonumber(sanc) or 0
    player.ice = tonumber(ice) or 0
    player.fire = tonumber(fire) or 0
end

function MultiPlay.sendMyBuffs()
    local name = MultiPlay.myPlayerName
    if gmcp and gmcp.Char and gmcp.Char.Info and gmcp.Char.Info.name then
        name = gmcp.Char.Info.name
        MultiPlay.myPlayerName = name
    end
    if not name or name == "" then
        name = capitalizeFirst(getCharacterName()) or "<Unknown>"
        MultiPlay.myPlayerName = name
    end

    local buffs = MultiPlay.getBuffFlags()
    raiseGlobalEvent("MPBuffResponse", name, buffs.sanc, buffs.ice, buffs.fire)
end

function MultiPlay.updateStoredPlayerBuffs(name, sanc, ice, fire)
    local key = getPlayerKey(name)
    if key == "" then return false end

    local found = false
    for _, player in ipairs(MultiPlay.myForm) do
        if getPlayerKey(player.name) == key then
            MultiPlay.applyBuffFlagsToPlayer(player, sanc, ice, fire)
            found = true
            break
        end
    end

    if not found then
        MultiPlay.pendingBuffs[key] = {
            sanc = tonumber(sanc) or 0,
            ice = tonumber(ice) or 0,
            fire = tonumber(fire) or 0,
        }
    end

    return found
end

-- Full MPInfoResponse messages are primarily for vitals. Buff state can change
-- faster than vitals broadcasts and some profiles/packages may send MPInfo
-- without SIF fields, which previously overwrote an active letter with 0 and
-- made it flash/disappear. Treat MPBuffResponse as authoritative for clearing
-- SIF; MPInfoResponse may add positive flags, but it should not clear an
-- already-active flag from an existing row.
function MultiPlay.preserveExistingBuffFlags(playerInfo, existingPlayer)
    if not playerInfo or not existingPlayer then return end

    if (tonumber(playerInfo.sanc) or 0) <= 0 and (tonumber(existingPlayer.sanc) or 0) > 0 then
        playerInfo.sanc = existingPlayer.sanc
    end
    if (tonumber(playerInfo.ice) or 0) <= 0 and (tonumber(existingPlayer.ice) or 0) > 0 then
        playerInfo.ice = existingPlayer.ice
    end
    if (tonumber(playerInfo.fire) or 0) <= 0 and (tonumber(existingPlayer.fire) or 0) > 0 then
        playerInfo.fire = existingPlayer.fire
    end
end


-- Build a player-info table for the current profile in the same shape as
-- entries in MultiPlay.myForm. Returns nil if vitals haven't arrived yet.
function MultiPlay.getSelfInfo()

    if gmcp and gmcp.Char then
        if gmcp.Char.Vitals then
            local vitals = gmcp.Char.Vitals
            MultiPlay.myVitals.hp = vitals.hp
            MultiPlay.myVitals.maxHp = vitals.maxHp
            MultiPlay.myVitals.mana = vitals.mana
            MultiPlay.myVitals.maxMana = vitals.maxMana
            MultiPlay.myVitals.br = vitals.br
            MultiPlay.myVitals.mv = vitals.mv
            MultiPlay.myVitals.maxMv = vitals.maxMv
        end

        if gmcp.Char.Info then
            local myInfo = gmcp.Char.Info
            MultiPlay.myPlayerName = myInfo.name
            MultiPlay.myClass = myInfo.class
            MultiPlay.myLevel = myInfo.level
        end
    end

    if not gmcp or not gmcp.Char or not gmcp.Char.Vitals then
        return nil
    end

    if not MultiPlay.myPlayerName or MultiPlay.myPlayerName == "" then
        MultiPlay.myPlayerName = capitalizeFirst(getCharacterName()) or "<Unknown>"
    end

    local v = MultiPlay.myVitals
    local buffs = MultiPlay.getBuffFlags()
    return {
        name = MultiPlay.myPlayerName,
        class = classToCode[MultiPlay.myClass] or "???",
        level = MultiPlay.myLevel,
        hp = v.hp, maxHp = v.maxHp,
        mana = v.mana, maxMana = v.maxMana,
        br = v.br, mv = v.mv, maxMv = v.maxMv,
        -- MultiPlay only displays whether these affects are active. Do not
        -- broadcast tick counts; Medievia does not provide dynamic decrement
        -- updates here, and stale tick numbers are misleading.
        sanc = buffs.sanc,
        ice = buffs.ice,
        fire = buffs.fire,
    }
end


-- Game-side cooldown for Char.Vitals.Get sometimes isn't cleared on
-- profile reset, so the server never re-sends Char.Vitals/Char.Info and
-- gmcp stays empty. When a caller needs those and they're missing, poke
-- the server and retry the callback once after 0.5s.
function MultiPlay.withGmcp(callback)
    if gmcp and gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Info then
        callback()
    else
        sendGMCP("Char.Vitals.Get")
        tempTimer(0.5, callback)
    end
end


function MultiPlay.sendMyInfo()
    MultiPlay.withGmcp(function()
        local info = MultiPlay.getSelfInfo()
        if not info or not info.hp then
            return
        end

        local last = MultiPlay.lastSent
        if last
            and last.name == info.name
            and last.class == info.class
            and last.level == info.level
            and last.hp == info.hp and last.maxHp == info.maxHp
            and last.mana == info.mana and last.maxMana == info.maxMana
            and last.br == info.br and last.mv == info.mv and last.maxMv == info.maxMv
            and last.sanc == info.sanc and last.ice == info.ice and last.fire == info.fire then
            return
        end

        MultiPlay.lastSent = info

        raiseGlobalEvent("MPInfoResponse", info.name, info.class, info.level,
            info.hp, info.maxHp, info.mana, info.maxMana, info.br, info.mv, info.maxMv,
            info.sanc, info.ice, info.fire)
    end)
end


function MultiPlay.enableModule()
    enableAlias("MultiPlay")
    enableTrigger("MultiPlay")
    -- Toggling MultiPlay back on should always re-open the stats window,
    -- even if the user previously X-closed it (which sets the persistent
    -- hidden flag). forceShowAdjContainer clears both flags and persists
    -- the cleared state.
    if MedUI and MedUI.forceShowAdjContainer then
        MedUI.forceShowAdjContainer(MPWindow and MPWindow.window)
    elseif MPWindow and MPWindow.window then
        MPWindow.window:show(true)
    end

    -- On package install/load the gmcp tree may already be populated from
    -- earlier in the session, so no Char.Vitals/Char.Info event will fire to
    -- trigger our normal repaint path. Paint once now from whatever's there.
    raiseEvent("MultiPlayConsoleUpdate")

    tempTimer(3, function()
        sendGMCP("Char.Vitals.Get")
        MultiPlay.requestInfo()
    end)
end


function MultiPlay.disableModule()
    disableAlias("MultiPlay")
    disableTrigger("MultiPlay")
    -- Auto-hide so re-enabling the module restores visibility without
    -- requiring `medui showall`. The user's X-close hidden flag is preserved.
    MPWindow.window:hide(true)
end


function MultiPlay.eventHandler(event, ...)
    if event == "gmcp.Char.Vitals" then
        local vitals = gmcp.Char.Vitals
        MultiPlay.myVitals.hp = vitals.hp
        MultiPlay.myVitals.maxHp = vitals.maxHp
        MultiPlay.myVitals.mana = vitals.mana
        MultiPlay.myVitals.maxMana = vitals.maxMana
        MultiPlay.myVitals.br = vitals.br
        MultiPlay.myVitals.mv = vitals.mv
        MultiPlay.myVitals.maxMv = vitals.maxMv

        if MedUI and MedUI.options.enableMultiPlay then
            MultiPlay.sendMyInfo()
        end

        -- raiseGlobalEvent only delivers to other profiles, so without this
        -- the self row never repaints from our own GMCP updates.
        raiseEvent("MultiPlayConsoleUpdate")

    elseif event == "gmcp.Char.Info" then
        local info = gmcp.Char.Info
        MultiPlay.myPlayerName = info.name
        MultiPlay.myClass = info.class
        MultiPlay.myLevel = info.level

        --echo("Received character info: " .. info.name .. " (Class: " .. info.class .. ", Level: " .. info.level .. ")\n")

        disableTrigger("MultiPlay")

        raiseEvent("MultiPlayConsoleUpdate")

    elseif event == "gmcp.Char.Afflictions.Add" then
        if MultiPlay.applyAfflictionAdd() then MultiPlay.onBuffsChanged() end

    elseif event == "gmcp.Char.Afflictions.Remove" then
        if MultiPlay.applyAfflictionRemove() then MultiPlay.onBuffsChanged() end

    elseif event == "gmcp.Char.Afflictions.List" then
        if MultiPlay.applyAfflictionsList() then MultiPlay.onBuffsChanged() end

    elseif event == "MPTell" then
        --echo("got MPTell\n")
        local message = arg[1]
        local profile = arg[2]
        if getProfileName() ~= profile then
            echo(profile .. " << " .. message)
            expandAlias(message)
        end

    elseif event == "MPTellPlayer" then
        --echo("got MPTellPlayer\n")
        local player = arg[1]
        local message = arg[2]
        local profile = arg[3]
        -- myPlayerName derives from gmcp.Char.Info; without it we fall back to
        -- the profile name and can miss tells addressed to our char name.
        MultiPlay.withGmcp(function()
            if player and MultiPlay.myPlayerName
                and player:lower() == MultiPlay.myPlayerName:lower() then
                echo(profile .. " < " .. MultiPlay.myPlayerName .. " << " .. message)
                expandAlias(message)
            end
        end)

    elseif event == "MPTellClass" then
        --echo("got MPTellClass\n")
        local class = arg[1]
        local message = arg[2]
        local profile = arg[3]
        MultiPlay.withGmcp(function()
            if gmcp and gmcp.Char and gmcp.Char.Info and gmcp.Char.Info.class == class then
                echo(profile .. " < " .. class .. " << " .. message)
                expandAlias(message)
            end
        end)

    elseif event == "MPRequestInfo" then
        --echo("got MPRequestInfo\n")
        if MedUI and MedUI.options.enableMultiPlay then
            -- Force a fresh broadcast: a profile only asks when it has no
            -- record of us, so dedup against lastSent must not suppress this.
            MultiPlay.lastSent = nil
            MultiPlay.sendMyInfo()
            MultiPlay.sendMyBuffs()
        end

    elseif event == "MPBuffResponse" then
        local name = arg[1]
        local sanc = tonumber(arg[2]) or 0
        local ice = tonumber(arg[3]) or 0
        local fire = tonumber(arg[4]) or 0

        if getPlayerKey(name) ~= getPlayerKey(MultiPlay.myPlayerName) then
            MultiPlay.updateStoredPlayerBuffs(name, sanc, ice, fire)
            raiseEvent("MultiPlayConsoleUpdate")
        end

    elseif event == "MPInfoResponse" then
        --display(arg)

        local playerInfo = {
            name = arg[1],
            class = arg[2],
            level = arg[3],
            hp = arg[4],
            maxHp = arg[5],
            mana = arg[6],
            maxMana = arg[7],
            br = arg[8],
            mv = arg[9],
            maxMv = arg[10],
            sanc = tonumber(arg[11]) or 0,
            ice = tonumber(arg[12]) or 0,
            fire = tonumber(arg[13]) or 0
        }

        local profile = arg[14]
        --echo("Received info from [" .. profile .. "] ".. playerInfo.name .. " (Class: " .. playerInfo.class .. ", Level: " .. playerInfo.level .. ")\n")

        -- Buff broadcasts can race ahead of the first full info row. Merge any
        -- pending flags so the row shows the correct SIF on first paint.
        local pendingKey = getPlayerKey(playerInfo.name)
        local pendingBuffs = MultiPlay.pendingBuffs[pendingKey]
        if pendingBuffs then
            MultiPlay.applyBuffFlagsToPlayer(playerInfo, pendingBuffs.sanc, pendingBuffs.ice, pendingBuffs.fire)
            MultiPlay.pendingBuffs[pendingKey] = nil
        end

        local found = false

        -- Case-insensitive match so a row first broadcast in lowercase
        -- (pre-Char.Info) is replaced by the proper-case row instead of
        -- producing a duplicate.
        local incomingKey = playerInfo.name and playerInfo.name:lower() or ""
        for id, player in ipairs(MultiPlay.myForm) do
            if player.name and player.name:lower() == incomingKey then
                MultiPlay.preserveExistingBuffFlags(playerInfo, player)
                MultiPlay.myForm[id] = playerInfo
                found = true
                break
            end
        end

        -- otherwise add this player to the form
        if not found then
            table.insert(MultiPlay.myForm, playerInfo)
        end

        raiseEvent("MultiPlayConsoleUpdate")

    elseif event == "MPSmartHeal" then
        local targetName = arg[1]
        local missingHp = tonumber(arg[2])

        -- myClass derives from gmcp.Char.Info; without it we silently skip
        -- heal requests even on a Cleric profile.
        MultiPlay.withGmcp(function()
            if MultiPlay.myClass == "Cleric" then
                MultiPlay.smartHeal(targetName, missingHp)
            end
        end)

    end
end


-- Smart heal stub - called on Cleric profiles when a heal is requested
-- @param targetName string  The name of the player to heal
-- @param missingHp number   The amount of HP the target is missing
function MultiPlay.smartHeal(targetName, missingHp)
    if MultiPlay.myClass ~= "Cleric" then
        return
    end

    cecho(string.format("\n<DeepSkyBlue>MultiPlay: <white>Smart heal requested for <yellow>%s<white> (missing <red>%d<white> hp)\n", targetName, missingHp))

    if MultiPlay.myVitals.mana > 150 then
        send("c heal " .. targetName)
    else
        send("c cure crit " .. targetName)
    end

end

for _, id in ipairs(MultiPlay.eventHandlerIDs) do
    killAnonymousEventHandler(id)
end

MultiPlay.eventHandlerIDs = {
    registerAnonymousEventHandler("MPTell", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("MPTellPlayer", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("MPTellClass", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("MPRequestInfo", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("MPInfoResponse", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("MPBuffResponse", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("gmcp.Char.Vitals", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("gmcp.Char.Info", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("gmcp.Char.Afflictions.Add", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("gmcp.Char.Afflictions.Remove", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("gmcp.Char.Afflictions.List", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("MPSmartHeal", "MultiPlay.eventHandler")
}
