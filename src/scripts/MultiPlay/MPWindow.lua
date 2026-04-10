MPWindow = MPWindow or {}
MPWindow.gaugeFrames = MPWindow.gaugeFrames or {}

-- Adjustable container for the whole window
MPWindow.window = MPWindow.window or Adjustable.Container:new({
    name = "MultiPlay Stats",
})

-- Text mode console
MPWindow.console = MPWindow.console or Geyser.MiniConsole:new({
    name = "MPConsole",
    width = "100%", height = "100%",
    x = 0, y = 0,
    autoWrap = false,
    color = "black",
    scrollBar = false,
    fontSize = 13,
}, MPWindow.window)

-- Gauge mode container (created on demand)
MPWindow.gaugeContainer = MPWindow.gaugeContainer or nil

-- Stylesheet constants for gauge bars
local backStyleSheet = [[background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #666666, stop: 1 #cccccc);
    border-width: 1px;
    border-color: black;
    border-style: solid;
    border-radius: 5;
    padding: 2px;
]]

local function getGaugeStyleSheet(current, max)
    local gradMax, gradMin

    local pct = 100
    if max > 0 then
        pct = current / max * 100
    end

    local textColor

    if pct > 90 then
        gradMax = "#0047b3"
        gradMin = "#b3d1ff"
        textColor = "white"
    elseif pct > 75 then
        gradMax = "#98f041"
        gradMin = "#66cc00"
        textColor = "black"
    elseif pct > 25 then
        gradMax = "#ffff00"
        gradMin = "#ffff66"
        textColor = "black"
    else
        gradMax = "#ff0000"
        gradMin = "#ff6666"
        textColor = "white"
    end

    local styleSheet = string.format(
        "background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 1 %s);\
        border-top: 1px black solid;\
        border-left: 1px black solid;\
        border-bottom: 1px black solid;\
        border-radius: 5;\
        padding: 2px;\
        outline:2px", gradMax, gradMin)

    return styleSheet, textColor
end

local rowHeight = 25

local cellStyle = "background-color: #222222; border: 1px solid #444444; padding: 2px;"
local cellStyleAlt = "background-color: #333333; border: 1px solid #444444; padding: 2px;"

-- Hidden auto-categories based on class (internal only, not shown to user)
local classToCategory = {
    CLE = "Casters",
    MAG = "Casters",
    WAR = "Melee",
    THI = "Melee",
}

-- Internal category membership: { Casters = {name1, name2}, Melee = {name3, ...} }
MPWindow.categories = MPWindow.categories or {}


--- Auto-assign a player to their class category (internal tracking)
function MPWindow.updateCategory(player)
    local category = classToCategory[player.class]
    if not category then return end

    if not MPWindow.categories[category] then
        MPWindow.categories[category] = {}
    end

    if not table.index_of(MPWindow.categories[category], player.name) then
        table.insert(MPWindow.categories[category], player.name)
    end
end


--- Get all players in a given internal category
function MPWindow.getCategoryMembers(category)
    return MPWindow.categories[category] or {}
end


--- Request smart heal from all Clerics for a target player
function MPWindow.requestHeal(playerName, missingHp)
    raiseGlobalEvent("MPSmartHeal", playerName, missingHp)
    raiseEvent("MPSmartHeal", playerName, missingHp, getProfileName())
end


--- Find which user-visible group a player belongs to (returns first match or "")
function MPWindow.getPlayerGroup(playerName)
    for group, players in pairs(MultiPlay.myGroups) do
        if table.index_of(players, playerName) then
            return group
        end
    end
    return ""
end


--- Build right-click context menu on a label for assigning a player to a group
function MPWindow.setupGroupMenu(label, playerName)
    local menuItems = {"New Group"}

    -- Existing groups as a submenu under "Add to"
    local groupNames = {}
    for group, _ in pairs(MultiPlay.myGroups) do
        table.insert(groupNames, group)
    end

    if #groupNames > 0 then
        table.insert(menuItems, "Add to")
        table.insert(menuItems, groupNames)
    end

    -- Remove from group option (if player is in one)
    local currentGroup = MPWindow.getPlayerGroup(playerName)
    if currentGroup ~= "" then
        table.insert(menuItems, "Remove from " .. currentGroup)
    end

    label:createRightClickMenu({
        MenuItems = menuItems,
        Style = "Dark",
        MenuWidth = 120,
        MenuFormat1 = "c9",
    })

    label:setMenuAction("New Group", function()
        local groupName = "group" .. (table.size(MultiPlay.myGroups) + 1)
        MultiPlay.addToGroup(groupName, playerName)
        raiseEvent("MultiPlayConsoleUpdate")
        cecho(string.format("\n<DeepSkyBlue>MultiPlay: <white>Added <yellow>%s<white> to new group <yellow>%s\n", playerName, groupName))
        closeAllLevels(label)
    end)

    for _, group in ipairs(groupNames) do
        label:setMenuAction("Add to." .. group, function()
            -- Remove from current group first
            if currentGroup ~= "" and MultiPlay.myGroups[currentGroup] then
                local idx = table.index_of(MultiPlay.myGroups[currentGroup], playerName)
                if idx then
                    table.remove(MultiPlay.myGroups[currentGroup], idx)
                end
            end
            MultiPlay.addToGroup(group, playerName)
            raiseEvent("MultiPlayConsoleUpdate")
            cecho(string.format("\n<DeepSkyBlue>MultiPlay: <white>Added <yellow>%s<white> to group <yellow>%s\n", playerName, group))
            closeAllLevels(label)
        end)
    end

    if currentGroup ~= "" then
        label:setMenuAction("Remove from " .. currentGroup, function()
            local idx = table.index_of(MultiPlay.myGroups[currentGroup], playerName)
            if idx then
                table.remove(MultiPlay.myGroups[currentGroup], idx)
                raiseEvent("MultiPlayConsoleUpdate")
                cecho(string.format("\n<DeepSkyBlue>MultiPlay: <white>Removed <yellow>%s<white> from group <yellow>%s\n", playerName, currentGroup))
            end
            closeAllLevels(label)
        end)
    end
