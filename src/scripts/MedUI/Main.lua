--[[
  Changelog:
    2.0.0 - Add MultiPlay module
    1.9.1 - Fix windows resizing when map and chat are hidden
    1.9.0 - Detect MMCP for both original PR and development versions
    1.8.2 - Use gmcp Char.Info to trigger options loading
    1.8.1 - Don't reset main font size
    1.8.0 - Use GMCP variables for gauges, remove prompt parsing
    1.7.8 - Fix beginner prompt, add correct map for Medievia and Haven, fix map/chat window placement
    1.7.7 - Embed EMCO chat module instead of requiring as dependency
    1.7.6 - Size and place Map and Chat windows
    1.7.5 - Check for and install MDK requirement for MedChat
    1.7.4 - Fix login triggers
    1.7.3 - Remove updater code - using MPKG now
    1.7.2 - Add mapper additions to Muddler project properly
    1.7.1 - Add font to resources
    1.7.0 - Add Medievia Mapper additions for Mudlet generic_mapper
    1.6.6 - Fix missing Repeat alias pattern
    1.6.5 - Fix missing Repeat alias
    1.6.4 - Fix self-updater
    1.6.3 - Fix prompt regex for prompts containing blind, plague, poison, etc
            Use profile name for options persistence
    1.6.2 - Add option to toggle timestamps in the MedChat window
    1.6.1 - Fixed buffs not hiding when gauges are disabled
            Trim whitespace from MMCP messages to prevent misaligned timestamps
    1.6.0 - Added Changelog
            Add option to keep the inline map in 'medui' command
--]]

AnsiColors = {
    StyleReset = "\27[0m",
    StyleBold = "\27[1m",
    StyleReverse = "\27[7m",
    ForeBlack = "\27[30m",
    ForeRed = "\27[31m",
    ForeGreen = "\27[32m",
    ForeYellow = "\27[33m",
    ForeBlue = "\27[34m",
    ForeMagenta = "\27[35m",
    ForeCyan = "\27[36m",
    ForeWhite = "\27[37m",
    FBLDGRY = "\27[1;30m",
    FBLDRED = "\27[1;31m",
    FBLDGRN = "\27[1;32m",
    FBLDYEL = "\27[1;33m",
    FBLDBLU = "\27[1;34m",
    FBLDMAG = "\27[1;35m",
    FBLDCYN = "\27[1;36m",
    FBLDWHT = "\27[1;37m",
    BBLK = "\27[40m",
    BRED = "\27[41m",
    BGRN = "\27[42m",
    BYEL = "\27[43m",
    BBLU = "\27[44m",
    BMAG = "\27[45m",
    BCYN = "\27[46m",
    BWHT = "\27[47m"
}

AnsiMap = {
  ["<black>"]   = AnsiColors.ForeBlack,
  ["<red>"]     = AnsiColors.ForeRed,
  ["<green>"]   = AnsiColors.ForeGreen,
  ["ansi_010"]  = AnsiColors.ForeGreen,
  ["<yellow>"]  = AnsiColors.ForeYellow,
  ["<blue>"]    = AnsiColors.ForeBlue,
  ["ansi_012"]  = AnsiColors.ForeBlue,
  ["<magenta>"] = AnsiColors.ForeMagenta,
  ["<cyan>"]    = AnsiColors.ForeCyan,
  ["<white>"]   = AnsiColors.ForeWhite,
  ["blue"]    = AnsiColors.ForeBlue,
  ["yellow"]  = AnsiColors.ForeYellow,
  ["ansi_light_red"]     = AnsiColors.ForeRed,
}


MedUI = MedUI or {
  version = "__VERSION__",
  MedChat = {},
  MedMap = {},
  oldBorderBottom = getBorderBottom(),
  options = {
    enableGauges = true,
    keepInlineMap = false,
    enableTimestamps = true,
    mapFontSize = 9,
    chatFontSize = 8,
    enableMultiPlay = false,
    mpGaugeMode = false,
  },
  affTable = {
    ["Armor"]                 = "armor",
    ["Bless"]                 = "bless",
    ["Breathe Water"]         = "breathwater",
    ["Detect Invisibility"]   = "detectinv",
    ["Fire Protection"]       = "protfire",
    ["Fireshield"]            = "fireshield",
    ["Ice Protection"]        = "protice",
    ["Iceshield"]             = "iceshield",
    ["Infravision"]           = "infravision",
    ["Levitate"]              = "levitate",
    ["Lightning Protection"]  = "protlightning",
    ["Manashield"]            = "manashield",
    ["Phantasmal Images"]     = "phanimages",
    ["Protection From Evil"]  = "protfromevil",
    ["Protection From Good"]  = "protfromgood",
    ["Quickness"]             = "quickness",
    ["Sanctuary"]             = "sanc",
    ["Sense Life"]            = "senselife",
    ["Shield"]                = "shield",
    ["Strength"]              = "strength",
  },
  --Stores the location reference of the PNG for each buff and debuff
  --Use with getMudletHomeDir() to get full path
  iconLocation = "/MedUI"
}

