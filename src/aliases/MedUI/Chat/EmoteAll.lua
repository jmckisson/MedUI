local emoteStr = "says, '" .. matches[2] .. "'"

if mudlet.supports.mmcp then
    mmcp.emoteAll(emoteStr)
else
    chatEmoteAll(emoteStr)
end