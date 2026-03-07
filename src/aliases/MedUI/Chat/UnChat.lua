if mudlet.supports.mmcp then
    mmcp.disconnect(matches[2])
else
    chatUnChat(matches[2])
end