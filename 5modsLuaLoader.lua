local getAppdataPath <const> = utils.get_appdata_path("PopstarDevs", "").."\\2Take1Menu"
local scriptsPath <const> = getAppdataPath.."\\scripts\\lib\\5modsLua\\"

if not menu.is_trusted_mode_enabled(eTrustedFlags.LUA_TRUST_NATIVES) then
    menu.notify("Trusted mode for natives must be enabled.", "5Mods Lua Loader")
    return menu.exit()
end

if not utils.dir_exists(scriptsPath) then
    utils.make_dir(scriptsPath)
    menu.notify("5Mods scripts folder not found. Creating scripts folder.", "5Mods Lua Loader")
end

require("lib\\5modsLuaLoader\\natives2845")

local parent <const> = menu.add_feature("5Mods Lua Scripts", "parent", 0)
local scriptFeats <const> = menu.add_feature("5Mods Lua Script Features", "parent", 0)

local function get_key_pressed(keyID)
    if type(keyID) == "number" then
        --menu.notify(tostring(keyID))
        return controls.is_control_just_pressed(0, keyID)
    end
end

local pid = player.player_id()
local infoTable = { -- this is going to suck
    ["Player"] = {
        Ped = player.get_player_ped(pid)
    },
    ["Vehicle"] = {
        Id = ped.get_vehicle_ped_is_using(player.get_player_ped(pid))
    }
}

local loadedScripts = {}

local function loadScript(scriptName)
    local scriptPath = scriptsPath .. scriptName .. ".lua"
 
    local chunk, errorMessage = _loadfile(scriptPath)
    if not chunk then
        menu.notify("Error loading script: " .. tostring(errorMessage), "Error", 7)
        return
    end

    -- support for https://www.gta5-mods.com/tools/jm36-lua-plugin-for-script-hook-v-reloaded
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

    _G.get_key_pressed = get_key_pressed

    _G.IsControlJustPressed = function(id, idx)
        return get_key_pressed(idx)
    end

    _G.wait = function(time)
        return coroutine.yield(time)
    end

    _G["io"].open = function(path, mode) 
        local newPath = scriptsPath .. path
        return io.open(newPath, mode)
    end

    _G["Libs"] = setmetatable({}, {
        __index = function(t, key)
            return require("lib.5ModsLua.libs." .. key)
        end
    })
    
    _G["TIME"] = CLOCK --Override time native namespace
    _G["Keys"] = require("lib\\5modsLuaLoader\\keys")
    _G["keys"] = require("lib\\5modsLuaLoader\\keys")

    chunk()

    local status, scriptEnv = pcall(require, "lib\\5modsLua\\"..scriptName)
    if not status then
        menu.notify("Error loading module for script: " .. tostring(scriptEnv), "Error", 7)
        return
    end
    
    if scriptEnv and type(scriptEnv.init) == "function" then
        scriptEnv.init()
    end

    if scriptEnv and type(scriptEnv.tick) == "function" then
        loadedScripts[scriptName] = menu.add_feature(scriptName, "toggle", scriptFeats.id, function(f)
            while f.on do
                scriptEnv.tick()
                coroutine.yield(0)
            end
        end)
    end

    menu.notify("Loaded "..scriptName, "Lua Loader")
end

-- Loading scripts
do
    local scripts = utils.get_all_files_in_directory(scriptsPath, "lua")

    for _, scriptFile in ipairs(scripts) do
        local scriptName = scriptFile:gsub("%.lua", "")
        local scriptParent = menu.add_feature(scriptName, "parent", parent.id)
        menu.add_feature("Run", "toggle", scriptParent.id, function(f)
            if f.on then
                loadScript(scriptName)
            else
                if loadedScripts[scriptName] then
                    --unload logic. package.loaded might be blacklisted though
                    menu.delete_feature(loadedScripts[scriptName].id, true)
                end
            end
        end)
    end
end