MedUI.buffIconTable = {
    sanc =         {icon="/icons/sanc.png",            active=false, labelName="spell_label_sanc",         buffType="buff",   order=1},
    fireshield =   {icon="/icons/fireshield.png",      active=false, labelName="spell_label_fireshield",   buffType="buff",   order=2},
    iceshield =    {icon="/icons/iceshield.png",       active=false, labelName="spell_label_iceshield",    buffType="buff",   order=3},
    protfire =     {icon="/icons/prot_fire.png",       active=false, labelName="spell_label_protfire",     buffType="buff",   order=4},
    protice =      {icon="/icons/prot_ice.png",        active=false, labelName="spell_label_protice",      buffType="buff",   order=5},
    protlightning ={icon="/icons/prot_lightning.png",  active=false, labelName="spell_label_protlightning",buffType="buff",   order=6},
    manashield =   {icon="/icons/manashield.png",      active=false, labelName="spell_label_manashield",   buffType="buff",   order=7},
    phanimages =   {icon="/icons/phanimages.png",      active=false, labelName="spell_label_phanimages",   buffType="buff",   order=8},
    quickness =    {icon="/icons/quickness.png",       active=false, labelName="spell_label_quickness",    buffType="buff",   order=9},
    levitate =     {icon="/icons/levitate.png",        active=false, labelName="spell_label_levitate",     buffType="buff",   order=10},
    breathwater =  {icon="/icons/breathwater.png",     active=false, labelName="spell_label_breathwater",  buffType="buff",   order=11},
    strength =     {icon="/icons/strength.png",        active=false, labelName="spell_label_strength",     buffType="buff",   order=12},
    armor =        {icon="/icons/armor.png",           active=false, labelName="spell_label_armor",        buffType="buff",   order=13},
    bless =        {icon="/icons/bless.png",           active=false, labelName="spell_label_bless",        buffType="buff",   order=14},
    stoneskin =    {icon="/icons/stoneskin_shield.png",active=false, labelName="spell_label_stoneskin",    buffType="buff",   order=15},
    shield =       {icon="/icons/shield.png",          active=false, labelName="spell_label_shield",       buffType="buff",   order=16},
    protfromgood = {icon="/icons/protfromgood.png",    active=false, labelName="spell_label_protfromgood", buffType="buff",   order=17},
    blind =        {icon="/icons/blind.png",           active=false, labelName="spell_label_blind",        buffType="debuff", order=18},
    infravision =  {icon="/icons/infravision.png",     active=false, labelName="spell_label_infravision",  buffType="buff",   order=19},
    detectevil =   {icon="/icons/detect_evil.png",     active=false, labelName="spell_label_detectevil",   buffType="buff",   order=20},
    detectgood =   {icon="/icons/detect_good.png",     active=false, labelName="spell_label_detectgood",   buffType="buff",   order=21},
    detectinv =    {icon="/icons/detect_inv.png",      active=false, labelName="spell_label_detectinv",    buffType="buff",   order=22},
    detectmagic =  {icon="/icons/detect_magic.png",    active=false, labelName="spell_label_detectmagic",  buffType="buff",   order=23},
    senselife =    {icon="/icons/senselife.png",       active=false, labelName="spell_label_senselife",    buffType="buff",   order=24},
  }


function MedUI.MedMap.mapStart()
  MedUI.MedMap.Console:clear()
  selectCurrentLine()
  local length = #ansi2string(getCurrentLine())

  if length < 80 then
    MedUI.MedMap.Console:setFontSize((tonumber(MedUI.options.mapFontSize) + 9) or 18)
  elseif length < 200 then
    MedUI.MedMap.Console:setFontSize((tonumber(MedUI.options.mapFontSize) + 3) or 12)
  else
    MedUI.MedMap.Console:setFontSize(tonumber(MedUI.options.mapFontSize) or 9)
  end
  copy()
  MedUI.MedMap.Console:appendBuffer()

  if not MedUI.options.keepInlineMap then
    deleteLine()
  end
end

function MedUI.MedMap.mapMid()
  selectCurrentLine()
  copy()
  MedUI.MedMap.Console:appendBuffer()
  if not MedUI.options.keepInlineMap then
    deleteLine()
  end
end

