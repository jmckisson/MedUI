if mudlet.supports.mmcp then
    mmcp.chatTo(matches[2], matches[3])
else
    chat(matches[2], matches[3])
end