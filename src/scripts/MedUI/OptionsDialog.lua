MedUI = MedUI or {}
MedUI.OptionsDialog = MedUI.OptionsDialog or {}

local Dialog = MedUI.OptionsDialog
Dialog.isOpen = false
Dialog.rows = Dialog.rows or {}

local DIALOG_WIDTH = 560
local DIALOG_HEIGHT = 470
local TITLE_HEIGHT = 44
local ROW_HEIGHT = 38
local SIDE_PAD = 18

local function panelCSS()
  return [[
    background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1,
      stop:0 rgba(38, 38, 44, 245), stop:1 rgba(22, 22, 26, 245));
    border: 2px solid #8b1a1a;
    border-radius: 10px;
  ]]
end

local function backdropCSS()
  return [[background-color: rgba(0, 0, 0, 140);]]
end

local function titleCSS()
  return [[
    background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1,
      stop:0 #6b0f0f, stop:1 #3a0808);
    border-top-left-radius: 8px;
    border-top-right-radius: 8px;
    border-bottom: 1px solid #8b1a1a;
  ]]
end

local function rowCSS()
  return [[
    background-color: rgba(255, 255, 255, 8);
    border: 1px solid rgba(255, 255, 255, 20);
    border-radius: 6px;
  ]]
end

local function toggleOnCSS()
  return [[
    background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1,
      stop:0 #2e8b2e, stop:1 #1f5f1f);
    border: 1px solid #7fdc7f;
    border-radius: 5px;
  ]]
end

local function toggleOnHoverCSS()
  return [[
    background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1,
      stop:0 #38a738, stop:1 #267326);
    border: 1px solid #a0f0a0;
    border-radius: 5px;
  ]]
end

local function toggleOffCSS()
  return [[
    background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1,
      stop:0 #6e1f1f, stop:1 #3e0d0d);
    border: 1px solid #c46666;
    border-radius: 5px;
  ]]
end

local function toggleOffHoverCSS()
  return [[
    background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1,
      stop:0 #8a2a2a, stop:1 #501212);
    border: 1px solid #e08585;
    border-radius: 5px;
  ]]
end

local function stepperButtonCSS()
  return [[
    background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1,
      stop:0 #4a4a55, stop:1 #2a2a30);
    border: 1px solid #8a8a96;
    border-radius: 5px;
  ]]
end

local function stepperButtonHoverCSS()
  return [[
    background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1,
      stop:0 #5e5e6c, stop:1 #38384a);
    border: 1px solid #b0b0c0;
    border-radius: 5px;
  ]]
end

local function valueDisplayCSS()
  return [[
    background-color: rgba(0, 0, 0, 120);
    border: 1px solid rgba(255, 255, 255, 40);
    border-radius: 5px;
  ]]
end

local function closeXCSS()
  return [[
    background-color: transparent;
    border: 1px solid transparent;
    border-radius: 14px;
  ]]
end

local function closeXHoverCSS()
  return [[
    background-color: rgba(255, 60, 60, 180);
    border: 1px solid #ffaaaa;
    border-radius: 14px;
  ]]
end

local function footerButtonCSS()
  return [[
    background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1,
      stop:0 #6b0f0f, stop:1 #3a0808);
    border: 1px solid #8b1a1a;
    border-radius: 6px;
  ]]
end

local function footerButtonHoverCSS()
  return [[
    background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1,
      stop:0 #8a1818, stop:1 #4a0a0a);
    border: 1px solid #c46666;
    border-radius: 6px;
  ]]
end

local function htmlLabel(text, sizePt, color, align, bold)
  sizePt = sizePt or 10
  color = color or "#e6e6e6"
  align = align or "left"
  local weight = bold and "font-weight: bold;" or ""
  local style = string.format(
    "font-family: 'Bitstream Vera Sans'; color: %s; font-size: %dpt; %s",
    color, sizePt, weight)
  return string.format([[<div align="%s" style="%s">%s</div>]], align, style, text)
end

local function applyChange(option)
  if option.onChange then option.onChange() end
  MedUI.reconfigure()
  MedUI.saveOptions(true)
end

function Dialog.onToggle(key)
  MedUI.options[key] = not MedUI.options[key]
  local options = MedUI.optionsList
  for _, opt in ipairs(options) do
    if opt.key == key then applyChange(opt) break end
  end
  Dialog.refreshRow(key)
end