function MedUI.MedMap.mapEnd(roomName)
  selectCurrentLine()
  copy()
  MedUI.MedMap.Console:appendBuffer()
  if not MedUI.options.keepInlineMap then
    deleteLine()
  end

  -- paste the parsed name into the main console as we still want to see the room name
  if roomName and not MedUI.options.keepInlineMap then
    cecho("\n<yellow>"..roomName)
  end

  setTriggerStayOpen("MedieviaMapStart", 0)

end

---------------------------------------------------------------------------------
---- Buffs and Bars Code --------------------------------------------------------
---------------------------------------------------------------------------------
MedBuffsNBars = MedBuffsNBars or {}

local function makeGradientCSS(color)
  local gradMin
  local gradMax
  if color == "blue" then
      gradMax = "#0047b3"
      gradMin = "#b3d1ff"
    elseif color == "green" then
      gradMax = "#98f041"
      gradMin = "#66cc00"
    elseif color == "yellow" then
      gradMax = "#ffff00"
      gradMin = "#ffff66"
    elseif color == "red" then
      gradMax = "#ff0000"
      gradMin = "#ff9999"
    end

  if not gradMax or not gradMin then
    display("Failed to make gradiant for color: " .. color)
  end

  return string.format([[
    background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 1 %s);
    border-style: solid;
    border-color: white;
    border-width: 1px;
    border-radius: 5px;
    margin: 5px;
  ]], gradMax, gradMin)
end

local gaugeHeight = "90%"
local iconSize = "25px"

local function makeGaugeBox(iconFile, gaugeColor, labelText, containerName, x, y, column)
  -- Container for icon, text, gauge
  MedBuffsNBars[containerName] = Geyser.Container:new({
    name = containerName..".Footer",
    x = x, y = y,
    width = "20%",
  }, column)

  local icon = Geyser.Label:new({
    name = labelText.."_icon",
    x = "0px", y = "3px",
    width = iconSize, height = iconSize,
    color = "black",
  }, MedBuffsNBars[containerName])

  icon:setStyleSheet(string.format("border-image:url(%s);",
    getMudletHomeDir()..MedUI.iconLocation.."/icons/"..iconFile))

  local label = Geyser.Label:new({
    name = labelText.."_label",
    x = "5%", y = "7%",
    width = "10%", height = "25px",
    color = "black",
  }, MedBuffsNBars[containerName])
  label:echo("<center><p style='font-size:18px; color = white'><b>???<b></p></center>")

  local gauge = Geyser.Gauge:new({
    name = labelText.."_gauge",
    x = "15%", y = "0px",
    height = gaugeHeight,
    width = "70%",
  }, MedBuffsNBars[containerName])

  gauge.front:setStyleSheet(makeGradientCSS(gaugeColor))
  gauge.back:setStyleSheet([[
    background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #666666, stop: 1 #cccccc);
    border-style: solid;
    border-color: white;
    border-width: 1px;
    border-radius: 5px;
    margin: 5px;
  ]])
  gauge:setValue(math.random(100),100)
  gauge.front:echo([[<font color="black">]]..labelText..[[</font>]])

  MedBuffsNBars.gauges = MedBuffsNBars.gauges or {}
  MedBuffsNBars.gauges[labelText] = {}
  MedBuffsNBars.gauges[labelText].label = label
  MedBuffsNBars.gauges[labelText].gauge = gauge

  return MedBuffsNBars[containerName]
end

function MedUI.createGauges()

  -- Don't re-init
  if MedBuffsNBars.HPBox then
    return
  end

  --*** HP Gauge ***--
  MedBuffsNBars.HPBox = makeGaugeBox("hp.png", "red", "HP", "HPBox", 0, 0, MedBuffsNBars.LeftColumn)

  --***Mana Gauge***--
  MedBuffsNBars.ManaBox = makeGaugeBox("mana.png", "blue", "MP", "ManaBox", 0, 0, MedBuffsNBars.LeftColumn)

  --***MV Gauge***--
  MedBuffsNBars.MVBox = makeGaugeBox("mv.png", "yellow", "MV", "MVBox",  0, 0, MedBuffsNBars.RightColumn)

  --***Breath***--
  MedBuffsNBars.BRBox = makeGaugeBox("breath.png", "green", "BR", "BRBox", 0, "50%", MedBuffsNBars.RightColumn)

end

