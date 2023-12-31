function fivemCompat()
    _G["Citizen"].CreateThread = function(callback)
        return menu.create_thread(callback)
    end
    _G["Citizen"].InvokeNative = function(hash, ...)
        return native.call(hash, ...)
    end
end
