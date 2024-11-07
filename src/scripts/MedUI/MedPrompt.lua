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

MedPrompt = MedPrompt or {
  statsPattern = "^\\s*(?<hp>\\d+)\/\\s*(?<maxhp>\\d+)hp\\s*(?<mana>\\d+)\/\\s*(?<maxmana>\\d+)m\\s*(?<mvs>\\d+)\/\\s*(?<maxmvs>\\d+)mv\\s*(-?[0-9]+)ac\\s*(.*)hr\\s*(.*)dr\\s*(-?[0-9]+)a\\s*(.*)xp",
}

MedPrompt.setupComplete = false

--[[
  Called from the actual prompt trigger, assembles the necessary data needed
  for the evtPromptData event
]]--
function MedPrompt.gotPromptLine(matches)

  selectCaptureGroup("hp")
  local r,g,b = getFgColor()
  local hpColorStr = closestColor(r,g,b)
  --display(string.format("hp: %d C[%d,%d,%d]: %s",matches.hp,r,g,b,hpColorStr))
  local hpColor = AnsiMap[hpColorStr]
  selectCaptureGroup("mn")
  r,g,b = getFgColor()
  local mnColorStr = closestColor(r,g,b)
  --display(string.format("mn: %d C[%d,%d,%d]: %s",matches.mn,r,g,b,mnColorStr))
  local mnColor = AnsiMap[mnColorStr]
  
  if not hpColor then
    --display("resetting hpColor to blue, colorStr was " .. hpColorStr)
    hpColor = "blue"
  end
  
  if not mnColor then
    --display("resetting mnColor to blue, colorStr was " .. mnColorStr)
    mnColor = "blue"
  end
  
  local bufStr = string.format("%s%s%s%s%s%s",
              matches.sanc == "S" and "S" or "s",
              matches.fshield == "F" and "F" or "f",
              matches.ishield == "I" and "I" or "i",
              matches.mshield == "M" and "M" or "m",
              matches.images == "P" and "P" or "p",
              matches.invis == "V" and "V" or "v")
              
  local mMana = MedPrompt.maxMana and MedPrompt.maxMana or matches.mana
  local mHp = MedPrompt.maxHp and MedPrompt.maxHp or matches.hp
  local mMvs = MedPrompt.maxMvs and MedPrompt.maxMvs or matches.mvs
  
  --cecho(string.format("\n mMana %d  mHp %d  mMvs %d", mMana, mHp, mMvs))
  
  local promptData = {
    pk = matches.pk,
    hp = tonumber(matches.hp),
    hpAnsiColor = hpColor,
    hpColor = hpColorStr,
    maxHp = tonumber(mHp),
    mana = tonumber(matches.mana),
    mnAnsiColor = mnColor,
    manaColor = mnColorStr,
    maxMana = tonumber(mMana),
    mvs = tonumber(matches.mvs),
    maxMvs = tonumber(mMvs),
    br = tonumber(matches.breath),
    buffs = bufStr,
    lowGuy = matches.heal,
    lowPct = tonumber(matches.pct)
  }
    
  raiseEvent("evtPromptData", promptData)
end