function Dialog.onStep(key, delta)
  local current = tonumber(MedUI.options[key]) or 0
  local options = MedUI.optionsList
  local optMin, optMax = 6, 24
  local opt
  for _, o in ipairs(options) do
    if o.key == key then
      opt = o
      optMin = o.min or optMin
      optMax = o.max or optMax
      break
    end
  end
  local newVal = current + delta
  if newVal < optMin then newVal = optMin end
  if newVal > optMax then newVal = optMax end
  MedUI.options[key] = newVal
  if opt then applyChange(opt) end
  Dialog.refreshRow(key)
end

function Dialog.refreshRow(key)
  local row = Dialog.rows[key]
  if not row then return end
  if row.type == "toggle" then
    local on = MedUI.options[key] and true or false
    row.toggle:setStyleSheet(on and toggleOnCSS() or toggleOffCSS())
    row.toggle.onState = on
    row.toggle:echo(htmlLabel(on and "ON" or "OFF", 9, "#ffffff", "center", true))
  elseif row.type == "value" then
    row.valueLabel:echo(htmlLabel(tostring(MedUI.options[key]), 10, "#ffffff", "center", true))
  end
end

local function setHoverable(label, normalCSS, hoverCSS)
  label:setStyleSheet(normalCSS)
  label:setOnEnter(function()
    if label.onState then
      label:setStyleSheet(toggleOnHoverCSS())
    elseif label.onState == false then
      label:setStyleSheet(toggleOffHoverCSS())
    else
      label:setStyleSheet(hoverCSS)
    end
  end)
  label:setOnLeave(function()
    if label.onState then
      label:setStyleSheet(toggleOnCSS())
    elseif label.onState == false then
      label:setStyleSheet(toggleOffCSS())
    else
      label:setStyleSheet(normalCSS)
    end
  end)
end

local function buildRow(parent, yPx, option)
  local row = {type = option.type, key = option.key}

  local rowBgHeight = ROW_HEIGHT - 6
  local ctlHeight = 20
  local ctlY = math.floor((rowBgHeight - ctlHeight) / 2)

  local rowBg = Geyser.Label:new({
    name = "MedUIOptRow_" .. option.key,
    x = SIDE_PAD, y = yPx,
    width = DIALOG_WIDTH - (SIDE_PAD * 2), height = rowBgHeight,
  }, parent)
  rowBg:setStyleSheet(rowCSS())

  local nameLabel = Geyser.Label:new({
    name = "MedUIOptName_" .. option.key,
    x = 12, y = 0,
    width = 360, height = "100%",
  }, rowBg)
  nameLabel:setStyleSheet([[
    background-color: transparent;
    qproperty-alignment: 'AlignVCenter | AlignLeft';
    padding-left: 4px;
  ]])
  nameLabel:echo(htmlLabel(option.label, 10, "#e6e6e6", "left", false))

  if option.type == "toggle" then
    local on = MedUI.options[option.key] and true or false
    local toggleW = 64
    local toggle = Geyser.Label:new({
      name = "MedUIOptToggle_" .. option.key,
      x = -(toggleW + 12), y = ctlY,
      width = toggleW, height = ctlHeight,
    }, rowBg)
    toggle:setStyleSheet(on and toggleOnCSS() or toggleOffCSS())
    toggle.onState = on
    toggle:echo(htmlLabel(on and "ON" or "OFF", 9, "#ffffff", "center", true))
    toggle:setClickCallback("MedUI.OptionsDialog.onToggle", option.key)
    toggle:setOnEnter(function()
      toggle:setStyleSheet(toggle.onState and toggleOnHoverCSS() or toggleOffHoverCSS())
    end)
    toggle:setOnLeave(function()
      toggle:setStyleSheet(toggle.onState and toggleOnCSS() or toggleOffCSS())
    end)
    row.toggle = toggle
  elseif option.type == "value" then
    local btnW = 26
    local valW = 42
    local groupW = btnW + valW + btnW + 4
    local startX = -(groupW + 12)

    local minus = Geyser.Label:new({
      name = "MedUIOptMinus_" .. option.key,
      x = startX, y = ctlY,
      width = btnW, height = ctlHeight,
    }, rowBg)
    minus:echo(htmlLabel("&#8722;", 11, "#ffffff", "center", true))
    minus:setClickCallback("MedUI.OptionsDialog.onStep", option.key, -1)
    setHoverable(minus, stepperButtonCSS(), stepperButtonHoverCSS())

    local valueLabel = Geyser.Label:new({
      name = "MedUIOptValue_" .. option.key,
      x = startX + btnW + 2, y = ctlY,
      width = valW, height = ctlHeight,
    }, rowBg)
    valueLabel:setStyleSheet(valueDisplayCSS())
    valueLabel:echo(htmlLabel(tostring(MedUI.options[option.key]), 10, "#ffffff", "center", true))

    local plus = Geyser.Label:new({
      name = "MedUIOptPlus_" .. option.key,
      x = startX + btnW + valW + 4, y = ctlY,
      width = btnW, height = ctlHeight,
    }, rowBg)
    plus:echo(htmlLabel("+", 11, "#ffffff", "center", true))
    plus:setClickCallback("MedUI.OptionsDialog.onStep", option.key, 1)
    setHoverable(plus, stepperButtonCSS(), stepperButtonHoverCSS())

    row.valueLabel = valueLabel
  end

  return row
