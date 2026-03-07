if mudlet.supports.mmcp then
    mmcp.chatGroup(matches[2], matches[3])
else
    chatGroup(matches[2], matches[3])
end