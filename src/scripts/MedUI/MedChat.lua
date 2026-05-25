MedChat = MedChat or {}

local function medieviaTabbedChat_InitMedChat()

  local EMCO = require("MedUI.emco")
  local stylesheet = [[background-color: rgb(0,255,255,255); border-width: 1px; border-style: solid; border-color: gold; border-radius: 10px;]]
  local istylesheet = [[background-color: rgb(60,0,0,255); border-width: 1px; border-style: solid; border-color: gold; border-radius: 10px;]]

  if MedChat.AdjCont and MedChat.AdjCont:get_width() == 0 then
    --cecho("\n<yellow>Found existing MedChat.AdjCont with 0 width, setting to nil and reinitializing...\n")
    MedChat.AdjCont = nil
    MedChat.EMCOConsole = nil
  end

  MedChat.AdjCont = MedChat.AdjCont or Adjustable.Container:new({
    name = "Medievia Chat",
    x = "-30.303%", y = "50%",  -- compensate for the border being width/3.3
    width = "30.303%",
    height = "50%",
    lockStyle = "border",
    adjLabelstyle = MedUI.themedAdjLabelStyle(),
    autoLoad = true,
    autoSave = true,
  })

  MedChat.AdjCont:setTitle("Medievia Chat")

  MedChat.EMCOConsole = MedChat.EMCOConsole or EMCO:new({
    name = "MedChat",
    x = "0",
    y = "0",
    width = "100%",
    height = "100%",
    allTab = true,
    allTabName = "All",
    gap = 2,
    consoleColor = "black",
    consoles = {
      "All",
      "Form",
      "Clan",
      "Town",
      "Chat",
    },
    activeTabCSS = stylesheet,
    fontSize=tonumber(MedUI.options.chatFontSize) or 8,
    inactiveTabCSS = istylesheet,
  }, MedChat.AdjCont)

  MedChat.AdjCont:connectToBorder("right")
  -- Respect the autoloaded hidden state — if the user closed the chat AdjCont
  -- via its X button last session, leave it closed (use `medui showall` to
  -- bring it back). The AdjCont is shown by default for fresh installs.
  if not MedChat.AdjCont.hidden then
    MedChat.AdjCont:show()
  end
  MedChat.AdjCont:lockContainer("light")
  if MedUI and MedUI.persistOnClose then MedUI.persistOnClose(MedChat.AdjCont) end

  -- Initialize MMCP tab if our client supports MMCP (MudMaster Chat Protocol)
  if mudlet.supports.mmcp or chatCall then
    if not table.index_of(MedChat.EMCOConsole.consoles, "MMCP") then
      MedChat.EMCOConsole:addTab("MMCP", #MedChat.EMCOConsole.consoles + 1)
    end
  end

  -- Disable file logging on all tabs (including MMCP, added above)
  MedChat.EMCOConsole:disableAllLogging()
end


function MedChat.appendToChatPanel(channel)
  selectCurrentLine()

  if MedUI.options.enableTimestamps then
    MedChat.EMCOConsole:cecho(channel, "<white>["..getTime(true, "HH:mm:ss") .."] ")
  end

  MedChat.EMCOConsole:append(channel)
  deselect()
  resetFormat()
end

function MedChat.eventHandler(event, ...)

  if event == "sysMMCPChatMessage" or event == "sysMMCPMessage" then
    local trimmedStr = arg[2]:match("^%s*(.-)%s*$")

    if MedUI.options.enableTimestamps then
      MedChat.EMCOConsole:cecho("MMCP", "<white>["..getTime(true, "HH:mm:ss") .."] ")
    end

    MedChat.EMCOConsole:decho("MMCP", ansi2decho(trimmedStr) .. "\n", false)

  elseif event == "sysUninstallPackage" and arg[1] == "MedUI" then
    stopNamedEventHandler("MedUI", "MedChat")
  end
end

local mudletVersion = getMudletVersion()
if mudletVersion.major == 4 and mudletVersion.minor < 20 then
  registerNamedEventHandler("MedUI", "MedChatLegacy", "sysMMCPMessage", "MedChat.eventHandler")
end
registerNamedEventHandler("MedUI", "MedChat", "sysMMCPChatMessage", "MedChat.eventHandler")

-- Defer one tick so Qt drains its deleteLater queue (old TLabels from
-- before resetProfile) before any luaL_ref runs for our new callbacks.
-- probably not needed anymore after PTB fix
tempTimer(0, medieviaTabbedChat_InitMedChat)

