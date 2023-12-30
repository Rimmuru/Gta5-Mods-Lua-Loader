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
    local key = MenuKey()
    key:push_str(keyID)
    return key:is_down()
end

local function get_key_pressed(keyID)
    if type(keyID)== "number" then
        return controls.is_control_just_pressed(0, keyID)
    end
end

local function loadScript(scriptName)
    local scriptPath = scriptsPath .. scriptName .. ".lua"
 
    local chunk, errorMessage = _loadfile(scriptPath)
    if not chunk then
        menu.notify("Error loading script: " .. tostring(errorMessage), "Error", 7)
        return
    end

    _G.get_key_pressed = get_key_pressed
    _G.wait = function(time)
        return coroutine.yield(time)
    end
    _G["io"].open = function(path, ...) -- has some other params idc about
        path = scriptsPath
    end
    _G["TIME"] = CLOCK
    _G["Keys"] = require("lib\\5modsLuaLoader\\keys")
    _G["keys"] = require("lib\\5modsLuaLoader\\keys")

    chunk()

    menu.notify("Loaded "..scriptName, "Lua Loader")

    local scriptEnv = require("lib\\5modsLua\\"..scriptName)
    if scriptEnv.init ~= nil then
        scriptEnv.init()
    end

    if scriptEnv.tick ~= nil then
        local scriptFeat = menu.add_feature(scriptName, "toggle", scriptFeats.id, function(f)
            while f.on do
                scriptEnv.tick()
                coroutine.yield(0)
            end
        end)
    end
end

-- Loading scripts
do
    local scripts = utils.get_all_files_in_directory(scriptsPath, "lua")

    for _, scriptFile in ipairs(scripts) do
        local scriptName = scriptFile:gsub("%.lua", "")
        local scriptParent = menu.add_feature(scriptName, "parent", parent.id)
        menu.add_feature("Load " .. scriptName, "action", scriptParent.id, function(f)
            loadScript(scriptName)
        end)
    end
end