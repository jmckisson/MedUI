if mudlet.supports.mmcp then
    mmcp.setGroup(matches[2])
else
    chatSetGroup(matches[2], matches[3])
end