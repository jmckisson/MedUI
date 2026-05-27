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
-- not needed after PTB fix
--tempTimer(0, function()
    -- Adjustable container for the whole window
    MPWindow.window = MPWindow.window or Adjustable.Container:new({
        name = "MultiPlay Stats",
    })

    MPWindow.window:setTitle("MultiPlay Stats")
    if MedUI and MedUI.persistOnClose then MedUI.persistOnClose(MPWindow.window) end
    if MedUI and MedUI.applyMedUILockStyle then MedUI.applyMedUILockStyle(MPWindow.window) end

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
--end)

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

-- Precomputed front-gauge stylesheets keyed by band. Only four distinct
-- outputs, so we build them once at load time instead of string.format-ing on
-- every vitals tick.
local function buildGaugeSheet(gradMax, gradMin)
    return string.format(
        "background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 1 %s);\
        border-top: 1px black solid;\
        border-left: 1px black solid;\
        border-bottom: 1px black solid;\
        border-radius: 5;\
        padding: 2px;\
        outline:2px", gradMax, gradMin)
end

local gaugeBands = {
    {sheet = buildGaugeSheet("#0047b3", "#b3d1ff"), textColor = "white"},
    {sheet = buildGaugeSheet("#98f041", "#66cc00"), textColor = "black"},
    {sheet = buildGaugeSheet("#ffff00", "#ffff66"), textColor = "black"},
    {sheet = buildGaugeSheet("#ff0000", "#ff6666"), textColor = "white"},
}

local function getGaugeBand(current, max)
    local pct = 100
    if max > 0 then
        pct = current / max * 100
    end
    if pct > 90 then return 1
    elseif pct > 75 then return 2
    elseif pct > 25 then return 3
    else return 4 end
end

-- Mirrors the four gauge bands for plain-text labels on dark cells:
-- blue (full) / green (high) / yellow (medium) / red (low).
local function getBandLabelColor(current, max)
    local pct = 100
    if max > 0 then
        pct = current / max * 100
    end
    if pct > 90 then return "white"
    elseif pct > 75 then return "LawnGreen"
    elseif pct > 25 then return "yellow"
    else return "red" end
end

local rowHeight = 25
local headerHeight = 24

local cellStyle = "background-color: #222222; border: 1px solid #444444; padding: 2px;"
local cellStyleAlt = "background-color: #333333; border: 1px solid #444444; padding: 2px;"

-- Ordered column metadata for the gauge view. gaugePolicy controls HBox
-- behavior: "fixed" keeps the column at gaugeWidth pixels; "dynamic" lets the
-- column stretch to fill leftover horizontal space so HP/mana grow when the
-- window is widened and shrink gracefully on small monitors.
MPWindow.columnDefs = {
    {key = "name",  label = "Name",  gaugeWidth = 90,  gaugePolicy = "fixed",   cellKind = "name",       style = cellStyle},
    {key = "hp",    label = "HP",    gaugeWidth = 120, gaugePolicy = "dynamic", cellKind = "hpGauge"},
    {key = "mana",  label = "Mana",  gaugeWidth = 120, gaugePolicy = "dynamic", cellKind = "manaGauge"},
    {key = "mv",    label = "MV",    gaugeWidth = 40,  gaugePolicy = "fixed",   cellKind = "mvLabel",    style = cellStyle},
    {key = "br",    label = "BR",    gaugeWidth = 40,  gaugePolicy = "fixed",   cellKind = "brLabel",    style = cellStyle},
    {key = "class", label = "Class", gaugeWidth = 50,  gaugePolicy = "fixed",   cellKind = "classLabel", style = cellStyleAlt},
    {key = "level", label = "Lvl",   gaugeWidth = 40,  gaugePolicy = "fixed",   cellKind = "levelLabel", style = cellStyleAlt},
    {key = "group", label = "Group", gaugeWidth = 65,  gaugePolicy = "fixed",   cellKind = "groupLabel", style = cellStyleAlt},
    -- Keep SIF as the final/rightmost column. It is intentionally very narrow
    -- because it shows only active spell letters (Sanc/Iceshield/Fireshield),
    -- not tick numbers.
    {key = "buffs", label = "SIF",   gaugeWidth = 42,  gaugePolicy = "fixed",   cellKind = "buffLabel",  style = cellStyleAlt},
}

