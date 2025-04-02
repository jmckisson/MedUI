AnsiColors = {
    StyleReset = "\27[0m",
    StyleBold = "\27[1m",
    StyleReverse = "\27[7m",
    ForeBlack = "\27[30m",
    ForeRed = "\27[31m",
    ForeGreen = "\27[32m",
    ForeYellow = "\27[33m",
    ForeBlue = "\27[34m",
    ForeMagenta = "\27[35m",
    ForeCyan = "\27[36m",
    ForeWhite = "\27[37m",
    FBLDGRY = "\27[1;30m",
    FBLDRED = "\27[1;31m",
    FBLDGRN = "\27[1;32m",
    FBLDYEL = "\27[1;33m",
    FBLDBLU = "\27[1;34m",
    FBLDMAG = "\27[1;35m",
    FBLDCYN = "\27[1;36m",
    FBLDWHT = "\27[1;37m",
    BBLK = "\27[40m",
    BRED = "\27[41m",
    BGRN = "\27[42m",
    BYEL = "\27[43m",
    BBLU = "\27[44m",
    BMAG = "\27[45m",
    BCYN = "\27[46m",
    BWHT = "\27[47m"
}

AnsiMap = {
  ["<black>"]   = AnsiColors.ForeBlack,
  ["<red>"]     = AnsiColors.ForeRed,
  ["<green>"]   = AnsiColors.ForeGreen,
  ["ansi_010"]  = AnsiColors.ForeGreen,
  ["<yellow>"]  = AnsiColors.ForeYellow,
  ["<blue>"]    = AnsiColors.ForeBlue,
  ["ansi_012"]  = AnsiColors.ForeBlue,
  ["<magenta>"] = AnsiColors.ForeMagenta,
  ["<cyan>"]    = AnsiColors.ForeCyan,
  ["<white>"]   = AnsiColors.ForeWhite,
  ["blue"]    = AnsiColors.ForeBlue,
  ["yellow"]  = AnsiColors.ForeYellow,
  ["ansi_light_red"]     = AnsiColors.ForeRed,
}

MedPrompt = MedPrompt or {}

MedPrompt.setupComplete = false

function MedPrompt.killLoginTriggers()
  if MedPrompt.loginTrigIds then
    for k, v in pairs(MedPrompt.loginTrigIds) do
      killTrigger(v)
    end
  end
  MedPrompt.loginTrigIds = {}
end

MedPrompt.killLoginTriggers()


function MedPrompt.doConnectionSetup()

  tempTimer(.5, function()
    MedUI.loadOptions()
    MedUI.reconfigure()
    tempTimer(.5, [[MedUI.updateVitals()]])
  end)

  MedPrompt.killLoginTriggers()
  loadMap(getMudletHomeDir().."/MedUI/MedieviaMap.dat")
  closeMapWidget()

  MedPrompt.setupComplete = true
end

registerNamedEventHandler("MedUI", "MedLoginHandler", "gmcp.Char.Info", "MedPrompt.doConnectionSetup")

