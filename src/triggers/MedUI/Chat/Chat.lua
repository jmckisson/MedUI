MedChat.appendToChatPanel("Chat")
--[[
selectCurrentLine()

if MedUI.options.enableTimestamps then
  MedChat.runEMCO:cecho("Chat", "<white>["..getTime(true, "HH:mm:ss") .."] ")
end

MedChat.runEMCO:append("Chat")
deselect()
resetFormat()
--]]