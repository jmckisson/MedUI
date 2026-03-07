if mudlet.supports.mmcp then
    mmcp.ping(matches[2])
else
    chatPing(matches[2])
end