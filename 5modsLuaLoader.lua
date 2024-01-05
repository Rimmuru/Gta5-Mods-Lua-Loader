local getAppdataPath <const> = utils.get_appdata_path("PopstarDevs", "").."\\2Take1Menu"
local scriptsPath <const> = getAppdataPath.."\\scripts\\lib\\5modsLua\\"

if not menu.is_trusted_mode_enabled(eTrustedFlags.LUA_TRUST_NATIVES) then
    menu.notify("Trusted mode for natives must be enabled.", "5Mods Lua Loader")
    return menu.exit()
end

do -- dependencies check
    local includes <const> = {
        "natives2845",
        "JM36Compat",
        "5modsCompat",
        "fivemCompat",
        "standCompat"
    }
   
   for _, v in ipairs(includes) do
       if not utils.file_exists(getAppdataPath.."\\scripts\\lib\\5modsLuaLoader\\"..v..".lua") then
           menu.notify("Dependency "..v.." is missing. Please reinstall the script.")
           return menu.exit()
       else
           require("lib\\5modsLuaLoader\\"..v)
       end
   end

   local directories = {
        "resources",
        "store",
        "lib"
    }

    if not utils.dir_exists(scriptsPath) then
        utils.make_dir(scriptsPath)
        originalMenu.notify("Scripts folder not found. Creating scripts folder.")
    end
    
    for _, v in ipairs(directories) do
        if not utils.dir_exists(scriptsPath..v) then
            utils.make_dir(scriptsPath..v.."\\")
        end
    end
end

local parent <const> = menu.add_feature("5Mods Lua Scripts", "parent", 0)
local scriptFeats <const> = menu.add_feature("5Mods Lua Script Features", "parent", 0)
local scriptPlayerFeats <const> = menu.add_player_feature("5Mods Lua Script Features", "parent", 0)

local loadedScripts = {}

local function loadScript(scriptName)
    scriptName = trim(scriptName):lower()
    local scriptPath = scriptsPath .. scriptName 
   
    if not string.find(scriptName, "pluto") then
        scriptPath = scriptPath .. ".lua"
    end
    
    if not scriptParents[scriptName] then
        print("Loading script "..scriptName)
        scriptParents[scriptName] = originalMenu.add_feature(scriptName, "parent", scriptFeats.id)
    end

    if not scriptPlayerParents[scriptName] then
        print("Loading script "..scriptName)
        scriptPlayerParents[scriptName] = originalMenu.add_player_feature(scriptName, "parent", scriptPlayerFeats.id)
    end

    local scriptParentId = scriptParents[scriptName].id
    local scriptPlayerParentId = scriptPlayerParents[scriptName].id

    -- support for https://www.gta5-mods.com/tools/jm36-lua-plugin-for-script-hook-v-reloaded
    JM36Compat()

    -- support for https://www.gta5-mods.com/scripts/tags/lua
    modsCompat()
    
    -- attempt to support fivem - complicated cunt
    fivemCompat()

    --stand - kill me now erroring cunt
    standCompat()

    local chunk, errorMessage = _loadfile(scriptPath)
    if not chunk then
        originalMenu.notify("Error loading script: " .. tostring(errorMessage), "Error", 7)
        return
    end

    _G["menu"].my_root = function() 
        originalMenu.notify(tostring("Standcompat my_root: "..scriptName))
        return my_root(scriptName) 
    end
    _G["menu"].player_root = function() 
        return player_root(scriptName) 
    end

    chunk()

    standRestoreOriginalMenu()

    local status, scriptEnv = pcall(require, "lib\\5modsLua\\"..scriptName)
    if not status then
        originalMenu.notify("Error loading module for script: " .. tostring(scriptEnv), "Error", 7)
        return
    end
    
    if scriptEnv and type(scriptEnv.init) == "function" then
        scriptEnv.init()
    end

    if scriptEnv and type(scriptEnv.tick) == "function" then
        loadedScripts[scriptName] = menu.add_feature(scriptName, "toggle", scriptParentId, function(f)
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
    local function getAllScripts()
        local luaFiles = utils.get_all_files_in_directory(scriptsPath, "lua")
        local plutoFiles = utils.get_all_files_in_directory(scriptsPath, "pluto")
    
        local allFiles = {}
    
        table.move(luaFiles, 1, #luaFiles, #allFiles + 1, allFiles)
    
        table.move(plutoFiles, 1, #plutoFiles, #allFiles + 1, allFiles)
    
        return allFiles
    end
    
    for _, scriptFile in ipairs(getAllScripts()) do
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