end

function Dialog.close()
  if Dialog.backdrop then
    Dialog.backdrop:hide()
    Dialog.backdrop:delete()
    Dialog.backdrop = nil
  end
  Dialog.panel = nil
  Dialog.rows = {}
  Dialog.isOpen = false
end

local function eatClick() end

function Dialog.open()
  if Dialog.isOpen then
    Dialog.close()
    return
  end

  local sw, sh = getMainWindowSize()
  local dx = math.floor((sw - DIALOG_WIDTH) / 2)
  local dy = math.floor((sh - DIALOG_HEIGHT) / 2)

  Dialog.backdrop = Geyser.Label:new({
    name = "MedUIOptBackdrop",
    x = 0, y = 0,
    width = "100%", height = "100%",
  })
  Dialog.backdrop:setStyleSheet(backdropCSS())
  Dialog.backdrop:setClickCallback(eatClick)

  Dialog.panel = Geyser.Label:new({
    name = "MedUIOptPanel",
    x = dx, y = dy,
    width = DIALOG_WIDTH, height = DIALOG_HEIGHT,
  }, Dialog.backdrop)
  Dialog.panel:setStyleSheet(panelCSS())
  Dialog.panel:setClickCallback(eatClick)

  local title = Geyser.Label:new({
    name = "MedUIOptTitle",
    x = 0, y = 0,
    width = "100%", height = TITLE_HEIGHT,
  }, Dialog.panel)
  title:setStyleSheet(titleCSS())
  title:echo(htmlLabel("MedUI Options &mdash; v" .. tostring(MedUI.version), 12, "#ffd9a0", "center", true))

  local closeX = Geyser.Label:new({
    name = "MedUIOptCloseX",
    x = -36, y = 8,
    width = 28, height = 28,
  }, title)
  closeX:setStyleSheet(closeXCSS())
  closeX:echo(htmlLabel("&#10006;", 10, "#ffaaaa", "center", true))
  closeX:setClickCallback("MedUI.OptionsDialog.close")
  closeX:setOnEnter(function() closeX:setStyleSheet(closeXHoverCSS()) end)
  closeX:setOnLeave(function() closeX:setStyleSheet(closeXCSS()) end)

  local options = MedUI.optionsList
  local startY = TITLE_HEIGHT + 14
  for i, option in ipairs(options) do
    local yPx = startY + ((i - 1) * ROW_HEIGHT)
    Dialog.rows[option.key] = buildRow(Dialog.panel, yPx, option)
  end

  local closeBtn = Geyser.Label:new({
    name = "MedUIOptCloseBtn",
    x = -130, y = -44,
    width = 112, height = 32,
  }, Dialog.panel)
  closeBtn:echo(htmlLabel("Close", 10, "#ffffff", "center", true))
  closeBtn:setClickCallback("MedUI.OptionsDialog.close")
  setHoverable(closeBtn, footerButtonCSS(), footerButtonHoverCSS())

  Dialog.backdrop:show()
  Dialog.isOpen = true
end

function Dialog.toggle()
  if Dialog.isOpen then Dialog.close() else Dialog.open() end
end

if MedUI.optionsDialogAlias then
  killAlias(MedUI.optionsDialogAlias)
end
MedUI.optionsDialogAlias = tempAlias("^medui options$", [[MedUI.OptionsDialog.toggle()]])
