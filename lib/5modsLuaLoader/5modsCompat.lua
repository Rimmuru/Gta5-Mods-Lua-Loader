local function get_key_pressed(keyID)
    if type(keyID) == "number" then
        --menu.notify(tostring(keyID))
        return controls.is_control_just_pressed(0, keyID)
    end
end

function modsCompat()
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
    
    _G["TIME"] = CLOCK --Override native namespace
    _G["AI"] = TASK

    _G["Keys"] = require("lib\\5modsLuaLoader\\keys")
    _G["keys"] = require("lib\\5modsLuaLoader\\keys")
end