function MedUI.InitUI()

  -- Don't re-init if already done
  if MedBuffsNBars.Bottom then
    return
  end

  -- nullify the map window if it it somehow loaded with a 0 width
  if MedUI.MedMap.AdjCont and MedUI.MedMap.AdjCont:get_width() == 0 then
    MedUI.MedMap.AdjCont = nil
    MedUI.MedMap.Console = nil
  end

  -- Mapper container
  MedUI.MedMap.AdjCont = Adjustable.Container:new({
    name = "Medievia Map",
    x = "-30.303%", y = 0,
    width = "30.303%",
    height = "50%",
    lockStyle = "border",
    adjLabelstyle = "background-color:darkred; border: 0; padding: 1px;",
    autoLoad = true,
    autoSave = true
  })

  MedUI.MedMap.AdjCont:setTitle("Medievia Map")

  MedUI.MedMap.Console = Geyser.MiniConsole:new({
    name="MapConsole",
    x= 0, y= 0,
    autoWrap = false,
    color = "black",
    scrollBar = false,
    fontSize = tonumber(MedUI.options.mapFontSize) or 9,
    width="100%", height="100%",
  }, MedUI.MedMap.AdjCont)

  MedUI.MedMap.Console:setFont("Medievia Mudlet Sans Mono")
  MedUI.MedMap.AdjCont:connectToBorder("right")
  MedUI.MedMap.AdjCont:show()
  MedUI.MedMap.AdjCont:lockContainer("light")

  -- Gauge and Buffs containers
  MedBuffsNBars.Bottom = Geyser.Label:new({
    name = "MedBuffsNBars.Bottom",
    x = "20", y = "-6%",
    width = "50%",
    height = "6%",
  })
  MedBuffsNBars.Bottom:setStyleSheet("background-color: black;")

  MedBuffsNBars.Footer = Geyser.HBox:new({
    name = "MedBuffsNBars.Footer",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
  },MedBuffsNBars.Bottom)

  MedBuffsNBars.LeftColumn = Geyser.VBox:new({
    name = "MedBuffsNBars.LeftColumn",
  },MedBuffsNBars.Footer)

  MedBuffsNBars.RightColumn = Geyser.VBox:new({
    name = "MedBuffsNBars.RightColumn",
  },MedBuffsNBars.Footer)

  local bottomBoxHeight = MedBuffsNBars.Bottom:get_height()

  MedBuffsNBars.BuffBox = Geyser.Container:new({
    name = "playerBuffs",
    x= "1%", y=-bottomBoxHeight - 35,
    width = "25%", height="35",
  })

  MedUI.initAffects() --SpellEffects
end

--Helper function to show which buffs have been turned on in the table, used for debugging
-- lua med_showBuffTable()
-- Only used for debugging
function medBuffsNBars_showBuffTable()
  echo('\n')
  for k, v in pairs(MedUI.buffIconTable) do
    echo(v.icon.."::"..tostring(v.active).."::"..v.labelName.."::"..v.buffType..'\n')
  end
end


--All icons must be enabled by default, then we can show and hide
function MedUI.initAffects()

  local counter = 0
  MedBuffsNBars.sortedBuffTable = MedUI.sortedBuffsTable()

  for k, v in pairs(MedBuffsNBars.sortedBuffTable) do

    MedBuffsNBars.dynamic_x_int = 5 + (28*counter)
    MedBuffsNBars.dynamic_x_str = tostring(MedBuffsNBars.dynamic_x_int).."px"
    if not v.label then
      v.label = Geyser.Label:new({
        name = v.labelName,
        x = MedBuffsNBars.dynamic_x_str, y = "5px",
        width = "30px", height = "30px",
      }, MedBuffsNBars.BuffBox)
      local medPicImageLoc = getMudletHomeDir() .. MedUI.iconLocation .. v.icon
      v.label:setStyleSheet([[
        border-image:url(]]..medPicImageLoc..[[);
      ]])
    end
    --echo(v.icon.."::"..tostring(v.active).."::"..v.labelName.."::"..v.buffType..'\n')
    counter=counter + 1
  end
  --echo(counter..'\n')
end

--Does the actual work of checking the table for each buff and positioning it
function MedUI.buildAffects()
  --med_showBuffTable()

  local counter = 0

  local sortedBuffTable = MedBuffsNBars.sortedBuffTable or MedUI.sortedBuffsTable()
  for k, v in pairs(sortedBuffTable) do
    --echo('\n'..v.icon.."::"..tostring(v.active).."::"..v.labelName.."::"..v.buffType..'\n')
    MedBuffsNBars.dynamic_x_int = 5 + (28*counter)
    MedBuffsNBars.dynamic_x_str = tostring(MedBuffsNBars.dynamic_x_int).."px"
    if v.active then
      --echo("\nTEST"..v.icon.."\n")
      v.label:move(MedBuffsNBars.dynamic_x_int, 5)
      showWindow(v.labelName)
      counter = counter + 1
    end
  end

end

