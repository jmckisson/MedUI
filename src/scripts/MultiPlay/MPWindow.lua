MPWindow = MPWindow or {}
MPWindow.gaugeFrames = MPWindow.gaugeFrames or {}
MPWindow.groupVersion = MPWindow.groupVersion or 0
MPWindow.pendingUpdateTimer = nil

-- Bumped whenever group membership changes; per-frame menus are rebuilt only
-- when their cached version differs.
function MPWindow.invalidateMenus()
    MPWindow.groupVersion = MPWindow.groupVersion + 1
end

-- Coalesces bursts of MultiPlayConsoleUpdate events (e.g. when N profiles all
-- broadcast vitals at once) into a single repaint.
function MPWindow.queueUpdate()
    if MPWindow.pendingUpdateTimer then return end
    MPWindow.pendingUpdateTimer = tempTimer(0.05, function()
        MPWindow.pendingUpdateTimer = nil
        MPWindow.Update()
    end)
end

-- Defer one tick so Qt drains its deleteLater queue (old TLabels from
-- before resetProfile) before any luaL_ref runs for our new callbacks.
tempTimer(0, function()
    -- Adjustable container for the whole window
    MPWindow.window = MPWindow.window or Adjustable.Container:new({
        name = "MultiPlay Stats",
    })

    MPWindow.window:setTitle("MultiPlay Stats")

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
end)

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
    local pct = 100
    if max > 0 then
        pct = current / max * 100
    end

    local band, gradMax, gradMin, textColor

    if pct > 90 then
        band, gradMax, gradMin, textColor = 1, "#0047b3", "#b3d1ff", "white"
    elseif pct > 75 then
        band, gradMax, gradMin, textColor = 2, "#98f041", "#66cc00", "black"
    elseif pct > 25 then
        band, gradMax, gradMin, textColor = 3, "#ffff00", "#ffff66", "black"
    else
        band, gradMax, gradMin, textColor = 4, "#ff0000", "#ff6666", "white"
    end

    local styleSheet = string.format(
        "background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 1 %s);\
        border-top: 1px black solid;\
        border-left: 1px black solid;\
        border-bottom: 1px black solid;\
        border-radius: 5;\
        padding: 2px;\
        outline:2px", gradMax, gradMin)

    return styleSheet, textColor, band
end

