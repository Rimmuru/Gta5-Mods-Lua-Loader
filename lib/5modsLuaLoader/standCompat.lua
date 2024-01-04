local getAppdataPath <const> = utils.get_appdata_path("PopstarDevs", "").."\\2Take1Menu"
local scriptsPath <const> = getAppdataPath.."\\scripts\\lib\\5modsLua\\"

local originalRequire <const> = require
originalMenu = menu --needs to be global because kill me
originalPlayer = player
originalEvent = event
scriptParents = {}
scriptPlayerParents = {}

function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function create_texture_wrapper(filePath)
    local id = scriptdraw.register_sprite(filePath)
    originalMenu.notify("create_texture id: "..tostring(id))
    return id 
end

local function scripts_dir()
    return scriptsPath
end

local function resources_dir()
    return scriptsPath.."resources\\"
end

local function store_dir()
    return scriptsPath.."store\\"
end

function my_root(scriptName)
    originalMenu.notify(tostring("Standcompat my_root 1: "..scriptName))
    
    local scriptParent = scriptParents[scriptName]
    if scriptParent then
        originalMenu.notify(tostring("Standcompat my_root 1 name: "..scriptParent.name))
        return scriptParent.id
    else
        return scriptFeats.id
    end
end

function player_root(scriptName)
    local scriptPlayerParent = scriptPlayerParents[scriptName]
    if scriptPlayerParent then
        return scriptPlayerParent.id
    else
        return scriptPlayerFeats.id
    end
end

local function RGBAToInt(Red, Green, Blue, Alpha)
    Alpha = Alpha or 255
    return ((Red & 0x0ff) << 0x00) | ((Green & 0x0ff) << 0x08) | ((Blue & 0x0ff) << 0x10) | ((Alpha & 0x0ff) << 0x18)
end

local function createColorPickerFeature(name, command, description, defaultColor, root)
    local rgba = {}
    originalMenu.add_feature(name, "action", root, function()
        local status, ABGR, r, g, b, a
        repeat
            status, ABGR, r, g, b, a = cheeseUtils.pick_color(red, green, blue, 255)
   
           if status == 2 then
               return
           end
   
           coroutine.yield(0)
       until status == 0

        r = r / 255.0
        g = g / 255.0
        b = b / 255.0
        a = a / 255.0
        
        rgba = {r, g, b, a}
    end)  

    return rgba
end

local function utilsGlobals()
    _G["util"] = {}
    _G["util"].yield = function(...)
        coroutine.yield()
    end
    _G["util"].keep_running = function(...)
    end
    _G["util"].require_natives = function(...)
        originalRequire("lib\\standScriptLoader\\natives2845")
    end
    _G["util"].toast = function(str, bitflags)
        originalMenu.notify(tostring(str), "Stand Loader")
    end
    _G["util"].log = function(str)
       print(tostring(str), "Stand Loader")
    end
    _G["util"].create_tick_handler = function(func)
       --do nothing for now, will 100% forget
    end
end