--Used to hide all of the buffs before an update
function MedUI.clearAffects()

  for k, v in pairs(MedUI.buffIconTable) do
    hideWindow(v.labelName)
  end
end

--Clears and the builds the buffs
function MedUI.updateAffects()
  MedUI.clearAffects()

  if MedUI.options.enableGauges then
    MedUI.buildAffects()
  end
end

--Used with testing to make sure icons are displaying, turns them all on
function medBuffsNBars_test_showAllBuffIcons()
  --med_showBuffTable()
  local counter = 0
  local sortedBuffTable = MedUI.sortedBuffsTable()
  for k, v in pairs(sortedBuffTable) do
    --echo('\n'..v.icon.."::"..tostring(v.active).."::"..v.labelName.."::"..v.buffType..'\n')
    MedBuffsNBars.dynamic_x_int = 5 + (28*counter)
    MedBuffsNBars.dynamic_x_str = tostring(MedBuffsNBars.dynamic_x_int).."px"
    v.label:move(MedBuffsNBars.dynamic_x_int, 5)
    --moveWindow(v.labelName, dynamic_x_int, 5)
    showWindow(v.labelName)
    counter = counter + 1
  end
end

--Used to sort the table in position of priority which is in the buff table
--KEEP IN MIND THIS CREATES A SECOND TABLE THAT IS USED TEMPORARILY
--DO NOT ATTEMPT TO SET VALUES IN THIS TABLE
function MedUI.sortedBuffsTable()
  local sortedBuffTable = {}
  for k, v in pairs(MedUI.buffIconTable) do
    sortedBuffTable[v.order] = v
  end
  return sortedBuffTable
end

--Turns off all buffs in the table itself. Used with "SC" and "SC A" to clear buffs and reset them
-- Provides a way to resync buffs when first logging on.
-- It can also fix buffs that may have fallen off but not been caught by trigger for whatever reason.
function MedUI.allBuffsOff()
  for k, v in pairs(MedUI.buffIconTable) do
    v.active = false
  end
end

function MedUI.enableGauges()

  MedUI.clearAffects()
  MedUI.createGauges()

  registerNamedEventHandler("MedUI", "MedBuffsNBars", "gmcp.Char.Vitals", "MedUI.updateVitals")
  registerNamedEventHandler("MedUI", "MedBuffs", "gmcp.Char.Afflictions", "MedUI.updateAfflictions")

  tempTimer(.1, function()
    MedBuffsNBars.Bottom:show()

    local totalHeight = math.ceil(tonumber(MedBuffsNBars.BuffBox:get_height()) + tonumber(MedBuffsNBars.Bottom:get_height()))
    -- Only capture the pre-gauge border when re-enabling after an explicit disable.
    -- On first load the initial value is captured at table construction (line 81).
    -- On reinstall while gauges are active, Bottom is not hidden and getBorderBottom()
    -- would return the gauge height, which would corrupt the restore on disable.
    if MedBuffsNBars.Bottom["hidden"] then
      MedUI.oldBorderBottom = getBorderBottom()
    end
    setBorderBottom(totalHeight)
  end)

end

function MedUI.disableGauges()
  setBorderBottom(MedUI.oldBorderBottom)
  if MedBuffsNBars.Bottom then
    MedBuffsNBars.Bottom:hide()
  end

  -- hide buffs container too
  if MedBuffsNBars.BuffBox then
    MedUI.clearAffects()
    MedBuffsNBars.BuffBox:hide()
  end
end


function MedUI.enableMultiPlay()
  if MultiPlay then
    MultiPlay.enableModule()
  end
end


function MedUI.disableMultiPlay()
  if MultiPlay then
    MultiPlay.disableModule()
  end
end


function MedUI.updateAfflictions()
  if not MedUI.options.enableGauges then
    return
  end

  local added = gmcp.Char.Afflictions.Add

  if added and added.name then
      local affName = added.name
      local affTicks = added.ticks
      local shortName = MedUI.affTable[affName]
      if shortName then
        if MedUI.options.enableGauges then
          MedUI.buffIconTable[shortName].active = true
          MedUI.updateAffects()
        end
      end
  end

  local removed = gmcp.Char.Afflictions.Remove

  if removed then
    local shortName = MedUI.affTable[removed]
    if shortName and MedUI.options.enableGauges then
      MedUI.buffIconTable[shortName].active = false
      MedUI.updateAffects()
    end
  end
end


