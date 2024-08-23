if not MedPrompt.setupComplete then
--  deleteLine()
  --moveCursor(0,getLineNumber()-1)
  --deleteLine()
end

local output = MedPrompt.generatePromptRegex(multimatches[3][1])