MedChat = MedChat or {}

function medieviaTabbedChat_InitMedChat()
  -- create some variable space so we don't pollute global variables
 
  local EMCO = require("MedUI.emco")
  local stylesheet = [[background-color: rgb(0,255,255,255); border-width: 1px; border-style: solid; border-color: gold; border-radius: 10px;]]
  local istylesheet = [[background-color: rgb(60,0,0,255); border-width: 1px; border-style: solid; border-color: gold; border-radius: 10px;]]
  --local medchatstylesheet = [[background-color: rgb(255,255,255,255); border-width: 1px; border-style: solid; border-color: gold; border-radius: 10px;]]
  -- create an adjustable container for more flexibility

  if MedChat.Left and MedChat.Left:get_width() == 0 then
    --cecho("\n<yellow>Found existing MedChat.Left with 0 width, setting to nil and reinitializing...\n")
    MedChat.Left = nil
    MedChat.runEMCO = nil
  end

  MedChat.Left = MedChat.Left or Adjustable.Container:new({
    name = "Medievia Chat",
    x = "-30.303%", y = "50%",  -- compensate for the border being width/3.3
    width = "30.303%",
    height = "50%",
    lockStyle = "border",
    adjLabelstyle = "background-color:darkred; border: 0; padding: 1px;",
    autoLoad = true,
    autoSave = true,
  })
  

  MedChat.runEMCO = MedChat.runEMCO or EMCO:new({
    x = "0",
    y = "0",
    width = "100%",
    height = "100%",
    allTab = true,
    allTabName = "All",
    gap = 2,
    consoleColor = "black",
    consoles = {
      "All",
      "Form",
      "Clan", 
      "Town",
      "Chat",
    },
    activeTabCSS = stylesheet,
    fontSize=8,
    inactiveTabCSS = istylesheet,
  }, MedChat.Left)

  MedChat.Left:connectToBorder("right")
  MedChat.Left:show()
  MedChat.Left:lockContainer("light")
end

if chatCall then
  if not table.index_of(MedChat.runEMCO.consoles, "MMCP") then
    MedChat.runEMCO:addTab("MMCP", #MedChat.runEMCO.consoles + 1)
  end
end

function MedChat.appendToChatPanel(channel)
  selectCurrentLine()

  if MedUI.options.enableTimestamps then
    MedChat.runEMCO:cecho(channel, "<white>["..getTime(true, "HH:mm:ss") .."] ")
  end

  MedChat.runEMCO:append(channel)
  deselect()
  resetFormat()
end

function MedChat.eventHandler(event, ...)

  if event == "sysMMCPMessage" then
    local trimmedStr = arg[1]:match("^%s*(.-)%s*$")
    
    if MedUI.options.enableTimestamps then
      MedChat.runEMCO:cecho("MMCP", "<white>["..getTime(true, "HH:mm:ss") .."] ")
    end
    
    MedChat.runEMCO:decho("MMCP", ansi2decho(trimmedStr) .. "\n", false)
    
  elseif event == "sysUninstallPackage" and arg[1] == "MedUI" then
    --[[
    for _,id in ipairs(MedChat.registeredEvents) do
      killAnonymousEventHandler(id)
    end
    ]]
    stopNamedEventHandler("MedUI", "MedChat")
  end
end

--MedChat.registeredEvents = {
--  registerAnonymousEventHandler("sysMMCPMessage", "MedChat.eventHandler")
--}

registerNamedEventHandler("MedUI", "MedChat", "sysMMCPMessage", "MedChat.eventHandler")

medieviaTabbedChat_InitMedChat()