-- Update gauge values from data parsed from GMCP
function MedUI.updateVitals()
  if not MedUI.options.enableGauges or not gmcp.Char then
    return
  end

  if not MedBuffsNBars.gauges or not MedBuffsNBars.gauges["HP"] then
    return
  end

  local vitals = gmcp.Char.Vitals

  if vitals.hp and vitals.maxHp then
    MedBuffsNBars.gauges["HP"].gauge:setValue(vitals.hp, vitals.maxHp)
    MedBuffsNBars.gauges["HP"].label:echo("<center><p style='font-size:18px; color = white'><b>".. vitals.hp .."<b></p></center>")
  end

  if vitals.mana and vitals.maxMana then
    MedBuffsNBars.gauges["MP"].gauge:setValue(vitals.mana, vitals.maxMana)
    MedBuffsNBars.gauges["MP"].label:echo("<center><p style='font-size:18px; color = white'><b>".. vitals.mana .."<b></p></center>")
  end

  if vitals.mv and vitals.maxMv then
    MedBuffsNBars.gauges["MV"].gauge:setValue(vitals.mv, vitals.maxMv)
    MedBuffsNBars.gauges["MV"].label:echo("<center><p style='font-size:18px; color = white'><b>".. vitals.mv .."<b></p></center>")
  end

  if vitals.br then
    MedBuffsNBars.gauges["BR"].gauge:setValue(vitals.br, 100)
    MedBuffsNBars.gauges["BR"].label:echo("<center><p style='font-size:18px; color = white'><b>".. vitals.br .."<b></p></center>")
  end

end


---------------------------------------------------------------------------------
---- End Buffs and Bars Code ----------------------------------------------------
---------------------------------------------------------------------------------

function MedUI.config(arg)

  if arg and arg ~= " " then
    local logoPath = getMudletHomeDir() .. MedUI.iconLocation .. "/graphics/medui.ans"
    local f, err = io.open(logoPath, "r")
    if f then
      local logo = f:read("*a")
      f:close()
      decho("\n" .. ansi2decho(logo))
    else
      cecho("\n<red>MedUI: could not load logo (" .. tostring(err) .. ")")
    end
  end


  cecho("<DeepSkyBlue>MedUI by <firebrick>Kymbahl <DeepSkyBlue>& <gold>Kronos<DeepSkyBlue>, version: <orange>" .. MedUI.version .. "\n")

  local optionsList = {
    {description = "Enable Gauges", optionKey = "enableGauges", type = "toggle", helpKey = "<white>'<yellow>medui %d<white>' or '<yellow>medui gauges<white>' to toggle"},
    {description = "Keep Inline Map", optionKey = "keepInlineMap", type = "toggle", helpKey = "<white>'<yellow>medui %d<white>' or '<yellow>medui inlinemap<white>' to toggle"},
    {description = "Enable Timestamps", optionKey = "enableTimestamps", type = "toggle", helpKey = "<white>'<yellow>medui %d<white>' or '<yellow>medui timestamp<white>' to toggle"},
    {description = "Map Font Size", optionKey = "mapFontSize", type = "value",
      specialAction = function() MedUI.MedMap.Console:setFontSize(tonumber(MedUI.options.mapFontSize) or 9) end, 
      helpKey = "<white>'<yellow>medui %d <size><white>' or '<yellow>medui mapFontSize <size><white>' to adjust"},
    {description = "Chat Font Size", optionKey = "chatFontSize", type = "value",
      specialAction = function() MedChat.EMCOConsole:setFontSize(tonumber(MedUI.options.chatFontSize) or 8) end,
      helpKey = "<white>'<yellow>medui %d <size><white>' or '<yellow>medui chatFontSize <size><white>' to adjust"},
    {description = "Enable MultiPlay Module", optionKey = "enableMultiPlay", type = "toggle",
      helpKey = "<white>'<yellow>medui %d<white>' or '<yellow>medui mp<white>' to toggle"},
    {description = "MultiPlay Gauge Mode", optionKey = "mpGaugeMode", type = "toggle",
      specialAction = function() MPWindow.setDisplayMode(MedUI.options.mpGaugeMode) end,
      helpKey = "<white>'<yellow>medui %d<white>' or '<yellow>medui mpgauges<white>' to toggle"}
  }

  local args = {}
  for a in arg:gmatch("%S+") do table.insert(args, a) end

  local argNum = tonumber(args[1])
  if argNum and optionsList[argNum] then
    local selectedOption = optionsList[argNum]

    if selectedOption.type == "toggle" then
      -- Toggle the option
      MedUI.options[selectedOption.optionKey] = not MedUI.options[selectedOption.optionKey]
    else
      if args[2] then
        MedUI.options[selectedOption.optionKey] = args[2]
      end

    end
    -- Execute any special action if defined
    if selectedOption.specialAction then
      selectedOption.specialAction()
    end
  end

  local YES = "<green>YES"
  local NO = "<red>NO"

	local str = "\n<DeepSkyBlue>Options:"
  for i, option in ipairs(optionsList) do

    if option.type == "toggle" then
      local status = MedUI.options[option.optionKey] and YES or NO
      str = string.format("%s\n<DeepSkyBlue>%2d] %-26s: %s     %s%s",
        str,
        i,
        option.description,
        status,
        (status == NO and " " or ""), -- Need extra space here because apparently strlen is broken with color tags
        string.format(option.helpKey, i))
    else
      local value = MedUI.options[option.optionKey]
      str = string.format("%s\n<DeepSkyBlue>%2d] %-26s: %s%s%s",
        str,
        i,
        option.description,
        value,
        string.rep(" ", 8 - string.len(tostring(value))),
        string.format(option.helpKey, i))
    end
  end
  str = string.format("%s\n", str)
  cecho(str)

  MedUI.reconfigure()

  if arg and arg ~= "" then
    MedUI.saveOptions()
  end
