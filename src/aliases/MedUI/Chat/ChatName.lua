if mudlet.supports.mmcp then
  mmcp.chatName(matches[2])
else
  chatName(matches[2])
end

-- For CombatReps script, needs refactor
if CR then
  CR.loadOptions(matches[2])
end