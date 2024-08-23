MedChat.appendToChatPanel("Town")
--[[
selectCurrentLine()

if MedUI.options.enableTimestamps then
  MedChat.runEMCO:cecho("Town", "<white>["..getTime(true, "HH:mm:ss") .."] ")
end

MedChat.runEMCO:append("Town")
deselect()
resetFormat()
--]]