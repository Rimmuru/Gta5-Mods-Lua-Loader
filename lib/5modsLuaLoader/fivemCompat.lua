function fivemCompat()
    _G["Citizen"] = _G["Citizen"] or {}
    _G["Citizen"].CreateThread = function(callback)
        return menu.create_thread(callback)
    end
    _G["Citizen"].InvokeNative = function(hash, ...)
        return native.call(hash, ...)
    end
    _G.TriggerEvent = function(str, callback)
    end
    _G["Citizen"].Wait = function(time)
        return coroutine.yield(time)
    end
end
