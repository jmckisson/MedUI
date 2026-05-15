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

  local logo = ""
  logo = logo .. "\27[38;2;104;0;0;48;2;122;0;0m▄\27[38;2;115;0;0;48;2;122;0;0m▄\27[38;2;121;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m                                                        \27[38;2;15;0;0;48;2;98;0;0m▄\27[48;2;0;0;0m              \27[38;2;29;0;0;48;2;82;0;0m▄\27[38;2;122;0;0;48;2;98;0;0m▄\27[38;2;29;0;0;48;2;0;0;0m▄\27[38;2;11;0;0;48;2;33;0;0m▄\27[48;2;122;0;0m \27[38;2;5;1;0;48;2;0;0;0m▄\27[48;2;0;0;0m                    \27[m\n"
  logo = logo .. "\27[48;2;0;0;0m  \27[38;2;0;0;0;48;2;6;0;0m▄\27[38;2;0;0;0;48;2;70;0;0m▄\27[38;2;23;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m                              \27[38;2;125;1;1;48;2;122;0;0m▄\27[38;2;132;11;11;48;2;122;0;0m▄\27[38;2;139;25;25;48;2;123;0;0m▄\27[38;2;132;11;11;48;2;122;0;0m▄\27[38;2;126;2;1;48;2;122;0;0m▄\27[38;2;125;1;1;48;2;122;0;0m▄\27[38;2;126;2;1;48;2;122;0;0m▄▄\27[48;2;122;0;0m               \27[38;2;14;1;0;48;2;92;0;0m▄\27[38;2;2;1;0;48;2;0;0;0m▄▄\27[48;2;0;0;0m             \27[38;2;0;0;0;48;2;7;0;0m▄\27[38;2;102;0;0;48;2;119;0;0m▄\27[38;2;122;0;0;48;2;119;0;0m▄\27[38;2;99;0;0;48;2;6;0;0m▄\27[38;2;82;0;0;48;2;117;0;0m▄\27[38;2;121;0;0;48;2;77;0;0m▄\27[38;2;6;0;0;48;2;0;0;0m▄\27[48;2;0;0;0m                   \27[m\n"
  logo = logo .. "\27[48;2;0;0;0m     \27[38;2;0;0;0;48;2;12;0;0m▄\27[38;2;51;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m                           \27[38;2;122;0;0;48;2;123;0;0m▄\27[48;2;131;9;9m \27[38;2;169;95;85;48;2;177;108;100m▄\27[38;2;239;236;214;48;2;213;194;165m▄\27[38;2;174;100;95;48;2;160;70;67m▄\27[38;2;138;22;22;48;2;131;9;9m▄\27[38;2;141;29;29;48;2;134;15;15m▄\27[38;2;239;236;214;48;2;167;88;79m▄\27[38;2;187;129;114;48;2;147;44;40m▄\27[38;2;127;4;4;48;2;127;3;2m▄\27[48;2;122;0;0m             \27[38;2;94;2;2;48;2;120;1;0m▄\27[38;2;38;33;16;48;2;20;17;7m▄\27[38;2;239;236;214;48;2;94;91;78m▄\27[38;2;103;101;92;48;2;41;37;23m▄\27[48;2;2;1;0m \27[48;2;0;0;0m             \27[38;2;0;0;0;48;2;32;0;0m▄\27[38;2;109;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m \27[38;2;122;0;0;48;2;100;0;0m▄\27[48;2;122;0;0m \27[38;2;122;0;0;48;2;86;0;0m▄\27[38;2;35;0;0;48;2;0;0;0m▄\27[48;2;0;0;0m                  \27[m\n"
  logo = logo .. "\27[48;2;0;0;0m      \27[38;2;0;0;0;48;2;2;0;0m▄\27[38;2;58;0;0;48;2;120;0;0m▄\27[48;2;122;0;0m   \27[38;2;124;1;0;48;2;122;0;0m▄\27[38;2;129;7;6;48;2;122;0;0m▄\27[38;2;133;15;15;48;2;122;0;0m▄\27[38;2;132;12;12;48;2;122;0;0m▄\27[38;2;131;8;8;48;2;122;0;0m▄\27[38;2;136;19;19;48;2;122;0;0m▄\27[38;2;133;14;14;48;2;122;0;0m▄\27[38;2;129;7;6;48;2;122;0;0m▄\27[38;2;132;11;10;48;2;122;0;0m▄\27[38;2;135;18;18;48;2;122;0;0m▄\27[38;2;133;14;13;48;2;122;0;0m▄\27[38;2;125;1;1;48;2;122;0;0m▄\27[48;2;122;0;0m  \27[38;2;124;1;0;48;2;122;0;0m▄\27[38;2;129;7;6;48;2;122;0;0m▄\27[38;2;131;11;10;48;2;122;0;0m▄\27[38;2;133;14;14;48;2;122;0;0m▄\27[38;2;129;7;6;48;2;122;0;0m▄\27[38;2;124;1;0;48;2;122;0;0m▄\27[48;2;122;0;0m \27[38;2;124;1;0;48;2;122;0;0m▄\27[38;2;129;7;6;48;2;122;0;0m▄\27[38;2;135;18;18;48;2;122;0;0m▄\27[38;2;136;19;19;48;2;126;3;2m▄\27[38;2;156;64;62;48;2;154;57;57m▄\27[38;2;230;223;196;48;2;232;225;199m▄\27[48;2;174;100;95m \27[38;2;134;16;16;48;2;137;21;21m▄\27[38;2;132;10;10;48;2;131;9;9m▄\27[38;2;137;20;20;48;2;145;37;37m▄\27[38;2;135;16;16;48;2;142;30;30m▄\27[38;2;126;2;1;48;2;127;3;2m▄\27[48;2;122;0;0m \27[38;2;124;1;0;48;2;122;0;0m▄\27[38;2;129;7;6;48;2;122;0;0m▄\27[38;2;131;11;10;48;2;122;0;0m▄\27[38;2;133;14;14;48;2;122;0;0m▄\27[38;2;129;7;6;48;2;122;0;0m▄\27[38;2;125;2;1;48;2;122;0;0m▄\27[38;2;129;7;6;48;2;122;0;0m▄\27[38;2;136;19;19;48;2;122;0;0m▄\27[38;2;137;20;20;48;2;122;0;0m▄\27[38;2;129;7;6;48;2;122;0;0m▄\27[38;2;128;5;5;48;2;122;0;0m▄\27[38;2;130;7;7;48;2;122;0;0m▄\27[38;2;51;12;8;48;2;62;0;0m▄\27[38;2;19;16;6;48;2;23;20;9m▄\27[38;2;28;25;11;48;2;42;39;26m▄\27[38;2;14;12;4;48;2;29;25;11m▄\27[48;2;2;1;0m \27[38;2;1;1;0;48;2;0;0;0m▄\27[38;2;6;5;1;48;2;0;0;0m▄\27[38;2;13;11;4;48;2;0;0;0m▄\27[38;2;17;15;6;48;2;0;0;0m▄\27[38;2;18;16;6;48;2;0;0;0m▄\27[38;2;7;5;1;48;2;0;0;0m▄\27[38;2;1;0;0;48;2;0;0;0m▄\27[48;2;0;0;0m       \27[38;2;1;0;0;48;2;5;0;0m▄\27[38;2;105;0;0;48;2;120;0;0m▄\27[48;2;122;0;0m    \27[38;2;122;0;0;48;2;34;0;0m▄\27[38;2;67;0;0;48;2;0;0;0m▄\27[38;2;9;0;0;48;2;0;0;0m▄▄\27[38;2;120;0;0;48;2;82;0;0m▄\27[38;2;14;0;0;48;2;0;0;0m▄\27[48;2;0;0;0m            \27[m\n"
  logo = logo .. "\27[48;2;0;0;0m       \27[38;2;0;0;0;48;2;14;0;0m▄\27[38;2;114;0;0;48;2;120;0;0m▄\27[48;2;122;0;0m  \27[38;2;132;11;11;48;2;127;4;3m▄\27[38;2;165;86;79;48;2;173;104;92m▄\27[38;2;239;236;214;48;2;217;195;168m▄\27[38;2;203;171;147;48;2;154;60;59m▄\27[38;2;151;52;52;48;2;202;170;144m▄\27[38;2;167;88;83;48;2;229;216;195m▄\27[38;2;239;236;214;48;2;181;123;109m▄\27[38;2;221;209;180;48;2;152;53;53m▄\27[38;2;152;53;53;48;2;198;160;135m▄\27[38;2;163;78;76;48;2;230;217;197m▄\27[38;2;239;236;214;48;2;189;140;118m▄\27[38;2;172;102;88;48;2;142;30;30m▄\27[38;2;134;14;14;48;2;126;2;1m▄\27[38;2;137;21;21;48;2;126;2;1m▄\27[38;2;184;126;112;48;2;137;21;21m▄\27[38;2;221;206;180;48;2;159;71;67m▄\27[38;2;158;70;67;48;2;212;190;162m▄\27[38;2;166;83;80;48;2;218;196;169m▄\27[38;2;239;236;214;48;2;153;58;57m▄\27[38;2;162;77;72;48;2;136;18;18m▄\27[38;2;136;18;18;48;2;126;2;1m▄\27[38;2;166;88;82;48;2;136;18;18m▄\27[38;2;238;234;212;48;2;151;51;51m▄\27[38;2;170;96;87;48;2;216;195;169m▄\27[38;2;150;49;49;48;2;222;203;178m▄\27[38;2;172;100;91;48;2;179;117;103m▄\27[38;2;238;234;211;48;2;231;223;197m▄\27[38;2;176;104;98;48;2;174;100;95m▄\27[48;2;138;22;22m \27[38;2;149;48;48;48;2;157;63;61m▄\27[38;2;234;229;205;48;2;199;167;142m▄\27[38;2;203;160;148;48;2;187;128;116m▄\27[38;2;136;19;19;48;2;133;12;12m▄\27[38;2;137;21;21;48;2;126;2;1m▄\27[38;2;184;126;112;48;2;137;21;21m▄\27[38;2;221;206;180;48;2;159;71;67m▄\27[38;2;158;70;67;48;2;212;190;162m▄\27[38;2;166;83;80;48;2;218;196;169m▄\27[38;2;239;236;214;48;2;153;58;57m▄\27[38;2;164;81;75;48;2;141;28;28m▄\27[38;2;146;38;38;48;2;147;43;41m▄\27[38;2;200;160;143;48;2;221;203;178m▄\27[38;2;239;236;214;48;2;215;194;166m▄\27[38;2;156;63;61;48;2;189;139;119m▄\27[38;2;140;27;27;48;2;137;21;21m▄\27[38;2;166;84;79;48;2;217;194;167m▄\27[38;2;105;65;62;48;2;194;183;163m▄\27[38;2;72;71;66;48;2;70;69;64m▄\27[38;2;235;230;207;48;2;172;170;157m▄\27[38;2;128;126;114;48;2;101;99;90m▄\27[38;2;21;18;7;48;2;10;8;2m▄\27[38;2;26;23;10;48;2;11;10;3m▄\27[38;2;232;229;207;48;2;50;49;45m▄\27[38;2;53;52;49;48;2;167;164;146m▄\27[38;2;50;48;41;48;2;183;182;178m▄\27[38;2;121;116;96;48;2;189;189;186m▄\27[38;2;219;215;195;48;2;70;68;60m▄\27[38;2;37;35;26;48;2;12;10;3m▄\27[38;2;1;1;0;48;2;0;0;0m▄\27[48;2;0;0;0m     \27[38;2;13;0;0;48;2;0;0;0m▄\27[38;2;122;0;0;48;2;57;0;0m▄\27[48;2;122;0;0m       \27[38;2;122;0;0;48;2;121;0;0m▄▄\27[48;2;122;0;0m \27[38;2;122;0;0;48;2;100;0;0m▄\27[38;2;109;0;0;48;2;0;0;0m▄\27[38;2;27;0;0;48;2;0;0;0m▄\27[48;2;0;0;0m          \27[m\n"
  logo = logo .. "\27[48;2;0;0;0m        \27[38;2;20;0;0;48;2;63;0;0m▄\27[48;2;122;0;0m  \27[38;2;127;3;2;48;2;127;3;3m▄\27[38;2;158;65;64;48;2;158;67;65m▄\27[38;2;237;233;210;48;2;238;234;211m▄\27[38;2;162;75;73;48;2;169;94;86m▄\27[38;2;135;16;16;48;2;137;21;21m▄\27[38;2;150;49;49;48;2;155;61;60m▄\27[38;2;230;223;196;48;2;233;226;201m▄\27[38;2;174;100;95;48;2;181;119;107m▄\27[38;2;138;22;22;48;2;141;29;29m▄\27[38;2;148;46;46;48;2;150;49;49m▄\27[48;2;239;236;214m \27[38;2;194;147;130;48;2;193;145;128m▄\27[38;2;141;29;29;48;2;139;24;24m▄\27[38;2;163;81;73;48;2;152;52;51m▄\27[38;2;239;236;214;48;2;234;228;204m▄\27[38;2;179;116;102;48;2;226;211;189m▄\27[38;2;148;45;45;48;2;216;188;172m▄\27[38;2;143;34;34;48;2;217;190;174m▄\27[38;2;142;32;32;48;2;239;236;214m▄\27[38;2;139;25;25;48;2;182;118;110m▄\27[38;2;151;50;50;48;2;150;48;48m▄\27[38;2;233;226;200;48;2;217;198;175m▄\27[38;2;202;169;142;48;2;216;207;175m▄\27[38;2;141;29;29;48;2;148;46;45m▄\27[38;2;126;2;1;48;2;134;13;13m▄\27[38;2;151;50;50;48;2;155;61;60m▄\27[48;2;230;223;196m \27[48;2;174;100;95m \27[38;2;133;13;13;48;2;138;22;22m▄\27[38;2;144;36;36;48;2;145;39;39m▄\27[48;2;224;213;183m \27[48;2;203;160;148m \27[38;2;142;31;31;48;2;141;30;30m▄\27[38;2;163;81;73;48;2;153;54;53m▄\27[38;2;239;236;214;48;2;234;228;204m▄\27[38;2;179;116;102;48;2;226;211;189m▄\27[38;2;148;45;45;48;2;216;188;172m▄\27[38;2;143;34;34;48;2;217;190;174m▄\27[38;2;142;32;32;48;2;239;236;214m▄\27[38;2;134;15;15;48;2;181;115;107m▄\27[38;2;127;3;2;48;2;136;18;18m▄\27[38;2;145;39;39;48;2;163;80;75m▄\27[38;2;229;218;197;48;2;238;235;213m▄\27[38;2;214;189;166;48;2;170;96;87m▄\27[38;2;154;60;59;48;2;145;37;37m▄\27[38;2;173;103;91;48;2;209;184;156m▄\27[38;2;112;12;12;48;2;81;29;21m▄\27[38;2;50;49;47;48;2;53;52;48m▄\27[38;2;227;218;190;48;2;219;216;202m▄\27[38;2;138;135;120;48;2;134;131;117m▄\27[38;2;24;21;9;48;2;25;22;9m▄\27[38;2;12;10;3;48;2;11;9;3m▄\27[38;2;40;36;19;48;2;59;54;35m▄\27[38;2;73;72;67;48;2;40;35;17m▄\27[38;2;197;191;167;48;2;48;47;41m▄\27[38;2;135;132;124;48;2;133;130;119m▄\27[48;2;239;236;214m \27[38;2;58;58;55;48;2;57;57;54m▄\27[38;2;2;1;0;48;2;1;1;0m▄\27[48;2;0;0;0m    \27[38;2;27;0;0;48;2;0;0;0m▄\27[38;2;122;0;0;48;2;106;0;0m▄\27[48;2;122;0;0m              \27[38;2;122;0;0;48;2;90;0;0m▄\27[38;2;55;0;0;48;2;0;0;0m▄\27[48;2;0;0;0m        \27[m\n"
  logo = logo .. "\27[48;2;0;0;0m         \27[48;2;122;0;0m  \27[38;2;127;4;3;48;2;127;3;2m▄\27[48;2;158;65;64m \27[48;2;237;233;210m \27[38;2;166;85;79;48;2;162;74;72m▄\27[48;2;135;16;16m \27[38;2;153;56;56;48;2;151;50;50m▄\27[48;2;230;223;196m \27[38;2;178;112;103;48;2;174;100;95m▄\27[38;2;140;27;27;48;2;138;22;22m▄\27[38;2;148;46;46;48;2;147;43;43m▄\27[48;2;239;236;214m \27[48;2;194;147;130m \27[48;2;141;29;29m \27[38;2;144;36;36;48;2;159;71;67m▄\27[38;2;222;203;183;48;2;239;236;214m▄\27[38;2;231;222;199;48;2;186;134;115m▄\27[38;2;153;55;54;48;2;141;29;29m▄\27[38;2;140;26;26;48;2;127;3;2m▄\27[38;2;148;45;43;48;2;127;3;3m▄\27[38;2;148;46;40;48;2;128;5;5m▄\27[38;2;141;29;29;48;2;148;45;45m▄\27[38;2;199;154;137;48;2;227;219;192m▄\27[38;2;237;234;211;48;2;204;176;149m▄\27[38;2;154;59;58;48;2;143;33;33m▄\27[38;2;139;25;25;48;2;127;3;3m▄\27[38;2;159;73;69;48;2;152;54;53m▄\27[38;2;239;236;214;48;2;230;223;196m▄\27[38;2;191;146;123;48;2;177;107;99m▄\27[38;2;143;33;33;48;2;138;22;22m▄\27[38;2;148;45;45;48;2;144;36;36m▄\27[48;2;224;213;183m \27[38;2;205;168;152;48;2;203;160;148m▄\27[38;2;145;38;38;48;2;141;30;30m▄\27[38;2;147;43;42;48;2;159;71;67m▄\27[38;2;222;203;183;48;2;239;236;214m▄\27[38;2;231;222;199;48;2;186;134;115m▄\27[38;2;154;59;58;48;2;141;29;29m▄\27[38;2;140;26;26;48;2;127;3;2m▄\27[38;2;148;45;43;48;2;127;3;3m▄\27[38;2;147;46;39;48;2;126;2;1m▄\27[38;2;125;2;1;48;2;122;0;0m▄\27[38;2;128;6;6;48;2;135;17;17m▄\27[38;2;151;53;52;48;2;175;107;95m▄\27[38;2;239;236;214;48;2;236;231;208m▄\27[38;2;211;185;159;48;2;196;156;132m▄\27[38;2;139;25;25;48;2;144;34;34m▄\27[38;2;126;2;1;48;2;119;7;7m▄\27[38;2;58;50;48;48;2;50;50;47m▄\27[38;2;227;218;190;48;2;228;219;191m▄\27[48;2;138;135;120m \27[38;2;37;33;16;48;2;25;22;10m▄\27[38;2;57;54;43;48;2;33;32;27m▄\27[38;2;239;236;214;48;2;173;171;159m▄\27[38;2;143;138;117;48;2;192;186;161m▄\27[38;2;73;72;67;48;2;64;63;60m▄\27[38;2;124;117;96;48;2;116;111;94m▄\27[48;2;239;236;214m \27[38;2;78;76;70;48;2;58;58;55m▄\27[38;2;18;15;6;48;2;5;4;1m▄\27[48;2;0;0;0m    \27[38;2;97;0;0;48;2;65;0;0m▄\27[48;2;122;0;0m                \27[38;2;122;0;0;48;2;117;0;0m▄\27[38;2;40;0;0;48;2;0;0;0m▄\27[48;2;0;0;0m       \27[m\n"
  logo = logo .. "\27[48;2;0;0;0m         \27[38;2;82;0;0;48;2;105;0;0m▄\27[48;2;122;0;0m \27[38;2;127;3;2;48;2;135;15;15m▄\27[38;2;139;25;25;48;2;185;127;113m▄\27[38;2;148;45;44;48;2;234;228;203m▄\27[38;2;140;28;28;48;2;192;154;129m▄\27[38;2;134;13;13;48;2;143;34;34m▄\27[38;2;137;21;21;48;2;175;106;96m▄\27[38;2;146;41;40;48;2;234;228;203m▄\27[38;2;143;33;33;48;2;203;182;150m▄\27[38;2;134;15;15;48;2;148;44;43m▄\27[38;2;136;19;19;48;2;167;87;80m▄\27[38;2;144;36;36;48;2;234;228;203m▄\27[38;2;143;34;34;48;2;215;190;169m▄\27[38;2;129;6;6;48;2;143;34;33m▄\27[38;2;125;2;1;48;2;133;13;13m▄\27[38;2;128;5;4;48;2;151;53;52m▄\27[38;2;138;23;23;48;2;217;194;173m▄\27[38;2;144;35;35;48;2;221;204;178m▄\27[38;2;142;30;30;48;2;196;159;133m▄\27[38;2;133;13;13;48;2;195;144;131m▄\27[38;2;125;2;1;48;2;133;12;12m▄\27[38;2;123;1;0;48;2;131;9;9m▄\27[38;2;127;3;3;48;2;146;39;39m▄\27[38;2;136;19;19;48;2;207;173;154m▄\27[38;2;143;33;33;48;2;217;198;170m▄\27[38;2;138;23;23;48;2;175;102;94m▄\27[38;2;137;19;19;48;2;205;172;149m▄\27[38;2;143;33;33;48;2;208;176;155m▄\27[38;2;143;33;33;48;2;227;215;191m▄\27[38;2;134;15;15;48;2;170;97;83m▄\27[38;2;135;16;16;48;2;165;82;75m▄\27[38;2;144;36;36;48;2;234;228;203m▄\27[38;2;143;34;34;48;2;216;202;173m▄\27[38;2;133;12;12;48;2;151;50;49m▄\27[38;2;125;2;1;48;2;133;13;13m▄\27[38;2;128;5;4;48;2;151;53;52m▄\27[38;2;138;23;23;48;2;217;194;173m▄\27[38;2;144;35;35;48;2;221;204;178m▄\27[38;2;142;30;30;48;2;196;159;133m▄\27[38;2;133;13;13;48;2;195;144;131m▄\27[38;2;126;2;1;48;2;133;12;12m▄\27[38;2;122;0;0;48;2;125;1;1m▄\27[38;2;122;0;0;48;2;123;1;0m▄\27[38;2;126;2;1;48;2;137;20;20m▄\27[38;2;132;12;11;48;2;190;138;124m▄\27[38;2;130;8;8;48;2;164;83;75m▄\27[38;2;126;2;1;48;2;132;11;11m▄\27[38;2;125;1;1;48;2;126;2;1m▄\27[38;2;128;19;18;48;2;125;90;78m▄\27[38;2;39;37;26;48;2;233;226;202m▄\27[38;2;34;32;23;48;2;192;187;165m▄\27[38;2;15;13;5;48;2;45;42;29m▄\27[38;2;11;9;3;48;2;40;38;31m▄\27[38;2;33;31;21;48;2;209;205;183m▄\27[38;2;44;41;28;48;2;231;228;210m▄\27[38;2;25;22;12;48;2;189;179;156m▄\27[38;2;22;19;9;48;2;99;94;79m▄\27[38;2;34;32;23;48;2;227;223;199m▄\27[38;2;34;32;23;48;2;213;206;179m▄\27[38;2;4;3;1;48;2;21;18;8m▄\27[38;2;0;0;0;48;2;1;0;0m▄\27[48;2;0;0;0m   \27[38;2;60;0;0;48;2;97;0;0m▄\27[48;2;122;0;0m       \27[38;2;68;0;0;48;2;122;0;0m▄\27[38;2;30;1;0;48;2;122;0;0m▄\27[38;2;112;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m  \27[38;2;112;0;0;48;2;122;0;0m▄\27[38;2;56;0;0;48;2;122;0;0m▄\27[38;2;112;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m   \27[38;2;113;0;0;48;2;11;0;0m▄\27[38;2;49;0;0;48;2;0;0;0m▄\27[38;2;46;0;0;48;2;0;0;0m▄\27[48;2;0;0;0m    \27[m\n"
  logo = logo .. "\27[48;2;0;0;0m         \27[38;2;53;0;0;48;2;74;0;0m▄\27[48;2;122;0;0m  \27[38;2;122;0;0;48;2;126;2;1m▄\27[38;2;122;0;0;48;2;125;2;1m▄\27[38;2;122;0;0;48;2;126;2;1m▄\27[38;2;122;0;0;48;2;125;1;1m▄\27[38;2;122;0;0;48;2;125;2;1m▄\27[38;2;122;0;0;48;2;126;2;1m▄▄\27[38;2;122;0;0;48;2;123;0;0m▄\27[48;2;122;0;0m \27[38;2;122;0;0;48;2;125;2;1m▄\27[38;2;122;0;0;48;2;124;1;0m▄\27[48;2;122;0;0m   \27[38;2;122;0;0;48;2;126;2;1m▄\27[38;2;122;0;0;48;2;124;1;0m▄\27[38;2;122;0;0;48;2;126;2;1m▄\27[38;2;122;0;0;48;2;125;1;1m▄\27[48;2;122;0;0m   \27[38;2;122;0;0;48;2;125;2;1m▄\27[38;2;122;0;0;48;2;126;2;1m▄▄\27[38;2;122;0;0;48;2;125;2;1m▄\27[38;2;122;0;0;48;2;126;2;1m▄▄\27[48;2;122;0;0m \27[38;2;122;0;0;48;2;123;0;0m▄\27[38;2;122;0;0;48;2;125;2;1m▄\27[38;2;122;0;0;48;2;124;1;0m▄\27[48;2;122;0;0m   \27[38;2;122;0;0;48;2;126;2;1m▄\27[38;2;122;0;0;48;2;124;1;0m▄\27[38;2;122;0;0;48;2;126;2;1m▄\27[38;2;122;0;0;48;2;125;1;1m▄\27[48;2;122;0;0m        \27[38;2;122;0;0;48;2;125;2;1m▄\27[38;2;70;0;0;48;2;3;1;0m▄\27[38;2;0;0;0;48;2;2;1;0m▄\27[48;2;0;0;0m   \27[38;2;0;0;0;48;2;2;1;0m▄▄\27[48;2;0;0;0m \27[38;2;0;0;0;48;2;2;1;0m▄▄\27[38;2;0;0;0;48;2;1;1;0m▄\27[48;2;0;0;0m    \27[38;2;0;0;0;48;2;16;0;0m▄\27[38;2;102;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m      \27[38;2;39;0;0;48;2;12;0;0m▄\27[48;2;0;0;0m  \27[38;2;0;0;0;48;2;71;0;0m▄\27[38;2;32;0;0;48;2;122;0;0m▄\27[38;2;117;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m \27[38;2;77;0;0;48;2;2;0;0m▄\27[38;2;0;0;0;48;2;15;0;0m▄\27[38;2;15;0;0;48;2;116;0;0m▄\27[38;2;113;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m   \27[38;2;107;0;0;48;2;5;0;0m▄\27[48;2;0;0;0m   \27[m\n"
  logo = logo .. "\27[48;2;0;0;0m         \27[38;2;47;0;0;48;2;53;0;0m▄\27[48;2;122;0;0m                                                 \27[38;2;122;0;0;48;2;114;0;0m▄\27[38;2;44;0;0;48;2;0;0;0m▄\27[48;2;0;0;0m              \27[38;2;0;0;0;48;2;21;0;0m▄\27[38;2;104;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m     \27[38;2;122;0;0;48;2;101;0;0m▄\27[38;2;25;0;0;48;2;0;0;0m▄\27[48;2;0;0;0m   \27[38;2;0;0;0;48;2;17;0;0m▄\27[38;2;15;0;0;48;2;120;0;0m▄\27[38;2;122;0;0;48;2;121;0;0m▄\27[38;2;112;0;0;48;2;63;0;0m▄\27[38;2;16;0;0;48;2;2;1;0m▄\27[38;2;0;0;0;48;2;1;0;0m▄\27[38;2;0;0;0;48;2;55;0;0m▄\27[38;2;59;0;0;48;2;122;0;0m▄\27[38;2;93;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m \27[38;2;112;0;0;48;2;70;0;0m▄\27[48;2;0;0;0m  \27[m\n"
  logo = logo .. "\27[48;2;0;0;0m         \27[38;2;53;0;0;48;2;47;0;0m▄\27[48;2;122;0;0m  \27[38;2;115;0;0;48;2;122;0;0m▄▄\27[38;2;119;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m                                             \27[38;2;122;0;0;48;2;118;0;0m▄\27[38;2;95;0;0;48;2;0;0;0m▄\27[48;2;0;0;0m              \27[38;2;0;0;0;48;2;8;0;0m▄\27[38;2;59;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m      \27[38;2;122;0;0;48;2;27;0;0m▄\27[38;2;55;0;0;48;2;0;0;0m▄\27[38;2;2;0;0;48;2;0;0;0m▄\27[48;2;0;0;0m  \27[38;2;2;0;0;48;2;28;0;0m▄\27[38;2;117;0;0;48;2;122;0;0m▄\27[38;2;122;0;0;48;2;101;0;0m▄\27[38;2;113;0;0;48;2;9;0;0m▄\27[38;2;27;0;0;48;2;0;0;0m▄\27[38;2;15;0;0;48;2;0;0;0m▄\27[38;2;1;1;0;48;2;0;0;0m▄\27[38;2;72;0;0;48;2;71;0;0m▄\27[38;2;0;0;0;48;2;82;0;0m▄\27[48;2;0;0;0m  \27[m\n"
  logo = logo .. "\27[48;2;0;0;0m         \27[38;2;111;0;0;48;2;76;0;0m▄\27[38;2;2;0;0;48;2;99;0;0m▄\27[38;2;0;0;0;48;2;11;0;0m▄\27[48;2;0;0;0m  \27[38;2;0;0;0;48;2;4;0;0m▄\27[38;2;0;0;0;48;2;34;0;0m▄\27[38;2;1;0;0;48;2;113;0;0m▄\27[38;2;92;0;0;48;2;122;0;0m▄\27[48;2;122;0;0m                                            \27[38;2;121;0;0;48;2;50;0;0m▄\27[38;2;29;0;0;48;2;0;0;0m▄\27[48;2;0;0;0m              \27[38;2;2;0;0;48;2;105;0;0m▄\27[48;2;122;0;0m       \27[38;2;122;0;0;48;2;110;0;0m▄\27[38;2;121;0;0;48;2;28;0;0m▄\27[38;2;82;0;0;48;2;0;0;0m▄\27[38;2;0;0;0;48;2;4;0;0m▄\27[38;2;0;0;0;48;2;12;0;0m▄\27[38;2;0;0;0;48;2;14;0;0m▄\27[38;2;0;0;0;48;2;47;0;0m▄\27[38;2;0;0;0;48;2;53;0;0m▄\27[48;2;0;0;0m      \27[m\n"
  logo = logo .. "\27[49;38;2;0;0;0m▀▀▀▀▀▀▀▀▀\27[49;38;2;1;0;0m▀\27[49;38;2;0;0;0m▀▀▀▀▀▀▀▀\27[49;38;2;104;0;0m▀\27[49;38;2;122;0;0m▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀\27[49;38;2;40;0;0m▀\27[49;38;2;0;0;0m▀▀▀▀▀▀▀▀▀▀▀▀▀▀\27[49;38;2;21;0;0m▀\27[49;38;2;120;0;0m▀\27[49;38;2;122;0;0m▀▀▀▀▀▀▀▀\27[49;38;2;115;0;0m▀\27[49;38;2;26;0;0m▀\27[49;38;2;0;0;0m▀▀▀▀▀▀▀▀▀\27[m\n"

  decho("\n"..ansi2decho(logo))

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