end


--- Set up the scrollable gauge container (created once)
function MPWindow.setupGaugeContainer()
    if MPWindow.gaugeContainer then return end

    MPWindow.gaugeContainer = Geyser.Container:new({
        name = "MPGaugeContainer",
        x = 0, y = 0,
        width = "100%", height = "100%",
    }, MPWindow.window)
end


--- Build or update a single horizontal player frame at the given row index
function MPWindow.buildPlayerFrame(index, player)
    local frameName = "mpframe_" .. index

    -- If this frame already exists, update it in place
    if MPWindow.gaugeFrames[index] then
        MPWindow.updatePlayerFrame(index, player)
        return
    end

    local yPos = (index - 1) * rowHeight

    -- Row container (HBox for horizontal layout)
    local row = Geyser.HBox:new({
        name = frameName,
        x = 0, y = yPos,
        width = "100%", height = rowHeight,
    }, MPWindow.gaugeContainer)

    -- Player Name label
    local nameLabel = Geyser.Label:new({
        name = frameName .. "_name",
        width = 90, height = "100%",
    }, row)
    nameLabel:setStyleSheet(cellStyle)
    nameLabel:echo(player.name, "white", "c")
    nameLabel:setFontSize(10)

    -- HP Gauge
    local hpGauge = Geyser.Gauge:new({
        name = frameName .. "_hp",
        width = 120, height = "100%",
    }, row)
    hpGauge.back:setStyleSheet(backStyleSheet)
    local hpSheet, hpTextColor = getGaugeStyleSheet(player.hp, player.maxHp)
    hpGauge.front:setStyleSheet(hpSheet)
    hpGauge:setValue(player.hp, player.maxHp, string.format("<b><font color='%s'>%d HP</font></b>", hpTextColor, player.hp))

    -- Click on HP gauge to request smart heal from Clerics
    local pName = player.name
    hpGauge.front:setClickCallback(function()
        -- Find this player's current data
        for _, p in ipairs(MultiPlay.myForm) do
            if p.name == pName then
                local missingHp = p.maxHp - p.hp
                if missingHp > 0 then
                    MPWindow.requestHeal(pName, missingHp)
                end
                break
            end
        end
    end)

    -- Mana Gauge
    local manaGauge = Geyser.Gauge:new({
        name = frameName .. "_mana",
        width = 120, height = "100%",
    }, row)
    manaGauge.back:setStyleSheet(backStyleSheet)
    local manaSheet, manaTextColor = getGaugeStyleSheet(player.mana, player.maxMana)
    manaGauge.front:setStyleSheet(manaSheet)
    manaGauge:setValue(player.mana, player.maxMana, string.format("<b><font color='%s'>%d MN</font></b>", manaTextColor, player.mana))

    -- MV label
    local mvLabel = Geyser.Label:new({
        name = frameName .. "_mv",
        width = 30, height = "100%",
    }, row)
    mvLabel:setStyleSheet(cellStyle)
    mvLabel:echo(tostring(player.mv) .. " mv", "white", "c")
    mvLabel:setFontSize(9)

    -- BR label
    local brLabel = Geyser.Label:new({
        name = frameName .. "_br",
        width = 30, height = "100%",
    }, row)
    brLabel:setStyleSheet(cellStyle)
    brLabel:echo(tostring(player.br) .. " br", "white", "c")
    brLabel:setFontSize(9)

    -- Class label
    local classLabel = Geyser.Label:new({
        name = frameName .. "_class",
        width = 25, height = "100%",
    }, row)
    classLabel:setStyleSheet(cellStyleAlt)
    classLabel:echo(tostring(player.class), "cyan", "c")
    classLabel:setFontSize(9)

    -- Level label
    local levelLabel = Geyser.Label:new({
        name = frameName .. "_level",
        width = 25, height = "100%",
    }, row)
    levelLabel:setStyleSheet(cellStyleAlt)
    levelLabel:echo(tostring(player.level), "yellow", "c")
    levelLabel:setFontSize(9)

    -- Group label
    local groupLabel = Geyser.Label:new({
        name = frameName .. "_group",
        width = 55, height = "100%",
    }, row)
    groupLabel:setStyleSheet(cellStyleAlt)
    local groupName = MPWindow.getPlayerGroup(player.name)
    groupLabel:echo(groupName, "orange", "c")
    groupLabel:setFontSize(9)

    -- Right-click menu on the row name label
    MPWindow.setupGroupMenu(nameLabel, player.name)

    -- Store references for updates
    MPWindow.gaugeFrames[index] = {
        row = row,
        nameLabel = nameLabel,
        hpGauge = hpGauge,
        manaGauge = manaGauge,
        mvLabel = mvLabel,
        brLabel = brLabel,
        classLabel = classLabel,
        levelLabel = levelLabel,
        groupLabel = groupLabel,
        playerName = player.name,
    }
