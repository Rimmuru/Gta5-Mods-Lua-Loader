local getAppdataPath <const> = utils.get_appdata_path("PopstarDevs", "").."\\2Take1Menu"
local scriptsPath <const> = getAppdataPath.."\\scripts\\lib\\5modsLua\\"

function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function create_texture_wrapper(filePath)
    local id = scriptdraw.register_sprite(filePath)
    --originalMenu.notify("create_texture id: "..tostring(id))
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
    --originalMenu.notify(tostring("Standcompat my_root 1: "..scriptName))
    
    local scriptParent = scriptParents[scriptName]
    if scriptParent then
        --originalMenu.notify(tostring("Standcompat my_root 1 name: "..scriptParent.name))
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

local function utilsGlobals()
    _G["util"] = {}
    _G["util"].yield = function(...)
        return coroutine.yield()
    end
    _G["util"].keep_running = function(...)
    end
    _G["util"].require_natives = function(...)
        return originalRequire("lib\\standScriptLoader\\natives2845")
    end
    _G["util"].toast = function(str, bitflags)
        return originalMenu.notify(tostring(str), "Stand Loader")
    end
    _G["util"].log = function(str)
       return print(tostring(str), "Stand Loader")
    end
    _G["util"].create_tick_handler = function(func)
       --do nothing for now, will 100% forget
    end
end

local function menuGlobals()
    _G["menu"] = {}

    --todo: add description as a hint
    _G["menu"].toggle = function(root, name, command, description, callback)        
        local id = type(root) == "userdata" and root.id or root

        local feature = originalMenu.add_feature(name, "toggle", id, function(feat)
            callback(feat.on)
        end)
    
        if feature and description and type(description) == "string" then
            feature.hint = description
        end

        return feature
    end    
 
    _G["menu"].colour = function(name, command, description, defaultColor, root) --doesnt pass the colour back -.-
    end 
      
    --value isnt passed back to stand :(
    _G["menu"].slider = function(root, name, command, description, min, max, defaultValue, step, callback)   
        local id = type(root) == "userdata" and root.id or root

        local feature = originalMenu.add_feature(name, "autoaction_value_i", id, function(f)
            callback(f.value)
        end)
    
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
        local id = type(root) == "userdata" and root.id or root

        local feature = originalMenu.add_feature(name, "action", id, callback)

        if feature and description and type(description) == "string" then
            feature.hint = description
        end
    
        return feature
    end
    
    _G["menu"].readonly = function(root, name, value)  
        return {
            parent = parent,
            name = menu_name,
            value = value or "",
        }
    end  
 
    _G["menu"].divider = function(root, name)
        local totalLength = 100  
        local nameLength = #name
        local spaces = math.max(0, (totalLength - nameLength) // 2) 
        local dividerName = string.rep(" ", spaces) .. name .. string.rep(" ", spaces) 
        local id = type(root) == "userdata" and root.id or root

        return originalMenu.add_feature(dividerName, "action", id) 
    end    
   
    _G["menu"].toggle_loop = function(parent, menu_name, command_names, help_text, on_tick, on_stop)
        local id = type(parent) == "userdata" and parent.id or parent
        return originalMenu.add_feature(menu_name.."", "toggle", id, function(f)
            while f.on do
                if on_tick and type(on_tick) == "function" then
                    on_tick()
                end
                coroutine.yield()
            end
            if on_stop and type(on_stop) == "function" then
                on_stop()
            end
        end)
    end   

    _G["menu"].list = function(root, name, command, description, callback)
        local id = type(root) == "userdata" and root.id or root
        return originalMenu.add_feature(name, "parent", id, callback) 
    end

    _G["menu"].my_root = function() 
        return my_root(scriptName) 
    end

    _G["menu"].player_root = function()
        return player_root(scriptName) 
    end

    _G["menu"].ref_by_path = function(path, version)
        version = version or nil
        print("ref_by_path called with path: " .. tostring(path) .. ", version: " .. tostring(version))
    end
    

    _G["menu"].trigger_commands = function(str)
    end
    _G["menu"].trigger_command = function(str)
    end
    _G["menu"].show_command_box_click_based = function(var, str)
        --input box of sorts i think, pass value back as param1
    end

    _G["menu"].hyperlink = function(id, name, link, help)

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

    _G["players"].user_ped = function()
        return PLAYER.PLAYER_PED_ID()
    end
end
    
local function directxGlobals()
    _G["directx"] = _G["directx"] or {}
    _G["directx"].create_texture = create_texture_wrapper
    
    _G["directx"].draw_texture = function(texture_id, sizeX, sizeY, centerX, centerY, posX, posY, rotation, color)
        local colorInt = RGBAToInt(color["r"] * 255, color["g"] * 255, color["b"] * 255)
    
        local position = v2(posX * 2 - 1, posY * -2 + 1)
    
        local scale = sizeX
    
        local radians = rotation * 2 * math.pi
    
        if texture_id == nil then
            return 
        end
    
        scriptdraw.draw_sprite(texture_id, position, scale, radians, colorInt)
    end   
    
    _G["directx"].draw_text = function(x, y, text, allign, scale, colour, unk)
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
    _G["event"] = originalEvent
end
