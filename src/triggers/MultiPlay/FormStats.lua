-- This trigger will be disabled automatically when we receive Char.Info from GMCP
-- myPlayerName should be set to getCharacterName() if it is set in the options dialog
if MultiPlay.myPlayerName == matches[3] or getCharacterName() == matches[3] then
    --echo("MultiPlay: Set class to " .. matches[4] .. " from formStats trigger\n")
    MultiPlay.myClass = matches[4]
    MultiPlay.myLevel = tonumber(matches[5])
end
