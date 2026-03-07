if mudlet.supports.mmcp then
    mmcp.allowSnoop(matches[2])
else
    chatAllowSnoop(matches[2])
end