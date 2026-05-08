
-- Char.Info.name is server-authoritative and properly cased; Char.Vitals.name
-- has been observed in lowercase, and getCharacterName() reflects whatever the
-- user typed in Mudlet's profile dialog. Capitalize the profile-name fallback
-- so the multiplay window doesn't render lowercased rows before Char.Info arrives.
local function capitalizeFirst(s)
    if not s or s == "" then return nil end
    return s:sub(1, 1):upper() .. s:sub(2)
end

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
        mv = -1
    },
    eventHandlerIDs = {},
    bReceivedCharInfo = false,
    bReceivedCharVitals = false,
    -- Snapshot of the last broadcast payload; sendMyInfo skips the global
    -- event when nothing has changed to keep N profiles from producing N^2
    -- vitals broadcasts per round.
    lastSent = nil
}

-- Tell all others to execute a command
function MultiPlay.tellAll(command)
    raiseGlobalEvent("MPTell", command)
    raiseEvent("MPTell", command, getProfileName())
    -- could just send() it to ourself
end

function MultiPlay.tellPlayer(player, command)
    raiseGlobalEvent("MPTellPlayer", player, command)
    raiseEvent("MPTellPlayer", player, command, getProfileName())
end

function MultiPlay.tellGroup(group, command)
    if MultiPlay.myGroups[group] then
        for _, player in ipairs(MultiPlay.myGroups[group]) do
            raiseGlobalEvent("MPTellPlayer", player, command)
            raiseEvent("MPTellPlayer", player, command, getProfileName())
        end
    --raiseGlobalEvent("MPTellGroup", group, command)
    --raiseEvent("MPTellGroup", group, command, getProfileName())
    end
end

function MultiPlay.requestInfo()
    raiseGlobalEvent("MPRequestInfo")
end

function MultiPlay.addGroup(group)
    if not MultiPlay.myGroups[group] then
        MultiPlay.myGroups[group] = {}
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
end

function MultiPlay.removeFromGroup(group, player)
    local list = MultiPlay.myGroups[group]
    if not list or not player then return false end
    local key = player:lower()
    for i = #list, 1, -1 do
        if list[i]:lower() == key then
            table.remove(list, i)
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


function MultiPlay.sendMyInfo()

    -- GMCP might be off, or data might not be available yet
    -- don't respond to requests if so
    if not MultiPlay.myVitals or not MultiPlay.myVitals.hp then
        return
    end

    local classStr = "???"

    if MultiPlay.myClass ~= nil then
        if MultiPlay.myClass == "Warrior" then
            classStr = "WAR"
        elseif MultiPlay.myClass == "Cleric" then
            classStr = "CLE"
        elseif MultiPlay.myClass == "Mage" then
            classStr = "MAG"
        elseif MultiPlay.myClass == "Thief" then
            classStr = "THI"
        end
    end

    if not MultiPlay.myPlayerName or MultiPlay.myPlayerName == "" then
        MultiPlay.myPlayerName = capitalizeFirst(getCharacterName()) or "<Unknown>"
    end

    local v = MultiPlay.myVitals
    local last = MultiPlay.lastSent
    if last
        and last.name == MultiPlay.myPlayerName
        and last.class == classStr
        and last.level == MultiPlay.myLevel
        and last.hp == v.hp and last.maxHp == v.maxHp
        and last.mana == v.mana and last.maxMana == v.maxMana
        and last.br == v.br and last.mv == v.mv then
        return
    end

    MultiPlay.lastSent = {
        name = MultiPlay.myPlayerName,
        class = classStr,
        level = MultiPlay.myLevel,
        hp = v.hp, maxHp = v.maxHp,
        mana = v.mana, maxMana = v.maxMana,
        br = v.br, mv = v.mv,
    }

    raiseGlobalEvent("MPInfoResponse", MultiPlay.myPlayerName, classStr, MultiPlay.myLevel,
        v.hp, v.maxHp, v.mana, v.maxMana, v.br, v.mv)
end


function MultiPlay.enableModule()
    enableAlias("MultiPlay")
    enableTrigger("MultiPlay")
    MPWindow.window:show()
end


function MultiPlay.disableModule()
    disableAlias("MultiPlay")
    disableTrigger("MultiPlay")
    MPWindow.window:hide()
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

        MultiPlay.bReceivedCharVitals = true

        if MedUI and MedUI.options.enableMultiPlay then
            MultiPlay.sendMyInfo()
        end

    elseif event == "gmcp.Char.Info" then
        local info = gmcp.Char.Info
        MultiPlay.myPlayerName = info.name
        MultiPlay.myClass = info.class
        MultiPlay.myLevel = info.level

        --echo("Received character info: " .. info.name .. " (Class: " .. info.class .. ", Level: " .. info.level .. ")\n")

        MultiPlay.bReceivedCharInfo = true
        disableTrigger("MultiPlay")

    elseif event == "MPTell" then
        local message = arg[1]
        local profile = arg[2]
        echo(profile .. " >> " .. message)
        expandAlias(message)

    elseif event == "MPTellPlayer" then
        local player = arg[1]
        local message = arg[2]
        local profile = arg[3]
        if player and MultiPlay.myPlayerName
            and player:lower() == MultiPlay.myPlayerName:lower() then
            echo(profile .. " >> " .. message)
            expandAlias(message)
        end

    --[[
    elseif event == "MPTellGroup" then
        local group = arg[1]
        local message = arg[2]
        local profile = arg[3]
        if (table.index_of(MultiPlay.myGroups, group) ~= nil) then
            echo(profile .. " >> " .. message)
            expandAlias(message)
        end
    --]]

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
            mv = arg[9]
        }

        local profile = arg[10]
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

        -- Only Clerics respond to smart heal requests
        if MultiPlay.myClass == "Cleric" then
            MultiPlay.smartHeal(targetName, missingHp)
        end

    end
end


--- Smart heal stub - called on Cleric profiles when a heal is requested
--- @param targetName string  The name of the player to heal
--- @param missingHp number   The amount of HP the target is missing
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

tempTimer(10, function()
    if MedUI.options.enableMultiPlay then
        sendGMCP("Char.Vitals.Get")
        MultiPlay.requestInfo()
    end
end)


MultiPlay.eventHandlerIDs = {

    registerAnonymousEventHandler("MPTell", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("MPTellPlayer", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("MPRequestInfo", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("MPInfoResponse", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("gmcp.Char.Vitals", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("gmcp.Char.Info", "MultiPlay.eventHandler"),
    registerAnonymousEventHandler("MPSmartHeal", "MultiPlay.eventHandler")
}