end


--- Update an existing player frame with new data
function MPWindow.updatePlayerFrame(index, player)
    local frame = MPWindow.gaugeFrames[index]
    if not frame then return end

    frame.nameLabel:echo(player.name, "white", "c")

    local hpSheet, hpTextColor = getGaugeStyleSheet(player.hp, player.maxHp)
    frame.hpGauge.front:setStyleSheet(hpSheet)
    frame.hpGauge:setValue(player.hp, player.maxHp, string.format("<b><font color='%s'>%d HP</font></b>", hpTextColor, player.hp))

    local manaSheet, manaTextColor = getGaugeStyleSheet(player.mana, player.maxMana)
    frame.manaGauge.front:setStyleSheet(manaSheet)
    frame.manaGauge:setValue(player.mana, player.maxMana, string.format("<b><font color='%s'>%d MN</font></b>", manaTextColor, player.mana))

    frame.mvLabel:echo(tostring(player.mv), "white", "c")
    frame.brLabel:echo(tostring(player.br), "white", "c")
    frame.classLabel:echo(tostring(player.class), "cyan", "c")
    frame.levelLabel:echo(tostring(player.level), "yellow", "c")

    local groupName = MPWindow.getPlayerGroup(player.name)
    frame.groupLabel:echo(groupName, "orange", "c")

    -- Refresh right-click menu every update so group changes are reflected
    MPWindow.setupGroupMenu(frame.nameLabel, player.name)

    frame.playerName = player.name
end


--- Remove gauge frames that are no longer needed
function MPWindow.cleanupGaugeFrames(playerCount)
    for i = playerCount + 1, #MPWindow.gaugeFrames do
        if MPWindow.gaugeFrames[i] and MPWindow.gaugeFrames[i].row then
            MPWindow.gaugeFrames[i].row:hide()
            MPWindow.gaugeFrames[i] = nil
        end
    end
end


--- Update the gauge display with current player data
function MPWindow.UpdateGauges()
    MPWindow.setupGaugeContainer()

    for id, player in ipairs(MultiPlay.myForm) do
        MPWindow.buildPlayerFrame(id, player)
    end

    MPWindow.cleanupGaugeFrames(#MultiPlay.myForm)
end


--- Text console update
function MPWindow.UpdateConsole()
    MPWindow.console:clear()

    for id, player in ipairs(MultiPlay.myForm) do
        local infoStr = string.format("<white>%-12s<blue>|<white>%3s<blue>|<white>%2d<blue>|<white>%4d<blue>/<white>%d<blue>hp <white>%4d<blue>/<white>%d<blue>m <white>%d<blue>mv <white>%d<blue>br\n",
            player.name, player.class, player.level, player.hp, player.maxHp, player.mana, player.maxMana, player.mv, player.br)

        MPWindow.console:cecho(infoStr)
    end
end


--- Main update dispatcher - picks text or gauge mode
function MPWindow.Update()
    if MedUI and MedUI.options and MedUI.options.mpGaugeMode then
        MPWindow.console:hide()
        if MPWindow.gaugeContainer then
            MPWindow.gaugeContainer:show()
        end
        MPWindow.UpdateGauges()
    else
        if MPWindow.gaugeContainer then
            MPWindow.gaugeContainer:hide()
        end
        MPWindow.console:show()
        MPWindow.UpdateConsole()
    end
end


--- Switch display mode
function MPWindow.setDisplayMode(gaugeMode)
    if gaugeMode then
        MPWindow.console:hide()
        MPWindow.setupGaugeContainer()
        MPWindow.gaugeContainer:show()
        MPWindow.UpdateGauges()
    else
        if MPWindow.gaugeContainer then
            MPWindow.gaugeContainer:hide()
        end
        MPWindow.console:show()
        MPWindow.UpdateConsole()
    end
end


registerNamedEventHandler("MultiPlay", "WindowUpdate", "MultiPlayConsoleUpdate", MPWindow.Update)
