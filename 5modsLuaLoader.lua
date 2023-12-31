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

do -- dependencies check
    local includes <const> = {
        "natives2845",
        "JM36Compat",
        "5modsCompat"
    }
   
   for _, v in ipairs(includes) do
       if not utils.file_exists(getAppdataPath.."\\scripts\\lib\\5modsLuaLoader\\"..v..".lua") then
           menu.notify("Dependency "..v.." is missing. Please reinstall the script.")
       else
           require("lib\\5modsLuaLoader\\"..v)
       end
   end
end

local parent <const> = menu.add_feature("5Mods Lua Scripts", "parent", 0)
local scriptFeats <const> = menu.add_feature("5Mods Lua Script Features", "parent", 0)

local loadedScripts = {}

local function loadScript(scriptName)
    local scriptPath = scriptsPath .. scriptName .. ".lua"
 
    local chunk, errorMessage = _loadfile(scriptPath)
    if not chunk then
        menu.notify("Error loading script: " .. tostring(errorMessage), "Error", 7)
        return
    end

    -- support for https://www.gta5-mods.com/tools/jm36-lua-plugin-for-script-hook-v-reloaded
    JM36Compat()

    -- support for https://www.gta5-mods.com/scripts/tags/lua
    modsCompat()
    
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