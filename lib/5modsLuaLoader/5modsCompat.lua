local getAppdataPath <const> = utils.get_appdata_path("PopstarDevs", "").."\\2Take1Menu"
local scriptsPath <const> = getAppdataPath.."\\scripts\\lib\\5modsLua\\"

local function get_key_pressed(keyID)
    if type(keyID) == "number" then
        --menu.notify(tostring(keyID))
        return controls.is_control_just_pressed(0, keyID)
    end
end

local allowedExtensions <const> = {
    [".txt"] = true,
    [".log"] = true,
    [".xml"] = true,
    [".ini"] = true,
    [".cfg"] = true,
    [".csv"] = true,
    [".json"] = true,
    [".lua"] = true,
    [".luac"] = true,
    [".2t1"] = true,
    [".jpg"] = true,
    [".jpeg"] = true,
    [".png"] = true,
    [".gif"] = true,
    [".bmp"] = true,
    [".dds"] = true,
    [".spritefont"] = true,
    [".index"] = true
}

local function isExtensionAllowed(extension)
    return allowedExtensions[extension] == true
end

local function getFileExtension(path)
    return path:match("^.+(%..+)$")
end

function modsCompat()
    _G.get_key_pressed = get_key_pressed
    
    _G.IsControlJustPressed = function(id, idx)
        return get_key_pressed(idx)
    end
        
    _G.wait = function(time)
        return coroutine.yield(time)
    end
    
    local originalOpen <const> = io.open  
    _G["io"].open = function(path, mode)
        local extension = getFileExtension(path)
        if not extension or not allowedExtensions[extension] then
            path = path .. ".2t1"
        end
        local newPath = scriptsPath .. path
        return originalOpen(newPath, mode)
    end
    
    _G["Libs"] = setmetatable({}, {
        __index = function(t, key)
            return require("lib.5ModsLua.libs." .. key)
        end
    })
    
    _G["TIME"] = CLOCK --Override native namespaces
    _G["AI"] = TASK
    _G["PAD"] = CONTROLS

    _G["Keys"] = require("lib\\5modsLuaLoader\\keys")
    _G["keys"] = require("lib\\5modsLuaLoader\\keys")
end
