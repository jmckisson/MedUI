mudlet.custom_name_search = function (lines)

    if not gmcp.Room then
        local line_count = #lines + 1
        local capture_next = false

        for i=1,line_count do

            if lines[i] then

                local map_name_result = string.match(lines[i], "┤(.-)├")
                local map_name_result2 = string.match(lines[i], "^%+%-*%[(.-)%]%-*%+$")

                if map_name_result then
                    room_name = map_name_result
                    --map.echo("Name Search: room_name:" ..room_name)
                break

                elseif map_name_result2 then
                    room_name = map_name_result2
                    --map.echo("Name Search: room_name:" ..room_name)
                break

                elseif capture_next then
                    room_name = lines[i]
                    --map.echo("Name Search: room_name (after map line): " .. room_name)
                break

                elseif lines[i]:find("^└[-─]+┘$") or lines[i]:find("^%+[-%-]%+") then
                    --map.echo("Name Search: capturing next line after map")
                    capture_next = true

                -- If we got to the prompt and nothing was found, it was probably the first line...
                elseif string.find(lines[i], map.save.prompt_pattern[map.character]) then
                    room_name = lines[1]
                end
            end
        end

        return room_name
    end

    return gmcp.Room.Info.name
end


local function killCustomMapEventHandlers()
    if MedUI.mapCustomEventHandlers then
        for k, v in pairs(MedUI.mapCustomEventHandlers) do
            killAnonymousEventHandler(v)
        end
    end

    MedUI.mapCustomEventHandlers = {}
end


local function setCustomNameConfig()
    -- map.configs may not exist at this point as its config() is called for a sysLoadEvent or sysInstall
    if not map then
        tempTimer(.5, function()
            if map and map.configs and not map.configs.custom_name_search then
                map.setConfigs("custom_name_search", true)
                killCustomMapEventHandlers()
            --else
                --cecho("\n<yellow>[MedUI] There was an error setting up the Mudlet Mapper, the Mudlet Mapper may not work properly\n")
            end
        end)
    else
        if map.configs and not map.configs.custom_name_search then
            map.setConfigs("custom_name_search", true)
            killCustomMapEventHandlers()
        end
    end

end

killCustomMapEventHandlers()


table.insert(MedUI.mapCustomEventHandlers, registerAnonymousEventHandler("sysLoadEvent", function()
    setCustomNameConfig()
end))

table.insert(MedUI.mapCustomEventHandlers, registerAnonymousEventHandler("sysInstall", function(event, name)
    if name == "generic_mapper" then
        setCustomNameConfig()
    end
end))