local function colHPolicy(col)
    return col.gaugePolicy == "dynamic" and Geyser.Dynamic or Geyser.Fixed
end

-- Map key -> def for O(1) lookups
MPWindow.columnDefByKey = {}
for _, def in ipairs(MPWindow.columnDefs) do
    MPWindow.columnDefByKey[def.key] = def
end

-- Subset of columns shown in the text-console view, in display order. group
-- isn't included because the text view doesn't emit a group field today.
MPWindow.textColumnOrder = {"name", "class", "level", "hp", "mana", "mv", "br", "buffs"}

-- Per-column metadata for the text view: column width in characters (used for
-- header padding) and the separator emitted before the column's data.
MPWindow.textColumnInfo = {
    name  = {width = 12, sep = ""},
    class = {width = 3,  sep = "<blue>|"},
    level = {width = 2,  sep = "<blue>|"},
    hp    = {width = 11, sep = "<blue>|"},
    mana  = {width = 10, sep = " "},
    mv    = {width = 6,  sep = " "},
    br    = {width = 5,  sep = " "},
    buffs = {width = 5,  sep = " "},
}

local function colHidden(key)
    return MedUI and MedUI.options and MedUI.options.mpHiddenColumns
        and MedUI.options.mpHiddenColumns[key] or false
end

local function getSortKey()
    return MedUI and MedUI.options and MedUI.options.mpSortKey or nil
end

local function getSortDir()
    return MedUI and MedUI.options and MedUI.options.mpSortDir or "asc"
end

local function sortHpMana(cur, max)
    if MedUI and MedUI.options and MedUI.options.mpSortByPercent then
        return (max and max > 0) and (cur / max) or 0
    end
    return tonumber(cur) or 0
end

-- Returns a comparable value for the given player + column key. HP and Mana
-- honor the mpSortByPercent option (raw value by default — percentages all
-- tie at 1.0 when everyone is at full health and produce no visible reorder).
local function sortValue(player, key)
    if key == "name" then
        return tostring(player.name or ""):lower()
    elseif key == "class" then
        return tostring(player.class or ""):lower()
    elseif key == "level" then
        return tonumber(player.level) or 0
    elseif key == "hp" then
        return sortHpMana(player.hp, player.maxHp)
    elseif key == "mana" then
        return sortHpMana(player.mana, player.maxMana)
    elseif key == "mv" then
        return tonumber(player.mv) or 0
    elseif key == "br" then
        return tonumber(player.br) or 0
    elseif key == "buffs" then
        return (tonumber(player.sanc) or 0) + (tonumber(player.ice) or 0) + (tonumber(player.fire) or 0)
    elseif key == "group" then
        return MPWindow.getPlayerGroup(player.name or ""):lower()
    end
    return 0
end

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


-- Reverse playerName(lower) -> group index, rebuilt lazily when groupVersion
-- changes. Avoids O(groups * members) scans of MultiPlay.myGroups on every
-- vitals tick.
MPWindow.playerToGroup = MPWindow.playerToGroup or {}
MPWindow.playerToGroupVersion = -1

local function ensurePlayerGroupIndex()
    if MPWindow.playerToGroupVersion == MPWindow.groupVersion then return end
    local map = {}
    for group, players in pairs(MultiPlay.myGroups) do
        for _, p in ipairs(players) do
            if p then map[p:lower()] = group end
        end
    end
    MPWindow.playerToGroup = map
    MPWindow.playerToGroupVersion = MPWindow.groupVersion
end