end

function MedUI.setMudletOptions()
  tempTimer(1, function() 

    setFont("main", "Medievia Mudlet Sans Mono")

    setServerEncoding("MEDIEVIA")
    setConfig("controlCharacterHandling", "oem")

    if MedUI.MedMap and MedChat and MedUI.MedMap.AdjCont and MedChat.AdjCont
      and not MedUI.MedMap.AdjCont["hidden"] and not MedChat.AdjCont["hidden"] then
      local w,h = getMainWindowSize()
      setBorderRight(w/3.3)
    end

    -- Disable the generic_mapper "English Exits Trigger" to allow the Medievia mapper to function properly
    disableTrigger("English Exits Trigger")

    -- Add A Medievia prompt test pattern to the mapper test patterns
    local test_pattern = "^%b()<(.-)>"
    if map then
      if not table.index_of(map.defaults.prompt_test_patterns, test_pattern) then
        table.insert(map.defaults.prompt_test_patterns, "^%b()<(.-)>")
      end
    end
  end)
end

function MedUI.reconfigure()

    MedUI.setMudletOptions()

    if MedUI.options.enableGauges then
        MedUI.enableGauges()
        MedUI.updateVitals()
    else
        MedUI.disableGauges()
    end

    if MedUI.options.enableMultiPlay then
      MedUI.enableMultiPlay()
    else
      MedUI.disableMultiPlay()
    end

    if MPWindow then
      MPWindow.setDisplayMode(MedUI.options.mpGaugeMode)
    end

end

function MedUI.loadOptions()
  local charName = string.lower(getProfileName())

  local loadTable = {}
  local tablePath = getMudletHomeDir().."/medui_"..charName..".lua"
  if io.exists(tablePath) then
    table.load(tablePath, loadTable)
  end

  MedUI.options = table.deepcopy(loadTable.options)

  MedUI.options = MedUI.options or {
    enableGauges = true,
    keepInlineMap = false,
    enableTimestamps = true,
    mapFontSize = 9,
    chatFontSize = 8,
    enableMultiPlay = false,
    mpGaugeMode = false
  }

  cecho("\n<DeepSkyBlue> MedUI: loaded options for <yellow>" .. charName .. "\n")
  MedUI.charName = charName
end

function MedUI.saveOptions()
  local charName = string.lower(getProfileName())

  local saveTable = {
    options = table.deepcopy(MedUI.options)
  }

  table.save(getMudletHomeDir().."/medui_"..charName..".lua", saveTable)

  cecho("\n<DeepSkyBlue> MedUI: saved options for <yellow>" .. charName .. "\n")
  MedUI.charName = charName
end


