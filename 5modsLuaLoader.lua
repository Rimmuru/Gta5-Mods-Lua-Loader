local getAppdataPath <const> = utils.get_appdata_path("PopstarDevs", "").."\\2Take1Menu"
local scriptsPath <const> = getAppdataPath.."\\scripts\\lib\\5modsLua\\"

if not menu.is_trusted_mode_enabled(eTrustedFlags.LUA_TRUST_NATIVES) then
    menu.notify("Trusted mode for natives must be enabled.", "5Mods Lua Loader")
    return menu.exit()
end

--set them before we override them
originalMenu = menu 
originalPlayer = player
originalEvent = event
originalRequire = require
scriptParents = {}
scriptPlayerParents = {}

local add_feature <const> = menu.add_feature

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

local parent <const> = add_feature("5Mods Lua Scripts", "parent", 0)
local scriptFeats <const> = add_feature("5Mods Lua Script Features", "parent", 0)
local scriptPlayerFeats <const> = menu.add_player_feature("5Mods Lua Script Features", "parent", 0)

local loadedScripts = {}

local function loadScript(scriptName)
    scriptName = trim(scriptName)
    local scriptPath = scriptsPath .. scriptName 
   
    if not string.find(scriptName, "pluto") then
        scriptPath = scriptPath .. ".lua"
    end
    
    if not scriptParents[scriptName] then
        scriptParents[scriptName] = originalMenu.add_feature(scriptName, "parent", scriptFeats.id)
    end

    if not scriptPlayerParents[scriptName] then
        scriptPlayerParents[scriptName] = originalMenu.add_player_feature(scriptName, "parent", scriptPlayerFeats.id)
    end

    local scriptParentId = scriptParents[scriptName].id
    local scriptPlayerParentId = scriptPlayerParents[scriptName].id

    -- support for https://www.gta5-mods.com/tools/jm36-lua-plugin-for-script-hook-v-reloaded
    JM36Compat()
      
    -- support for https://www.gta5-mods.com/scripts/tags/lua
    modsCompat()
    
    -- attempt to support fivem --impliment when stand is stable
    fivemCompat()

    --stand - kill me now
    standCompat()

    _G["menu"].my_root = function() 
        originalMenu.notify(tostring("Standcompat my_root: "..scriptName))
        return my_root(scriptName) 
    end
    _G["menu"].player_root = function() 
        originalMenu.notify(tostring("Standcompat player_root: "..scriptName))
        return player_root(scriptName) 
    end
   
    _G["menu"].ref_by_path = function(path, version)
        version = version or nil
        originalMenu.notify("ref_by_path called with path: " .. tostring(path) .. ", version: " .. tostring(version))
        return ref_by_path(path, version)
    end

    local chunk, errorMessage = _loadfile(scriptPath)
    if not chunk then
        originalMenu.notify("Error loading script: " .. tostring(errorMessage), "Error", 7)
        return
    end

    chunk()

   local status, scriptEnv = pcall(require, scriptName)
   if not status then
       originalMenu.notify("Error loading module for script: " .. tostring(scriptEnv), "Error", 7)
       return
   end
    
    if scriptEnv and type(scriptEnv.init) == "function" then
        scriptEnv.init()
    end

    if scriptEnv and type(scriptEnv.tick) == "function" then
        loadedScripts[scriptName] = add_feature(scriptName, "toggle", scriptParentId, function(f)
            while f.on do
                scriptEnv.tick()
                coroutine.yield(0)
            end
        end)
    end
    
    standRestoreOriginalMenu()
    if scriptEnv then
        menu.notify("Loaded "..scriptName, "Lua Loader")
    end
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
        local scriptName = scriptFile:gsub("%.lua", ""):lower()
        local scriptParent = add_feature(scriptName, "parent", parent.id)

        add_feature("Load", "action", scriptParent.id, function(f)
            loadScript(scriptName)
        end)

        add_feature("Unload", "action", scriptParent.id, function(f)
            if scriptParents[scriptName] then
                --unload logic. original package.loaded is unused as 2t1 replaces require
                originalMenu.delete_feature(scriptParents[scriptName].id, true)
                package.unload(scriptName)
            end
        end)
    end
end