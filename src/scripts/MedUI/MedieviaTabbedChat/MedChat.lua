MedChat = MedChat or {}

function medieviaTabbedChat_InitMedChat()
  -- create some variable space so we don't pollute global variables
 
  local EMCO = require("MDK.emco")
  local stylesheet = [[background-color: rgb(0,255,255,255); border-width: 1px; border-style: solid; border-color: gold; border-radius: 10px;]]
  local istylesheet = [[background-color: rgb(60,0,0,255); border-width: 1px; border-style: solid; border-color: gold; border-radius: 10px;]]
  --local medchatstylesheet = [[background-color: rgb(255,255,255,255); border-width: 1px; border-style: solid; border-color: gold; border-radius: 10px;]]
  -- create an adjustable container for more flexibility
  MedChat.Left = MedChat.Left or Adjustable.Container:new({
    name = "Medievia Chat",
    x = "67%", y = "50%",
    width = "23%",
    height = "50%",
    lockStyle = "border",
    adjLabelstyle = "background-color:darkred; border: 0; padding: 1px;",
    autoLoad = true,
    autoSave = true,
  })
  MedChat.Left:lockContainer("light")


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
      "MMCP",
    },
    activeTabCSS = stylesheet,
    fontSize=8,
    inactiveTabCSS = istylesheet,
  }, MedChat.Left)

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
    for _,id in ipairs(MedChat.registeredEvents) do
      killAnonymousEventHandler(id)
    end

  end
end

MedChat.registeredEvents = {
  registerAnonymousEventHandler("sysMMCPMessage", "MedChat.eventHandler")
}

medieviaTabbedChat_InitMedChat()

MedChat.Left:show()