local function menuGlobals()
    _G["menu"] = {}
    _G["menu"].is_trusted_mode_enabled = function(flag)
        if not flag then
            return trusted_mode & 31 == 31
        else
            return trusted_mode & flag == flag
        end
    end

    --todo: add description as a hint
    _G["menu"].toggle = function(root, name, command, description, callback)        
        local feature
        if type(root) == "userdata" then
            feature = originalMenu.add_feature(name, "autoaction_value_i", root.id, function(feat)
                local toggle = feat.on
                callback(toggle)
            end)
        else
            feature = originalMenu.add_feature(name, "autoaction_value_i", root, function(feat)
                local toggle = feat.on
                callback(toggle)
            end)        
        end
    
        if feature and description and type(description) == "string" then
            feature.hint = description
        end

        return feature
    end    
 
    _G["menu"].colour = function(name, command, description, defaultColor, root) --doesnt pass the colour back -.-
        return createColorPickerFeature(command, command, name, defaultColor, name)
    end 
      
    --value isnt passed back to stand :(
    _G["menu"].slider = function(root, name, command, description, min, max, defaultValue, step, callback)   
        local feature
        if type(root) == "userdata" then
            feature = originalMenu.add_feature(name, "autoaction_value_i", root.id, function()
                callback(f.value)
            end)
        else
            feature = originalMenu.add_feature(name, "autoaction_value_i", root, function()
                callback(f.value)
            end)        
        end
    
        if feature and description and type(description) == "string" then
            feature.hint = description
        end
    
        if feature then
            feature.min = min
            feature.max = max
            feature.value = defaultValue
            feature.mod = step
        end
    
        return feature
    end

    _G["menu"].action = function(root, name, command, description, callback)
        local feature
        if type(root) == "userdata" then
            feature = originalMenu.add_feature(name, "action", root.id, callback)
        else
            feature = originalMenu.add_feature(name, "action", root, callback)
        end
    
        if feature and description and type(description) == "string" then
            feature.hint = description
        end
    
        return feature
    end
    
    _G["menu"].readonly = function(root, name, value)  
        return {} --todo make work 
    end   

    _G["menu"].divider = function(root, name)
        local totalLength = 100  
        local nameLength = #name
        local spaces = math.max(0, (totalLength - nameLength) // 2) 
        local dividerName = string.rep(" ", spaces) .. name .. string.rep(" ", spaces) 
        if type(root) == "userdata" then
            return originalMenu.add_feature(dividerName, "action", root.id) 
        else
            return originalMenu.add_feature(dividerName, "action", root)
        end
    end    
   
    _G["menu"].toggle_loop = function(root, name, command, description, ontick, callback)
        if type(root) == "userdata" then
            return originalMenu.add_feature(name, "toggle", root.id, callback)
        else
            return originalMenu.add_feature(name, "toggle", root, callback)
        end
    end

    _G["menu"].list = function(root, name, command, description, callback)
        if type(root) == "userdata" then
            return originalMenu.add_feature(name, "parent", root.id, callback)
        else
            return originalMenu.add_feature(name, "parent", root, callback)
        end    
    end

    _G["menu"].my_root = function() 
        return my_root(scriptName) 
    end

    _G["menu"].player_root = function()
        return player_root(scriptName) 
    end

    _G["menu"].ref_by_path = function(path, version) 
    end

    _G["menu"].trigger_commands = function(str)
    end
    _G["menu"].trigger_command = function(str)
    end

    _G["menu"].hyperlink = function(id, name, link, help)
        return 0
    end
end

local function playersGlobals()
    _G["players"] = _G["players"] or {}

    _G["players"].list = function(includeUser, includeFriends, includeStrangers)
        local playersList = {}

        for i = 0, 31 do
            if originalPlayer.is_player_valid(i) then
                local isUser = (i == originalPlayer.player_id())
                local isFriend = originalPlayer.is_player_friend(i)

                if (includeUser and isUser) or 
                   (includeFriends and isFriend) or 
                   (includeStrangers and not isUser and not isFriend) then
                    playersList[#playersList+1] = i
                end
            end
        end
        return playersList
    end

    _G["players"].on_join = function(callback)
       --originalEvent.add_event_listener("player_join", function(e) --this is wrong
       --    id = e
       --end)
    end
    _G["players"].user = function()
        return originalPlayer.player_id()
    end
    _G["players"].dispatch_on_join = function()
        --related to on_join, seems to be a event listener calling on_join
    end
    _G["players"].get_rockstar_id = function(id)
        return originalPlayer.get_player_scid(id)
    end

end
    
local function directxGlobals()
    _G["directx"] = _G["directx"] or {}
    _G["directx"].create_texture = create_texture_wrapper
    
    --todo: fix rotation and scaling issues
    _G["directx"].draw_texture = function(texture_id, sizeX, sizeY, centerX, centerY, posX, posY, rotation, color)
        --local colorInt = (color["r"] * 255) << 24 | (color["g"] * 255) << 16 | (color["b"] * 255) << 8 | (color["a"] * 255)
        local colorInt = RGBAToInt(color["r"]*255, color["g"]*255, color["b"]*255)
    
        local position = v2(posX * 2 - 1, posY * -2 + 1)
    
        local scale = sizeX
        --local scale = 1 --test
        --print("scale: "..sizeX)
        
        if texture_id == nil then
            return 
        end

        --void draw_sprite(int id, v2 pos, float scale, float rot, uint32_t color, float|nil phase)⚓︎
        scriptdraw.draw_sprite(texture_id, position, scale, rotation, colorInt)
    end

    _G["directx"].draw_text = function(x, y, text, allign, scale, colour, unk) --void draw_text(string text, v2 pos, v2 size, float scale, uint32_t color, uint32_t flags, int|nil font)⚓︎   
        scriptdraw.draw_text(text, v2(x, y), v2(scale, scale), scale, RGBAToInt(colour["r"]*255, colour["g"]*255, colour["b"]*255), eDrawTextFlags.TEXTFLAG_VCENTER)
    end
end

local function filesystemGlobals()
    _G["filesystem"] = _G["filesystem"] or {}
    _G["filesystem"].scripts_dir = scripts_dir
    _G["filesystem"].resources_dir = resources_dir
    _G["filesystem"].store_dir = store_dir
    _G["filesystem"].mkdirs = function(dir)
        utils.make_dir(dir)
    end
end

function standCompat()
    _G.require = function(moduleName)
        if string.find(moduleName, "natives") then
            return originalRequire("lib\\5modsLuaLoader\\natives2845")
        else
            return originalRequire(moduleName)
        end
    end

    utilsGlobals()
    menuGlobals()
    playersGlobals()
    directxGlobals()
    filesystemGlobals() 
end

function standRestoreOriginalMenu()
    _G["menu"] = originalMenu
    _G["player"] = originalPlayer
    _G["require"] = originalRequire
end