function MedUI.eventHandler(event, ...)

    if event == "sysWindowResizeEvent" then
        local x, y, windowName = arg[1], arg[2], arg[3]

        -- MedChat may not be loaded yet, so check for it, MedUI.MedMap is loaded at the top of this file
        if windowName == "main" and MedUI.MedMap and MedUI.MedMap.AdjCont and MedChat and MedChat.AdjCont then
          if not MedUI.MedMap.AdjCont["hidden"] and not MedChat.AdjCont["hidden"] then
            local w,h = getMainWindowSize()
            setBorderRight(w/3.3)
          end
        end

    elseif event == "sysLoadEvent" then
      MedUI.doConnectionSetup()
      closeMapWidget()

    elseif event == "sysInstallPackage" and arg[1] == "MedUI" then
      MedUI.doConnectionSetup()
      MedUI.config(" ")
      MedUI.setMudletOptions()
      closeMapWidget()

    elseif event == "sysUninstallPackage" and arg[1] == "MedUI" then
        stopNamedEventHandler("MedUI", "MedUIResize")
        stopNamedEventHandler("MedUI", "MedUILoad")
        stopNamedEventHandler("MedUI", "MedUIInstall")
        stopNamedEventHandler("MedUI", "MedUIUninstall")
        stopNamedEventHandler("MedUI", "MedBuffsNBars")
        if MedChat and MedChat.AdjCont then
          MedChat.AdjCont:delete()
          MedChat.AdjCont = nil
          MedChat.EMCOConsole = nil
        end
        if MedUI.MedMap and MedUI.MedMap.AdjCont then
          MedUI.MedMap.AdjCont:delete()
          MedUI.MedMap.AdjCont = nil
          MedUI.MedMap.Console = nil
        end
        if MedBuffsNBars.Bottom then
          MedBuffsNBars.Bottom:delete()
          MedBuffsNBars.Bottom = nil
        end
        if MPWindow then
          MPWindow.window:delete()
          MPWindow.window = nil
          MPWindow.console = nil
          MPWindow.gaugeContainer = nil
          MPWindow.gaugeFrames = {}
        end
        MedBuffsNBars.Footer = nil
        MedBuffsNBars.LeftColumn = nil
        MedBuffsNBars.RightColumn = nil
        MedBuffsNBars.HPBox = nil
        MedBuffsNBars.ManaBox = nil
        MedBuffsNBars.MVBox = nil
        MedBuffsNBars.BRBox = nil
        MedBuffsNBars.gauges = nil
        if MedBuffsNBars.BuffBox then
          MedBuffsNBars.BuffBox:delete()
          MedBuffsNBars.BuffBox = nil
        end
        for _, v in pairs(MedUI.buffIconTable) do
          v.label = nil
        end
        setBorderRight(0)
        setBorderBottom(0)

    end
end

registerNamedEventHandler("MedUI", "MedUIResize", "sysWindowResizeEvent", "MedUI.eventHandler")
registerNamedEventHandler("MedUI", "MedUILoad", "sysLoadEvent", "MedUI.eventHandler")
registerNamedEventHandler("MedUI", "MedUIInstall", "sysInstallPackage", "MedUI.eventHandler")
registerNamedEventHandler("MedUI", "MedUIUninstall", "sysUninstallPackage", "MedUI.eventHandler")

if MedUI.configAlias then
  killAlias(MedUI.configAlias)
end

MedUI.configAlias = tempAlias("^medui\\s*(.*)?$", [[MedUI.config(matches[2])]])

if MedUI.gaugeAlias then
  killAlias(MedUI.gaugeAlias)
end

MedUI.gaugeAlias = tempAlias("^medui gauges$", [[MedUI.config(1)]])

if MedUI.inlineMapAlias then
  killAlias(MedUI.inlineMapAlias)
end

MedUI.inlineMapAlias = tempAlias("^medui inlinemap$", [[MedUI.config(2)]])

if MedUI.timestampAlias then
  killAlias(MedUI.timestampAlias)
end

MedUI.timestampAlias = tempAlias("^medui timestamp$", [[MedUI.config(3)]])

if MedUI.mapFontAlias then
  killAlias(MedUI.mapFontAlias)
end

MedUI.mapFontAlias = tempAlias("^medui mapFontSize (\\d+)$", [[MedUI.config("4 " .. matches[2])]])

if MedUI.chatFontAlias then
  killAlias(MedUI.chatFontAlias)
end

MedUI.chatFontAlias = tempAlias("^medui chatFontSize (\\d+)$", [[MedUI.config("5 " .. matches[2])]])

if MedUI.multiPlayAlias then
  killAlias(MedUI.multiPlayAlias)
end

MedUI.multiPlayAlias = tempAlias("^medui mp$", [[MedUI.config("6")]])

if MedUI.mpGaugesAlias then
  killAlias(MedUI.mpGaugesAlias)
end

MedUI.mpGaugesAlias = tempAlias("^medui mpgauges$", [[MedUI.config("7")]])

MedUI.charName = string.lower(getProfileName())

local setupComplete = false

function MedUI.doConnectionSetup()

  if setupComplete then
    return
  end
  setupComplete = true

  -- Defer one tick so Qt drains its deleteLater queue (old TLabels from
  -- before resetProfile) before any luaL_ref runs for our new callbacks.
  --tempTimer(0, function()
  -- fixed in PTB
    MedUI.InitUI()
    MedUI.loadOptions()
    MedUI.reconfigure()

    loadMap(getMudletHomeDir().."/MedUI/MedieviaMap.dat")
    closeMapWidget()
  --end)
end

registerNamedEventHandler("MedUI", "MedLoginHandler", "gmcp.Char.Info", "MedUI.doConnectionSetup")
