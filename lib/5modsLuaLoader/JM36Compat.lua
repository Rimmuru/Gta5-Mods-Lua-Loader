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