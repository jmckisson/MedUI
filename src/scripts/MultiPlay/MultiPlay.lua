
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
    send(command)
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
    return {
        name = MultiPlay.myPlayerName,
        class = classToCode[MultiPlay.myClass] or "???",
        level = MultiPlay.myLevel,
        hp = v.hp, maxHp = v.maxHp,
        mana = v.mana, maxMana = v.maxMana,
        br = v.br, mv = v.mv, maxMv = v.maxMv,
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
            and last.br == info.br and last.mv == info.mv and last.maxMv == info.maxMv then
            return
        end

        MultiPlay.lastSent = info

        raiseGlobalEvent("MPInfoResponse", info.name, info.class, info.level,
            info.hp, info.maxHp, info.mana, info.maxMana, info.br, info.mv, info.maxMv)
    end)
end


function MultiPlay.enableModule()
    enableAlias("MultiPlay")
    enableTrigger("MultiPlay")
    -- Use auto-show so we clear our own auto_hidden flag without clobbering
    -- the user's hidden flag (set when they X-close the window). If they
    -- previously X-closed, hidden=true keeps it closed; show(true) will
    -- only actually display the window when both flags are clear.
    MPWindow.window:show(true)

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
            maxMv = arg[10]
        }

        local profile = arg[11]
        --echo("Received info from [" .. profile .. "] ".. playerInfo.name .. " (Class: " .. playerInfo.class .. ", Level: " .. playerInfo.level .. ")\n")

        local found = false

        -- Case-insensitive match so a row first broadcast in lowercase
        -- (pre-Char.Info) is replaced by the proper-case row instead of
        -- producing a duplicate.
        local incomingKey = playerInfo.name and playerInfo.name:lower() or ""
        for id, player in ipairs(MultiPlay.myForm) do
            if player.name and player.name:lower() == incomingKey then
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
    registerAnonymousEventHandler("gmcp.Char.Vitals", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("gmcp.Char.Info", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("MPSmartHeal", "MultiPlay.eventHandler")
}