--- Find which user-visible group a player belongs to (returns first match or "")
function MPWindow.getPlayerGroup(playerName)
    if not playerName then return "" end
    ensurePlayerGroupIndex()
    return MPWindow.playerToGroup[playerName:lower()] or ""
end


-- Geyser's createMenuItems only adds labels; it never prunes ones that were
-- removed from MenuItems. Walk the cached MenuLabels/nestedLabels and drop
-- anything not present in the fresh items list so stale entries (e.g. "Remove
-- from groupX" after the player leaves the group) disappear on rebuild.
local function pruneStaleMenuLabels(menuLabel, newItems)
    if not menuLabel.MenuLabels then return end

    local keep = {}
    for _, item in ipairs(newItems) do
        if type(item) == "string" then
            keep[item] = true
        end
    end

    for name, stale in pairs(menuLabel.MenuLabels) do
        if not keep[name] then
            if menuLabel.nestedLabels then
                for i = #menuLabel.nestedLabels, 1, -1 do
                    if menuLabel.nestedLabels[i] == stale then
                        table.remove(menuLabel.nestedLabels, i)
                    end
                end
            end
            stale:hide()
            menuLabel.MenuLabels[name] = nil
        end
    end

    for i, item in ipairs(newItems) do
        if type(item) == "table" and type(newItems[i - 1]) == "string" then
            local child = menuLabel.MenuLabels[newItems[i - 1]]
            if child then pruneStaleMenuLabels(child, item) end
        end
    end
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
        -- Geyser's findMenuElement reads from rightClickMenu.MenuItems, which
        -- starts out as the same table reference as label.MenuItems. Replacing
        -- label.MenuItems leaves the rightClickMenu pointing at the stale list,
        -- so setMenuAction can't see newly-added items. Update both.
        pruneStaleMenuLabels(label.rightClickMenu, menuItems)
        label.MenuItems = menuItems
        label.rightClickMenu.MenuItems = menuItems
        label:createMenuItems(true)
    end

    label:setMenuAction("New Group", function()
        local groupName = "g" .. (table.size(MultiPlay.myGroups) + 1)
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


-- Header cell styles. Active = column currently being sorted by.
local headerStyle = "background-color: #1f1f2a; border: 1px solid #444444; padding: 1px;"
local headerStyleActive = "background-color: #2e6a2e; border: 1px solid #66cc66; padding: 1px;"

MPWindow.headerCells = MPWindow.headerCells or {}


--- Refresh header labels to reflect the current sort column + direction.
function MPWindow.updateGaugeHeader()
    local sortKey = getSortKey()
    local sortDir = getSortDir()

    for _, col in ipairs(MPWindow.columnDefs) do
        local cell = MPWindow.headerCells[col.key]
        if cell then
            local active = (sortKey == col.key)
            local arrow = active and (sortDir == "desc" and " ▼" or " ▲") or ""
            cell:setStyleSheet(active and headerStyleActive or headerStyle)
            cell:echo(col.label .. arrow, "white", "c")
        end
    end
end


--- Build the clickable header row above the gauge rows. Headers for hidden
--- columns are skipped entirely — visibility is controlled from the MedUI
--- Options dialog, not from the header.
function MPWindow.setupGaugeHeader()
    if MPWindow.headerRow then
        MPWindow.updateGaugeHeader()
        return
    end

    MPWindow.headerRow = Geyser.HBox:new({
        name = "MPHeaderRow",
        x = 0, y = 0,
        width = "100%", height = headerHeight,
    }, MPWindow.gaugeContainer)

    for _, col in ipairs(MPWindow.columnDefs) do
        if not colHidden(col.key) then
            local cellName = "mpheader_" .. col.key
            local cell = Geyser.Label:new({
                name = cellName,
                h_policy = colHPolicy(col),
                width = col.gaugeWidth, height = headerHeight,
            }, MPWindow.headerRow)
            cell:setFontSize(9)
            local key = col.key
            cell:setClickCallback(function() MPWindow.cycleSort(key) end)
            MPWindow.headerCells[col.key] = cell
        end
    end

    MPWindow.updateGaugeHeader()
end


--- Cycle through sort states for a column: not-sorted → asc → desc → not-sorted.
function MPWindow.cycleSort(key)
    if not MedUI or not MedUI.options then return end
    local curKey = MedUI.options.mpSortKey
    local curDir = MedUI.options.mpSortDir or "asc"
    if curKey ~= key then
        MedUI.options.mpSortKey = key
        MedUI.options.mpSortDir = "asc"
    elseif curDir == "asc" then
        MedUI.options.mpSortDir = "desc"
    else
        MedUI.options.mpSortKey = nil
        MedUI.options.mpSortDir = "asc"
    end
    if MedUI.saveOptions then MedUI.saveOptions(true) end
    if MPWindow.headerRow then MPWindow.updateGaugeHeader() end
    MPWindow.Update()
end


--- Toggle whether a column is shown. Called from the MedUI Options dialog.
--- The header HBox and the player-row HBoxes both depend on which cells
--- exist, so tear them down and let the next Update() rebuild them.
function MPWindow.toggleColumnVisibility(key)
    if not MedUI or not MedUI.options then return end
    MedUI.options.mpHiddenColumns = MedUI.options.mpHiddenColumns or {}
    MedUI.options.mpHiddenColumns[key] = not MedUI.options.mpHiddenColumns[key] or nil
    if MedUI.saveOptions then MedUI.saveOptions(true) end
    MPWindow.rebuildGaugeHeader()
    MPWindow.rebuildGaugeFrames()
    MPWindow.Update()
end


--- Tear down the gauge header so setupGaugeHeader rebuilds it with the
--- current visibility set.
function MPWindow.rebuildGaugeHeader()
    MPWindow.headerCells = {}
    if MPWindow.headerRow then
        MPWindow.headerRow:hide()
        MPWindow.headerRow = nil
    end
end


--- Tear down all gauge-mode player frames so the next Update() rebuilds them
--- with the current column visibility.
function MPWindow.rebuildGaugeFrames()
    for i = 1, MPWindow.gaugeFrameCount or 0 do
        local frame = MPWindow.gaugeFrames[i]
        if frame and frame.row then frame.row:hide() end
        MPWindow.gaugeFrames[i] = nil
    end
    MPWindow.gaugeFrameCount = 0
end


local function activeBuffFlagValue(value)
    return (tonumber(value) or 0) > 0
end

-- Compact "SIF" string of just the active letters, used as the dedup key
-- for updatePlayerFrame so we only re-echo when the visible state changes.
local function buffTextState(player)
    local s = activeBuffFlagValue(player.sanc) and "S" or ""
    local i = activeBuffFlagValue(player.ice) and "I" or ""
    local f = activeBuffFlagValue(player.fire) and "F" or ""
    return s .. i .. f
end

-- HTML for the gauge view's SIF label. <span> with inline color keeps the
-- letters colored without needing a Geyser color arg per element.
local function buffGaugeHtml(player)
    local parts = {}
    if activeBuffFlagValue(player.sanc) then table.insert(parts, "<span style='color:white;'>S</span>") end
    if activeBuffFlagValue(player.ice) then table.insert(parts, "<span style='color:cyan;'>I</span>") end
    if activeBuffFlagValue(player.fire) then table.insert(parts, "<span style='color:red;'>F</span>") end
    return "<nobr>" .. table.concat(parts, " ") .. "</nobr>"
end

local function buffConsoleText(player)
    local parts = {}
    if activeBuffFlagValue(player.sanc) then table.insert(parts, "<white>S") end
    if activeBuffFlagValue(player.ice) then table.insert(parts, "<cyan>I") end
    if activeBuffFlagValue(player.fire) then table.insert(parts, "<red>F") end
    if #parts == 0 then return "" end
    return table.concat(parts, " ")
end


-- Construct the single Geyser widget that represents `col` for player `player`
-- inside the given row HBox. Returns the widget plus its initial display state
-- so updatePlayerFrame can dedup later. Returns nil if the column is hidden.
-- Fixed-policy columns keep their gaugeWidth in pixels; Dynamic-policy columns
-- (HP/mana) share the leftover space so they grow/shrink with the window.
local function buildColumnCell(col, row, frameName, player, frameIndex)
    if colHidden(col.key) then return nil end
    local cellName = frameName .. "_" .. col.key
    local width = col.gaugeWidth
    local policy = colHPolicy(col)

    if col.cellKind == "name" then
        local label = Geyser.Label:new({name = cellName, h_policy = policy, width = width, height = "100%"}, row)
        label:setStyleSheet(col.style)
        label:echo(player.name, "white", "l")
        label:setFontSize(10)
        return label, {shownName = player.name}

    elseif col.cellKind == "hpGauge" then
        local gauge = Geyser.Gauge:new({name = cellName, h_policy = policy, width = width, height = "100%"}, row)
        gauge.back:setStyleSheet(backStyleSheet)
        local band = getGaugeBand(player.hp, player.maxHp)
        local info = gaugeBands[band]
        gauge.front:setStyleSheet(info.sheet)
        gauge:setValue(player.hp, player.maxHp,
            string.format("<b><font color='%s'>%d HP</font></b>", info.textColor, player.hp))
        gauge.front:setClickCallback(function()
            local frame = MPWindow.gaugeFrames[frameIndex]
            if not frame or not frame.player then return end
            local p = frame.player
            local missingHp = p.maxHp - p.hp
            if missingHp > 0 then
                MPWindow.requestHeal(p.name, missingHp)
            end
        end)
        return gauge, {shownHp = player.hp, shownMaxHp = player.maxHp, hpBand = band}

    elseif col.cellKind == "manaGauge" then
        local gauge = Geyser.Gauge:new({name = cellName, h_policy = policy, width = width, height = "100%"}, row)
        gauge.back:setStyleSheet(backStyleSheet)
        local band = getGaugeBand(player.mana, player.maxMana)
        local info = gaugeBands[band]
        gauge.front:setStyleSheet(info.sheet)
        gauge:setValue(player.mana, player.maxMana,
            string.format("<b><font color='%s'>%d MN</font></b>", info.textColor, player.mana))
        return gauge, {shownMana = player.mana, shownMaxMana = player.maxMana, manaBand = band}

    elseif col.cellKind == "mvLabel" then
        local label = Geyser.Label:new({name = cellName, h_policy = policy, width = width, height = "100%"}, row)
        label:setStyleSheet(col.style)
        label:echo(tostring(player.mv), getBandLabelColor(player.mv, player.maxMv), "c")
        label:setFontSize(9)
        return label, {shownMv = player.mv, shownMaxMv = player.maxMv}

    elseif col.cellKind == "brLabel" then
        local label = Geyser.Label:new({name = cellName, h_policy = policy, width = width, height = "100%"}, row)
        label:setStyleSheet(col.style)
        label:echo(tostring(player.br), getBandLabelColor(player.br, 100), "c")
        label:setFontSize(9)
        return label, {shownBr = player.br}

    elseif col.cellKind == "buffLabel" then
        local label = Geyser.Label:new({name = cellName, h_policy = policy, width = width, height = "100%"}, row)
        label:setStyleSheet(col.style)
        label:echo(buffGaugeHtml(player), "white", "c")
        label:setFontSize(8)
        return label, {shownBuffs = buffTextState(player)}

    elseif col.cellKind == "classLabel" then
        local label = Geyser.Label:new({name = cellName, h_policy = policy, width = width, height = "100%"}, row)
        label:setStyleSheet(col.style)
        label:echo(tostring(player.class), "cyan", "c")
        label:setFontSize(9)
        return label, {shownClass = player.class}

    elseif col.cellKind == "levelLabel" then
        local label = Geyser.Label:new({name = cellName, h_policy = policy, width = width, height = "100%"}, row)
        label:setStyleSheet(col.style)
        label:echo(tostring(player.level), "yellow", "c")
        label:setFontSize(9)
        return label, {shownLevel = player.level}

    elseif col.cellKind == "groupLabel" then
        local label = Geyser.Label:new({name = cellName, h_policy = policy, width = width, height = "100%"}, row)
        label:setStyleSheet(col.style)
        local groupName = MPWindow.getPlayerGroup(player.name)
        label:echo(groupName, "orange", "c")
        label:setFontSize(9)
        return label, {shownGroup = groupName}
    end
end


--- Build or update a single horizontal player frame at the given row index
function MPWindow.buildPlayerFrame(index, player)
    local frameName = "mpframe_" .. index

    -- If this frame already exists, update it in place
    if MPWindow.gaugeFrames[index] then
        MPWindow.updatePlayerFrame(index, player)
        return
    end

    local yPos = headerHeight + (index - 1) * rowHeight

    -- Row container (HBox for horizontal layout)
    local row = Geyser.HBox:new({
        name = frameName,
        x = 0, y = yPos,
        width = "100%", height = rowHeight,
    }, MPWindow.gaugeContainer)

    local frame = {
        row = row,
        cells = {},
        player = player,
        playerName = player.name,
        menuVersion = MPWindow.groupVersion,
    }

    for _, col in ipairs(MPWindow.columnDefs) do
        local widget, state = buildColumnCell(col, row, frameName, player, index)
        if widget then
            frame.cells[col.key] = widget
            if state then
                for k, v in pairs(state) do frame[k] = v end
            end
        end
    end

    -- Right-click menu hangs off the name label when that column is visible.
    if frame.cells.name then
        MPWindow.setupGroupMenu(frame.cells.name, player.name)
    end

    if index > MPWindow.gaugeFrameCount then
        MPWindow.gaugeFrameCount = index
    end

    MPWindow.gaugeFrames[index] = frame
end


--- Update an existing player frame with new data, skipping any Geyser calls
--- whose displayed value hasn't changed since the last update. Cells for
--- hidden columns are skipped automatically because frame.cells lacks them.
function MPWindow.updatePlayerFrame(index, player)
    local frame = MPWindow.gaugeFrames[index]
    if not frame then return end

    -- Keep the live player ref current so the HP click callback can read
    -- up-to-date vitals without rescanning the display list.
    frame.player = player

    local cells = frame.cells

    if cells.name and frame.shownName ~= player.name then
        cells.name:echo(player.name, "white", "l")
        frame.shownName = player.name
    end

    if cells.hp and (frame.shownHp ~= player.hp or frame.shownMaxHp ~= player.maxHp) then
        local hpBand = getGaugeBand(player.hp, player.maxHp)
        local hpInfo = gaugeBands[hpBand]
        if frame.hpBand ~= hpBand then
            cells.hp.front:setStyleSheet(hpInfo.sheet)
            frame.hpBand = hpBand
        end
        cells.hp:setValue(player.hp, player.maxHp, string.format("<b><font color='%s'>%d HP</font></b>", hpInfo.textColor, player.hp))
        frame.shownHp = player.hp
        frame.shownMaxHp = player.maxHp
    end

    if cells.mana and (frame.shownMana ~= player.mana or frame.shownMaxMana ~= player.maxMana) then
        local manaBand = getGaugeBand(player.mana, player.maxMana)
        local manaInfo = gaugeBands[manaBand]
        if frame.manaBand ~= manaBand then
            cells.mana.front:setStyleSheet(manaInfo.sheet)
            frame.manaBand = manaBand
        end
        cells.mana:setValue(player.mana, player.maxMana, string.format("<b><font color='%s'>%d MN</font></b>", manaInfo.textColor, player.mana))
        frame.shownMana = player.mana
        frame.shownMaxMana = player.maxMana
    end

    if cells.mv and (frame.shownMv ~= player.mv or frame.shownMaxMv ~= player.maxMv) then
        cells.mv:echo(tostring(player.mv), getBandLabelColor(player.mv, player.maxMv), "c")
        frame.shownMv = player.mv
        frame.shownMaxMv = player.maxMv
    end

    if cells.br and frame.shownBr ~= player.br then
        cells.br:echo(tostring(player.br), getBandLabelColor(player.br, 100), "c")
        frame.shownBr = player.br
    end

    if cells.buffs then
        local state = buffTextState(player)
        if frame.shownBuffs ~= state then
            cells.buffs:echo(buffGaugeHtml(player), "white", "c")
            frame.shownBuffs = state
        end
    end

    if cells.class and frame.shownClass ~= player.class then
        cells.class:echo(tostring(player.class), "cyan", "c")
        frame.shownClass = player.class
    end

    if cells.level and frame.shownLevel ~= player.level then
        cells.level:echo(tostring(player.level), "yellow", "c")
        frame.shownLevel = player.level
    end

    if cells.group then
        local groupName = MPWindow.getPlayerGroup(player.name)
        if frame.shownGroup ~= groupName then
            cells.group:echo(groupName, "orange", "c")
            frame.shownGroup = groupName
        end
    end

    -- Only rebuild the right-click menu when group membership has actually
    -- changed, not on every vitals tick.
    if cells.name and frame.menuVersion ~= MPWindow.groupVersion then
        MPWindow.setupGroupMenu(cells.name, player.name)
        frame.menuVersion = MPWindow.groupVersion
    end

    frame.playerName = player.name
end


--- Remove gauge frames that are no longer needed. Tracks a high-water mark
--- explicitly because #gaugeFrames is undefined once we punch nil holes.
MPWindow.gaugeFrameCount = MPWindow.gaugeFrameCount or 0

function MPWindow.cleanupGaugeFrames(playerCount)
    for i = playerCount + 1, MPWindow.gaugeFrameCount do
        local frame = MPWindow.gaugeFrames[i]
        if frame and frame.row then
            frame.row:hide()
            MPWindow.gaugeFrames[i] = nil
        end
    end
    MPWindow.gaugeFrameCount = playerCount
end


--- Build the ordered list of rows to display: self first (if vitals known),
--- then everyone else from MultiPlay.myForm. Filters self out of myForm in
--- case it ever gets broadcast back to the originating profile.
--- Reuses a single table across calls to avoid per-tick GC churn.
MPWindow._displayList = MPWindow._displayList or {}

function MPWindow.getDisplayList()
    local list = MPWindow._displayList
    local n = 0
    local self = MultiPlay.getSelfInfo()
    if self then
        n = n + 1
        list[n] = self
    end
    local selfKey = self and self.name and self.name:lower() or nil
    for _, p in ipairs(MultiPlay.myForm) do
        if not (selfKey and p.name and p.name:lower() == selfKey) then
            n = n + 1
            list[n] = p
        end
    end
    for i = #list, n + 1, -1 do
        list[i] = nil
    end

    -- Apply user-selected sort. When no sort is active the natural order is
    -- self-first then form-order, which we already produced above.
    local sortKey = getSortKey()
    if sortKey and MPWindow.columnDefByKey[sortKey] then
        local dir = getSortDir()
        table.sort(list, function(a, b)
            local va, vb = sortValue(a, sortKey), sortValue(b, sortKey)
            if va == vb then return false end
            if dir == "desc" then return va > vb end
            return va < vb
        end)
    end

    return list
end


--- Update the gauge display with current player data
function MPWindow.UpdateGauges()
    MPWindow.setupGaugeContainer()
    MPWindow.setupGaugeHeader()

    local rows = MPWindow.getDisplayList()
    for id, player in ipairs(rows) do
        MPWindow.buildPlayerFrame(id, player)
    end

    MPWindow.cleanupGaugeFrames(#rows)
end


-- Format the data portion of one column in text mode. Returns nil for hidden
-- columns so the caller can skip the separator too.
local function renderTextCell(key, player)
    if colHidden(key) then return nil end
    if key == "name" then
        return string.format("<white>%-12s", player.name or "")
    elseif key == "class" then
        return string.format("<white>%3s", player.class or "")
    elseif key == "level" then
        return string.format("<white>%2d", tonumber(player.level) or 0)
    elseif key == "hp" then
        local c = getBandLabelColor(player.hp, player.maxHp)
        return string.format("<%s>%4d<blue>/<white>%4d<blue>hp", c, player.hp or 0, player.maxHp or 0)
    elseif key == "mana" then
        local c = getBandLabelColor(player.mana, player.maxMana)
        return string.format("<%s>%4d<blue>/<white>%4d<blue>m", c, player.mana or 0, player.maxMana or 0)
    elseif key == "mv" then
        local c = getBandLabelColor(player.mv, player.maxMv)
        return string.format("<%s>%4d<blue>mv", c, player.mv or 0)
    elseif key == "br" then
        local c = getBandLabelColor(player.br, 100)
        return string.format("<%s>%3d<blue>br", c, player.br or 0)
    elseif key == "buffs" then
        return buffConsoleText(player)
    end
end


-- Emit the column header line into the text console. Each visible column's
-- header is one clickable element that cycles the sort state. The active sort
-- direction is shown as a ▲/▼ next to the column label. Hidden columns are
-- skipped entirely (toggled from the MedUI Options dialog).
local function emitTextHeader()
    local sortKey = getSortKey()
    local sortDir = getSortDir()
    local console = MPWindow.console
    local first = true

    for _, key in ipairs(MPWindow.textColumnOrder) do
        local info = MPWindow.textColumnInfo[key]
        local def = MPWindow.columnDefByKey[key]
        if info and def and not colHidden(key) then
            if not first and info.sep ~= "" then
                console:cecho(info.sep)
            end
            first = false

            local active = (sortKey == key)
            local arrow = active and (sortDir == "desc" and "▼" or "▲") or ""
            local label = def.label .. arrow
            if #label > info.width then label = label:sub(1, info.width) end
            local padded = label .. string.rep(" ", math.max(0, info.width - #label))

            console:cechoLink(string.format("<%s>%s", active and "LawnGreen" or "white", padded),
                function() MPWindow.cycleSort(key) end,
                "Click to sort by " .. def.label, true)
        end
    end
    console:echo("\n")
end


--- Text console update. Emits a clickable header line followed by one row
--- per player using only the visible columns.
function MPWindow.UpdateConsole()
    MPWindow.console:clear()
    emitTextHeader()

    local rows = MPWindow.getDisplayList()
    local parts = {}
    for _, player in ipairs(rows) do
        local rowParts = {}
        local first = true
        for _, key in ipairs(MPWindow.textColumnOrder) do
            local cell = renderTextCell(key, player)
            if cell then
                local sep = MPWindow.textColumnInfo[key].sep
                if not first and sep ~= "" then
                    table.insert(rowParts, sep)
                end
                first = false
                table.insert(rowParts, cell)
            end
        end
        table.insert(rowParts, "\n")
        table.insert(parts, table.concat(rowParts))
    end

    if #parts > 0 then
        MPWindow.console:cecho(table.concat(parts))
    end
end


--- Main update dispatcher - picks text or gauge mode
function MPWindow.Update()
    -- If the MultiPlay module is disabled the window is hidden; skip all the
    -- Geyser work but let the underlying MultiPlay.myForm table keep
    -- collecting cross-profile vitals so the display is fresh when re-enabled.
    if not MedUI or not MedUI.options or not MedUI.options.enableMultiPlay then
        return
    end

    -- After sysUninstallPackage nils MPWindow.console, late-firing events
    -- (queued timer, in-flight gmcp.Char.Vitals) can still land here.
    if not MPWindow.console then return end

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
    if not MPWindow.console then return end
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
