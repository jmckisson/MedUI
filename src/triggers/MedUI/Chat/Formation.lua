MedChat.appendToChatPanel("Form")
--[[
selectCurrentLine()

if MedUI.options.enableTimestamps then
  MedChat.runEMCO:cecho("Form", "<white>["..getTime(true, "HH:mm:ss") .."] ")
end

MedChat.runEMCO:append("Form")
deselect()
resetFormat()
--]]