-- Mirrors the four bands in getGaugeStyleSheet for plain-text labels on dark
-- cells: blue (full) / green (high) / yellow (medium) / red (low).
local function getBandLabelColor(current, max)
    local pct = 100
    if max > 0 then
        pct = current / max * 100
    end
    if pct > 90 then return "deepskyblue"
    elseif pct > 75 then return "lawngreen"
    elseif pct > 25 then return "yellow"
    else return "red" end
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
    if not playerName then return "" end
    local key = playerName:lower()
    for group, players in pairs(MultiPlay.myGroups) do
        for _, p in ipairs(players) do
            if p and p:lower() == key then
                return group
            end
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

    if not label.rightClickMenu then
        label:createRightClickMenu({
            MenuItems = menuItems,
            Style = "Dark",
            MenuWidth = 120,
            MenuFormat1 = "c9",
        })
    else
        label.MenuItems = menuItems
        label:createMenuItems(true)
    end

    label:setMenuAction("New Group", function()
        local groupName = "group" .. (table.size(MultiPlay.myGroups) + 1)
        MultiPlay.addToGroup(groupName, playerName)
        MPWindow.invalidateMenus()
        raiseEvent("MultiPlayConsoleUpdate")
        cecho(string.format("\n<DeepSkyBlue>MultiPlay: <white>Added <yellow>%s<white> to new group <yellow>%s\n", playerName, groupName))
        closeAllLevels(label)
    end)

    for _, group in ipairs(groupNames) do
        label:setMenuAction("Add to." .. group, function()
            if currentGroup ~= "" then
                MultiPlay.removeFromGroup(currentGroup, playerName)
            end
            MultiPlay.addToGroup(group, playerName)
            MPWindow.invalidateMenus()
            raiseEvent("MultiPlayConsoleUpdate")
            cecho(string.format("\n<DeepSkyBlue>MultiPlay: <white>Added <yellow>%s<white> to group <yellow>%s\n", playerName, group))
            closeAllLevels(label)
        end)
    end

    if currentGroup ~= "" then
        label:setMenuAction("Remove from " .. currentGroup, function()
            if MultiPlay.removeFromGroup(currentGroup, playerName) then
                MPWindow.invalidateMenus()
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
    nameLabel:echo(player.name, "white", "l")
    nameLabel:setFontSize(10)

    -- HP Gauge
    local hpGauge = Geyser.Gauge:new({
        name = frameName .. "_hp",
        width = 120, height = "100%",
    }, row)
    hpGauge.back:setStyleSheet(backStyleSheet)
    local hpSheet, hpTextColor, hpBand = getGaugeStyleSheet(player.hp, player.maxHp)
    hpGauge.front:setStyleSheet(hpSheet)
    hpGauge:setValue(player.hp, player.maxHp, string.format("<b><font color='%s'>%d HP</font></b>", hpTextColor, player.hp))

    -- Click on HP gauge to request smart heal from Clerics
    local pName = player.name
    hpGauge.front:setClickCallback(function()
        for _, p in ipairs(MPWindow.getDisplayList()) do
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
    local manaSheet, manaTextColor, manaBand = getGaugeStyleSheet(player.mana, player.maxMana)
    manaGauge.front:setStyleSheet(manaSheet)
    manaGauge:setValue(player.mana, player.maxMana, string.format("<b><font color='%s'>%d MN</font></b>", manaTextColor, player.mana))

    -- MV label
    local mvLabel = Geyser.Label:new({
        name = frameName .. "_mv",
        width = 30, height = "100%",
    }, row)
    mvLabel:setStyleSheet(cellStyle)
    mvLabel:echo(tostring(player.mv), getBandLabelColor(player.mv, player.maxMv), "c")
    mvLabel:setFontSize(9)

    -- BR label
    local brLabel = Geyser.Label:new({
        name = frameName .. "_br",
        width = 30, height = "100%",
    }, row)
    brLabel:setStyleSheet(cellStyle)
    brLabel:echo(tostring(player.br), getBandLabelColor(player.br, 100), "c")
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

    -- Store references and cached display values to avoid redundant Qt calls
    -- on subsequent updates (the hot path during multi-profile vitals bursts).
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
        shownName = player.name,
        shownHp = player.hp,
        shownMaxHp = player.maxHp,
        shownMana = player.mana,
        shownMaxMana = player.maxMana,
        shownMv = player.mv,
        shownMaxMv = player.maxMv,
        shownBr = player.br,
        shownClass = player.class,
        shownLevel = player.level,
        shownGroup = groupName,
        hpBand = hpBand,
        manaBand = manaBand,
        menuVersion = MPWindow.groupVersion,
    }
end


--- Update an existing player frame with new data, skipping any Qt calls
--- whose displayed value hasn't changed since the last update.
function MPWindow.updatePlayerFrame(index, player)
    local frame = MPWindow.gaugeFrames[index]
    if not frame then return end

    if frame.shownName ~= player.name then
        frame.nameLabel:echo(player.name, "white", "c")
        frame.shownName = player.name
    end

    if frame.shownHp ~= player.hp or frame.shownMaxHp ~= player.maxHp then
        local hpSheet, hpTextColor, hpBand = getGaugeStyleSheet(player.hp, player.maxHp)
        if frame.hpBand ~= hpBand then
            frame.hpGauge.front:setStyleSheet(hpSheet)
            frame.hpBand = hpBand
        end
        frame.hpGauge:setValue(player.hp, player.maxHp, string.format("<b><font color='%s'>%d HP</font></b>", hpTextColor, player.hp))
        frame.shownHp = player.hp
        frame.shownMaxHp = player.maxHp
    end

    if frame.shownMana ~= player.mana or frame.shownMaxMana ~= player.maxMana then
        local manaSheet, manaTextColor, manaBand = getGaugeStyleSheet(player.mana, player.maxMana)
        if frame.manaBand ~= manaBand then
            frame.manaGauge.front:setStyleSheet(manaSheet)
            frame.manaBand = manaBand
        end
        frame.manaGauge:setValue(player.mana, player.maxMana, string.format("<b><font color='%s'>%d MN</font></b>", manaTextColor, player.mana))
        frame.shownMana = player.mana
        frame.shownMaxMana = player.maxMana
    end

    if frame.shownMv ~= player.mv or frame.shownMaxMv ~= player.maxMv then
        frame.mvLabel:echo(tostring(player.mv), getBandLabelColor(player.mv, player.maxMv), "c")
        frame.shownMv = player.mv
        frame.shownMaxMv = player.maxMv
    end

    if frame.shownBr ~= player.br then
        frame.brLabel:echo(tostring(player.br), getBandLabelColor(player.br, 100), "c")
        frame.shownBr = player.br
    end

    if frame.shownClass ~= player.class then
        frame.classLabel:echo(tostring(player.class), "cyan", "c")
        frame.shownClass = player.class
    end

    if frame.shownLevel ~= player.level then
        frame.levelLabel:echo(tostring(player.level), "yellow", "c")
        frame.shownLevel = player.level
    end

    local groupName = MPWindow.getPlayerGroup(player.name)
    if frame.shownGroup ~= groupName then
        frame.groupLabel:echo(groupName, "orange", "c")
        frame.shownGroup = groupName
    end

    -- Only rebuild the right-click menu when group membership has actually
    -- changed, not on every vitals tick.
    if frame.menuVersion ~= MPWindow.groupVersion then
        MPWindow.setupGroupMenu(frame.nameLabel, player.name)
        frame.menuVersion = MPWindow.groupVersion
    end

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


--- Build the ordered list of rows to display: self first (if vitals known),
--- then everyone else from MultiPlay.myForm. Filters self out of myForm in
--- case it ever gets broadcast back to the originating profile.
function MPWindow.getDisplayList()
    local list = {}
    local self = MultiPlay.getSelfInfo()
    if self then
        table.insert(list, self)
    end
    local selfKey = self and self.name and self.name:lower() or nil
    for _, p in ipairs(MultiPlay.myForm) do
        if not (selfKey and p.name and p.name:lower() == selfKey) then
            table.insert(list, p)
        end
    end
    return list
end


--- Update the gauge display with current player data
function MPWindow.UpdateGauges()
    MPWindow.setupGaugeContainer()

    local rows = MPWindow.getDisplayList()
    for id, player in ipairs(rows) do
        MPWindow.buildPlayerFrame(id, player)
    end

    MPWindow.cleanupGaugeFrames(#rows)
end


--- Text console update
function MPWindow.UpdateConsole()
    MPWindow.console:clear()

    for _, player in ipairs(MPWindow.getDisplayList()) do
        local mvColor = getBandLabelColor(player.mv, player.maxMv)
        local brColor = getBandLabelColor(player.br, 100)
        local infoStr = string.format("<white>%-12s<blue>|<white>%3s<blue>|<white>%2d<blue>|<white>%4d<blue>/<white>%d<blue>hp <white>%4d<blue>/<white>%d<blue>m <%s>%d<blue>mv <%s>%d<blue>br\n",
            player.name, player.class, player.level,
            player.hp, player.maxHp,
            player.mana, player.maxMana,
            mvColor, player.mv,
            brColor, player.br)

        MPWindow.console:cecho(infoStr)
    end
end


--- Main update dispatcher - picks text or gauge mode
function MPWindow.Update()
    -- If the MultiPlay module is disabled the window is hidden; skip all the
    -- Geyser/Qt work but let the underlying MultiPlay.myForm table keep
    -- collecting cross-profile vitals so the display is fresh when re-enabled.
    if not MedUI or not MedUI.options or not MedUI.options.enableMultiPlay then
        return
    end

    if MedUI.options.mpGaugeMode then
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


registerNamedEventHandler("MultiPlay", "WindowUpdate", "MultiPlayConsoleUpdate", MPWindow.queueUpdate)