function MedPrompt.generatePromptRegex(input)

  -- List of color codes and their meanings
  local colorCodes = {
    ["#r"] = "Red", ["#lr"] = "Dark red",
    ["#g"] = "Green", ["#lg"] = "Dark green",
    ["#y"] = "Yellow", ["#ly"] = "Dark yellow",
    ["#b"] = "Blue", ["#lb"] = "Dark blue",
    ["#m"] = "Magenta", ["#lm"] = "Dark magenta",
    ["#c"] = "Cyan", ["#lc"] = "Dark cyan",
    ["#w"] = "White", ["#lw"] = "Dark white",
    ["#x"] = "metered"
  }

  -- List of special tags and their meanings
  local specialTags = {
    ["&a"] = {name="ac", rx="\\d+"},        ["&k"] = {name="pk", rx="\\w+"},
    ["&A"] = {name="align", rx="-?\\d+"},   ["&K"] = {name="pk", rx="\\w+"},
    ["&b"] = {name="breath", rx="\\d+"},    ["&Id"] = {name="ldp", rx=".+"},
    ["&B"] = {name="blood", rx="\\d+"},     ["&Ie"] = {name="legg", rx=".+"},
    ["&D"] = {name="dplvl", rx=".+"},       ["&Il"] = {name="llead", rx=".+"},
    ["&d"] = {name="dp", rx=".+"},          ["&Iq"] = {name="laq", rx=".+"},
    ["&E"] = {name="egglvl", rx=".+"},      ["&It"] = {name="ltrade", rx=".+"},
    ["&e"] = {name="eggpts", rx=".+"},      ["&Ix"] = {name="lxp", rx=".+"},
    ["&FB"] = {name="blind", rx=".?"},       ["&l"] = {name="leading", rx=".+"},
    ["&FC"] = {name="curse", rx=".?"},       ["&L"] = {name="leadlvl", rx=".+"},
    ["&FF"] = {name="fshield", rx="."},     ["&M"] = {name="maxmana", rx="\\d+"},
    ["&FG"] = {name="plague", rx=".?"},      ["&m"] = {name="mana", rx="\\d+"},
    ["&FI"] = {name="ishield", rx="."},     ["&N"] = {name="newline", rx="\\s"},
    ["&FL"] = {name="lev", rx="."},         ["&Q"] = {name="aqlvl", rx=".+"},
    ["&FM"] = {name="mshield", rx="."},     ["&q"] = {name="aqpts", rx=".+"},
    ["&FO"] = {name="poison", rx=".?"},      ["&R"] = {name="risk", rx=".+"},
    ["&FP"] = {name="images", rx="."},      ["&T"] = {name="trlvl", rx=".+"},
    ["&FQ"] = {name="quick", rx="."},       ["&t"] = {name="trpts", rx=".+"},
    ["&FS"] = {name="sanc", rx="."},        ["&u"] = {name="mnt", rx=".*"},
    ["&FV"] = {name="invis", rx="."},       ["&V"] = {name="maxmvs", rx="\\d+"},
    ["&FW"] = {name="breathew", rx="."},  ["&v"] = {name="mvs", rx="\\d+"},
    ["&H"] = {name="maxhp", rx="\\d+"},		 ["&W"] = {name="hngrthrst", rx=".?"},
 		["&X"] = {name="xplvl", rx=".+"},       ["&h"] = {name="hp", rx="\\d+"},
  }
  
  if input == "none" then
    input = "#b<#x&h#bhp #x&m#bm #x&v#b&umv #x&b#b&ubr#b>"
  end

  local cleanedInput = input
  
  for k, v in pairs(colorCodes) do
    cleanedInput = cleanedInput:gsub(k, "")
  end
      
  -- escape PCRE characters
  cleanedInput = cleanedInput:gsub("([%^%$%(%)%.%[%]%*%+%-%?%{%}\\|/])", "\\%1")
  
  local nameCount = {}

  -- Sort tags by length to ensure longer tags are matched first
  local tags = {}
  for tag in pairs(specialTags) do
      table.insert(tags, tag)
  end
  table.sort(tags, function(a, b) return #a > #b end) -- Sort by descending length

  for _, tag in ipairs(tags) do
    local tagName = specialTags[tag].name
              
    local pattern = tag:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") .. "(%w*)"

    cleanedInput = cleanedInput:gsub(pattern, function(following)

      nameCount[tagName] = (nameCount[tagName] or 0) + 1
      local nameWithCount = tagName .. (nameCount[tagName] > 1 and tostring(nameCount[tagName]) or "")
        return string.format("(?<%s>%s)%s", nameWithCount, specialTags[tag].rx, following)
    end)

  end
    
  --prepend formation prompt to escaped input
  MedPrompt.promptPattern = "(?:<\\[\\s*(?<pct>\\d+)%\\](?<heal>\\w+)>)*?(?:\\[\\w+\\])*?"..cleanedInput
  if MedPrompt.debugEnabled then
    print("prompt pattern='"..MedPrompt.promptPattern.."'")
  end
  
  if MedPrompt.promptTriggerId then
    killTrigger(MedPrompt.promptTriggerId)
  end
  
  MedPrompt.promptTriggerId = tempRegexTrigger(MedPrompt.promptPattern, function() MedPrompt.gotPromptLine(matches) end)
  
  if not string.find(MedPrompt.promptPattern, "<maxhp>") then
    -- set up stats trigger so we can find maxhp and maxmana
    if MedPrompt.statsTriggerId then
      killTrigger(MedPrompt.statsTriggerId)
    end
    
    MedPrompt.statsTriggerId = tempRegexTrigger(MedPrompt.statsPattern, function()

      if matches.maxhp then
        MedPrompt.maxHp = tonumber(matches.maxhp)
      end
      if matches.maxmana then
        MedPrompt.maxMana = tonumber(matches.maxmana)
      end
      
      if matches.maxmvs then
        MedPrompt.maxMvs = tonumber(matches.maxmvs)
      end
    end)
    
    send("stat")
  end
  
  if not string.find(MedPrompt.promptPattern, "<pk>") then
    --cecho("\n<red>WARNING: PK type not found in your prompt, falling back to standard triggers")
    if MedPrompt.pkTrigIds then
      for k, v in pairs(MedPrompt.pkTrigIds) do
        killTrigger(v)
      end
    end
    MedPrompt.pkTrigIds = {}
    local trigId = tempRegexTrigger("^WARNING! You HAVE ENTERED a CHAOTIC PLAYER KILLING area", function()
      raiseEvent("evtMedPKChange", "CPK")
    end)
    table.insert(MedPrompt.pkTrigIds, tridId)
    trigId = tempRegexTrigger("^WARNING! You HAVE LEFT a CHAOTIC PLAYER KILLING AREA and ENTERED a GRAVE NEUTRAL",
      function()
        raiseEvent("evtMedPKChange", "GNPK")
      end)
    table.insert(MedPrompt.pkTrigIds, tridId)
    trigId = tempRegexTrigger("^WARNING! You HAVE LEFT a CHAOTIC PLAYER KILLING AREA and ENTERED a NEUTRAL",
      function()
        raiseEvent("evtMedPKChange", "NPK")
      end)
    table.insert(MedPrompt.pkTrigIds, tridId)
    trigId = tempRegexTrigger("^NOTICE: You are leaving a PLAYER KILLING area\.",
      function()
        raiseEvent("evtMedPKChange", "LPK")
      end)
    table.insert(MedPrompt.pkTrigIds, tridId)
  end

  MedPrompt.setupComplete = true
    
  return MedPrompt.promptPattern
end


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
  send("prompt")
  --MedPrompt.setupComplete = true
  MedPrompt.killLoginTriggers()
  loadMap(getMudletHomeDir().."/MedUI/MedieviaMap.dat")
end

local trigId = tempRegexTrigger("^Reconnecting", [[MedPrompt.doConnectionSetup()]], 1)
table.insert(MedPrompt.loginTrigIds, trigId)

trigId = tempRegexTrigger("^You are the (.*) person to connect", [[MedPrompt.doConnectionSetup()]], 1)
table.insert(MedPrompt.loginTrigIds, trigId)

trigId = tempTrigger("Norb the Minotaur telepaths you, 'You are in the zone", [[MedPrompt.doConnectionSetup()]], 1)
table.insert(MedPrompt.loginTrigIds, trigId)
