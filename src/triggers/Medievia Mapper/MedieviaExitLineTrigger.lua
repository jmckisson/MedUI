if not map or not map.prompt or not map.prompt.exits then
    return
end

-- Exit information is now in GMCP Room.Info, we should be using that instead
map.prompt.exits = map.prompt.exits .. ", " .. string.trim(matches[2])
setTriggerStayOpen("Medievia Multi-Line Exits Trigger",1)