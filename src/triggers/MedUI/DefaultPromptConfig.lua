if not MedPrompt.setupComplete then
  deleteLine()
  moveCursor(0,getLineNumber()-1)
  deleteLine()
end

MedPrompt.generatePromptRegex("none")