MedChat.appendToChatPanel("Clan")
--[[
selectCurrentLine()

if MedUI.options.enableTimestamps then
  MedChat.runEMCO:cecho("Clan", "<white>["..getTime(true, "HH:mm:ss") .."] ")
end

MedChat.runEMCO:append("Clan")
deselect()
resetFormat()
--]]