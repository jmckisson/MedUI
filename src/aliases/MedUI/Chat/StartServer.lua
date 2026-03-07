local serverCmd = nil
if mudlet.supports.mmcp then
  serverCmd = mmcp.startServer
else
  serverCmd = chatStartServer
end

if matches[2] ~= nil then
  serverCmd(matches[2])
else
  serverCmd()
end