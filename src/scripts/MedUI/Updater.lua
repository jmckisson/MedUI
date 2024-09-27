--[[
  Changelog:
    1.7.2 - Add mapper additions to Muddler project properly
    1.7.1 - Add font to resources
    1.7.0 - Add Medievia Mapper additions for Mudlet generic_mapper
    1.6.6 - Fix missing Repeat alias pattern
    1.6.5 - Fix missing Repeat alias
    1.6.4 - Fix self-updater
    1.6.3 - Fix prompt regex for prompts containing blind, plague, poison, etc
            Use profile name for options persistence
    1.6.2 - Add option to toggle timestamps in the MedChat window
    1.6.1 - Fixed buffs not hiding when gauges are disabled
            Trim whitespace from MMCP messages to prevent misaligned timestamps
    1.6.0 - Added Changelog
            Add option to keep the inline map in 'medui' command
--]]

MedUIUpdater = MedUIUpdater or {
  -- Make sure this version number exists in the versions.lua or the "versions behind" counting will fail!
  version = "1.7.2"
}

--[[ 
  function to compare two versions represented by string float values
  returns 0 if equal, -1 if version1 < version2, 1 if version1 > version2
--]]
local function compareVersions(version1, version2)
  local function splitVersion(version)
    local parts = {}
    for part in string.gmatch(version, "[^.]+") do
      table.insert(parts, tonumber(part))
    end
    return parts
  end

  local parts1 = splitVersion(version1)
  local parts2 = splitVersion(version2)

  for i = 1, math.max(#parts1, #parts2) do
    local num1 = parts1[i] or 0
    local num2 = parts2[i] or 0
    if num1 < num2 then
      return -1 -- version1 < version2
    elseif num1 > num2 then
      return 1 -- version1 > version2
    end
    -- if equal, move to the next part
  end

  return 0 -- versions are equal
end

local profilePath = getMudletHomeDir()
profilePath = profilePath:gsub("\\","/")


--[[
  Compares our currently installed version against the latest version in the downloaded medui_versions.lua
  file. If we're out of date, notify the user and set up an update alias. We may also force a check by
  passing in true which will tell the user/debugger/me that they are a number of versions ahead of the
  published package.
--]]
local function check_version(forced)
  MedUIUpdater.downloading = false
  local path = profilePath .. "/medui downloads/medui_versions.lua"
  local versions = {}
  table.load(path, versions)
  local pos = table.index_of(versions, MedUIUpdater.version) or 0
  
  local versionResult = compareVersions(MedUIUpdater.version, versions[#versions])
  
  if versionResult == -1 then
    
    if MedUIUpdater.updateAlias then
      killAlias(MedUIUpdater.updateAlias)
    end
    
    MedUIUpdater.updateAlias = tempAlias("^medui update$", [[MedUIUpdater.updateVersion()]])
    
    cecho(string.format("\n<DeepSkyBlue>Your MedUI (<yellow>%s<DeepSkyBlue>) is currently <red>%d<DeepSkyBlue> version%s behind the latest (<yellow>%s<DeepSkyBlue>).",
      MedUIUpdater.version, #versions - pos, (#versions - pos) > 1 and "s" or "", versions[#versions]))
    cecho("\n<DeepSkyBlue>To update now, please type: <yellow>medui update<reset>")
    
  elseif forced and versionResult == 1 then
    cecho(string.format("\n<DeepSkyBlue>Your MedUI (<yellow>%s<DeepSkyBlue>) is currently ahead of the latest (<yellow>%s<DeepSkyBlue>)!",
      MedUIUpdater.version, versions[#versions]))
  end

  if MedUIUpdater.update_timer then
    MedUIUpdater.update_timer = nil
  end
  
  MedUIUpdater.update_timer = tempTimer(3600, [[MedUIUpdater.checkVersion()]])
end

--[[
  Initiate download of the latest published medui_versions file
--]]
function MedUIUpdater.checkVersion()
  if MedUIUpdater.update_timer then
    killTimer(MedUIUpdater.update_timer)
    MedUIUpdater.update_timer = nil
  end
  if not MedUIUpdater.update_waiting and MedUIUpdater.configs.download_path ~= "" then
    local path, file = profilePath .. "/medui downloads", "/medui_versions.lua"
    MedUIUpdater.downloading = true
    downloadFile(path .. file, MedUIUpdater.configs.download_path .. file)
    MedUIUpdater.update_waiting = true
  end
end

--[[
  Updates MedUI by uninstalling the currently installed package and installing the
  recently downloaded one
--]]
local function update_version()
  MedUIUpdater.downloading = false
  local path = profilePath .. "/medui downloads/MedUI.mpackage"
  
  if MedUIUpdater.updateAlias then
    killAlias(MedUIUpdater.updateAlias)
    MedUIUpdater.updateAlias= nil
  end
  
  if MedUIUpdater.loginTriggers ~= nil then
    for k, v in pairs(MedUIUpdater.loginTriggers) do
      killTrigger(v)
    end
  end
  MedUIUpdater.updatingUI = true
  uninstallPackage("MedUI")
  installPackage(path)
  MedUIUpdater.updatingUI = nil
  cecho("\n<DeepSkyBlue>MedUI Script updated successfully.")
end

--[[
  Initiate download of the latest published MedUI package
--]]
function MedUIUpdater.updateVersion()
  local path, file = profilePath .. "/medui downloads", "/MedUI.mpackage"
  MedUIUpdater.downloading = true
  downloadFile(path .. file, MedUIUpdater.configs.download_path .. file)
end

function MedUIUpdater.initConfig()
  MedUIUpdater.configs = MedUIUpdater.configs or {
    download_path = "https://raw.githubusercontent.com/jmckisson/MedScripts/master/MedUI"
  }
  
end

function MedUIUpdater.eventHandler(event, ...)

  if event == "sysDataSendRequest" then

    -- check to prevent multiple version checks in a row without user intervention
    if MedUIUpdater.update_waiting and MedUIUpdater.update_timer then
      MedUIUpdater.update_waiting = nil
      
    -- check to ensure version check cycle is started
    elseif not MedUIUpdater.update_waiting and not MedUIUpdater.update_timer then
      MedUIUpdater.checkVersion()
    end
    
  elseif event == "sysInstall" then
    MedUIUpdater.initConfig()
  
    local path = profilePath.."/medui downloads"
    if not io.exists(path) then lfs.mkdir(path) end
    
  elseif event == "sysUninstallPackage" and not MedUIUpdater.updatingUI and arg[1] == "MedUI" then
    for _,id in ipairs(MedUIUpdater.registeredEvents) do
      killAnonymousEventHandler(id)
    end
    
  elseif event == "sysDownloadDone" and MedUIUpdater.downloading then
    local file = arg[1]
    
    if string.ends(file, "/medui_versions.lua") then
      check_version(false)
    elseif string.ends(file, "/MedUI.mpackage") then
      update_version()
    end

  end
end

MedUIUpdater.registeredEvents = {
  registerAnonymousEventHandler("sysDownloadDone", "MedUIUpdater.eventHandler"),
  registerAnonymousEventHandler("sysInstall", "MedUIUpdater.eventHandler"),
  registerAnonymousEventHandler("sysDataSendRequest", "MedUIUpdater.eventHandler"),
  registerAnonymousEventHandler("sysUninstallPackage", "MedUIUpdater.eventHandler")
}


local trigId = tempRegexTrigger("^You are the (.*) person to connect since",
  function()
    MedUIUpdater.initConfig()
    send("prompt")
  end)
  
if MedUIUpdater.loginTriggers ~= nil then
  for k, v in pairs(MedUIUpdater.loginTriggers) do
    killTrigger(v)
  end
end

MedUIUpdater.loginTriggers = {}
  
table.insert(MedUIUpdater.loginTriggers, trigId)

MedUIUpdater.initConfig()