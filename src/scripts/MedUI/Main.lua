--[[
  Changelog:
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

MedUI = MedUI or {
  version = "__VERSION__",
  MedChat = {},
  MedMap = {},
  options = {
    enableGauges = true,
    keepInlineMap = false,
    enableTimestamps = true
  }
}
GUI = GUI or {}

GUI.BoxCSS = CSSMan.new([[
  background-color: rgba(0,0,0,100);
  border-style: solid;
  border-width: 1px;
  border-radius: 10px;
  border-color: white;
  margin: 10px;
]])

-- nullify the map window if it it somehow loaded with a 0 width
if MedUI.MedMap.MapperAdjCont and MedUI.MedMap.MapperAdjCont:get_width() == 0 then
  MedUI.MedMap.MapperAdjCont = nil
  MedUI.MedMap.Mapper = nil
end

-- create an adjustable container for more flexibility
MedUI.MedMap.MapperAdjCont = Adjustable.Container:new({
  name = "Medieiva Map",
  x = "-30.303%", y = 0,
  width = "30.303%",
  height = "50%",
  lockStyle = "border",
  adjLabelstyle = "background-color:darkred; border: 0; padding: 1px;",
  autoLoad = true,
  autoSave = true
})


MedUI.MedMap.Mapper = Geyser.MiniConsole:new({
    name="MedMapper",
    x= 0, y= 0,
    autoWrap = false,
    color = "black",
    scrollBar = false,
    fontSize = 9,
    width="100%", height="100%",
  },
  MedUI.MedMap.MapperAdjCont
)
MedUI.MedMap.Mapper:setFont("Medievia Mudlet Sans Mono")
MedUI.MedMap.MapperAdjCont:connectToBorder("right")
MedUI.MedMap.MapperAdjCont:show()
MedUI.MedMap.MapperAdjCont:lockContainer("light")

function MedUI.MedMap.mapStart()
  MedUI.MedMap.Mapper:clear()
  selectCurrentLine()
  local length = #ansi2string(getCurrentLine())

  if length < 80 then
    MedUI.MedMap.Mapper:setFontSize(18)
  elseif length < 200 then
    MedUI.MedMap.Mapper:setFontSize(12)
  else
    MedUI.MedMap.Mapper:setFontSize(9)
  end
  copy()
  MedUI.MedMap.Mapper:appendBuffer()
  
  if not MedUI.options.keepInlineMap then
    deleteLine()
  end
end

function MedUI.MedMap.mapMid()
  selectCurrentLine()
  copy()
  MedUI.MedMap.Mapper:appendBuffer()
  if not MedUI.options.keepInlineMap then
    deleteLine()
  end
end

function MedUI.MedMap.mapEnd(roomName)
  selectCurrentLine()
  copy()
  MedUI.MedMap.Mapper:appendBuffer()
  if not MedUI.options.keepInlineMap then
    deleteLine()
  end

  if roomName then
    -- For CombatReps script, needs refactor
    CR = CR or {}
    CR.needRoomName = false
    CR.lastRoom = CR.myRoom
    CR.myRoom = matches[2]
  
    setTriggerStayOpen("MedieviaMapStart", 0)
    -- paste the parsed name into the main console as we still want to see the room name
    if not MedUI.options.keepInlineMap then
      cecho("\n<yellow>"..roomName)
    end
  end
end

---------------------------------------------------------------------------------
---- Buffs and Bars Code --------------------------------------------------------
---------------------------------------------------------------------------------
MedBuffsNBars = MedBuffsNBars or {}

--Stores the location reference of the PNG for each buff and debuff
--Use with getMudletHomeDir() to get full path
function medBuffsNBars_initializeBuffTable()
 
  MedBuffsNBars.buffIconTable = {
    sanc = {MedBuffsNBars.iconLocation.."/icons/sanc.png", false, "spell_label_sanc", "buff", "ref_place_holder", 1},
    fireshield = {MedBuffsNBars.iconLocation.."/icons/fireshield.png", false, "spell_label_fireshield", "buff", "ref_place_holder", 2},
    iceshield = {MedBuffsNBars.iconLocation.."/icons/iceshield.png", false, "spell_label_iceshield", "buff", "ref_place_holder", 3},
    protfire = {MedBuffsNBars.iconLocation.."/icons/prot_fire.png", false, "spell_label_protfire", "buff", "ref_place_holder", 4},
    protice = {MedBuffsNBars.iconLocation.."/icons/prot_ice.png", false, "spell_label_protice", "buff", "ref_place_holder", 5},
    protlightning = {MedBuffsNBars.iconLocation.."/icons/prot_lightning.png", false, "spell_label_protlightning", "buff", "ref_place_holder", 6},
    manashield = {MedBuffsNBars.iconLocation.."/icons/manashield.png", false, "spell_label_manashield", "buff", "ref_place_holder", 7},
    phanimages = {MedBuffsNBars.iconLocation.."/icons/phanimages.png", false, "spell_label_phanimages", "buff", "ref_place_holder", 8},
    quickness = {MedBuffsNBars.iconLocation.."/icons/quickness.png", false, "spell_label_quickness", "buff", "ref_place_holder", 9},
    levitate = {MedBuffsNBars.iconLocation.."/icons/levitate.png", false, "spell_label_levitate", "buff", "ref_place_holder", 10},
    breathwater = {MedBuffsNBars.iconLocation.."/icons/breathwater.png", false, "spell_label_breathwater", "buff", "ref_place_holder", 11},
    strength = {MedBuffsNBars.iconLocation.."/icons/strength.png", false, "spell_label_strength", "buff", "ref_place_holder", 12},
    armor = {MedBuffsNBars.iconLocation.."/icons/armor.png", false, "spell_label_armor", "buff", "ref_place_holder", 13},
    bless = {MedBuffsNBars.iconLocation.."/icons/bless.png", false, "spell_label_bless", "buff", "ref_place_holder", 14},
    stoneskin = {MedBuffsNBars.iconLocation.."/icons/stoneskin_shield.png", false, "spell_label_stoneskin", "buff", "ref_place_holder", 15},
    shield = {MedBuffsNBars.iconLocation.."/icons/shield.png", false, "spell_label_shield", "buff", "ref_place_holder", 16},
    protfromgood = {MedBuffsNBars.iconLocation.."/icons/protfromgood.png", false, "spell_label_protfromgood", "buff", "ref_place_holder", 17},
    blind = {MedBuffsNBars.iconLocation.."/icons/blind.png", false, "spell_label_blind", "debuff", "ref_place_holder", 18},
    infravision = {MedBuffsNBars.iconLocation.."/icons/infravision.png", false, "spell_label_infravision", "buff", "ref_place_holder", 19},
    detectevil = {MedBuffsNBars.iconLocation.."/icons/detect_evil.png", false, "spell_label_detectevil", "buff", "ref_place_holder", 20},
    detectgood = {MedBuffsNBars.iconLocation.."/icons/detect_good.png", false, "spell_label_detectgood", "buff", "ref_place_holder", 21},
    detectinv = {MedBuffsNBars.iconLocation.."/icons/detect_inv.png", false, "spell_label_detectinv", "buff", "ref_place_holder", 22},
    detectmagic = {MedBuffsNBars.iconLocation.."/icons/detect_magic.png", false, "spell_label_detectmagic", "buff", "ref_place_holder", 23},
    senselife = {MedBuffsNBars.iconLocation.."/icons/senselife.png", false, "spell_label_senselife", "buff", "ref_place_holder", 24}       
  }
end

function medBuffsNBars_initializeBarGauges()

  --******CSS******--
  
  MedBuffsNBars.BoxCSS = CSSMan.new([[
    background-color: rgba(0,0,0,100);
    border-style: solid;
    border-width: 1px;
    border-radius: 10px;
    border-color: white;
    margin: 10px;
  ]])
  
  MedBuffsNBars.GaugeBackCSS = CSSMan.new([[
    background-color: rgba(0,0,0,0);
    border-style: solid;
    border-color: white;
    border-width: 1px;
    border-radius: 5px;
    margin: 5px;
  ]])
  
  MedBuffsNBars.GaugeFrontCSS = CSSMan.new([[
    background-color: rgba(0,0,0,0);
    border-style: solid;
    border-color: white;
    border-width: 1px;
    border-radius: 5px;
    margin: 5px;
   
  ]])
  
  MedBuffsNBars.BackgroundCSS = CSSMan.new([[
    background-color: black;
  ]])
  
  --*****Build GUI containers****--
  MedBuffsNBars.Bottom = Geyser.Label:new({
    name = "MedBuffsNBars.Bottom",
    x = "20", y = "-7%",
    width = "50%",
    height = "7%",
  })
  MedBuffsNBars.Bottom:setStyleSheet(MedBuffsNBars.BackgroundCSS:getCSS())
  
  --***Gauge Layout***--
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
  --********************--
  
  --*** HP Gauge ***--
  MedBuffsNBars.HPBox = Geyser.Container:new({
    name = "HPBox.Footer",
    x = 0, y = 0,
    width = "20%",
    --height = "100%",
  },MedBuffsNBars.LeftColumn)
  
  gauge_hp_label = Geyser.Label:new({
    name = "HP",
    x = "0px", y = "0px",
    width = "30px", height = "30pxpx",
    color = "black",
  }, MedBuffsNBars.HPBox)
  MedBuffsNBars.hpImageLoc = getMudletHomeDir()..MedBuffsNBars.iconLocation.."/icons/hp.png"
  gauge_hp_label:setStyleSheet([[
      border-image:url(]]..MedBuffsNBars.hpImageLoc..[[);
  ]])
  
  gauge_hpdisplay_label = Geyser.Label:new({
    name = "gauge_hpdisplay_label",
    x = "11%", y = "0px",
    width = "10%", height = "45px",
    color = "black",
  }, MedBuffsNBars.HPBox)
  gauge_hpdisplay_label:echo("<center><p style='font-size:18px; color = white'><b>???<b></p></center>")
  
  MedBuffsNBars.Health = Geyser.Gauge:new({
    name = "MedBuffsNBars.Health",
    x = "22%", y = "0px",
    height = "100%",
    width = "70%",
  }, MedBuffsNBars.HPBox)
  MedBuffsNBars.Health.back:setStyleSheet(MedBuffsNBars.GaugeBackCSS:getCSS())
  MedBuffsNBars.GaugeFrontCSS:set("background-color","red")
  MedBuffsNBars.Health.front:setStyleSheet(MedBuffsNBars.GaugeFrontCSS:getCSS())
  MedBuffsNBars.Health:setValue(math.random(100),100)
  MedBuffsNBars.Health.front:echo("HP")
  --********************--
  
  
  --***Mana Gauge***--
  
  MedBuffsNBars.ManaBox = Geyser.Container:new({
    name = "ManaBox.Footer",
    x = 0, y = 0,
    width = "20%",
    --height = "100%",
  },MedBuffsNBars.LeftColumn)
  
  gauge_mana_label = Geyser.Label:new({
    name = "Mana",
    x = "0px", y = "0px",
    width = "30px", height = "30px",
    color = "black",
  }, MedBuffsNBars.ManaBox)
  MedBuffsNBars.manaImageLoc = getMudletHomeDir()..MedBuffsNBars.iconLocation.."/icons/mana.png"
  gauge_mana_label:setStyleSheet([[
      border-image:url(]]..MedBuffsNBars.manaImageLoc..[[);
  ]])
  
  gauge_manadisplay_label = Geyser.Label:new({
    name = "gauge_manadisplay_label",
    x = "11%", y = "0px",
    width = "10%", height = "45px",
    color = "black",
  }, MedBuffsNBars.ManaBox)
  gauge_manadisplay_label:echo("<center><p style='font-size:18px; color = white'><b>???<b></p></center>")
  
  MedBuffsNBars.Mana = Geyser.Gauge:new({
    name = "MedBuffsNBars.Mana",
    x = "22%", y = "0px",
    height = "100%",
    width = "70%",
  },MedBuffsNBars.ManaBox)
  MedBuffsNBars.Mana.back:setStyleSheet(MedBuffsNBars.GaugeBackCSS:getCSS())
  MedBuffsNBars.GaugeFrontCSS:set("background-color","blue")
  MedBuffsNBars.Mana.front:setStyleSheet(MedBuffsNBars.GaugeFrontCSS:getCSS())
  MedBuffsNBars.Mana:setValue(math.random(100),100)
  MedBuffsNBars.Mana.front:echo("MP")
  
  
  --***MV Gauge***--
  
  MedBuffsNBars.MVBox = Geyser.Container:new({
    name = "MVBox.Footer",
    x = 0, y = 0,
    width = "20%",
    --height = "100%",
  },MedBuffsNBars.RightColumn)
  
  gauge_mv_label = Geyser.Label:new({
    name = "MV",
    x = "0px", y = "0px",
    width = "30px", height = "30px",
    color = "black",
  }, MedBuffsNBars.MVBox)
  MedBuffsNBars.mvImageLoc = getMudletHomeDir()..MedBuffsNBars.iconLocation.."/icons/mv.png"
  gauge_mv_label:setStyleSheet([[
      border-image:url(]]..MedBuffsNBars.mvImageLoc..[[);
  ]])
  
  gauge_mvdisplay_label = Geyser.Label:new({
    name = "gauge_mvdisplay_label",
    x = "11%", y = "0px",
    width = "10%", height = "45px",
    color = "black",
  }, MedBuffsNBars.MVBox)
  gauge_mvdisplay_label:echo("<center><p style='font-size:18px; color = white'><b>???<b></p></center>")
  
  MedBuffsNBars.Endurance = Geyser.Gauge:new({
    name = "MedBuffsNBars.Endurance",
    x = "22%", y = "0px",
    height = "100%",
    width = "70%",
  },MedBuffsNBars.MVBox)
  MedBuffsNBars.Endurance.back:setStyleSheet(MedBuffsNBars.GaugeBackCSS:getCSS())
  MedBuffsNBars.GaugeFrontCSS:set("background-color","yellow")
  MedBuffsNBars.Endurance.front:setStyleSheet(MedBuffsNBars.GaugeFrontCSS:getCSS())
  MedBuffsNBars.Endurance:setValue(math.random(100),100)
  --MedBuffsNBars.Endurance.front:echo("MedBuffsNBars.Endurance")
  MedBuffsNBars.Endurance.front:echo([[<span style = "color: black">MV</span>]])
  
  --***Breath***--
  
  MedBuffsNBars.BRBox = Geyser.Container:new({
    name = "BRBox.Footer",
    x = 0, y = "50%",
    width = "20%",
    --height = "100%",
  },MedBuffsNBars.RightColumn)
  
  gauge_br_label = Geyser.Label:new({
    name = "BR",
    x = "0px", y = "0px",
    width = "30px", height = "30px",
    color = "black",
  }, MedBuffsNBars.BRBox)
  MedBuffsNBars.brImageLoc = getMudletHomeDir()..MedBuffsNBars.iconLocation.."/icons/breath.png"
  gauge_br_label:setStyleSheet([[
      border-image:url(]]..MedBuffsNBars.brImageLoc..[[);
  ]])
  
  gauge_brdisplay_label = Geyser.Label:new({
    name = "gauge_brdisplay_label",
    x = "11%", y = "0px",
    width = "10%", height = "45px",
    color = "black",
  }, MedBuffsNBars.BRBox)
  gauge_brdisplay_label:echo("<center><p style='font-size:18px; color = white'><b>???<b></p></center>")
  
  MedBuffsNBars.Willpower = Geyser.Gauge:new({
    name = "MedBuffsNBars.Willpower",
    x = "22%", y = "0px",
    height = "100%",
    width = "70%",
  },MedBuffsNBars.BRBox)
  MedBuffsNBars.Willpower.back:setStyleSheet(MedBuffsNBars.GaugeBackCSS:getCSS())
  MedBuffsNBars.GaugeFrontCSS:set("background-color","green")
  MedBuffsNBars.Willpower.front:setStyleSheet(MedBuffsNBars.GaugeFrontCSS:getCSS())
  --test = math.random(100)
  --echo(test.."\n")
  MedBuffsNBars.Willpower:setValue(math.random(100),100)
  MedBuffsNBars.Willpower.front:echo("BR")

end

--Create Containers--
left_buff_container = Geyser.Container:new({
  name = "left_buff_container",
  x="1%", y="90%",
  width = "25%", height="35",
})

player_buffs_container = Geyser.Container:new({
  name = "playerBuffs", 
  x= "0px", y="0%",  
  width = "100%", height="100%", 
}, left_buff_container)


--Helper function to show which buffs have been turned on in the table, used for debugging
-- lua med_showBuffTable()
-- Only used for debugging
function medBuffsNBars_showBuffTable()
  echo('\n')
  for k, v in pairs(MedBuffsNBars.buffIconTable) do
    echo(v[1].."::"..tostring(v[2]).."::"..v[3].."::"..v[4]..'\n')
  end
end

--Sets the buff for the passed argument as true so it can display
function medBuffsNBars_setBuffOn(buff)

  MedBuffsNBars.buffIconTable[buff][2] = true
  medBuffsNBars_updateEffects()
  --echo("\nBuff on:"..buff.."\n")
end

--Sets the buff for the passed argument as false so it will not display
function medBuffsNBars_setBuffOff(buff)

  MedBuffsNBars.buffIconTable[buff][2] = false
  medBuffsNBars_updateEffects()
  --echo("\nBuff off:"..buff.."\n")
end

--All icons must be enabled by default, then we can show and hide
function medBuffsNBars_initializeEffects()  
  local counter = 0
  --for k, v in pairs(MedBuffsNBars.buffIconTable) do
  local sortedBuffTable = medBuffsNBars_sortedBuffTable()
  for k, v in pairs(sortedBuffTable) do

    MedBuffsNBars.dynamic_x_int = 5 + (28*counter)
    MedBuffsNBars.dynamic_x_str = tostring(MedBuffsNBars.dynamic_x_int).."px"
    local nameLabel = v[3]
    v[5] = Geyser.Label:new({
      name = nameLabel,
      x = MedBuffsNBars.dynamic_x_str, y = "5px",
      width = "30px", height = "30px",
    }, player_buffs_container)
    local medPicImageLoc = getMudletHomeDir() .. v[1]
    v[5]:setStyleSheet([[
      border-image:url(]]..medPicImageLoc..[[);
    ]])
    --echo(v[1].."::"..tostring(v[2]).."::"..v[3].."::"..v[4].."::"..v[5]..'\n')
    counter=counter + 1
  end
  --echo(counter..'\n')
end

--Does the actual work of checking the table for each buff and positioning it
function medBuffsNBars_buildEffects()
  --med_showBuffTable()

  local counter = 0
  
  local sortedBuffTable = medBuffsNBars_sortedBuffTable()
  for k, v in pairs(sortedBuffTable) do
    --echo('\n'..v[1].."::"..tostring(v[2]).."::"..v[3].."::"..v[4]..'\n')
    MedBuffsNBars.dynamic_x_int = 5 + (28*counter)
    MedBuffsNBars.dynamic_x_str = tostring(MedBuffsNBars.dynamic_x_int).."px"
    --echo('\n'..v[1].."::"..tostring(v[2]).."::"..v[3].."::"..v[4]..'\n')
    if(v[2]) then
      --echo("\nTEST"..v[1].."\n")
      v[5]:move(MedBuffsNBars.dynamic_x_int, 5)
      showWindow(v[3])
      counter = counter + 1
    end
  end

end

--Used to hide all of the buffs before an update
function medBuffsNBars_clearEffects()
  for k, v in pairs(MedBuffsNBars.buffIconTable) do
    hideWindow(v[3])
  end
end

--Clears and the builds the buffs
function medBuffsNBars_updateEffects()
  medBuffsNBars_clearEffects()

  if MedUI.options.enableGauges then
    medBuffsNBars_buildEffects()
  end
end

--Used with testing to make sure icons are displaying, turns them all on
function medBuffsNBars_test_showAllBuffIcons()
  --med_showBuffTable()
  local counter = 0
  local sortedBuffTable = medBuffsNBars_sortedBuffTable()
  for k, v in pairs(sortedBuffTable) do
    --echo('\n'..v[1].."::"..tostring(v[2]).."::"..v[3].."::"..v[4]..'\n')
    MedBuffsNBars.dynamic_x_int = 5 + (28*counter)
    MedBuffsNBars.dynamic_x_str = tostring(MedBuffsNBars.dynamic_x_int).."px"
    --echo('\n'..v[1].."::"..tostring(v[2]).."::"..v[3].."::"..v[4]..'\n')
    v[5]:move(MedBuffsNBars.dynamic_x_int, 5)
    --moveWindow(v[3], dynamic_x_int, 5)
    showWindow(v[3])
    counter = counter + 1
  end
end

--Used to sort the table in position of priority which is in the buff table
--KEEP IN MIND THIS CREATES A SECOND TABLE THAT IS USED TEMPORARILY
--DO NOT ATTEMPT TO SET VALUES IN THIS TABLE
function medBuffsNBars_sortedBuffTable()
  local sortedBuffTable = {}
  for k, v in pairs(MedBuffsNBars.buffIconTable) do
    sortedBuffTable[v[6]] = v
  end
  return sortedBuffTable
end

--Turns off all buffs in the table itself. Used with "SC" and "SC A" to clear buffs and reset them
-- Provides a way to resync buffs when first logging on.
-- It can also fix buffs that may have fallen off but not been caught by trigger for whatever reason.
function medBuffsNBars_allBuffsOff()
  for k, v in pairs(MedBuffsNBars.buffIconTable) do
    v[2] = false
  end
end

function MedUI.enableGauges()
  MedBuffsNBars.iconLocation = "/MedUI"
  
  if MedBuffsNBars.Bottom then
    MedBuffsNBars.Bottom:show()
  else
    --Builds the icons for buffs the first time
    medBuffsNBars_initializeBuffTable() -- Table_Spell_Effects
    medBuffsNBars_initializeEffects() --SpellEffects
    medBuffsNBars_clearEffects()
    medBuffsNBars_initializeBarGauges()
  end

  local totalHeight = math.ceil(tonumber(left_buff_container:get_height()) + tonumber(MedBuffsNBars.Bottom:get_height()))
  setBorderBottom(totalHeight)
  
end

function MedUI.disableGauges()
  setBorderBottom(0)
  if MedBuffsNBars.Bottom then
    MedBuffsNBars.Bottom:hide()
  end
  
  -- hide buffs container too
  if left_buff_container then
    medBuffsNBars_clearEffects()
    left_buff_container:hide()
  end
end

-- Update gauge values from data parsed from GMCP
function MedUI.updateVitals()
  if not MedUI.options.enableGauged then
    return
  end

  local vitals = gmcp.Char.Vitals

  if vitals.hp and vitals.maxHp then
    MedBuffsNBars.Health:setValue(vitals.hp, vitals.maxHp)
    gauge_hpdisplay_label:echo("<center><p style='font-size:18px; color = white'><b>".. vitals.hp .."<b></p></center>")
  end

  if vitals.mana and vitals.maxMana then
    MedBuffsNBars.Mana:setValue(vitals.mana, vitals.maxMana)
    gauge_manadisplay_label:echo("<center><p style='font-size:18px; color = white'><b>".. vitals.mana .."<b></p></center>")
  end

  if vitals.mv and vitals.maxMv then
    MedBuffsNBars.Endurance:setValue(vitals.mv, vitals.maxMv)
    gauge_mvdisplay_label:echo("<center><p style='font-size:18px; color = white'><b>".. vitals.mv .."<b></p></center>")
  end

  if vitals.br then
    MedBuffsNBars.Willpower:setValue(vitals.br, 100)
    gauge_brdisplay_label:echo("<center><p style='font-size:18px; color = white'><b>".. vitals.br .."<b></p></center>")
  end

end

registerNamedEventHandler("MedUI", "MedBuffsNBars", "gmcp.char.Vitals", "MedUI.updateVitals")


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

  decho(ansi2decho(logo))
  
  cecho("<DeepSkyBlue>MedUI by <firebrick>Kymbahl <DeepSkyBlue>& <gold>Kronos<DeepSkyBlue>, version: <orange>" .. MedUI.version .. "\n")
  
  local optionsList = {
    {description = "Enable Gauges", optionKey = "enableGauges", helpKey = "<white>'<yellow>medui %d<white>' or '<yellow>medui gauges<white>' to toggle"},
    {description = "Keep Inline Map", optionKey = "keepInlineMap", helpKey = "<white>'<yellow>medui %d<white>' or '<yellow>medui inlinemap<white>' to toggle"},
    {description = "Enable Timestamps", optionKey = "enableTimestamps", helpKey = "<white>'<yellow>medui %d<white>' or '<yellow>medui timestamp<white>' to toggle"}
  }
  
  local argNum = tonumber(arg)
  if argNum and optionsList[argNum] then
    local selectedOption = optionsList[argNum]
    -- Toggle the option
    MedUI.options[selectedOption.optionKey] = not MedUI.options[selectedOption.optionKey]
    -- Execute any special action if defined
    if selectedOption.specialAction then
      selectedOption.specialAction(self)
    end
  end
  
  local YES = "<green>YES"
  local NO = "<red>NO"

	local str = "\n<DeepSkyBlue>Options:"
  for i, option in ipairs(optionsList) do
    local status = MedUI.options[option.optionKey] and YES or NO
    str = string.format("%s\n<DeepSkyBlue>%2d] %-26s: %s     %s%s",
      str,
      i,
      option.description,
      status,
      (status == NO and " " or ""), -- Need extra space here because apparently strlen is broken with color tags
      string.format(option.helpKey, i))
  end
  str = string.format("%s\n", str)
  cecho(str)
  
  MedUI.reconfigure()
  MedUI.saveOptions()
end

function MedUI.setMudletOptions()
    setFont("main", "Medievia Mudlet Sans Mono")
    setFontSize("main", 13)

    setServerEncoding("MEDIEVIA")
    setConfig("controlCharacterHandling", "oem")

    local w,h = getMainWindowSize()
    setBorderRight(w/3.3)

    -- Disable the generic_mapper "English Exits Trigger" to allow the Medievia mapper to function properly
    disableTrigger("English Exits Trigger")

    -- Add A Medievia prompt test pattern to the mapper test patterns
    local test_pattern = "^%b()<(.-)>"
    if map then
      if not table.index_of(map.defaults.prompt_test_patterns, test_pattern) then
        table.insert(map.defaults.prompt_test_patterns, "^%b()<(.-)>")
      end
    end
end

function MedUI.reconfigure()

    MedUI.setMudletOptions()

    if MedUI.options.enableGauges then
        MedUI.enableGauges()
    else
        MedUI.disableGauges()
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
    enableTimestamps = true
  }

  -- reinitialize prompt triggers from saved data
  if MedUI.options.promptPattern then
    --echo("\nSetting promptPattern from save table\n")
    MedPrompt.promptPattern = MedUI.options.promptPattern
    MedPrompt.setupPromptTriggers()
  end

  cecho("\n<DeepSkyBlue> MedUI: loaded options for <yellow>" .. charName)
  MedUI.charName = charName
end

function MedUI.saveOptions()
  local charName = string.lower(getProfileName())

  if not MedUI.options.promptPattern and MedPrompt.promptPattern and MedPrompt.promptPattern ~= "" then
    --echo("\nAdding promptPattern to save table\n")
    MedUI.options.promptPattern = MedPrompt.promptPattern
  end

  local saveTable = {
    options = table.deepcopy(MedUI.options)
  }

  table.save(getMudletHomeDir().."/medui_"..charName..".lua", saveTable)

  cecho("\n<DeepSkyBlue> MedUI: saved options for <yellow>" .. charName)
  MedUI.charName = charName
end


function MedUI.eventHandler(event, ...)

    if event == "sysWindowResizeEvent" then
        local x, y, windowName = arg[1], arg[2], arg[3]

        if windowName == "main" then      
          local w,h = getMainWindowSize()
          setBorderRight(w/3.3)
        end

    elseif event == "sysLoadEvent" then
      MedUI.setMudletOptions()

    elseif event == "sysInstallPackage" and arg[1] == "MedUI" then
      MedUI.setMudletOptions()

    elseif event == "sysUninstallPackage" and arg[1] == "MedUI" then
        stopNamedEventHandler("MedUI", "MedUIResize")
        stopNamedEventHandler("MedUI", "MedUILoad")
        stopNamedEventHandler("MedUI", "MedUIInstall")
        stopNamedEventHandler("MedUI", "MedUIUninstall")
        stopNamedEventHandler("MedUI", "MedBuffsNBars")
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

MedUI.charName = string.lower(getProfileName())
