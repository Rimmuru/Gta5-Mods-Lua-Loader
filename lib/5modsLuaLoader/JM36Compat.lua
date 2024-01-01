local function toPascalCase(str)
    return str:gsub("(%w)(%w+)", function(a, b)
        return a:upper() .. b:lower()
    end):gsub("_", "")
end

local function convertNamespace(namespace)
    for key, func in pairs(namespace) do
        local newKey = toPascalCase(key)
        --menu.notify(tostring(newKey))
        _G[newKey] = func
    end
end

local pid = player.player_id()
local infoTable = { -- this is going to suck
    ["Player"] = {
        Ped = player.get_player_ped(pid),
        ["Vehicle"] = {
            Id = ped.get_vehicle_ped_is_using(player.get_player_ped(pid))
        }
    }
}

do 
    convertNamespace(ENTITY)
    convertNamespace(VEHICLE)
    convertNamespace(PLAYER)
    convertNamespace(PED)
    convertNamespace(WEAPON)
    convertNamespace(UI)
    convertNamespace(GRAPHICS)
    convertNamespace(SYSTEM)
end

function JM36Compat()
    _G["JM36_GTAV_LuaPlugin_Version"] = 20230724.0
    _G["JM36"] = _G["JM36"] or {}
    
    _G["Info"] = infoTable

    _G["JM36"].yield = function(time)
        return coroutine.yield(time)
    end
    _G["JM36"].Wait = function(time)
        return coroutine.yield(time)
    end
    
    _G["JM36"].CreateThread = function(callback)
        return menu.create_thread(callback)
    end

    _G["JM36"].CreateThread_HighPriority = function(callback)
        return menu.create_thread(callback)
    end
end