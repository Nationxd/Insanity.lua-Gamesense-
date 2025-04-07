-- v1.1
--[[


    INSANITY.LUA OUT NOW, ENJOY :D
    Разработчик: mq.class
    Дата: April 7, 2025
    Insanity Community - https://discord.gg/hrcuuY4Y2T
    


Сhangelog -> Inasnity.lua

[+] Добавлено:

+ AA Builder (по факту новый, а главное рабочий!)
+ Упрощение АА билдера теперь настраивать его стало проще, а сам билдер стал эффективным (кста из за этого луашка весит гораздо меньше предыдущего апдейта)
+ OnStaticKill - новый прикол для трештолка! (логика + фразы)
+ Новые фразы в деф трештолке
+ Значительные улучшения Всех видов резольверов!
+ Улучшил пресет AA -  random (теперь он играбелен!)
+ Упростил Default пресет (теперь он статический)
+ оптимизация многих методов (для чайников - просто оптимизация луа)
+ обновил ссылку на ДС
и многое другое

[-] Убрано:
- OLD AA Builder
- OLD Freestanding


[?] Переделано:
? AA Builder (перелопатил его, убрал ненужный хлам и теперь он работает хорошо и стабильно!)
? Freestanding (теперь норм работает)
? Trashtalk (теперь с норм функциями)
? CFG System (теперь 101% сохранит ваш конфиг без потерь в AA/Резольвер билдере)
и многое другое


Supports:

♥ @lolkekmlg - 5☆
♥ https://t.me/banzoteam - поддержка и пиар луашки. Спасибо, что помогаете на старте <3

---------------------------------------------- 
THANK U SO MUCH FOR SUPPORTING Insanity.lua <3
---------------------------------------------- 

P.S Жду ваших тикетов с предложениями для апдейта в дс <3

]]





local user = "Insanity User <3" -- не придумал че с этим делать

local menu = {
    ["home"] = {},
    ["anti-aim"] = {},
    ["resolver"] = {},
    ["visuals"] = {},
    ["misc"] = {}    
}

local ffi = require("ffi")
local CS_UM_SendPlayerItemFound = 63
local DispatchUserMessage_t = ffi.typeof([[
    bool(__thiscall*)(void*, int msg_type, int nFlags, int size, const void* msg)
]])
local VClient018 = client.create_interface("client.dll", "VClient018")
local pointer = ffi.cast("uintptr_t**", VClient018)
local vtable = ffi.cast("uintptr_t*", pointer[0])
local size = 0
local last_message_time = 0
local is_sending = false

while vtable[size] ~= 0x0 do
    size = size + 1
end

local hooked_vtable = ffi.new("uintptr_t[?]", size)
for i = 0, size - 1 do
    hooked_vtable[i] = vtable[i]
end

pointer[0] = hooked_vtable
local oDispatch = ffi.cast(DispatchUserMessage_t, vtable[38])

local function hkDispatch(thisptr, msg_type, nFlags, size, msg)
    if msg_type == CS_UM_SendPlayerItemFound then return false end
    return oDispatch(thisptr, msg_type, nFlags, size, msg)
end

hooked_vtable[38] = ffi.cast("uintptr_t", ffi.cast(DispatchUserMessage_t, hkDispatch))


local clipboard = {
    export = function(text)
        local ffi = require("ffi")
        ffi.cdef([[ typedef void(__thiscall* set_clipboard_text)(void*, const char*, int); ]])
        local pointer = ffi.cast("void***", client.create_interface("vgui2.dll", "VGUI_System010"))
        local func = ffi.cast("set_clipboard_text", pointer[0][9])
        func(pointer, text, #text)
    end,
    import = function()
        local ffi = require("ffi")
        ffi.cdef([[
            typedef int(__thiscall* get_clipboard_text_count)(void*);
            typedef void(__thiscall* get_clipboard_text)(void*, int, char*, int);
        ]])
        local pointer = ffi.cast("void***", client.create_interface("vgui2.dll", "VGUI_System010"))
        local count_func = ffi.cast("get_clipboard_text_count", pointer[0][7])
        local sizelen = count_func(pointer)
        if sizelen > 0 then
            local buffer = ffi.new("char[?]", sizelen)
            local text_func = ffi.cast("get_clipboard_text", pointer[0][11])
            text_func(pointer, 0, buffer, sizelen)
            return ffi.string(buffer, sizelen-1)
        end
        return ""
    end
}

-- очень крутые методы😎

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function normalize_angle(angle)
    while angle > 180 do angle = angle - 360 end
    while angle < -180 do angle = angle + 360 end
    return angle
end


local function can_penetrate_wall(local_player, enemy, yaw)
    if not local_player or not entity.is_alive(local_player) or not enemy or not entity.is_alive(enemy) then return false end

    local eye_pos = { client.eye_position() }
    if not eye_pos[1] then return false end

  
    local head_pos = { entity.hitbox_position(enemy, 0) } 
    if not head_pos[1] then return false end

    
    local fraction, hit_entity = client.trace_bullet(local_player, eye_pos[1], eye_pos[2], eye_pos[3], head_pos[1], head_pos[2], head_pos[3])
    if fraction == nil then fraction = 0 end

    
    return fraction > 0.9 or (hit_entity and hit_entity == enemy)
end

local function is_near_wall(distance)
    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return false end
    local eye_x, eye_y, eye_z = client.eye_position()
    if not eye_x then return false end
    local directions = {
        { 1, 0 },  
        {-1, 0 }, 
        { 0, 1 },  
        { 0, -1 }  
    }
    local pitch, yaw = client.camera_angles()
    if not yaw then return false end
    for _, dir in ipairs(directions) do
        local rad = math.rad(yaw)
        local dx = dir[1] * math.cos(rad) - dir[2] * math.sin(rad)
        local dy = dir[1] * math.sin(rad) + dir[2] * math.cos(rad)
        local end_x = eye_x + dx * distance
        local end_y = eye_y + dy * distance
        local end_z = eye_z
        local fraction = client.trace_line(lp, eye_x, eye_y, eye_z, end_x, end_y, end_z)
        if fraction < 1.0 then
            return true
        end
    end
    return false
end

local b64 = {
    encode = function(data)
        local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        return ((data:gsub('.', function(x) 
            local r,b='',x:byte()
            for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
            return r;
        end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if (#x < 6) then return '' end
            local c=0
            for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
            return b:sub(c+1,c+1)
        end)..({ '', '==', '=' })[#data%3+1])
    end,
    decode = function(data)
        local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        data = string.gsub(data, '[^'..b..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r,f='',(b:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c=0
            for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
        end))
    end
}

-- %killer% - нейм убийцы(твой нейм)
-- %victim% - нейм жертвы

local trashtalk_phrases = {
    OnKill = {
        single = { 
            "Ебать ты биомусор. Я на тя даже пресеты не грузил, хватило дефолта)",
            "Опять чудище ебаное со своим отцом мне хуй сосут бля)",
            "Соси хуй падаль. Ты даже не понял, как я тебя выебал.",
            "Я твоей мамке на ротан дал, пока ты пытался понять, откуда тебя убили, пробирочный нахуй)",
            "Best free open ss lua - Insanity(а ну и я тя выебал все)",
            "Как стать крутым? Вбить в поиск в тг: @Insanitylua",
            "Отпиши, когда в кд выходить будешь, бездарь ебаный"

        },
        double = { 
            {"Ты так старался, аж жалко стало... на секунду", "Потом я вспомнил, что ты дно ебаное"},
            {"опять умер", "блять какой же ты бездарь ебаный)"},
            {"бля мы не в доте", "но я бы кинул те реп за фид)"},
            {"Бро,тебе надо тренироваться","может через год сможешь хотя бы респавн свой защитить, бич нищий"},
            {"скачать фри луа = ✗","Сидеть с пастой = ✔"},
            {"После апдейта, Insanity стала весить меньше,а твой отец-подписва видимо нет."}

        },
        triple = { 
            {"1", "упал", "<3"},
            {"оправдывай свою сметана луа", "собачка", "без Insanity"},
            {"эахъахъпхъхпъ", "сколько можно", "ливни с кона если не умеешь играть"},
            {"про почти попал", "в мой", "PPHUD PREMUIM"},
            {"Сьебался", "таракан", "усатый"},
            {"На мыло", "и веревку", "бабки дать?"},
            {"ау лоу кд чурка", "а ты знал?", "Insanity бесплатный"},
            {"кто запустил", "этого хуесоса", "на кон?"}
        }
    },
    OnDeath = {
        single = { 
            "сука какой же ты сынок пизды",
            "iq?",
            "напиши матухе, спроси где ща шляется"
        },
        double = { 
            {"скажи", "ряльна"},
            {"анлак", "хай пинг че"},
            {"блять", "анлак"},
            {"ты купил деду новые органы?", "я у твоего их отрезал нахуй"}
        },
        triple = { 
            {"1х1 2х2 3х3 5х5", "2000$", "прям ща"},
            {"опять", "читеры на паблике", "F1"},
            {"я не мисаю", "я дал тебе шанс выйти в кд", "скажи спасибо"},
            {"фу бич", "мой скаут даже не начинал стрелять", "ты не достоин быть энеми, максимум виктимом."}
        }
    }
}

-- вкратце, если ты с пресетом Default(в аа - Default aka Static), то выпишет кастом месаг!!! Еее крута нешан блеснул умом✨

local killInStatic = {
    single = { 
        "мисснул в статик... что ты наделал...",
        "ЪПЪХПЪХПЪХПЪХПАЪХПАЪХПАХЪ КАК ТЫ В СТАТИК МИССНУЛ",
        "Тут могла быть ваша реклама, а пока - тут можно захуесосить бомжа на %victim%"
    },
    double = { 
        {"имейджин", "мисснуть в статик в 2к25)"},
        {"ЭПХЪХПЪПХАЪХЪАПЪХПАХЪПА", "ЧТО ЭТО БЫЛО БРАТАН"},
        {"годы идут", "а у типов не ресольвит статик))))"},
        {"мама говорила, в статик не миссают, а те, кто миссают - отбросы общества", "%victim% доказал, что отбросы существуют"}
    },
    triple = { 
        {"ХАХЪАХАЪАХЪВАХЪВХАЪВ БРАТАН", "НУ КАК МОЖНО БЫЛО", "МИССНУТЬ В СТАТИК"},
        {"ВНИМАНИЕ", "ОБНАРУЖЕН ХУЕCOC НА ПАБЛИКЕ МИССАЮЩИЙ В СТАТИКИ", "И ИМЯ ЕМУ - %victim%"},
        {"ты знаешь, почему ", "%killer% не лузает?", "Insanity не мисает в статики в отличии от тебя, ебаный хуеcoc на %victim%"}
    }
}

local trashtalk_queue = {}
local last_message_time = 0 
local is_sending = false 

local function send_trashtalk(phrases, victim_name, killer_name)
    local variant = math.random(1, 3) 
    local messages = {}

    if variant == 1 then
        local single = phrases.single[math.random(#phrases.single)]
        messages = {single} 
    elseif variant == 2 then
        messages = phrases.double[math.random(#phrases.double)] 
    else
        messages = phrases.triple[math.random(#phrases.triple)] 
    end

    for i, message in ipairs(messages) do
        if type(message) == "string" then
            message = message:gsub("%%victim%%", victim_name or "нн ебаный")
            messages[i] = message:gsub("%%killer%%", killer_name or "mq.class")
        end
    end

    for _, message in ipairs(messages) do
        table.insert(trashtalk_queue, message)
    end

    local function send_next_message()
        if #trashtalk_queue == 0 then
            is_sending = false 
            return
        end

        local current_time = globals.realtime()
        if current_time < last_message_time + 1.0 then
            client.delay_call(last_message_time + 1.0 - current_time, send_next_message)
            return
        end

        local message = table.remove(trashtalk_queue, 1)
        client.exec("say " .. message)
        last_message_time = globals.realtime()
        is_sending = true

        client.delay_call(1.0, send_next_message)
    end

    if not is_sending then
        send_next_message()
    end
end


local player_cache = {}

local function update_player_cache(player)
    if not entity.is_alive(player) then return end
    local velocity_x, velocity_y = entity.get_prop(player, "m_vecVelocity") or 0, entity.get_prop(player, "m_vecVelocity") or 0
    local velocity = math.sqrt((velocity_x or 0)^2 + (velocity_y or 0)^2)
    local animstate = entity.get_prop(player, "m_flPoseParameter", 11) or 0
    local simtime = entity.get_prop(player, "m_flSimulationTime") or 0
    local old_simtime = entity.get_prop(player, "m_flOldSimulationTime") or simtime
    local choked_ticks = math.max(0, math.floor((simtime - old_simtime) / globals.tickinterval() + 0.5))
    local eye_angles = {entity.get_prop(player, "m_angEyeAngles") or 0, entity.get_prop(player, "m_angEyeAngles", 1) or 0}
    local lby = entity.get_prop(player, "m_flLowerBodyYawTarget") or 0
    local on_ground = bit.band(entity.get_prop(player, "m_fFlags") or 0, 1) == 1

    
    player_cache[player] = player_cache[player] or {}
    local cache = player_cache[player]

    
    cache.velocity = velocity
    cache.animstate = animstate
    cache.simtime = simtime
    cache.choked_ticks = choked_ticks
    cache.eye_yaw = eye_angles[2] or 0
    cache.lby = lby
    cache.on_ground = on_ground
    cache.last_yaw = cache.last_yaw or 0
    cache.misses = cache.misses or 0
    cache.aa_history = cache.aa_history or {}

    
    table.insert(cache.aa_history, {yaw = cache.eye_yaw, time = simtime, lby = lby})
    if #cache.aa_history > 20 then
        table.remove(cache.aa_history, 1)
    end
end

local tbl = {
    items = {
        enabled = { ui.reference("aa", "anti-aimbot angles", "enabled") },
        dt = { ui.reference("rage", "aimbot", "double tap") },
        pitch = { ui.reference("aa", "anti-aimbot angles", "pitch") },
        base = { ui.reference("aa", "anti-aimbot angles", "yaw base") },
        jitter = { ui.reference("aa", "anti-aimbot angles", "yaw jitter") },
        yaw = { ui.reference("aa", "anti-aimbot angles", "yaw") },
        body = { ui.reference("aa", "anti-aimbot angles", "body yaw") },
        fsbody = { ui.reference("aa", "anti-aimbot angles", "freestanding body yaw") },
        edge = { ui.reference("aa", "anti-aimbot angles", "edge yaw") },
        roll = { ui.reference("aa", "anti-aimbot angles", "roll") },
        fs = { ui.reference("aa", "anti-aimbot angles", "freestanding") },
        hideshot = { ui.reference("aa", "other", "on shot anti-aim") },
        legs = { ui.reference("aa", "other", "leg movement") },      
        limitfl = { ui.reference("aa", "fake lag", "limit") },
        fl_enabled = { ui.reference("aa", "fake lag", "enabled") },
        fl_amount = { ui.reference("aa", "fake lag", "amount") },
        fl_variance = { ui.reference("aa", "fake lag", "variance") },
        slow_motion = { ui.reference("aa", "other", "slow motion") },
        fake_peek = { ui.reference("aa", "other", "fake peek") }
    }
}


local function is_in_air()
    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return false end
    local flags = entity.get_prop(lp, "m_fFlags") or 0
    return bit.band(flags, 1) == 0
end


local function can_see_enemy()
    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return false end

    local eye_pos = { entity.get_prop(lp, "m_vecOrigin") }
    eye_pos[3] = eye_pos[3] + (entity.get_prop(lp, "m_vecViewOffset[2]") or 64)
    local enemies = entity.get_players(true)

    for i, enemy in ipairs(enemies) do
        local enemy_pos = { entity.get_prop(enemy, "m_vecOrigin") }
        enemy_pos[3] = enemy_pos[3] + 64 
        local fraction = client.trace_line(lp, eye_pos[1], eye_pos[2], eye_pos[3], enemy_pos[1], enemy_pos[2], enemy_pos[3])
        if fraction > 0.98 then 
            return true
        end
    end
    return false
end

local function execute_autobuy() -- Довели, больше не буду пастить опен сурсный АБ с гитхаба🗿
    if not ui.get(menu["misc"].other.Autobuy) then return end 

    local weapon = ui.get(menu["misc"].other.AutobuyWeapon)
    local command = ""

    if weapon == "SSG 08" then
        command = "buy ssg08;"
    elseif weapon == "AWP" then
        command = "buy awp;"
    elseif weapon == "Auto-Sniper" then
        command = "buy scar20; buy g3sg1;" 
    end

    client.delay_call(0.1, function()
        client.exec(command)
    end)
end

client.set_event_callback("round_prestart", execute_autobuy)

--с любовью, для ньюкамеров)
local aa_configs = {
    ["default"] = {
        pitch = "Default",
        yaw_base = "Local view",
        yaw = 45,
        jitter = "Off",
        jitter_offset = 0,
        body_yaw = "Static"
    },
    ["better defensive"] = {
        pitch = "Minimal",
        yaw_base = "At targets",
        yaw = function() return normalize_angle(180 + math.sin(globals.realtime() * 8) * 45) end,
        jitter = "Random",
        jitter_offset = 60,
        body_yaw = "Jitter"
    },
    ["jitter"] = {
        pitch = "Down",
        yaw_base = "Local view",
        yaw = 180,
        jitter = "Random",
        jitter_offset = 90,
        body_yaw = "Opposite"
    },
    ["unpredictable"] = {
        pitch = "Down",
        yaw_base = "At targets",
        yaw = function() 
            local timer = globals.realtime() % 1.5
            if timer < 0.5 then last_yaw = last_yaw or math.random(-180, 180) end
            return normalize_angle(last_yaw or 0)
        end,
        jitter = "Random",
        jitter_offset = function() return math.random(30, 90) end,
        body_yaw = "Opposite"
    },
    ["random"] = {
        pitch = "Down",
        yaw_base = "Local view",
        yaw = 180,
        jitter = "Random",
        jitter_offset = 45,
        body_yaw = "Opposite"
    },
    ["aa builder"] = {
        pitch = function() return ui.get(menu["anti-aim"].builder.pitch.mode) end,
        yaw_base = function() return ui.get(menu["anti-aim"].builder.yaw.base) end,
        yaw = function() return ui.get(menu["anti-aim"].builder.yaw.static_value) end,
        jitter = function() return ui.get(menu["anti-aim"].builder.jitter.type) end,
        jitter_offset = function() return ui.get(menu["anti-aim"].builder.jitter.amplitude) end,
        body_yaw = function() return ui.get(menu["anti-aim"].builder.body_yaw.mode) end,
        roll = function() return ui.get(menu["anti-aim"].builder.roll.enabled) and ui.get(menu["anti-aim"].builder.roll.amount) or 0 end
    }
}

local clantag_steps_nakiev = {"$","n","n$","na","na$","nak","nak$","naki","naki$","nakie","nakie$","nakiev","nakiev.$","nakiev.l","nakiev.l$","nakiev.lu","nakiev.lu$","nakiev.lua","nakiev.lua","nakiev.lu$","nakiev.lu","nakiev.l$","nakiev.l","nakiev.$","nakiev","nakie$","nakie","naki$","naki","nak$","nak","na$","na","n$","n","$"}

local clantag_steps_insanity = {"1","I","I#","In","In01010101","Ins","Ins@","Insan","Insan1","Insani","Insani!","Insanity","Insanity.","Insanity.l","Insanity.l<3","Insanity.lua","Insanity.lua","Insanity.lua","Insanity.l<3","Insanity.l","Insanity.","Insanity","Insani!","Insani","Insan1","Insan","Ins@","In","I#","I","1","1"}

local last_clantag_index = 0
local last_clantag_time = 0

local function update_clantag()
    if not ui.get(menu["misc"].other.ClanTags) then 
        client.set_clan_tag("")
        return 
    end

    local current_time = globals.realtime()
    if current_time < last_clantag_time + 0.3 then return end

    local selected_animation = ui.get(menu["misc"].other.ClanTagAnimation)
    local steps = selected_animation == "Insanity" and clantag_steps_insanity or clantag_steps_nakiev
    last_clantag_index = (last_clantag_index % #steps) + 1
    client.set_clan_tag(steps[last_clantag_index])
    last_clantag_time = current_time
end

local last_yaw = nil


--когда это писал - ощущал себя богом
local function get_player_state()
    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return nil end

    local flags = entity.get_prop(lp, "m_fFlags") or 0
    local velocity_x, velocity_y = entity.get_prop(lp, "m_vecVelocity")
    local velocity = math.sqrt(velocity_x^2 + velocity_y^2)
    local ducked = entity.get_prop(lp, "m_bDucked") == 1
    local on_ground = bit.band(flags, 1) == 1

    if on_ground then
        if ducked then
            if velocity > 5 then
                return "Crouch Moving"
            else
                return "Crouch"
            end
        elseif velocity < 5 then
            return "Standing"
        else
            return "Walking"
        end
    else
        if ducked then
            return "Air Crouch"
        else
            return "Air"
        end
    end
end


local choked_commands = 0


client.set_event_callback("setup_command", function(cmd)
    if cmd.chokedcommands ~= nil then
        choked_commands = cmd.chokedcommands
    end
end)

local function apply_anti_aim(cmd)
    if not menu["anti-aim"].mode then return end
    local preset = ui.get(menu["anti-aim"].mode)
    
    if preset ~= "aa builder" then
        local config = aa_configs[preset]
        if not config then return end
        ui.set(tbl.items.pitch[1], type(config.pitch) == "function" and config.pitch() or config.pitch or "Default")
        ui.set(tbl.items.base[1], config.yaw_base or "Local view")
        ui.set(tbl.items.yaw[1], "180")
        ui.set(tbl.items.yaw[2], type(config.yaw) == "function" and config.yaw() or config.yaw or 180)
        ui.set(tbl.items.jitter[1], type(config.jitter) == "function" and config.jitter() or config.jitter or "Off")
        ui.set(tbl.items.jitter[2], type(config.jitter_offset) == "function" and config.jitter_offset() or config.jitter_offset or 0)
        ui.set(tbl.items.body[1], type(config.body_yaw) == "function" and config.body_yaw() or config.body_yaw or "Static")
        return
    end

    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return end

    local state = get_player_state()
    if not state then return end
    local state_config = menu["anti-aim"].builder.states[state]
    if not state_config then
        client.log("Error: state_config for " .. tostring(state) .. " is nil!")
        return
    end

    local tick = globals.tickcount()
    local velocity_x, velocity_y = entity.get_prop(lp, "m_vecVelocity")
    local velocity = math.sqrt(velocity_x^2 + velocity_y^2)
    local in_air = bit.band(entity.get_prop(lp, "m_fFlags") or 0, 1) ~= 1
    local dt_enabled = tbl.items.dt[1] and ui.get(tbl.items.dt[1])
    local dt_timer = tbl.items.dt[2] and ui.get(tbl.items.dt[2]) or 0
    local dt_active = dt_enabled and type(dt_timer) == "number" and dt_timer > globals.tickcount()
    local can_see = can_see_enemy()
    local choked = choked_commands  

    if ui.get(state_config.pitch.enabled) then
        local pitch_mode = ui.get(state_config.pitch.mode) or "Default"
        local pitch_value = 0
        local use_custom = false
        if pitch_mode == "Custom" then
            pitch_value = ui.get(state_config.pitch.custom_value) or 0
            use_custom = true
        elseif pitch_mode == "Dynamic" then
            pitch_value = in_air and -30 or (velocity > 50 and -89 or 0)
        elseif pitch_mode == "Down" then
            pitch_value = -89
        elseif pitch_mode == "Up" then
            pitch_value = 89
        elseif pitch_mode == "Minimal" then
            pitch_value = -30
        elseif pitch_mode == "Default" then
            pitch_value = 0
        end
        if ui.get(state_config.pitch.randomize) then
            pitch_value = pitch_value + (math.random() - 0.5) * (ui.get(state_config.pitch.random_range) or 10) * 2
            use_custom = true
        end
        if ui.get(state_config.pitch.velocity_influence) > 0 then
            pitch_value = pitch_value + (velocity / 260) * (ui.get(state_config.pitch.velocity_influence) or 0)
            use_custom = true
        end
        local valid_pitch_modes = {"Off", "Default", "Down", "Up", "Minimal", "Custom"}
        if not table.contains(valid_pitch_modes, pitch_mode) then
            pitch_mode = "Default"
        end
        ui.set(tbl.items.pitch[1], use_custom and "Custom" or pitch_mode)
        if use_custom then
            ui.set(tbl.items.pitch[2], clamp(pitch_value, -89, 89))
        end
    else
        ui.set(tbl.items.pitch[1], "Off")
    end

    if ui.get(state_config.yaw.enabled) then
        local yaw_base = ui.get(state_config.yaw.base) or "Local view"
        if ui.get(state_config.yaw.velocity_aware) and velocity > (ui.get(state_config.yaw.velocity_threshold) or 50) then
            yaw_base = "At targets"
        end
        ui.set(tbl.items.base[1], yaw_base)

        local yaw_mode = ui.get(state_config.yaw.mode) or "Static"
        local yaw_value = ui.get(state_config.yaw.static_value) or 0
        if yaw_mode == "Cycle" then
            local cycle_values = {180, 90, 0, -90, -180}
            yaw_value = cycle_values[(tick % #cycle_values) + 1]
        elseif yaw_mode == "Dynamic" then
            yaw_value = normalize_angle(math.sin(globals.realtime() * (ui.get(state_config.yaw.frequency) or 50) / 100) * (ui.get(state_config.yaw.amplitude) or 60))
        end
        ui.set(tbl.items.yaw[1], "180")
        ui.set(tbl.items.yaw[2], clamp(yaw_value, -180, 180))
    else
        ui.set(tbl.items.yaw[1], "Off")
        ui.set(tbl.items.yaw[2], 0)
    end

    if ui.get(state_config.jitter.enabled) then
        local jitter_type = ui.get(state_config.jitter.type) or "Off"
        local jitter_amplitude = ui.get(state_config.jitter.amplitude) or 30
        local jitter_value = 0
        if jitter_type == "Offset" then
            jitter_value = jitter_amplitude
        elseif jitter_type == "Center" then
            jitter_value = tick % 2 == 0 and jitter_amplitude or -jitter_amplitude
        elseif jitter_type == "Random" then
            jitter_value = (math.random() - 0.5) * jitter_amplitude * 2
        end
        if ui.get(state_config.jitter.sync_with_tick) then
            jitter_value = jitter_value * math.sin(tick * 0.1)
        end
        ui.set(tbl.items.jitter[1], jitter_type)
        ui.set(tbl.items.jitter[2], clamp(jitter_value, -90, 90))
    else
        ui.set(tbl.items.jitter[1], "Off")
        ui.set(tbl.items.jitter[2], 0)
    end

    if ui.get(state_config.body_yaw.enabled) then
        local body_yaw_mode = ui.get(state_config.body_yaw.mode) or "Off"
        local body_yaw_value = ui.get(state_config.body_yaw.static_value) or 0
        if body_yaw_mode == "Dynamic" then
            body_yaw_value = ui.get(state_config.body_yaw.enemy_aware) and (can_see and 0 or 45) or (velocity > 50 and 45 or -45)
            body_yaw_mode = "Static"
        elseif body_yaw_mode == "Opposite" then
            body_yaw_mode = "Opposite"
        end
        if ui.get(state_config.body_yaw.velocity_factor) > 0 and body_yaw_mode == "Static" then
            body_yaw_value = body_yaw_value + (velocity / 260) * 60 * (ui.get(state_config.body_yaw.velocity_factor) / 100)
        end
        if ui.get(state_config.body_yaw.invert) and body_yaw_mode == "Static" then
            body_yaw_value = -body_yaw_value
        end
        ui.set(tbl.items.body[1], body_yaw_mode)
        if body_yaw_mode == "Static" then
            ui.set(tbl.items.body[2], clamp(body_yaw_value, -180, 180))
        end
    else
        ui.set(tbl.items.body[1], "Off")
    end

    if ui.get(state_config.conditions.enabled) then
        local air_yaw_offset = ui.get(state_config.conditions.air_yaw_offset) or 0
        local velocity_yaw_shift = ui.get(state_config.conditions.velocity_yaw_shift) or 0
        if in_air and air_yaw_offset ~= 0 then
            ui.set(tbl.items.yaw[2], clamp(ui.get(tbl.items.yaw[2]) + air_yaw_offset, -180, 180))
        elseif velocity > 50 and velocity_yaw_shift ~= 0 then
            ui.set(tbl.items.yaw[2], clamp(ui.get(tbl.items.yaw[2]) + velocity_yaw_shift, -180, 180))
        end
        if ui.get(state_config.conditions.enemy_visible) and can_see then
            ui.set(tbl.items.yaw[2], clamp(ui.get(tbl.items.yaw[2]) + (ui.get(state_config.conditions.yaw_adjustment) or 0), -180, 180))
        end
        if ui.get(state_config.conditions.near_wall) then
            local wall_distance = ui.get(state_config.conditions.wall_distance) or 100
            if is_near_wall(wall_distance) then
                ui.set(tbl.items.yaw[2], clamp(ui.get(tbl.items.yaw[2]) + (ui.get(state_config.conditions.wall_yaw_offset) or 90), -180, 180))
            end
        end
    end

    if ui.get(state_config.defensive.enabled) then
        if ui.get(state_config.defensive.random_shift) then
            local random_shift = (math.random() - 0.5) * (ui.get(state_config.defensive.random_shift_max) or 30) * 2
            ui.set(tbl.items.yaw[2], clamp(ui.get(tbl.items.yaw[2]) + random_shift, -180, 180))
        end
        if ui.get(state_config.defensive.dt_defense) and dt_active then
            ui.set(tbl.items.jitter[2], clamp(ui.get(tbl.items.jitter[2]) + 30, -90, 90))
        end
    end

    if ui.get(state_config.flick.enabled) then
        local flick_condition = ui.get(state_config.flick.condition) or "Always"
        local flick_amplitude = ui.get(state_config.flick.amplitude) or 60
        local flick_interval = ui.get(state_config.flick.interval) or 5
        local flick_offset = ui.get(state_config.flick.random_offset) or 20
        if (flick_condition == "Always" or (flick_condition == "On Shot" and cmd.in_attack) or (flick_condition == "On Miss" and not can_see)) and (tick % flick_interval == 0) then
            local flick_value = flick_amplitude + (math.random() - 0.5) * flick_offset * 2
            ui.set(tbl.items.yaw[2], clamp(ui.get(tbl.items.yaw[2]) + flick_value, -180, 180))
        end
    end


    if ui.get(state_config.fake_lag.enabled) then
        local fake_lag_limit = ui.get(state_config.fake_lag.limit) or 10
        local fake_lag_mode = ui.get(state_config.fake_lag.mode) or "Static"
        local fake_lag_variance = ui.get(state_config.fake_lag.variance) or 0
        local fake_lag_adaptive_factor = ui.get(state_config.fake_lag.adaptive_factor) or 50
        
        if fake_lag_mode == "Static" then
            cmd.chokedcommands = fake_lag_limit
        elseif fake_lag_mode == "Adaptive" then
            cmd.chokedcommands = math.min(fake_lag_limit, math.floor(velocity * fake_lag_adaptive_factor / 100))
        elseif fake_lag_mode == "Random" then
            cmd.chokedcommands = math.random(1, fake_lag_limit)
        end
    end
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

client.set_event_callback("paint", function()
    local current_preset = ui.get(menu["anti-aim"].mode)
    if current_preset ~= last_preset then
        if last_preset == "aa builder" and current_preset ~= "aa builder" then
            ui.set(tbl.items.roll[1], 0)
            ui.set(tbl.items.edge[1], false)
        end
        last_preset = current_preset
    end
    update_clantag()  
end)

local function has_zeus(player)
    local weapon = entity.get_player_weapon(player)
    if weapon then
        local weapon_class = entity.get_classname(weapon)
        return weapon_class == "CWeaponTaser"
    end
    return false
end

local function extrapolate_position(player, ticks)
    local x, y, z = entity.get_origin(player)
    local vx, vy, vz = entity.get_prop(player, "m_vecVelocity")
    local tick_interval = globals.tickinterval()
    return 
        x + (vx or 0) * tick_interval * ticks,
        y + (vy or 0) * tick_interval * ticks,
        z + (vz or 0) * tick_interval * ticks
end


local function apply_zeus_fix(player)
    if not ui.get(menu["misc"].other.Zeus_Fix) then return end
    if not has_zeus(player) then return end

    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    local extrapolated_x, extrapolated_y, extrapolated_z = extrapolate_position(player, 6) 
    local eye_x, eye_y, eye_z = client.eye_position()
    local delta_x, delta_y = extrapolated_x - eye_x, extrapolated_y - eye_y
    local predicted_yaw = math.deg(math.atan2(delta_y, delta_x)) - 90
    predicted_yaw = normalize_angle(predicted_yaw)
    if can_penetrate_wall(local_player, player, predicted_yaw) then
        plist.set(player, "Force body yaw", true)
        plist.set(player, "Force body yaw value", clamp(predicted_yaw, -60, 60))
        plist.set(player, "Override hitbox", true)
        plist.set(player, "Override hitbox value", 0) 
        client.delay_call(0.015, function()
            plist.set(player, "Override hitbox", false)
        end)
    else
        plist.set(player, "Force body yaw", false)
    end
end

local function is_on_ladder()
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return false end
    local move_type = entity.get_prop(local_player, "m_MoveType")
    return move_type == 9 
end


local function fast_ladder(cmd)
    
    if not ui.get(menu["misc"].other.FastLadder) then return end

    
    if not is_on_ladder() then return end

    
    local pitch, yaw = client.camera_angles()
    if not pitch or not yaw then return end

    
    cmd.pitch = -35 
    cmd.yaw = yaw   

    
    cmd.forwardmove = 500 
    cmd.sidemove = 0      

    
    cmd.buttons = bit.band(cmd.buttons, bit.bnot(1)) 
    cmd.buttons = bit.band(cmd.buttons, bit.bnot(2)) 

    
    if cmd.chokedcommands < 2 then
        cmd.chokedcommands = 1 
    end
end


client.set_event_callback("setup_command", fast_ladder)

local player_cache = {}

client.set_event_callback("player_death", function(e)
    local local_player = entity.get_local_player()
    if not local_player then return end

    if not ui.get(menu["misc"].other.trashtalk) then return end

    local attacker = client.userid_to_entindex(e.attacker)
    local victim = client.userid_to_entindex(e.userid)
    local killer_name = entity.get_player_name(local_player) 

    if attacker == local_player and entity.is_enemy(victim) then
        local victim_name = entity.get_player_name(victim)
        local current_preset = ui.get(menu["anti-aim"].mode)
        if current_preset == "default" then
            send_trashtalk(killInStatic, victim_name, killer_name)
        else
            send_trashtalk(trashtalk_phrases.OnKill, victim_name, killer_name)
        end
    elseif victim == local_player and entity.is_enemy(attacker) then
        local victim_name = killer_name
        local attacker_name = entity.get_player_name(attacker)
        send_trashtalk(trashtalk_phrases.OnDeath, attacker_name, victim_name)
    end
end)

client.set_event_callback("aim_miss", function(e)
    local player = e.target
    if not entity.is_enemy(player) then return end

    update_player_cache(player)
    local cache = player_cache[player]
    if not cache then return end

    cache.misses = (cache.misses or 0) + 1
end)

local manual_state = "none"

local function handle_manual_and_freestand(cmd)
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end

    if ui.get(menu["misc"].binds.manual_left) then
        manual_state = "left"
    elseif ui.get(menu["misc"].binds.manual_right) then
        manual_state = "right"
    elseif ui.get(menu["misc"].binds.manual_reset) then
        manual_state = "none"
    end

    if manual_state ~= "none" then
        ui.set(tbl.items.enabled[1], false)
        local pitch, yaw = client.camera_angles()
        if manual_state == "left" then
            cmd.yaw = yaw + 90
        elseif manual_state == "right" then
            cmd.yaw = yaw - 90
        end
        return
    else
        ui.set(tbl.items.enabled[1], true)
    end

    if ui.get(menu["misc"].binds.freestanding) then
        ui.set(tbl.items.fs[1], true)
        ui.set(tbl.items.yaw[1], "180")
        ui.set(tbl.items.yaw[2], 0)
        ui.set(tbl.items.jitter[1], "Off")
        ui.set(tbl.items.body[1], "Opposite")
        ui.set(tbl.items.fsbody[1], true)
    else
        ui.set(tbl.items.fs[1], false)
    end
end

local resolver = {}

resolver.default = function(player)
    update_player_cache(player)
    local cache = player_cache[player]
    if not cache then return end

    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end

    local tick = globals.tickcount()
    local yaw = cache.eye_yaw
    local lby_delta = normalize_angle(cache.eye_yaw - cache.lby)
    local velocity_factor = clamp(cache.velocity / 260, 0, 1)
    local anim_factor = cache.animstate * 120 - 60
    local leg_anim = entity.get_prop(player, "m_flPoseParameter", 6) or 0
    local arm_anim = entity.get_prop(player, "m_flPoseParameter", 8) or 0
    local ping = client.latency() * 1000
    local eye_pos = { client.eye_position() }
    local enemy_pos = { entity.get_origin(player) }
    local dist = math.sqrt((eye_pos[1] - enemy_pos[1])^2 + (eye_pos[2] - enemy_pos[2])^2)
    local misses = cache.misses or 0

    cache.kalman = cache.kalman or { estimate = yaw, error = 1, last_estimate = yaw, accel = 0 }
    local delta_yaw = normalize_angle(yaw - cache.kalman.last_estimate)
    local k = cache.kalman.error / (cache.kalman.error + 0.1)
    cache.kalman.estimate = cache.kalman.estimate + k * delta_yaw + cache.kalman.accel
    cache.kalman.error = (1 - k) * cache.kalman.error + 0.05
    cache.kalman.accel = clamp(delta_yaw - (cache.kalman.accel or 0), -10, 10) * 0.1
    cache.kalman.last_estimate = yaw
    local predicted_yaw = cache.kalman.estimate

    local ping_adjustment = ping / 1000 * 60
    predicted_yaw = normalize_angle(predicted_yaw + ping_adjustment)

    local lby_updated = false
    if #cache.aa_history >= 2 then
        lby_updated = math.abs(normalize_angle(cache.aa_history[#cache.aa_history].lby - cache.aa_history[#cache.aa_history-1].lby)) > 10
    end
    local lby_threshold = ping > 100 and 30 or 25
    if lby_updated or math.abs(lby_delta) > lby_threshold then
        yaw = cache.lby + (lby_delta > 0 and clamp(60 + misses * 5, 60, 90) or -clamp(60 + misses * 5, 60, 90))
    else
        yaw = predicted_yaw + velocity_factor * 40 + (anim_factor > 0 and 35 or -35)
        if leg_anim > 0.7 then
            yaw = yaw + 25
        elseif leg_anim < 0.3 then
            yaw = yaw - 25
        end
        if arm_anim > 0.5 then
            yaw = yaw + 15
        elseif arm_anim < 0.5 then
            yaw = yaw - 15
        end
        if misses > 2 then
            yaw = yaw + (misses % 2 == 0 and 50 or -50) * (1 + misses * 0.1)
        end
    end

    local velocity_x, velocity_y = entity.get_prop(player, "m_vecVelocity")
    if velocity_x ~= 0 or velocity_y ~= 0 then
        local vel_angle = math.deg(math.atan2(velocity_y, velocity_x))
        local yaw_diff = normalize_angle(yaw - vel_angle)
        if math.abs(yaw_diff) > 90 then
            yaw = normalize_angle(yaw + 180 * (velocity_factor + 0.5))
        else
            yaw = yaw + clamp(velocity_factor * 50, 0, 60) * (velocity_x > 0 and 1 or -1)
        end
    end

    local jitter_detected = false
    if #cache.aa_history >= 5 then
        local delta_sum = 0
        for i = 2, #cache.aa_history do
            delta_sum = delta_sum + math.abs(normalize_angle(cache.aa_history[i].yaw - cache.aa_history[i-1].yaw))
        end
        local stability = delta_sum / (#cache.aa_history - 1)
        jitter_detected = stability > 30
        if jitter_detected then
            yaw = yaw + (tick % 2 == 0 and 60 or -60) * (stability / 50)
        elseif stability < 10 then
            yaw = yaw + (tick % 4 < 2 and 45 or -45)
        end
    end

    if dist < 300 then
        local random_factor = (300 - dist) / 300
        yaw = yaw + (math.random() - 0.5) * 80 * random_factor * (jitter_detected and 1.5 or 1)
    elseif dist > 1200 then
        yaw = yaw + velocity_factor * clamp((dist - 1200) / 800, 0, 2) * 50
    end

    yaw = normalize_angle(yaw)
    if can_penetrate_wall(local_player, player, yaw) then
        plist.set(player, "Force body yaw", true)
        plist.set(player, "Force body yaw value", clamp(yaw, -60, 60))
    else
        plist.set(player, "Force body yaw", false)
    end

    cache.last_yaw = yaw
end

resolver.bruteforce = function(player)
    update_player_cache(player)
    local cache = player_cache[player]
    if not cache then return end

    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end

    local tick = globals.tickcount()
    local misses = cache.misses or 0
    local history = cache.aa_history
    local choked_ticks = cache.choked_ticks or 0
    local ping = client.latency() * 1000

    local stability = 0
    if #history >= 5 then
        local delta_sum = 0
        for i = 2, #history do
            delta_sum = delta_sum + math.abs(normalize_angle(history[i].yaw - history[i-1].yaw))
        end
        stability = delta_sum / (#history - 1)
    end
    local step = clamp(20 - stability / 3, 5, 20)

    local base_angle = tick * 17 % 360 - 180
    local angles = {}
    for i = -120, 120, step do
        angles[#angles + 1] = normalize_angle(base_angle + i + (math.random() - 0.5) * 5)
    end
    local yaw = angles[(misses % #angles) + 1] or 0

    if #history >= 6 then
        local diffs = {}
        for i = 2, #history do
            diffs[i-1] = normalize_angle(history[i].yaw - history[i-1].yaw)
        end
        local pattern_detected = math.abs(diffs[#diffs] - diffs[#diffs-2]) < 10 and math.abs(diffs[#diffs-1] - diffs[#diffs-3]) < 10
        if pattern_detected then
            yaw = normalize_angle(history[#history].yaw + diffs[#diffs] * 1.5)
        end
    end

    local weapon = entity.get_player_weapon(player)
    local weapon_type = weapon and entity.get_classname(weapon) or ""
    if weapon_type == "CWeaponAWP" or weapon_type == "CWeaponSSG08" then
        yaw = yaw + (misses % 2 == 0 and 50 or -50)
    elseif weapon_type:match("CWeaponPistol") then
        yaw = yaw + (tick % 2 == 0 and 30 or -30)
    end

    local jitter_detected = stability > 30
    if cache.velocity > 80 then
        yaw = yaw + clamp(cache.velocity / 260, 0, 1) * 60 * (jitter_detected and 1.5 or 1) * (tick % 2 == 0 and 1 or -1)
    end

    if choked_ticks > 2 then
        yaw = yaw + choked_ticks * clamp(12 + ping / 200, 12, 20) * (tick % 2 == 0 and 1 or -1)
    end
    if misses > 4 then
        yaw = yaw + (misses % 2 == 0 and -90 or 90) * (1 + misses * 0.15)
    elseif misses > 2 then
        yaw = yaw + (tick % 3 == 0 and -60 or 60) * (1 + misses * 0.1)
    end

    yaw = normalize_angle(yaw)
    if can_penetrate_wall(local_player, player, yaw) then
        plist.set(player, "Force body yaw", true)
        plist.set(player, "Force body yaw value", clamp(yaw, -60, 60))
    else
        plist.set(player, "Force body yaw", false)
    end
end

resolver.logic = function(player)
    update_player_cache(player)
    local cache = player_cache[player]
    if not cache then return end

    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end

    local tick = globals.tickcount()
    local delta = normalize_angle(cache.eye_yaw - cache.last_yaw)
    local lby_delta = normalize_angle(cache.eye_yaw - cache.lby)
    local velocity_factor = clamp(cache.velocity / 260, 0, 1)
    local anim_factor = cache.animstate * 120 - 60
    local choked_ticks = cache.choked_ticks or 0
    local yaw = cache.eye_yaw
    local tick_interval = globals.tickinterval()
    local simtime_delta = globals.curtime() - (cache.last_update or 0)
    local ping = client.latency() * 1000

    local frequency = 0
    if #cache.aa_history >= 5 then
        local sin_sum, cos_sum = 0, 0
        for i = 1, #cache.aa_history do
            local t = (i - 1) / (#cache.aa_history - 1)
            sin_sum = sin_sum + cache.aa_history[i].yaw * math.sin(2 * math.pi * t)
            cos_sum = cos_sum + cache.aa_history[i].yaw * math.cos(2 * math.pi * t)
        end
        frequency = math.sqrt(sin_sum^2 + cos_sum^2) / #cache.aa_history
    end

    local acceleration = 0
    if #cache.aa_history >= 3 then
        local delta1 = normalize_angle(cache.aa_history[#cache.aa_history].yaw - cache.aa_history[#cache.aa_history-1].yaw)
        local delta2 = normalize_angle(cache.aa_history[#cache.aa_history-1].yaw - cache.aa_history[#cache.aa_history-2].yaw)
        acceleration = delta1 - delta2
    end

    local lby_threshold = ping > 100 and 35 or 30
    if math.abs(lby_delta) > lby_threshold then
        yaw = cache.lby + (lby_delta > 0 and clamp(70 + choked_ticks * 5, 70, 90) or -clamp(70 + choked_ticks * 5, 70, 90))
    elseif frequency > 15 then
        yaw = yaw + math.sin(tick * 0.5) * 50 + acceleration * 2
    else
        yaw = yaw + (velocity_factor > 0.5 and 45 or -45) + acceleration * 1.5
    end

    local velocity_x, velocity_y = entity.get_prop(player, "m_vecVelocity")
    local on_ground = cache.on_ground
    if velocity_x ~= 0 or velocity_y ~= 0 then
        local vel_angle = math.deg(math.atan2(velocity_y, velocity_x))
        yaw = yaw + normalize_angle(vel_angle - yaw) * velocity_factor * 0.3
        if not on_ground then
            yaw = yaw + (velocity_factor > 0.5 and 20 or -20)
        end
    end

    if simtime_delta > tick_interval * 3 then
        yaw = yaw + velocity_factor * 50 * (anim_factor > 0 and 1 or -1) * clamp(1 + ping / 200, 1, 1.5)
    end
    if choked_ticks > 3 then
        yaw = yaw + choked_ticks * clamp(15 + ping / 100, 15, 25) * (lby_delta > 0 and -1 or 1)
    end

    yaw = normalize_angle(yaw)
    if can_penetrate_wall(local_player, player, yaw) then
        plist.set(player, "Force body yaw", true)
        plist.set(player, "Force body yaw value", clamp(yaw, -60, 60))
    else
        plist.set(player, "Force body yaw", false)
    end

    cache.last_yaw = yaw
    cache.last_update = globals.curtime()
end

resolver.smart = function(player)
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) or not entity.is_alive(player) then return end

    update_player_cache(player)
    local cache = player_cache[player]
    if not cache then return end

    local tick = globals.tickcount()
    local yaw = cache.eye_yaw or 0
    local lby_delta = normalize_angle(cache.eye_yaw - (cache.lby or 0))
    local velocity = cache.velocity or 0
    local anim_factor = (cache.animstate or 0) * 120 - 60
    local history = cache.aa_history or {}
    local choked_ticks = cache.choked_ticks or 0
    local misses = cache.misses or 0
    local eye_pos = { client.eye_position() }
    local enemy_pos = { entity.get_origin(player) }
    local dist = math.sqrt((eye_pos[1] - enemy_pos[1])^2 + (eye_pos[2] - enemy_pos[2])^2)
    local ping = client.latency() * 1000

    local stability, avg_yaw, yaw_trend, accel = 0, 0, 0, 0
    if #history >= 5 then
        local delta_sum, trend_sum, accel_sum = 0, 0, 0
        for i = 2, #history do
            local delta = normalize_angle(history[i].yaw - history[i-1].yaw)
            delta_sum = delta_sum + math.abs(delta)
            trend_sum = trend_sum + delta
            if i > 2 then
                accel_sum = accel_sum + (delta - normalize_angle(history[i-1].yaw - history[i-2].yaw))
            end
            avg_yaw = avg_yaw + history[i].yaw
        end
        avg_yaw = normalize_angle(avg_yaw / #history)
        stability = delta_sum / (#history - 1)
        yaw_trend = trend_sum / (#history - 1)
        accel = accel_sum / (#history - 2)
    else
        avg_yaw = cache.lby or yaw
    end

    local velocity_factor = clamp(velocity / 260, 0, 1)
    local ping_factor = clamp(ping / 100, 0.5, 2)
    local aa_type = "static"
    if stability > 40 * ping_factor then
        aa_type = "jitter"
    elseif stability > 15 and choked_ticks > clamp(2 + dist / 1000, 2, 4) then
        aa_type = "desync"
    elseif velocity > 120 and math.abs(anim_factor) > 25 then
        aa_type = "dynamic"
    elseif math.abs(yaw_trend) > 12 or math.abs(accel) > 5 then
        aa_type = "spin"
    end

    if aa_type == "static" then
        yaw = avg_yaw + (lby_delta > 0 and 60 or -60)
        if misses > 2 then
            yaw = yaw + (misses % 2 == 0 and 60 or -60) * (1 - velocity_factor) * (1 + misses * 0.1)
        end
    elseif aa_type == "jitter" then
        yaw = yaw + math.sin(tick * 0.5 + ping / 1000 + accel) * clamp(90 - stability, 20, 90)
        if choked_ticks > 2 then
            yaw = yaw + choked_ticks * 20 * (dist > 800 and 0.6 or 1)
        end
    elseif aa_type == "desync" then
        yaw = cache.lby + (lby_delta > 0 and -clamp(70 + misses * 5, 70, 90) or clamp(70 + misses * 5, 70, 90))
        if misses > 1 then
            yaw = yaw + (misses % 2 == 0 and 50 or -50) * (1 + choked_ticks * 0.2)
        end
    elseif aa_type == "dynamic" then
        yaw = yaw + (anim_factor > 0 and velocity_factor * 70 or -velocity_factor * 70)
        if #history >= 3 then
            yaw = yaw + (yaw_trend + accel * 2) * clamp(3 - misses * 0.5, 1, 3)
        end
    elseif aa_type == "spin" then
        yaw = yaw + (yaw_trend * 6 + accel * 10) + (tick % 2 == 0 and 45 or -45)
    end

    local weapon = entity.get_player_weapon(player)
    local weapon_type = weapon and entity.get_classname(weapon) or ""
    if weapon_type == "CWeaponAWP" then
        yaw = yaw + (tick % 2 == 0 and 30 or -30)
    elseif weapon_type:match("CWeaponPistol") then
        yaw = yaw + (math.random() - 0.5) * 40
    end

    local simtime_delta = globals.curtime() - (cache.last_update or 0)
    if simtime_delta > 0.1 then
        yaw = yaw + (velocity > 80 and 60 or -60) * clamp(ping / 150, 0.5, 1.5)
    end
    if dist < 250 then
        yaw = yaw + (math.random() - 0.5) * 90 * (250 - dist) / 250
    end

    yaw = normalize_angle(yaw)
    if can_penetrate_wall(local_player, player, yaw) then
        plist.set(player, "Force body yaw", true)
        plist.set(player, "Force body yaw value", clamp(yaw, -60, 60))
    else
        plist.set(player, "Force body yaw", false)
    end
end

resolver.extra = function(player)
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) or not entity.is_alive(player) then return end

    update_player_cache(player)
    local cache = player_cache[player]
    if not cache then return end

    local tick = globals.tickcount()
    local current_x, current_y, current_z = entity.get_origin(player)
    local eye_x, eye_y, eye_z = client.eye_position()
    local velocity_x, velocity_y = entity.get_prop(player, "m_vecVelocity") or 0, 0
    local velocity = cache.velocity or 0
    local choked_ticks = cache.choked_ticks or 0
    local ping = client.latency() * 1000
    local dist = math.sqrt((eye_x - current_x)^2 + (eye_y - current_y)^2)
    local misses = cache.misses or 0
    local lby_delta = normalize_angle(cache.eye_yaw - (cache.lby or 0))

    local backtrack_data = backtrack.get_records(player) or {}
    if #backtrack_data == 0 then return end

    local backtrack_yaws = {}
    local backtrack_trend = 0
    for i = 1, #backtrack_data do
        local record = backtrack_data[i]
        if record and record.yaw then
            backtrack_yaws[#backtrack_yaws + 1] = record.yaw
            if i > 1 then
                backtrack_trend = backtrack_trend + normalize_angle(record.yaw - backtrack_data[i-1].yaw)
            end
        end
    end
    backtrack_trend = #backtrack_yaws > 1 and backtrack_trend / (#backtrack_yaws - 1) or 0

    local avg_backtrack_yaw = 0
    if #backtrack_yaws > 0 then
        for _, yaw in ipairs(backtrack_yaws) do
            avg_backtrack_yaw = avg_backtrack_yaw + yaw
        end
        avg_backtrack_yaw = normalize_angle(avg_backtrack_yaw / #backtrack_yaws)
    else
        avg_backtrack_yaw = cache.eye_yaw or 0
    end

    local backtrack_stability = 0
    if #backtrack_yaws >= 3 then
        local delta_sum = 0
        for i = 2, #backtrack_yaws do
            delta_sum = delta_sum + math.abs(normalize_angle(backtrack_yaws[i] - backtrack_yaws[i-1]))
        end
        backtrack_stability = delta_sum / (#backtrack_yaws - 1)
    end

    local anti_aim_type = "unknown"
    if backtrack_stability < 10 then
        anti_aim_type = "static"
    elseif backtrack_stability > 30 then
        anti_aim_type = "jitter"
    elseif math.abs(backtrack_trend) > 5 then
        anti_aim_type = "spin"
    end

    local yaw = avg_backtrack_yaw

    if anti_aim_type == "static" then
        yaw = avg_backtrack_yaw + (lby_delta > 0 and 60 or -60)
    elseif anti_aim_type == "jitter" then
        yaw = yaw + math.sin(tick * 0.8 + ping / 1000) * clamp(80 - velocity / 4, 20, 80)
    elseif anti_aim_type == "spin" then
        yaw = yaw + backtrack_trend * 4
    end

    local height_diff = current_z - eye_z
    if math.abs(height_diff) > 50 then
        yaw = yaw + (height_diff > 0 and 45 or -45) * clamp(velocity / 260, 0.5, 1)
    end

    local weapon = entity.get_player_weapon(player)
    local weapon_type = weapon and entity.get_classname(weapon) or ""
    if weapon_type == "CWeaponAWP" or weapon_type == "CWeaponSSG08" then
        yaw = yaw + (misses % 2 == 0 and 50 or -50)
    elseif weapon_type == "CWeaponPistol" then
        yaw = yaw + (math.random() * 2 - 1) * 30
    end

    if choked_ticks > 4 then
        yaw = yaw + choked_ticks * 15 * (dist < 500 and 1 or 0.5)
    end
    if misses > 3 then
        yaw = yaw + (tick % 2 == 0 and 90 or -90) * (1 - velocity / 260)
    end

    if ping > 100 then
        yaw = yaw + (math.random() * 2 - 1) * clamp(ping / 50, 10, 60)
    end

    if can_penetrate_wall(local_player, player, yaw) then
        yaw = yaw + (velocity_x > 0 and 30 or -30) * clamp(choked_ticks / 5, 0, 1)
    else
        yaw = yaw + backtrack_trend * 4
    end

    yaw = normalize_angle(yaw)
    if can_penetrate_wall(local_player, player, yaw) then
        plist.set(player, "Force body yaw", true)
        plist.set(player, "Force body yaw value", clamp(yaw, -60, 60))
    else
        plist.set(player, "Force body yaw", false)
    end

    cache.last_yaw = yaw
    cache.last_update = globals.curtime()
end

resolver["resolver builder"] = function(player)
    update_player_cache(player)
    local cache = player_cache[player]
    if not cache then return end

    local tick = globals.tickcount()
    local yaw = cache.eye_yaw or 0
    local delta_yaw = normalize_angle((cache.eye_yaw or 0) - (cache.last_yaw or 0))
    local lby_delta = normalize_angle((cache.eye_yaw or 0) - (cache.lby or 0))
    local velocity = cache.velocity or 0
    local anim_factor = (cache.animstate or 0) * 120 - 60 
    local history = cache.aa_history or {} 
    local dt_active = ui.get(tbl.items.dt[1]) or false
    local ping = client.latency() * 1000 
    local local_player = entity.get_local_player()

    if not local_player or not entity.is_alive(local_player) then return end

    local eye_pos = {client.eye_position()}
    if not eye_pos[1] or not eye_pos[2] or not eye_pos[3] then return end

    local player_pos = {entity.get_origin(player)}
    if not player_pos[1] or not player_pos[2] or not player_pos[3] then return end

    local fraction, hit_entity = client.trace_line(local_player, eye_pos[1], eye_pos[2], eye_pos[3], player_pos[1], player_pos[2], player_pos[3])
    if fraction == nil then fraction = 1 end

    
    if ui.get(menu.resolver.builder.velocity.enabled) then
        local velocity_factor = ui.get(menu.resolver.builder.velocity.factor) / 100
        local velocity_threshold = ui.get(menu.resolver.builder.velocity.threshold)
        local velocity_invert = ui.get(menu.resolver.builder.velocity.invert)
        local velocity_wall = ui.get(menu.resolver.builder.velocity.wall_aware)
        local velocity_clamp = ui.get(menu.resolver.builder.velocity.max_adjustment)
        local velocity_spike = ui.get(menu.resolver.builder.velocity.spike_factor) / 100
        if velocity > velocity_threshold then
            local velocity_adjust = clamp((velocity / 260) * 50 * velocity_factor, -velocity_clamp, velocity_clamp)
            if velocity_wall and fraction < 1 then
                velocity_adjust = velocity_adjust * 0.5
            end
            if velocity_spike > 0 and velocity > 150 then
                velocity_adjust = velocity_adjust + (velocity - 150) * velocity_spike
            end
            yaw = yaw + (velocity_invert and (tick % 2 == 0 and -velocity_adjust or velocity_adjust) or (tick % 2 == 0 and velocity_adjust or -velocity_adjust))
        end
    end

    
    if ui.get(menu.resolver.builder.animations.enabled) then
        local anim_mode = ui.get(menu.resolver.builder.animations.mode)
        local anim_influence = ui.get(menu.resolver.builder.animations.influence) / 100
        local anim_threshold = ui.get(menu.resolver.builder.animations.threshold)
        local lby_influence = ui.get(menu.resolver.builder.animations.lby_influence) / 100
        local choke_influence = ui.get(menu.resolver.builder.animations.choke_influence) / 100
        local anim_smoothing = ui.get(menu.resolver.builder.animations.smoothing) / 100
        local anim_boost = ui.get(menu.resolver.builder.animations.boost_factor) / 100
        if math.abs(anim_factor) > anim_threshold then
            local anim_adjust = 0
            if anim_mode == "Static" then
                anim_adjust = (anim_factor > 0 and 45 or -45) * anim_influence
            elseif anim_mode == "Dynamic" then
                anim_adjust = anim_factor * anim_influence
            elseif anim_mode == "Mixed" then
                anim_adjust = (anim_factor > 0 and math.sin(tick * 0.5) * 60 or math.cos(tick * 0.5) * -60) * anim_influence
            end
            if lby_influence > 0 and math.abs(lby_delta) > 25 then
                anim_adjust = anim_adjust + (lby_delta > 0 and 30 or -30) * lby_influence
            end
            if choke_influence > 0 and cache.choked_ticks > 2 then
                anim_adjust = anim_adjust + (cache.choked_ticks * 10) * choke_influence
            end
            yaw = yaw + anim_adjust * (1 - anim_smoothing) + (yaw * anim_smoothing)
            if anim_boost > 0 then
                yaw = yaw + (math.random() - 0.5) * 20 * anim_boost
            end
        end
    end

    
    if ui.get(menu.resolver.builder.history.enabled) then
        local history_mode = ui.get(menu.resolver.builder.history.mode)
        local history_depth = ui.get(menu.resolver.builder.history.depth)
        local stability_threshold = ui.get(menu.resolver.builder.history.stability_threshold)
        local invert = ui.get(menu.resolver.builder.history.invert)
        local weight_factor = ui.get(menu.resolver.builder.history.weight_factor) / 100
        local jitter_influence = ui.get(menu.resolver.builder.history.jitter_influence) / 100
        if #history >= history_depth then
            local avg_yaw = 0
            local delta_sum = 0
            for i = 1, history_depth do
                avg_yaw = avg_yaw + history[#history - i + 1].yaw
                if i > 1 then
                    delta_sum = delta_sum + math.abs(normalize_angle(history[#history - i + 1].yaw - history[#history - i].yaw))
                end
            end
            avg_yaw = avg_yaw / history_depth
            local stability = delta_sum / (history_depth - 1)
            local history_adjust = 0
            if history_mode == "Average" then
                history_adjust = normalize_angle(avg_yaw - yaw) * weight_factor
            elseif history_mode == "Delta" then
                history_adjust = delta_sum * weight_factor * (invert and -1 or 1)
            elseif history_mode == "Pattern" and stability < stability_threshold then
                history_adjust = (tick % 2 == 0 and 60 or -60) * weight_factor
            end
            if jitter_influence > 0 and stability > stability_threshold then
                history_adjust = history_adjust + math.sin(tick * 0.3) * 70 * jitter_influence
            end
            yaw = yaw + history_adjust
        end
    end

    
    if ui.get(menu.resolver.builder.miss.enabled) then
        local miss_mode = ui.get(menu.resolver.builder.miss.mode)
        local miss_amplitude = ui.get(menu.resolver.builder.miss.amplitude)
        local after_misses = ui.get(menu.resolver.builder.miss.after_misses)
        local invert = ui.get(menu.resolver.builder.miss.invert)
        local reset_threshold = ui.get(menu.resolver.builder.miss.reset_threshold)
        local scale_factor = ui.get(menu.resolver.builder.miss.scale_factor) / 100
        if cache.misses >= after_misses then
            local miss_adjust = 0
            if miss_mode == "Shift" then
                miss_adjust = miss_amplitude * (invert and -1 or 1)
            elseif miss_mode == "Random" then
                miss_adjust = (math.random() - 0.5) * miss_amplitude * 2
            elseif miss_mode == "Cycle" then
                miss_adjust = miss_amplitude * ((cache.misses % 2 == 0) and 1 or -1)
            end
            yaw = yaw + miss_adjust * (1 + scale_factor * cache.misses)
            if reset_threshold > 0 and cache.misses >= reset_threshold then
                cache.misses = 0
            end
        end
    end

    
    if ui.get(menu.resolver.builder.jitter.enabled) then
        local jitter_type = ui.get(menu.resolver.builder.jitter.type)
        local jitter_frequency = ui.get(menu.resolver.builder.jitter.frequency) / 100
        local jitter_amplitude = ui.get(menu.resolver.builder.jitter.amplitude)
        local chaos_factor = ui.get(menu.resolver.builder.jitter.chaos_factor) / 100
        local sync_with_tick = ui.get(menu.resolver.builder.jitter.sync_with_tick)
        local phase_shift = ui.get(menu.resolver.builder.jitter.phase_shift) / 100
        local jitter_adjust = 0
        if jitter_type == "Sine" then
            jitter_adjust = math.sin(tick * jitter_frequency + phase_shift) * jitter_amplitude
        elseif jitter_type == "Cosine" then
            jitter_adjust = math.cos(tick * jitter_frequency + phase_shift) * jitter_amplitude
        elseif jitter_type == "Random" then
            jitter_adjust = (math.random() - 0.5) * jitter_amplitude * 2
        end
        if chaos_factor > 0 then
            jitter_adjust = jitter_adjust + (math.random() - 0.5) * jitter_amplitude * chaos_factor
        end
        if sync_with_tick then
            jitter_adjust = jitter_adjust * math.sin(tick * 0.1)
        end
        yaw = yaw + jitter_adjust
    end

    
    if ui.get(menu.resolver.builder.defensive.enabled) then
        local anti_bruteforce = ui.get(menu.resolver.builder.defensive.anti_bruteforce)
        local anti_bruteforce_misses = ui.get(menu.resolver.builder.defensive.anti_bruteforce_misses)
        local random_shift = ui.get(menu.resolver.builder.defensive.random_shift)
        local random_shift_max = ui.get(menu.resolver.builder.defensive.random_shift_max)
        local jitter_amplitude = ui.get(menu.resolver.builder.defensive.jitter_amplitude)
        local adaptive_defense = ui.get(menu.resolver.builder.defensive.adaptive_defense)
        local adaptive_threshold = ui.get(menu.resolver.builder.defensive.adaptive_threshold)
        local ping_mode = ui.get(menu.resolver.builder.defensive.ping_mode)
        local edge_detection = ui.get(menu.resolver.builder.defensive.edge_detection)
        local choke_factor = ui.get(menu.resolver.builder.defensive.choke_factor) / 100
        local defensive_adjust = 0
        if anti_bruteforce and cache.misses >= anti_bruteforce_misses then
            defensive_adjust = defensive_adjust + (tick % 2 == 0 and 60 or -60)
        end
        if random_shift then
            defensive_adjust = defensive_adjust + (math.random() - 0.5) * random_shift_max * 2
        end
        if jitter_amplitude > 0 then
            defensive_adjust = defensive_adjust + math.sin(tick * 0.5) * jitter_amplitude
        end
        if adaptive_defense and #history >= 5 then
            local stability = 0
            for i = 2, #history do
                stability = stability + math.abs(normalize_angle(history[i].yaw - history[i-1].yaw))
            end
            stability = stability / (#history - 1)
            if stability < adaptive_threshold then
                defensive_adjust = defensive_adjust + (tick % 2 == 0 and 45 or -45)
            end
        end
        if ping_mode ~= "Off" and ping > (ping_mode == "Low" and 50 or 100) then
            defensive_adjust = defensive_adjust + (ping / 200) * 30
        end
        if edge_detection and fraction < 0.9 then
            defensive_adjust = defensive_adjust + 45
        end
        if choke_factor > 0 and cache.choked_ticks > 3 then
            defensive_adjust = defensive_adjust + (cache.choked_ticks * 15) * choke_factor
        end
        yaw = yaw + defensive_adjust
    end

    
    if ui.get(menu.resolver.builder.hitbox.enabled) then
        local hitbox_mode = ui.get(menu.resolver.builder.hitbox.mode)
        local static_hitbox = ui.get(menu.resolver.builder.hitbox.static_hitbox)
        local switch_speed = ui.get(menu.resolver.builder.hitbox.switch_speed)
        local on_miss = ui.get(menu.resolver.builder.hitbox.on_miss)
        local miss_count = ui.get(menu.resolver.builder.hitbox.miss_count)
        local randomize = ui.get(menu.resolver.builder.hitbox.randomize)
        local priority_factor = ui.get(menu.resolver.builder.hitbox.priority_factor) / 100
        local hitbox_value = 0
        if hitbox_mode == "Static" then
            hitbox_value = static_hitbox == "Head" and 0 or (static_hitbox == "Chest" and 4 or 6)
        elseif hitbox_mode == "Cycle" then
            hitbox_value = math.floor((tick / switch_speed) % 3) * 2
        elseif hitbox_mode == "Adaptive" and on_miss and cache.misses >= miss_count then
            hitbox_value = (cache.misses % 3) * 2
        end
        if randomize then
            hitbox_value = math.random(0, 2) * 2
        end
        plist.set(player, "Override hitbox", true)
        plist.set(player, "Override hitbox value", hitbox_value)
    else
        plist.set(player, "Override hitbox", false)
    end

    
    if ui.get(menu.resolver.builder.double_tap.enabled) then
        local dt_mode = ui.get(menu.resolver.builder.double_tap.mode)
        local shift_amount = ui.get(menu.resolver.builder.double_tap.shift_amount)
        local velocity_boost = ui.get(menu.resolver.builder.double_tap.velocity_boost) / 100
        local choke_adjust = ui.get(menu.resolver.builder.double_tap.choke_adjust) / 100
        if dt_active then
            local dt_adjust = 0
            if dt_mode == "Static" then
                dt_adjust = shift_amount
            elseif dt_mode == "Dynamic" then
                dt_adjust = shift_amount * math.sin(tick * 0.5)
            elseif dt_mode == "Random" then
                dt_adjust = (math.random() - 0.5) * shift_amount * 2
            end
            if velocity_boost > 0 then
                dt_adjust = dt_adjust + (velocity / 260) * 50 * velocity_boost
            end
            if choke_adjust > 0 and cache.choked_ticks > 2 then
                dt_adjust = dt_adjust + (cache.choked_ticks * 10) * choke_adjust
            end
            yaw = yaw + dt_adjust
        end
    end

    
    if ui.get(menu.resolver.builder.distance.enabled) then
        local min_dist = ui.get(menu.resolver.builder.distance.min_dist)
        local max_dist = ui.get(menu.resolver.builder.distance.max_dist)
        local dist_factor = ui.get(menu.resolver.builder.distance.dist_factor) / 100
        local close_shift = ui.get(menu.resolver.builder.distance.close_shift)
        local far_shift = ui.get(menu.resolver.builder.distance.far_shift)
        local dist = math.sqrt((eye_pos[1] - player_pos[1])^2 + (eye_pos[2] - player_pos[2])^2)
        if dist < min_dist then
            yaw = yaw + close_shift * dist_factor
        elseif dist > max_dist then
            yaw = yaw + far_shift * dist_factor
        else
            local dist_range = max_dist - min_dist
            local dist_progress = (dist - min_dist) / dist_range
            yaw = yaw + (close_shift + (far_shift - close_shift) * dist_progress) * dist_factor
        end
    end

    
    if ui.get(menu.resolver.builder["weapon⠀awareness"].enabled) then
        local sniper_adjust = ui.get(menu.resolver.builder["weapon⠀awareness"].sniper_adjust)
        local pistol_adjust = ui.get(menu.resolver.builder["weapon⠀awareness"].pistol_adjust)
        local rifle_adjust = ui.get(menu.resolver.builder["weapon⠀awareness"].rifle_adjust)
        local dynamic_switch = ui.get(menu.resolver.builder["weapon⠀awareness"].dynamic_switch)
        local switch_speed = ui.get(menu.resolver.builder["weapon⠀awareness"].switch_speed)
        local weapon = entity.get_player_weapon(player)
        local weapon_type = weapon and entity.get_classname(weapon) or ""
        local weapon_adjust = 0
        if weapon_type == "CWeaponAWP" or weapon_type == "CWeaponSSG08" then
            weapon_adjust = sniper_adjust
        elseif weapon_type == "CWeaponPistol" then
            weapon_adjust = pistol_adjust
        else
            weapon_adjust = rifle_adjust
        end
        if dynamic_switch then
            weapon_adjust = weapon_adjust * math.sin(tick / switch_speed)
        end
        yaw = yaw + weapon_adjust
    end

    
    if ui.get(menu.resolver.builder.prediction.enabled) then
        local ticks = ui.get(menu.resolver.builder.prediction.ticks)
        local accel_factor = ui.get(menu.resolver.builder.prediction.accel_factor) / 100
        local yaw_boost = ui.get(menu.resolver.builder.prediction.yaw_boost)
        local velocity_scale = ui.get(menu.resolver.builder.prediction.velocity_scale) / 100
        local wall_aware = ui.get(menu.resolver.builder.prediction.wall_aware)
        local vx, vy = entity.get_prop(player, "m_vecVelocity")
        local pred_x, pred_y = extrapolate_position(player, ticks)
        local delta_x, delta_y = pred_x - eye_pos[1], pred_y - eye_pos[2]
        local pred_yaw = math.deg(math.atan2(delta_y, delta_x)) - 90
        local pred_adjust = normalize_angle(pred_yaw - yaw) * velocity_scale
        if accel_factor > 0 and #history >= 3 then
            local accel = ((history[#history].x - history[#history-1].x) - (history[#history-1].x - history[#history-2].x)) / globals.tickinterval()
            pred_adjust = pred_adjust + accel * accel_factor
        end
        if wall_aware and fraction < 0.9 then
            pred_adjust = pred_adjust * 0.5
        end
        yaw = yaw + pred_adjust + yaw_boost
    end

    
    if ui.get(menu.resolver.builder["latency⠀compensation"].enabled) then
        local ping_threshold = ui.get(menu.resolver.builder["latency⠀compensation"].ping_threshold)
        local high_ping_shift = ui.get(menu.resolver.builder["latency⠀compensation"].high_ping_shift)
        local choke_factor = ui.get(menu.resolver.builder["latency⠀compensation"].choke_factor) / 100
        local smooth_transition = ui.get(menu.resolver.builder["latency⠀compensation"].smooth_transition)
        if ping > ping_threshold then
            local latency_adjust = high_ping_shift * (ping / 200)
            if choke_factor > 0 and cache.choked_ticks > 3 then
                latency_adjust = latency_adjust + (cache.choked_ticks * 15) * choke_factor
            end
            if smooth_transition then
                latency_adjust = latency_adjust * math.sin(tick * 0.1)
            end
            yaw = yaw + latency_adjust
        end
    end

    
    if ui.get(menu.resolver.builder.override.enabled) then
        local condition = ui.get(menu.resolver.builder.override.condition)
        local yaw_value = ui.get(menu.resolver.builder.override.yaw_value)
        local miss_threshold = ui.get(menu.resolver.builder.override.miss_threshold)
        local choke_threshold = ui.get(menu.resolver.builder.override.choke_threshold)
        local stability_threshold = ui.get(menu.resolver.builder.override.stability_threshold)
        local override = false
        if condition == "Always" then
            override = true
        elseif condition == "On Miss" and cache.misses >= miss_threshold then
            override = true
        elseif condition == "On High Choke" and cache.choked_ticks >= choke_threshold then
            override = true
        elseif condition == "On Low Stability" and #history >= 5 then
            local stability = 0
            for i = 2, #history do
                stability = stability + math.abs(normalize_angle(history[i].yaw - history[i-1].yaw))
            end
            stability = stability / (#history - 1)
            if stability < stability_threshold then
                override = true
            end
        end
        if override then
            yaw = normalize_angle(yaw_value)
        end
    end

    
    yaw = normalize_angle(yaw)
    if can_penetrate_wall(local_player, player, yaw) then
        plist.set(player, "Force body yaw", true)
        plist.set(player, "Force body yaw value", clamp(yaw, -60, 60))
    else
        plist.set(player, "Force body yaw", false)
    end

    cache.last_yaw = yaw
end

client.set_event_callback("net_update_start", function()
    local enemies = entity.get_players(true)
    local preset = ui.get(menu.resolver.preset)
    if resolver[preset] then
        for i, player in ipairs(enemies) do
            resolver[preset](player)
            apply_zeus_fix(player)  
        end
    end
end)

local smart_backtrack_active = false

local function smart_backtrack()
    if not ui.get(menu["misc"].other.smart_backtrack) then return end

    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end

    local tick_interval = globals.tickinterval()
    local latency = client.latency() or 0
    local max_backtrack_time = 0.2
    local max_ticks = math.floor(max_backtrack_time / tick_interval)
    local enemies = entity.get_players(true)
    local gravity = 800

    for _, enemy in ipairs(enemies) do
        if entity.is_alive(enemy) then
            update_player_cache(enemy)
            local cache = player_cache[enemy]
            if not cache then goto skip end

            local sim_time = cache.simtime or 0
            local choked_ticks = math.min(cache.choked_ticks or 0, 14)
            local velocity = {entity.get_prop(enemy, "m_vecVelocity") or 0, 0, 0}
            local speed = math.sqrt(velocity[1]^2 + velocity[2]^2)
            local on_ground = cache.on_ground or true
            local eye_yaw = cache.eye_yaw or 0
            local misses = cache.misses or 0  

            
            local latency_ticks = math.floor(latency / tick_interval + 0.5)
            local backtrack_ticks = latency_ticks + choked_ticks

            
            if speed > 10 then
                local speed_factor = math.min(speed / 260, 1)
                backtrack_ticks = backtrack_ticks + math.floor(speed_factor * 6)
            end
            if misses > 0 then
                backtrack_ticks = backtrack_ticks + math.min(misses * 2, 6)  
            end

            backtrack_ticks = math.max(1, math.min(backtrack_ticks, max_ticks))
            local target_time = sim_time - (backtrack_ticks * tick_interval)

            
            local predicted_time = target_time
            local pred_x, pred_y, pred_z = entity.get_origin(enemy)
            if pred_x and speed > 50 and choked_ticks > 2 then
                local extra_ticks = math.min(choked_ticks, 10)
                predicted_time = target_time - (extra_ticks * tick_interval)
                pred_x = pred_x + velocity[1] * tick_interval * extra_ticks
                pred_y = pred_y + velocity[2] * tick_interval * extra_ticks
                pred_z = pred_z + velocity[3] * tick_interval * extra_ticks
                if not on_ground then
                    pred_z = pred_z - (0.5 * gravity * (tick_interval * extra_ticks)^2)
                end
                plist.set(enemy, "Override hitbox", true)
                plist.set(enemy, "Override hitbox value", 0)
            else
                plist.set(enemy, "Override hitbox", false)
            end

            
            plist.set(enemy, "Correction active", true)
            plist.set(enemy, "Override simulation time", true)
            plist.set(enemy, "Simulation time override", target_time)

            
            local resolver_yaw = eye_yaw
            if speed > 80 then
                resolver_yaw = resolver_yaw + (velocity[1] > 0 and 30 or -30)
            elseif choked_ticks > 5 then
                resolver_yaw = resolver_yaw + (globals.tickcount() % 2 == 0 and 45 or -45)
            end
            if misses > 2 then
                resolver_yaw = resolver_yaw + (misses % 2 == 0 and 60 or -60)  
            end
            resolver_yaw = normalize_angle(resolver_yaw)
            plist.set(enemy, "Force body yaw", true)
            plist.set(enemy, "Force body yaw value", clamp(resolver_yaw, -60, 60))

            
            if not smart_backtrack_active then
                client.color_log(0, 255, 0, string.format(
                    "[Smart Backtrack] Enabled | Max Ticks: %d | Latency: %.1f ms",
                    max_ticks, latency * 1000
                ))
                smart_backtrack_active = true
            end
        end
        ::skip::
    end
end


local function reset_smart_backtrack()
    local enemies = entity.get_players(true)
    for _, enemy in ipairs(enemies) do
        plist.set(enemy, "Correction active", false)
        plist.set(enemy, "Override simulation time", false)
        plist.set(enemy, "Override hitbox", false)
        plist.set(enemy, "Force body yaw", false)
    end
    smart_backtrack_active = false
end

local function watermark()
    if not entity.is_alive(entity.get_local_player()) then return end
    if not ui.get(menu["visuals"].watermark) then return end

    local lp = entity.get_local_player()
    local screen_w, screen_h = client.screen_size()
    local center = {screen_w / 2, screen_h / 2}
    local alpha = 255
    local col = {indicators = {200, 150, 255}} 

    local yaw_body = math.max(-60, math.min(60, math.floor((entity.get_prop(lp, "m_flPoseParameter", 11) or 0) * 120 - 60 + 0.5)))
    renderer.text(center[1], center[2] + 15, col.indicators[1], col.indicators[2], col.indicators[3], alpha, "cd", 0, "Insanity")
    renderer.rectangle(center[1] - 30, center[2] + 25, 60, 3, 20, 20, 20, alpha)
    renderer.gradient(center[1] - 29, center[2] + 26, math.abs(yaw_body), 1, col.indicators[1], col.indicators[2], col.indicators[3], alpha, 20, 20, 20, alpha, true)
end


local function misc_logic()
    smart_backtrack() 
end


client.set_event_callback("paint", function()
    misc_logic()
    if ui.get(menu["visuals"].watermark) then
        watermark()
    end
end)


local function other_logic(cmd)
    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return end

    local tick = globals.tickcount()

    
    if ui.get(menu["misc"].other.leg_spammer) then
    ui.set(tbl.items.legs[1], tick % ui.get(menu["misc"].other.spammer) == 0 and "Never slide" or "Always slide")
    end
end


local function main(tbl_ref)
    local category = ui.new_combobox("aa", "anti-aimbot angles", "\aBA55D3FFcategory", {"home", "anti-aim", "resolver", "visuals", "misc"})
    
    -- НИЧЕГО НЕ ТРОГАТЬ ИЛИ ВСЕ ПОДЕТ ПО ПИЗДЕ! БАБКИ ЗАКОНЧАТСЯ, ЖЕНА НЕ БУДЕТ ДАВАТЬ, ДЕТИ УЙДУТ ИЗ ДОМА, ТЫ НАХУЙ УМРЕШЬ В НИЩИТЕ!!! Я ЭТУ КФГ СИСТЕМУ В РОТ ЕБАЛ!!!111!!111
    menu["home"] = {
        export = ui.new_button("aa", "anti-aimbot angles", "\aBA55D3FFexport", function()
            local config = { 
                anti_aim = {}, 
                resolver = {}, 
                visuals = {}, 
                misc = {} 
            }
    
            for k, v in pairs(menu["anti-aim"]) do
                if type(v) == "number" then 
                    local v1, v2 = ui.get(v)
                    config.anti_aim[k] = v2 ~= nil and {v1, v2} or v1
                elseif k == "builder" and type(v) == "table" then
                    config.anti_aim.builder = {}
                    for sub_k, sub_v in pairs(v) do
                        if type(sub_v) == "number" then 
                            local v1, v2 = ui.get(sub_v)
                            config.anti_aim.builder[sub_k] = v2 ~= nil and {v1, v2} or v1
                        elseif sub_k == "states" and type(sub_v) == "table" then
                            config.anti_aim.builder.states = {}
                            for state, state_v in pairs(sub_v) do
                                config.anti_aim.builder.states[state] = {}
                                for category, category_v in pairs(state_v) do
                                    config.anti_aim.builder.states[state][category] = {}
                                    for setting, setting_v in pairs(category_v) do
                                        if type(setting_v) == "number" then
                                            local v1, v2 = ui.get(setting_v)
                                            config.anti_aim.builder.states[state][category][setting] = v2 ~= nil and {v1, v2} or v1
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
    
            for k, v in pairs(menu["resolver"]) do
                if type(v) == "number" then 
                    local v1, v2 = ui.get(v)
                    config.resolver[k] = v2 ~= nil and {v1, v2} or v1
                elseif k == "builder" and type(v) == "table" then
                    config.resolver.builder = {}
                    for sub_k, sub_v in pairs(v) do
                        if type(sub_v) == "number" then 
                            local v1, v2 = ui.get(sub_v)
                            config.resolver.builder[sub_k] = v2 ~= nil and {v1, v2} or v1
                        elseif type(sub_v) == "table" then 
                            config.resolver.builder[sub_k] = {}
                            for sub_sub_k, sub_sub_v in pairs(sub_v) do
                                if type(sub_sub_v) == "number" then 
                                    local v1, v2 = ui.get(sub_sub_v)
                                    config.resolver.builder[sub_k][sub_sub_k] = v2 ~= nil and {v1, v2} or v1
                                end
                            end
                        end
                    end
                end
            end
    
            for k, v in pairs(menu["visuals"]) do
                if type(v) == "number" then 
                    local v1, v2 = ui.get(v)
                    config.visuals[k] = v2 ~= nil and {v1, v2} or v1
                end
            end
    
            for k, v in pairs(menu["misc"]) do
                if type(v) == "number" then 
                    local v1, v2 = ui.get(v)
                    config.misc[k] = v2 ~= nil and {v1, v2} or v1
                elseif type(v) == "table" then 
                    config.misc[k] = {}
                    for sub_k, sub_v in pairs(v) do
                        if type(sub_v) == "number" then
                            local v1, v2 = ui.get(sub_v)
                            config.misc[k][sub_k] = v2 ~= nil and {v1, v2} or v1
                        end
                    end
                end
            end
    
            local json_str = json.stringify(config)
            local b64_str = b64.encode(json_str)
            local export_str = "INSANITY " .. b64_str
            clipboard.export(export_str)
            client.color_log(221, 160, 221, "[Insanity] Configuration exported to clipboard successfully")
        end),
    
        import = ui.new_button("aa", "anti-aimbot angles", "\aDDA0DDFFimport", function()
            local config_str = clipboard.import()
            if config_str ~= "" and config_str:find("^INSANITY ") then
                local b64_str = config_str:sub(10)
                local json_str = b64.decode(b64_str)
                local success, config = pcall(json.parse, json_str)
                if success then
                    for k, v in pairs(config.anti_aim or {}) do
                        if menu["anti-aim"][k] and type(menu["anti-aim"][k]) == "number" then
                            ui.set(menu["anti-aim"][k], type(v) == "table" and unpack(v) or v)
                        elseif k == "builder" and type(v) == "table" then
                            for sub_k, sub_v in pairs(v) do
                                if menu["anti-aim"].builder[sub_k] and type(menu["anti-aim"].builder[sub_k]) == "number" then
                                    ui.set(menu["anti-aim"].builder[sub_k], type(sub_v) == "table" and unpack(sub_v) or sub_v)
                                elseif sub_k == "states" and type(sub_v) == "table" then
                                    for state, state_v in pairs(sub_v) do
                                        if menu["anti-aim"].builder.states[state] then
                                            for category, category_v in pairs(state_v) do
                                                if menu["anti-aim"].builder.states[state][category] then
                                                    for setting, setting_v in pairs(category_v) do
                                                        if menu["anti-aim"].builder.states[state][category][setting] and type(menu["anti-aim"].builder.states[state][category][setting]) == "number" then
                                                            ui.set(menu["anti-aim"].builder.states[state][category][setting], type(setting_v) == "table" and unpack(setting_v) or setting_v)
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
    
                    for k, v in pairs(config.resolver or {}) do
                        if menu["resolver"][k] and type(menu["resolver"][k]) == "number" then
                            ui.set(menu["resolver"][k], type(v) == "table" and unpack(v) or v)
                        elseif k == "builder" and type(v) == "table" then
                            for sub_k, sub_v in pairs(v) do
                                if menu["resolver"].builder[sub_k] then
                                    if type(sub_v) == "table" then
                                        if type(menu["resolver"].builder[sub_k]) == "number" then
                                            ui.set(menu["resolver"].builder[sub_k], unpack(sub_v))
                                        else
                                            for sub_sub_k, sub_sub_v in pairs(sub_v) do
                                                if menu["resolver"].builder[sub_k][sub_sub_k] and type(menu["resolver"].builder[sub_k][sub_sub_k]) == "number" then
                                                    ui.set(menu["resolver"].builder[sub_k][sub_sub_k], type(sub_sub_v) == "table" and unpack(sub_sub_v) or sub_sub_v)
                                                end
                                            end
                                        end
                                    elseif type(menu["resolver"].builder[sub_k]) == "number" then
                                        ui.set(menu["resolver"].builder[sub_k], sub_v)
                                    end
                                end
                            end
                        end
                    end
    
                    for k, v in pairs(config.visuals or {}) do
                        if menu["visuals"][k] and type(menu["visuals"][k]) == "number" then
                            ui.set(menu["visuals"][k], type(v) == "table" and unpack(v) or v)
                        end
                    end
    
                    for k, v in pairs(config.misc or {}) do
                        if menu["misc"][k] and type(menu["misc"][k]) == "number" then
                            ui.set(menu["misc"][k], type(v) == "table" and unpack(v) or v)
                        elseif type(v) == "table" then
                            for sub_k, sub_v in pairs(v) do
                                if menu["misc"][k] and menu["misc"][k][sub_k] and type(menu["misc"][k][sub_k]) == "number" then
                                    ui.set(menu["misc"][k][sub_k], type(sub_v) == "table" and unpack(sub_v) or sub_v)
                                end
                            end
                        end
                    end
    
                    client.color_log(186, 85, 211, "[Insanity] Configuration imported from clipboard successfully")
                else
                    client.color_log(186, 85, 211, "[Insanity] Failed to decode configuration: " .. tostring(config))
                end
            else
                client.color_log(186, 85, 211, "[Insanity] No valid configuration found in clipboard")
            end
        end)
    }
    
    menu["anti-aim"] = {
        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "Enable Anti-Aim Builder"),
        mode = ui.new_combobox("AA", "Anti-aimbot angles", "Anti-Aim Preset", {"default", "better defensive", "jitter", "unpredictable", "random", "aa builder"}),
        states = ui.new_combobox("AA", "Anti-aimbot angles", "State", {"Standing", "Walking", "Crouch", "Air", "Crouch Moving", "Air Crouch"}),
        builder = {
            state = ui.new_combobox("AA", "Anti-aimbot angles", "State", {"Standing", "Walking", "Crouch", "Air", "Crouch Moving", "Air Crouch"}),
            subgroup = ui.new_combobox("AA", "Anti-aimbot angles", "Subgroup", {"Pitch", "Yaw", "Jitter", "Body Yaw", "Conditions", "Defensive", "Flick", "Fake Lag"}),
            spacer = ui.new_label("AA", "Anti-aimbot angles", "⠀"),
            states = {
                ["Standing"] = {
                    pitch = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Pitch Enabled"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Standing] Pitch Mode", {"Default", "Down", "Up", "Minimal", "Custom", "Dynamic"}),
                        custom_value = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Custom Pitch", -89, 89, 0, true, "°"),
                        randomize = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Randomize Pitch"),
                        random_range = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Random Range", 0, 89, 10, true, "°"),
                        velocity_influence = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Velocity Influence", 0, 100, 0, true, "%")
                    },
                    yaw = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Yaw Enabled"),
                        base = ui.new_combobox("AA", "Anti-aimbot angles", "[Standing] Yaw Base", {"Local view", "At targets"}),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Standing] Yaw Mode", {"Static", "Cycle", "Dynamic"}),
                        static_value = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Static Yaw", -180, 180, 0, true, "°"),
                        frequency = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Dynamic Frequency", 10, 200, 50, true, "%"),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Dynamic Amplitude", 0, 180, 60, true, "°"),
                        velocity_aware = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Velocity Aware"),
                        velocity_threshold = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Velocity Threshold", 10, 300, 50, true, "u/s")
                    },
                    jitter = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Jitter Enabled"),
                        type = ui.new_combobox("AA", "Anti-aimbot angles", "[Standing] Jitter Type", {"Off", "Offset", "Center"}),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Jitter Amplitude", 0, 90, 30, true, "°"),
                        sync_with_tick = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Sync with Tick")
                    },
                    body_yaw = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Body Yaw Enabled"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Standing] Body Yaw Mode", {"Off", "Static", "Opposite", "Dynamic"}),
                        static_value = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Static Body Yaw", -180, 180, 0, true, "°"),
                        invert = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Invert Body Yaw"),
                        velocity_factor = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Velocity Factor", 0, 100, 25, true, "%"),
                        enemy_aware = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Enemy-Aware Adjustment")
                    },
                    conditions = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Conditions Enabled"),
                        air_yaw_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Air Yaw Offset", -180, 180, 0, true, "°"),
                        velocity_yaw_shift = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Velocity Yaw Shift", -90, 90, 30, true, "°"),
                        enemy_visible = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] On Enemy Visible"),
                        yaw_adjustment = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Yaw Adjustment", -90, 90, 0, true, "°"),
                        wall_yaw_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Wall Yaw Offset", -180, 180, 90, true, "°"),
                        near_wall = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Near Wall"),
                        wall_distance = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Wall Distance", 50, 300, 100, true, "u")
                    },
                    defensive = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Defensive Enabled"),
                        random_shift = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Random Shift"),
                        random_shift_max = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Random Shift Max", 0, 90, 30, true, "°"),
                        dt_defense = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Double Tap Defense")
                    },
                    flick = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Flick Enabled"),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Flick Amplitude", 10, 180, 60, true, "°"),
                        interval = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Flick Interval", 1, 20, 5, true, "ticks"),
                        random_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Random Offset", 0, 90, 20, true, "°"),
                        condition = ui.new_combobox("AA", "Anti-aimbot angles", "[Standing] Flick Condition", {"Always", "On Shot", "On Miss"})
                    },
                    fake_lag = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Standing] Fake Lag Enabled"),
                        limit = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Fake Lag Limit", 1, 14, 10, true, "ticks"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Standing] Fake Lag Mode", {"Static", "Adaptive", "Random"}),
                        variance = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Fake Lag Variance", 0, 100, 0, true, "%"),
                        adaptive_factor = ui.new_slider("AA", "Anti-aimbot angles", "[Standing] Adaptive Factor", 0, 100, 50, true, "%")
                    }
                },
                ["Walking"] = {
                    pitch = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Pitch Enabled"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Walking] Pitch Mode", {"Default", "Down", "Up", "Minimal", "Custom", "Dynamic"}),
                        custom_value = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Custom Pitch", -89, 89, 0, true, "°"),
                        randomize = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Randomize Pitch"),
                        random_range = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Random Range", 0, 89, 10, true, "°"),
                        velocity_influence = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Velocity Influence", 0, 100, 0, true, "%")
                    },
                    yaw = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Yaw Enabled"),
                        base = ui.new_combobox("AA", "Anti-aimbot angles", "[Walking] Yaw Base", {"Local view", "At targets"}),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Walking] Yaw Mode", {"Static", "Cycle", "Dynamic"}),
                        static_value = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Static Yaw", -180, 180, 0, true, "°"),
                        frequency = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Dynamic Frequency", 10, 200, 50, true, "%"),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Dynamic Amplitude", 0, 180, 60, true, "°"),
                        velocity_aware = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Velocity Aware"),
                        velocity_threshold = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Velocity Threshold", 10, 300, 50, true, "u/s")
                    },
                    jitter = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Jitter Enabled"),
                        type = ui.new_combobox("AA", "Anti-aimbot angles", "[Walking] Jitter Type", {"Off", "Offset", "Center"}),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Jitter Amplitude", 0, 90, 30, true, "°"),
                        sync_with_tick = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Sync with Tick")
                    },
                    body_yaw = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Body Yaw Enabled"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Walking] Body Yaw Mode", {"Off", "Static", "Opposite", "Dynamic"}),
                        static_value = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Static Body Yaw", -180, 180, 0, true, "°"),
                        invert = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Invert Body Yaw"),
                        velocity_factor = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Velocity Factor", 0, 100, 25, true, "%"),
                        enemy_aware = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Enemy-Aware Adjustment")
                    },
                    conditions = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Conditions Enabled"),
                        air_yaw_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Air Yaw Offset", -180, 180, 0, true, "°"),
                        velocity_yaw_shift = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Velocity Yaw Shift", -90, 90, 30, true, "°"),
                        wall_yaw_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Wall Yaw Offset", -180, 180, 90, true, "°"),
                        enemy_visible = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] On Enemy Visible"),
                        yaw_adjustment = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Yaw Adjustment", -90, 90, 0, true, "°"),
                        near_wall = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Near Wall"),
                        wall_distance = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Wall Distance", 50, 300, 100, true, "u")
                    },
                    defensive = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Defensive Enabled"),
                        random_shift = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Random Shift"),
                        random_shift_max = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Random Shift Max", 0, 90, 30, true, "°"),
                        dt_defense = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Double Tap Defense")
                    },
                    flick = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Flick Enabled"),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Flick Amplitude", 10, 180, 60, true, "°"),
                        interval = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Flick Interval", 1, 20, 5, true, "ticks"),
                        random_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Random Offset", 0, 90, 20, true, "°"),
                        condition = ui.new_combobox("AA", "Anti-aimbot angles", "[Walking] Flick Condition", {"Always", "On Shot", "On Miss"})
                    },
                    fake_lag = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Walking] Fake Lag Enabled"),
                        limit = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Fake Lag Limit", 1, 14, 10, true, "ticks"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Walking] Fake Lag Mode", {"Static", "Adaptive", "Random"}),
                        variance = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Fake Lag Variance", 0, 100, 0, true, "%"),
                        adaptive_factor = ui.new_slider("AA", "Anti-aimbot angles", "[Walking] Adaptive Factor", 0, 100, 50, true, "%")
                    }
                },
                ["Crouch"] = {
                    pitch = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Pitch Enabled"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch] Pitch Mode", {"Default", "Down", "Up", "Minimal", "Custom", "Dynamic"}),
                        custom_value = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Custom Pitch", -89, 89, 0, true, "°"),
                        randomize = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Randomize Pitch"),
                        random_range = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Random Range", 0, 89, 10, true, "°"),
                        velocity_influence = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Velocity Influence", 0, 100, 0, true, "%")
                    },
                    yaw = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Yaw Enabled"),
                        base = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch] Yaw Base", {"Local view", "At targets"}),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch] Yaw Mode", {"Static", "Cycle", "Dynamic"}),
                        static_value = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Static Yaw", -180, 180, 0, true, "°"),
                        frequency = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Dynamic Frequency", 10, 200, 50, true, "%"),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Dynamic Amplitude", 0, 180, 60, true, "°"),
                        velocity_aware = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Velocity Aware"),
                        velocity_threshold = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Velocity Threshold", 10, 300, 50, true, "u/s")
                    },
                    jitter = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Jitter Enabled"),
                        type = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch] Jitter Type", {"Off", "Offset", "Center"}),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Jitter Amplitude", 0, 90, 30, true, "°"),
                        sync_with_tick = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Sync with Tick")
                    },
                    body_yaw = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Body Yaw Enabled"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch] Body Yaw Mode", {"Off", "Static", "Opposite", "Dynamic"}),
                        static_value = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Static Body Yaw", -180, 180, 0, true, "°"),
                        invert = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Invert Body Yaw"),
                        velocity_factor = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Velocity Factor", 0, 100, 25, true, "%"),
                        enemy_aware = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Enemy-Aware Adjustment")
                    },
                    conditions = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Conditions Enabled"),
                        air_yaw_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Air Yaw Offset", -180, 180, 0, true, "°"),
                        velocity_yaw_shift = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Velocity Yaw Shift", -90, 90, 30, true, "°"),
                        wall_yaw_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Wall Yaw Offset", -180, 180, 90, true, "°"),
                        enemy_visible = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] On Enemy Visible"),
                        yaw_adjustment = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Yaw Adjustment", -90, 90, 0, true, "°"),
                        near_wall = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Near Wall"),
                        wall_distance = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Wall Distance", 50, 300, 100, true, "u")
                    },
                    defensive = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Defensive Enabled"),
                        random_shift = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Random Shift"),
                        random_shift_max = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Random Shift Max", 0, 90, 30, true, "°"),
                        dt_defense = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Double Tap Defense")
                    },
                    flick = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Flick Enabled"),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Flick Amplitude", 10, 180, 60, true, "°"),
                        interval = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Flick Interval", 1, 20, 5, true, "ticks"),
                        random_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Random Offset", 0, 90, 20, true, "°"),
                        condition = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch] Flick Condition", {"Always", "On Shot", "On Miss"})
                    },
                    fake_lag = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch] Fake Lag Enabled"),
                        limit = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Fake Lag Limit", 1, 14, 10, true, "ticks"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch] Fake Lag Mode", {"Static", "Adaptive", "Random"}),
                        variance = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Fake Lag Variance", 0, 100, 0, true, "%"),
                        adaptive_factor = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch] Adaptive Factor", 0, 100, 50, true, "%")
                    }
                },
                ["Air"] = {
                    pitch = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Pitch Enabled"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Air] Pitch Mode", {"Default", "Down", "Up", "Minimal", "Custom", "Dynamic"}),
                        custom_value = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Custom Pitch", -89, 89, 0, true, "°"),
                        randomize = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Randomize Pitch"),
                        random_range = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Random Range", 0, 89, 10, true, "°"),
                        velocity_influence = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Velocity Influence", 0, 100, 0, true, "%")
                    },
                    yaw = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Yaw Enabled"),
                        base = ui.new_combobox("AA", "Anti-aimbot angles", "[Air] Yaw Base", {"Local view", "At targets"}),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Air] Yaw Mode", {"Static", "Cycle", "Dynamic"}),
                        static_value = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Static Yaw", -180, 180, 0, true, "°"),
                        frequency = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Dynamic Frequency", 10, 200, 50, true, "%"),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Dynamic Amplitude", 0, 180, 60, true, "°"),
                        velocity_aware = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Velocity Aware"),
                        velocity_threshold = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Velocity Threshold", 10, 300, 50, true, "u/s")
                    },
                    jitter = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Jitter Enabled"),
                        type = ui.new_combobox("AA", "Anti-aimbot angles", "[Air] Jitter Type", {"Off", "Offset", "Center"}),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Jitter Amplitude", 0, 90, 30, true, "°"),
                        sync_with_tick = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Sync with Tick")
                    },
                    body_yaw = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Body Yaw Enabled"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Air] Body Yaw Mode", {"Off", "Static", "Opposite", "Dynamic"}),
                        static_value = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Static Body Yaw", -180, 180, 0, true, "°"),
                        invert = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Invert Body Yaw"),
                        velocity_factor = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Velocity Factor", 0, 100, 25, true, "%"),
                        enemy_aware = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Enemy-Aware Adjustment")
                    },
                    conditions = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Conditions Enabled"),
                        air_yaw_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Air Yaw Offset", -180, 180, 0, true, "°"),
                        velocity_yaw_shift = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Velocity Yaw Shift", -90, 90, 30, true, "°"),
                        wall_yaw_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Wall Yaw Offset", -180, 180, 90, true, "°"),
                        enemy_visible = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] On Enemy Visible"),
                        yaw_adjustment = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Yaw Adjustment", -90, 90, 0, true, "°"),
                        near_wall = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Near Wall"),
                        wall_distance = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Wall Distance", 50, 300, 100, true, "u")
                    },
                    defensive = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Defensive Enabled"),
                        random_shift = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Random Shift"),
                        random_shift_max = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Random Shift Max", 0, 90, 30, true, "°"),
                        dt_defense = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Double Tap Defense")
                    },
                    flick = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Flick Enabled"),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Flick Amplitude", 10, 180, 60, true, "°"),
                        interval = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Flick Interval", 1, 20, 5, true, "ticks"),
                        random_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Random Offset", 0, 90, 20, true, "°"),
                        condition = ui.new_combobox("AA", "Anti-aimbot angles", "[Air] Flick Condition", {"Always", "On Shot", "On Miss"})
                    },
                    fake_lag = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air] Fake Lag Enabled"),
                        limit = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Fake Lag Limit", 1, 14, 10, true, "ticks"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Air] Fake Lag Mode", {"Static", "Adaptive", "Random"}),
                        variance = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Fake Lag Variance", 0, 100, 0, true, "%"),
                        adaptive_factor = ui.new_slider("AA", "Anti-aimbot angles", "[Air] Adaptive Factor", 0, 100, 50, true, "%")
                    }
                },
                ["Crouch Moving"] = {
                    pitch = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Pitch Enabled"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch Moving] Pitch Mode", {"Default", "Down", "Up", "Minimal", "Custom", "Dynamic"}),
                        custom_value = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Custom Pitch", -89, 89, 0, true, "°"),
                        randomize = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Randomize Pitch"),
                        random_range = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Random Range", 0, 89, 10, true, "°"),
                        velocity_influence = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Velocity Influence", 0, 100, 0, true, "%")
                    },
                    yaw = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Yaw Enabled"),
                        base = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch Moving] Yaw Base", {"Local view", "At targets"}),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch Moving] Yaw Mode", {"Static", "Cycle", "Dynamic"}),
                        static_value = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Static Yaw", -180, 180, 0, true, "°"),
                        frequency = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Dynamic Frequency", 10, 200, 50, true, "%"),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Dynamic Amplitude", 0, 180, 60, true, "°"),
                        velocity_aware = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Velocity Aware"),
                        velocity_threshold = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Velocity Threshold", 10, 300, 50, true, "u/s")
                    },
                    jitter = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Jitter Enabled"),
                        type = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch Moving] Jitter Type", {"Off", "Offset", "Center"}),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Jitter Amplitude", 0, 90, 30, true, "°"),
                        sync_with_tick = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Sync with Tick")
                    },
                    body_yaw = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Body Yaw Enabled"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch Moving] Body Yaw Mode", {"Off", "Static", "Opposite", "Dynamic"}),
                        static_value = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Static Body Yaw", -180, 180, 0, true, "°"),
                        invert = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Invert Body Yaw"),
                        velocity_factor = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Velocity Factor", 0, 100, 25, true, "%"),
                        enemy_aware = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Enemy-Aware Adjustment")
                    },
                    conditions = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Conditions Enabled"),
                        air_yaw_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Air Yaw Offset", -180, 180, 0, true, "°"),
                        velocity_yaw_shift = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Velocity Yaw Shift", -90, 90, 30, true, "°"),
                        wall_yaw_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Wall Yaw Offset", -180, 180, 90, true, "°"),
                        enemy_visible = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] On Enemy Visible"),
                        yaw_adjustment = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Yaw Adjustment", -90, 90, 0, true, "°"),
                        near_wall = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Near Wall"),
                        wall_distance = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Wall Distance", 50, 300, 100, true, "u")
                    },
                    defensive = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Defensive Enabled"),
                        random_shift = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Random Shift"),
                        random_shift_max = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Random Shift Max", 0, 90, 30, true, "°"),
                        dt_defense = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Double Tap Defense")
                    },
                    flick = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Flick Enabled"),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Flick Amplitude", 10, 180, 60, true, "°"),
                        interval = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Flick Interval", 1, 20, 5, true, "ticks"),
                        random_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Random Offset", 0, 90, 20, true, "°"),
                        condition = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch Moving] Flick Condition", {"Always", "On Shot", "On Miss"})
                    },
                    fake_lag = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Crouch Moving] Fake Lag Enabled"),
                        limit = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Fake Lag Limit", 1, 14, 10, true, "ticks"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Crouch Moving] Fake Lag Mode", {"Static", "Adaptive", "Random"}),
                        variance = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Fake Lag Variance", 0, 100, 0, true, "%"),
                        adaptive_factor = ui.new_slider("AA", "Anti-aimbot angles", "[Crouch Moving] Adaptive Factor", 0, 100, 50, true, "%")
                    }
                },
                ["Air Crouch"] = {
                    pitch = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Pitch Enabled"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Air Crouching] Pitch Mode", {"Default", "Down", "Up", "Minimal", "Custom", "Dynamic"}),
                        custom_value = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Custom Pitch", -89, 89, 0, true, "°"),
                        randomize = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Randomize Pitch"),
                        random_range = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Random Range", 0, 89, 10, true, "°"),
                        velocity_influence = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Velocity Influence", 0, 100, 0, true, "%")
                    },
                    yaw = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Yaw Enabled"),
                        base = ui.new_combobox("AA", "Anti-aimbot angles", "[Air Crouching] Yaw Base", {"Local view", "At targets"}),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Air Crouching] Yaw Mode", {"Static", "Cycle", "Dynamic"}),
                        static_value = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Static Yaw", -180, 180, 0, true, "°"),
                        frequency = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Dynamic Frequency", 10, 200, 50, true, "%"),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Dynamic Amplitude", 0, 180, 60, true, "°"),
                        velocity_aware = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Velocity Aware"),
                        velocity_threshold = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Velocity Threshold", 10, 300, 50, true, "u/s")
                    },
                    jitter = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Jitter Enabled"),
                        type = ui.new_combobox("AA", "Anti-aimbot angles", "[Air Crouching] Jitter Type", {"Off", "Offset", "Center"}),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Jitter Amplitude", 0, 90, 30, true, "°"),
                        sync_with_tick = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Sync with Tick")
                    },
                    body_yaw = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Body Yaw Enabled"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Air Crouching] Body Yaw Mode", {"Off", "Static", "Opposite", "Dynamic"}),
                        static_value = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Static Body Yaw", -180, 180, 0, true, "°"),
                        invert = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Invert Body Yaw"),
                        velocity_factor = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Velocity Factor", 0, 100, 25, true, "%"),
                        enemy_aware = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Enemy-Aware Adjustment")
                    },
                    conditions = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Conditions Enabled"),
                        air_yaw_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Air Yaw Offset", -180, 180, 0, true, "°"),
                        velocity_yaw_shift = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Velocity Yaw Shift", -90, 90, 30, true, "°"),
                        wall_yaw_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Wall Yaw Offset", -180, 180, 90, true, "°"),
                        enemy_visible = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] On Enemy Visible"),
                        yaw_adjustment = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Yaw Adjustment", -90, 90, 0, true, "°"),
                        near_wall = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Near Wall"),
                        wall_distance = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Wall Distance", 50, 300, 100, true, "u")
                    },
                    defensive = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Defensive Enabled"),
                        random_shift = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Random Shift"),
                        random_shift_max = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Random Shift Max", 0, 90, 30, true, "°"),
                        dt_defense = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Double Tap Defense")
                    },
                    flick = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Flick Enabled"),
                        amplitude = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Flick Amplitude", 10, 180, 60, true, "°"),
                        interval = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Flick Interval", 1, 20, 5, true, "ticks"),
                        random_offset = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Random Offset", 0, 90, 20, true, "°"),
                        condition = ui.new_combobox("AA", "Anti-aimbot angles", "[Air Crouching] Flick Condition", {"Always", "On Shot", "On Miss"})
                    },
                    fake_lag = {
                        enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "[Air Crouching] Fake Lag Enabled"),
                        limit = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Fake Lag Limit", 1, 14, 10, true, "ticks"),
                        mode = ui.new_combobox("AA", "Anti-aimbot angles", "[Air Crouching] Fake Lag Mode", {"Static", "Adaptive", "Random"}),
                        variance = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Fake Lag Variance", 0, 100, 0, true, "%"),
                        adaptive_factor = ui.new_slider("AA", "Anti-aimbot angles", "[Air Crouching] Adaptive Factor", 0, 100, 50, true, "%")
                    }
                }
            }
        }
    }
    
    menu["resolver"] = {
        preset = ui.new_combobox("aa", "anti-aimbot angles", "\aBA55D3FFpreset", {"default", "bruteforce", "logic", "smart", "extra", "resolver builder"}),
        builder = {
            subgroup = ui.new_combobox("aa", "anti-aimbot angles", "\aBA55D3FFBuilder Settings", {
                "Velocity", "Animations", "History", "Miss", "Jitter", "Defensive", "Hitbox", "Double Tap", 
                "Distance", "Weapon Awareness", "Prediction", "Latency Compensation", "Override"
            }),
            spacer = ui.new_label("aa", "anti-aimbot angles", "⠀"),
            
            
            Velocity = {
                enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable Velocity Adjustment"),
                factor = ui.new_slider("aa", "anti-aimbot angles", "Velocity Factor", 0, 100, 50, true, "%"),
                threshold = ui.new_slider("aa", "anti-aimbot angles", "Velocity Threshold", 10, 300, 30, true, "u/s"),
                invert = ui.new_checkbox("aa", "anti-aimbot angles", "Invert Direction"),
                wall_aware = ui.new_checkbox("aa", "anti-aimbot angles", "Wall-Aware Adjustment"),
                max_adjustment = ui.new_slider("aa", "anti-aimbot angles", "Max Adjustment", 10, 90, 60, true, "°"),
                spike_factor = ui.new_slider("aa", "anti-aimbot angles", "Spike Factor", 0, 100, 20, true, "%")
            },
    
            
            Animations = {
                enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable Animation Adjustment"),
                mode = ui.new_combobox("aa", "anti-aimbot angles", "Animation Mode", {"Static", "Dynamic", "Mixed"}),
                influence = ui.new_slider("aa", "anti-aimbot angles", "Animation Influence", 0, 100, 40, true, "%"),
                threshold = ui.new_slider("aa", "anti-aimbot angles", "Animation Threshold", 5, 60, 15, true, "°"),
                lby_influence = ui.new_slider("aa", "anti-aimbot angles", "LBY Influence", 0, 100, 30, true, "%"),
                choke_influence = ui.new_slider("aa", "anti-aimbot angles", "Choked Ticks Influence", 0, 100, 20, true, "%"),
                smoothing = ui.new_slider("aa", "anti-aimbot angles", "Smoothing Factor", 0, 100, 30, true, "%"),
                boost_factor = ui.new_slider("aa", "anti-aimbot angles", "Boost Factor", 0, 100, 15, true, "%")
            },
    
            
            History = {
                enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable History Adjustment"),
                mode = ui.new_combobox("aa", "anti-aimbot angles", "History Mode", {"Average", "Delta", "Pattern"}),
                depth = ui.new_slider("aa", "anti-aimbot angles", "History Depth", 3, 20, 10, true, "ticks"),
                stability_threshold = ui.new_slider("aa", "anti-aimbot angles", "Stability Threshold", 5, 60, 15, true, "°"),
                invert = ui.new_checkbox("aa", "anti-aimbot angles", "Invert Adjustment"),
                weight_factor = ui.new_slider("aa", "anti-aimbot angles", "Weight Factor", 0, 100, 80, true, "%"),
                jitter_influence = ui.new_slider("aa", "anti-aimbot angles", "Jitter Influence", 0, 100, 10, true, "%")
            },
    
            
            Miss = {
                enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable Miss Adjustment"),
                mode = ui.new_combobox("aa", "anti-aimbot angles", "Miss Mode", {"Shift", "Random", "Cycle"}),
                amplitude = ui.new_slider("aa", "anti-aimbot angles", "Miss Amplitude", 10, 90, 50, true, "°"),
                after_misses = ui.new_slider("aa", "anti-aimbot angles", "After Misses", 1, 5, 1, true),
                invert = ui.new_checkbox("aa", "anti-aimbot angles", "Invert Miss Adjustment"),
                reset_threshold = ui.new_slider("aa", "anti-aimbot angles", "Reset Threshold", 0, 10, 0, true, "misses"),
                scale_factor = ui.new_slider("aa", "anti-aimbot angles", "Scale Factor", 0, 100, 20, true, "%")
            },
    
            
            Jitter = {
                enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable Jitter Adjustment"),
                type = ui.new_combobox("aa", "anti-aimbot angles", "Jitter Type", {"Sine", "Cosine", "Random"}),
                frequency = ui.new_slider("aa", "anti-aimbot angles", "Jitter Frequency", 10, 200, 50, true, "%"),
                amplitude = ui.new_slider("aa", "anti-aimbot angles", "Jitter Amplitude", 0, 60, 25, true, "°"),
                chaos_factor = ui.new_slider("aa", "anti-aimbot angles", "Jitter Chaos", 0, 100, 15, true, "%"),
                sync_with_tick = ui.new_checkbox("aa", "anti-aimbot angles", "Sync with Tick"),
                phase_shift = ui.new_slider("aa", "anti-aimbot angles", "Phase Shift", 0, 100, 0, true, "%")
            },
    
            
            Defensive = {
                enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable Defensive Adjustment"),
                anti_bruteforce = ui.new_checkbox("aa", "anti-aimbot angles", "Anti-Bruteforce"),
                anti_bruteforce_misses = ui.new_slider("aa", "anti-aimbot angles", "Anti-Bruteforce Misses", 1, 5, 2, true),
                random_shift = ui.new_checkbox("aa", "anti-aimbot angles", "Random Shift"),
                random_shift_max = ui.new_slider("aa", "anti-aimbot angles", "Random Shift Max", 10, 90, 50, true, "°"),
                jitter_amplitude = ui.new_slider("aa", "anti-aimbot angles", "Defensive Jitter", 0, 60, 0, true, "°"),
                adaptive_defense = ui.new_checkbox("aa", "anti-aimbot angles", "Adaptive Defense"),
                adaptive_threshold = ui.new_slider("aa", "anti-aimbot angles", "Adaptive Stability Threshold", 5, 60, 20, true, "°"),
                ping_mode = ui.new_combobox("aa", "anti-aimbot angles", "Ping Defense", {"Off", "Low", "High"}),
                edge_detection = ui.new_checkbox("aa", "anti-aimbot angles", "Edge Detection"),
                choke_factor = ui.new_slider("aa", "anti-aimbot angles", "Choke Defense Factor", 0, 100, 25, true, "%")
            },
    
            
            Hitbox = {
                enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable Hitbox Adjustment"),
                mode = ui.new_combobox("aa", "anti-aimbot angles", "Hitbox Mode", {"Static", "Cycle", "Adaptive"}),
                static_hitbox = ui.new_combobox("aa", "anti-aimbot angles", "Static Hitbox", {"Head", "Chest", "Pelvis"}),
                switch_speed = ui.new_slider("aa", "anti-aimbot angles", "Switch Speed", 5, 50, 20, true, "ticks"),
                on_miss = ui.new_checkbox("aa", "anti-aimbot angles", "Switch on Miss (Adaptive)"),
                miss_count = ui.new_slider("aa", "anti-aimbot angles", "Miss Count for Switch", 1, 5, 2, true),
                randomize = ui.new_checkbox("aa", "anti-aimbot angles", "Randomize Hitbox"),
                priority_factor = ui.new_slider("aa", "anti-aimbot angles", "Priority Factor", 0, 100, 50, true, "%")
            },
    
            
            ["Double Tap"] = {
                enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable Double Tap Adjustments"),
                mode = ui.new_combobox("aa", "anti-aimbot angles", "DT Mode", {"Static", "Dynamic", "Random"}),
                shift_amount = ui.new_slider("aa", "anti-aimbot angles", "Shift Amount", 0, 90, 30, true, "°"),
                velocity_boost = ui.new_slider("aa", "anti-aimbot angles", "Velocity Boost", 0, 100, 20, true, "%"),
                choke_adjust = ui.new_slider("aa", "anti-aimbot angles", "Choke Adjustment", 0, 100, 15, true, "%")
            },
    
            
            Distance = {
                enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable Distance Adjustment"),
                min_dist = ui.new_slider("aa", "anti-aimbot angles", "Min Distance", 50, 1000, 200, true, "u", 1),
                max_dist = ui.new_slider("aa", "anti-aimbot angles", "Max Distance", 50, 2000, 1500, true, "u", 1),
                dist_factor = ui.new_slider("aa", "anti-aimbot angles", "Distance Factor", 0, 100, 30, true, "%"),
                close_shift = ui.new_slider("aa", "anti-aimbot angles", "Close Range Shift", -90, 90, 45, true, "°"),
                far_shift = ui.new_slider("aa", "anti-aimbot angles", "Far Range Shift", -90, 90, 15, true, "°")
            },
    
            
            ["Weapon Awareness"] = {
                enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable Weapon Awareness"),
                sniper_adjust = ui.new_slider("aa", "anti-aimbot angles", "Sniper Adjustment", -60, 60, 30, true, "°"),
                pistol_adjust = ui.new_slider("aa", "anti-aimbot angles", "Pistol Adjustment", -60, 60, 15, true, "°"),
                rifle_adjust = ui.new_slider("aa", "anti-aimbot angles", "Rifle Adjustment", -60, 60, 20, true, "°"),
                dynamic_switch = ui.new_checkbox("aa", "anti-aimbot angles", "Dynamic Weapon Switch"),
                switch_speed = ui.new_slider("aa", "anti-aimbot angles", "Switch Speed", 1, 20, 5, true, "ticks")
            },
    
            
            Prediction = {
                enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable Prediction"),
                ticks = ui.new_slider("aa", "anti-aimbot angles", "Prediction Ticks", 1, 12, 6, true, "ticks"),
                accel_factor = ui.new_slider("aa", "anti-aimbot angles", "Acceleration Factor", 0, 100, 25, true, "%"),
                yaw_boost = ui.new_slider("aa", "anti-aimbot angles", "Yaw Boost", -60, 60, 0, true, "°"),
                velocity_scale = ui.new_slider("aa", "anti-aimbot angles", "Velocity Scale", 0, 200, 50, true, "%"),
                wall_aware = ui.new_checkbox("aa", "anti-aimbot angles", "Wall-Aware Prediction")
            },
    
            
            ["Latency Compensation"] = {
                enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable Latency Compensation"),
                ping_threshold = ui.new_slider("aa", "anti-aimbot angles", "Ping Threshold", 20, 200, 50, true, "ms"),
                high_ping_shift = ui.new_slider("aa", "anti-aimbot angles", "High Ping Shift", -90, 90, 30, true, "°"),
                choke_factor = ui.new_slider("aa", "anti-aimbot angles", "Choke Latency Factor", 0, 100, 20, true, "%"),
                smooth_transition = ui.new_checkbox("aa", "anti-aimbot angles", "Smooth Latency Transition")
            },
    
            
            Override = {
                enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable Manual Override"),
                condition = ui.new_combobox("aa", "anti-aimbot angles", "Override Condition", {"Always", "On Miss", "On High Choke", "On Low Stability"}),
                yaw_value = ui.new_slider("aa", "anti-aimbot angles", "Override Yaw", -180, 180, 0, true, "°"),
                miss_threshold = ui.new_slider("aa", "anti-aimbot angles", "Miss Threshold", 1, 5, 2, true),
                choke_threshold = ui.new_slider("aa", "anti-aimbot angles", "Choke Threshold", 3, 14, 5, true),
                stability_threshold = ui.new_slider("aa", "anti-aimbot angles", "Stability Threshold", 5, 60, 20, true, "°")
            }
        }
    }

    menu["visuals"] = {
        watermark = ui.new_checkbox("aa", "anti-aimbot angles", "\aBA55D3FFWatermark")
    }
    
    menu["misc"] = {
        other = {
            justspace = ui.new_label("aa", "anti-aimbot angles", "⠀"),
            Other1 = ui.new_label("aa", "anti-aimbot angles", "Others"),
            StrochkaBlyatO = ui.new_label("aa", "anti-aimbot angles", "\a373737FF‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾"),
            Zeus_Fix = ui.new_checkbox("aa", "anti-aimbot angles", "\aBA55D3FFZeus Fix"),
            smart_backtrack = ui.new_checkbox("aa", "anti-aimbot angles", "\aBA55D3FFSmart Backtrack"),
            trashtalk = ui.new_checkbox("aa", "anti-aimbot angles", "\aBA55D3FFtrashtalk"),
            leg_spammer = ui.new_checkbox("aa", "anti-aimbot angles", "\aBA55D3FFLeg Spammer"),
            spammer = ui.new_slider("aa", "anti-aimbot angles", "\aBA55D3FFLeg Spammer Speed", 1, 9, 1),
            ClanTags = ui.new_checkbox("aa", "anti-aimbot angles", "\aBA55D3FFCustom Clan Tags"),
            ClanTagAnimation = ui.new_combobox("aa", "anti-aimbot angles", "\aBA55D3FFClan Tag Animation", {"Insanity", "Nakiev"}),
            FastLadder = ui.new_checkbox("aa", "anti-aimbot angles", "\aBA55D3FFFast Ladder"),
            Autobuy = ui.new_checkbox("aa", "anti-aimbot angles", "\aBA55D3FFAutobuy"),
            AutobuyWeapon = ui.new_combobox("aa", "anti-aimbot angles", "\aBA55D3FFAutobuy Weapon", {"SSG 08", "AWP", "Auto-Sniper"})
    },
        binds = {
            justspace2 = ui.new_label("aa", "anti-aimbot angles", "⠀"),
            binds = ui.new_label("aa", "anti-aimbot angles", "Binds"),
            StrochkaBlyatO1 = ui.new_label("aa", "anti-aimbot angles", "\a373737FF‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾"),
            freestanding = ui.new_hotkey("aa", "anti-aimbot angles", "\aBA55D3FFFreestanding", false),
            manual_left = ui.new_hotkey("aa", "anti-aimbot angles", "\aBA55D3FFManual Left", false),
            manual_right = ui.new_hotkey("aa", "anti-aimbot angles", "\aBA55D3FFManual Right", false),
            manual_reset = ui.new_hotkey("aa", "anti-aimbot angles", "\aBA55D3FFManual Reset", false)
        }
        
    }

    menu["other"] = {
        socials_label = ui.new_label("aa", "other", "\aBA55D3FFSocials"),
        youtube_button = ui.new_button("aa", "other", "\aBA55D3FFYouTube", function()
            panorama.open("CSGOHud").SteamOverlayAPI.OpenExternalBrowserURL("https://www.youtube.com/@thischanneIdoesnotexist")
        end),
        discord_button = ui.new_button("aa", "other", "\aBA55D3FFDiscord", function()
            panorama.open("CSGOHud").SteamOverlayAPI.OpenExternalBrowserURL("https://discord.gg/hrcuuY4Y2T")
        end),
        telegram_button = ui.new_button("aa", "other", "\aBA55D3FFTelegram", function()
            panorama.open("CSGOHud").SteamOverlayAPI.OpenExternalBrowserURL("https://t.me/insanitylua")
        end),
    }

    menu["fake lag"] = {
        NameVer = ui.new_label("aa", "fake lag", "⠀⠀⠀⠀⠀⠀\aBA55D3FFInsanity | v1.1"),
        Stroka = ui.new_label("aa", "fake lag", "\a373737FF‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾"),
        Changelog = ui.new_label("aa", "fake lag", "⠀⠀⠀⠀⠀⠀Changelog"),
        Realnyoprobel = ui.new_label("aa", "fake lag", "⠀"),
        Clpage1 = ui.new_label("aa", "fake lag", "[+] New AA Builder"),
        Clpage2 = ui.new_label("aa", "fake lag", "[+] New CFG system"),
        Clpage3 = ui.new_label("aa", "fake lag", "[+] New Trashtalk"),
        Clpage4 = ui.new_label("aa", "fake lag", "[+] Resolver Builder"),
        Clpage5 = ui.new_label("aa", "fake lag", "[?] OLD AA Builder >> NEW AA Builder"),
        Clpage6 = ui.new_label("aa", "fake lag", "[-] Enemy"),
        Clpage7 = ui.new_label("aa", "fake lag", "[-] Nakiev.lua(press F)")

    }

    -- дальше бога нет.
    -- даже не знаю что хуже: это или конфиги.

    client.set_event_callback("paint_ui", function()
        if not ui.is_menu_open() then return end
    
        
        for _, v in pairs(tbl.items) do 
            for _, ref in pairs(v) do 
                if type(ref) == "number" then
                    ui.set_visible(ref, false)
                end
            end 
        end
    
        
        local function hide_elements(tbl)
            for _, item in pairs(tbl) do
                if type(item) == "number" then
                    ui.set_visible(item, false)
                elseif type(item) == "table" then
                    hide_elements(item)
                end
            end
        end
    
        hide_elements(menu)
    
        local selected_cat = ui.get(category)
    
        
        if selected_cat == "anti-aim" then
            ui.set_visible(menu["anti-aim"].mode, true)
            local is_aa_builder = ui.get(menu["anti-aim"].mode) == "aa builder"
            ui.set_visible(menu["anti-aim"].builder.state, is_aa_builder)
            ui.set_visible(menu["anti-aim"].builder.subgroup, is_aa_builder)
            ui.set_visible(menu["anti-aim"].builder.spacer, is_aa_builder)
            
            if is_aa_builder then
                local selected_state = ui.get(menu["anti-aim"].builder.state)
                local selected_subgroup = ui.get(menu["anti-aim"].builder.subgroup):lower()
                local state_config = menu["anti-aim"].builder.states[selected_state]
            
                if selected_subgroup == "pitch" then
                    ui.set_visible(state_config.pitch.enabled, true)
                    local pitch_enabled = ui.get(state_config.pitch.enabled)
                    ui.set_visible(state_config.pitch.mode, pitch_enabled)
                    local pitch_mode = ui.get(state_config.pitch.mode)
                    ui.set_visible(state_config.pitch.custom_value, pitch_enabled and pitch_mode == "Custom")
                    ui.set_visible(state_config.pitch.randomize, pitch_enabled)
                    ui.set_visible(state_config.pitch.random_range, pitch_enabled and ui.get(state_config.pitch.randomize))
                    ui.set_visible(state_config.pitch.velocity_influence, pitch_enabled)
            
                elseif selected_subgroup == "yaw" then
                    ui.set_visible(state_config.yaw.enabled, true)
                    local yaw_enabled = ui.get(state_config.yaw.enabled)
                    ui.set_visible(state_config.yaw.base, yaw_enabled)
                    ui.set_visible(state_config.yaw.mode, yaw_enabled)
                    local yaw_mode = ui.get(state_config.yaw.mode)
                    ui.set_visible(state_config.yaw.static_value, yaw_enabled and yaw_mode == "Static")
                    ui.set_visible(state_config.yaw.frequency, yaw_enabled and yaw_mode == "Dynamic")
                    ui.set_visible(state_config.yaw.amplitude, yaw_enabled and yaw_mode == "Dynamic")
                    ui.set_visible(state_config.yaw.velocity_aware, yaw_enabled)
                    ui.set_visible(state_config.yaw.velocity_threshold, yaw_enabled and ui.get(state_config.yaw.velocity_aware))
            
                elseif selected_subgroup == "jitter" then
                    ui.set_visible(state_config.jitter.enabled, true)
                    local jitter_enabled = ui.get(state_config.jitter.enabled)
                    ui.set_visible(state_config.jitter.type, jitter_enabled)
                    local jitter_type = jitter_enabled and ui.get(state_config.jitter.type) ~= "Off"
                    ui.set_visible(state_config.jitter.amplitude, jitter_type)
                    ui.set_visible(state_config.jitter.sync_with_tick, jitter_type)
            
                elseif selected_subgroup == "body yaw" then
                    ui.set_visible(state_config.body_yaw.enabled, true)
                    local body_yaw_enabled = ui.get(state_config.body_yaw.enabled)
                    ui.set_visible(state_config.body_yaw.mode, body_yaw_enabled)
                    local body_yaw_mode = ui.get(state_config.body_yaw.mode)
                    ui.set_visible(state_config.body_yaw.static_value, body_yaw_enabled and body_yaw_mode == "Static")
                    ui.set_visible(state_config.body_yaw.invert, body_yaw_enabled and body_yaw_mode ~= "Off")
                    ui.set_visible(state_config.body_yaw.velocity_factor, body_yaw_enabled and body_yaw_mode ~= "Off")
                    ui.set_visible(state_config.body_yaw.enemy_aware, body_yaw_enabled and body_yaw_mode == "Dynamic")
            
                elseif selected_subgroup == "conditions" then
                    ui.set_visible(state_config.conditions.enabled, true)
                    local conditions_enabled = ui.get(state_config.conditions.enabled)
                    ui.set_visible(state_config.conditions.air_yaw_offset, conditions_enabled)
                    ui.set_visible(state_config.conditions.velocity_yaw_shift, conditions_enabled and ui.get(state_config.conditions.air_yaw_offset) == 0)
                    ui.set_visible(state_config.conditions.enemy_visible, conditions_enabled)
                    local enemy_visible_enabled = conditions_enabled and ui.get(state_config.conditions.enemy_visible)
                    ui.set_visible(state_config.conditions.yaw_adjustment, enemy_visible_enabled)
                    ui.set_visible(state_config.conditions.near_wall, conditions_enabled)
                    local near_wall_enabled = conditions_enabled and ui.get(state_config.conditions.near_wall)
                    ui.set_visible(state_config.conditions.wall_distance, near_wall_enabled)
            
                elseif selected_subgroup == "defensive" then
                    ui.set_visible(state_config.defensive.enabled, true)
                    local defensive_enabled = ui.get(state_config.defensive.enabled)
                    ui.set_visible(state_config.defensive.random_shift, defensive_enabled)
                    ui.set_visible(state_config.defensive.random_shift_max, defensive_enabled and ui.get(state_config.defensive.random_shift))
                    ui.set_visible(state_config.defensive.dt_defense, defensive_enabled)
            
                elseif selected_subgroup == "flick" then
                    ui.set_visible(state_config.flick.enabled, true)
                    local flick_enabled = ui.get(state_config.flick.enabled)
                    ui.set_visible(state_config.flick.amplitude, flick_enabled)
                    ui.set_visible(state_config.flick.interval, flick_enabled)
                    ui.set_visible(state_config.flick.random_offset, flick_enabled)
                    ui.set_visible(state_config.flick.condition, flick_enabled)
            
                elseif selected_subgroup == "fake lag" then
                    ui.set_visible(state_config.fake_lag.enabled, true)
                    local fake_lag_enabled = ui.get(state_config.fake_lag.enabled)
                    ui.set_visible(state_config.fake_lag.limit, fake_lag_enabled)
                    ui.set_visible(state_config.fake_lag.mode, fake_lag_enabled)
                    local fake_lag_mode = ui.get(state_config.fake_lag.mode)
                    ui.set_visible(state_config.fake_lag.variance, fake_lag_enabled and fake_lag_mode == "Random")
                    ui.set_visible(state_config.fake_lag.adaptive_factor, fake_lag_enabled and fake_lag_mode == "Adaptive")
                end
            end
        end
        
        if selected_cat == "resolver" then
            ui.set_visible(menu["resolver"].preset, true)
            local is_builder_active = ui.get(menu["resolver"].preset) == "resolver builder"
            ui.set_visible(menu["resolver"].builder.subgroup, is_builder_active)
            ui.set_visible(menu["resolver"].builder.spacer, is_builder_active)
            
            if is_builder_active then
                local selected_subgroup = ui.get(menu["resolver"].builder.subgroup)
                local subgroup_config = menu["resolver"].builder[selected_subgroup]
                if subgroup_config and type(subgroup_config) == "table" then
                    ui.set_visible(subgroup_config.enabled, true)
                    local enabled = ui.get(subgroup_config.enabled)
        
                    if selected_subgroup == "Velocity" then
                        ui.set_visible(subgroup_config.factor, enabled)
                        ui.set_visible(subgroup_config.threshold, enabled)
                        ui.set_visible(subgroup_config.invert, enabled)
                        ui.set_visible(subgroup_config.wall_aware, enabled)
                        ui.set_visible(subgroup_config.max_adjustment, enabled)
                        ui.set_visible(subgroup_config.spike_factor, enabled)
                    elseif selected_subgroup == "Animations" then
                        ui.set_visible(subgroup_config.mode, enabled)
                        ui.set_visible(subgroup_config.influence, enabled)
                        ui.set_visible(subgroup_config.threshold, enabled)
                        ui.set_visible(subgroup_config.lby_influence, enabled)
                        ui.set_visible(subgroup_config.choke_influence, enabled)
                        ui.set_visible(subgroup_config.smoothing, enabled)
                        ui.set_visible(subgroup_config.boost_factor, enabled)
                    elseif selected_subgroup == "History" then
                        ui.set_visible(subgroup_config.mode, enabled)
                        ui.set_visible(subgroup_config.depth, enabled)
                        ui.set_visible(subgroup_config.stability_threshold, enabled)
                        ui.set_visible(subgroup_config.invert, enabled)
                        ui.set_visible(subgroup_config.weight_factor, enabled)
                        ui.set_visible(subgroup_config.jitter_influence, enabled)
                    elseif selected_subgroup == "Miss" then
                        ui.set_visible(subgroup_config.mode, enabled)
                        ui.set_visible(subgroup_config.amplitude, enabled)
                        ui.set_visible(subgroup_config.after_misses, enabled)
                        ui.set_visible(subgroup_config.invert, enabled)
                        ui.set_visible(subgroup_config.reset_threshold, enabled)
                        ui.set_visible(subgroup_config.scale_factor, enabled)
                    elseif selected_subgroup == "Jitter" then
                        ui.set_visible(subgroup_config.type, enabled)
                        ui.set_visible(subgroup_config.frequency, enabled)
                        ui.set_visible(subgroup_config.amplitude, enabled)
                        ui.set_visible(subgroup_config.chaos_factor, enabled)
                        ui.set_visible(subgroup_config.sync_with_tick, enabled)
                        ui.set_visible(subgroup_config.phase_shift, enabled)
                    elseif selected_subgroup == "Defensive" then
                        ui.set_visible(subgroup_config.anti_bruteforce, enabled)
                        ui.set_visible(subgroup_config.anti_bruteforce_misses, enabled and ui.get(subgroup_config.anti_bruteforce))
                        ui.set_visible(subgroup_config.random_shift, enabled)
                        ui.set_visible(subgroup_config.random_shift_max, enabled and ui.get(subgroup_config.random_shift))
                        ui.set_visible(subgroup_config.jitter_amplitude, enabled)
                        ui.set_visible(subgroup_config.adaptive_defense, enabled)
                        ui.set_visible(subgroup_config.adaptive_threshold, enabled and ui.get(subgroup_config.adaptive_defense))
                        ui.set_visible(subgroup_config.ping_mode, enabled)
                        ui.set_visible(subgroup_config.edge_detection, enabled)
                        ui.set_visible(subgroup_config.choke_factor, enabled)
                    elseif selected_subgroup == "Hitbox" then
                        ui.set_visible(subgroup_config.mode, enabled)
                        local mode = ui.get(subgroup_config.mode)
                        ui.set_visible(subgroup_config.static_hitbox, enabled and mode == "Static")
                        ui.set_visible(subgroup_config.switch_speed, enabled and (mode == "Cycle" or mode == "Adaptive"))
                        ui.set_visible(subgroup_config.on_miss, enabled and mode == "Adaptive")
                        ui.set_visible(subgroup_config.miss_count, enabled and mode == "Adaptive" and ui.get(subgroup_config.on_miss))
                        ui.set_visible(subgroup_config.randomize, enabled)
                        ui.set_visible(subgroup_config.priority_factor, enabled)
                    elseif selected_subgroup == "Double Tap" then
                        ui.set_visible(subgroup_config.mode, enabled)
                        ui.set_visible(subgroup_config.shift_amount, enabled)
                        ui.set_visible(subgroup_config.velocity_boost, enabled)
                        ui.set_visible(subgroup_config.choke_adjust, enabled)
                    elseif selected_subgroup == "Distance" then
                        ui.set_visible(subgroup_config.min_dist, enabled)
                        ui.set_visible(subgroup_config.max_dist, enabled)
                        ui.set_visible(subgroup_config.dist_factor, enabled)
                        ui.set_visible(subgroup_config.close_shift, enabled)
                        ui.set_visible(subgroup_config.far_shift, enabled)
                    elseif selected_subgroup == "Weapon Awareness" then
                        ui.set_visible(subgroup_config.sniper_adjust, enabled)
                        ui.set_visible(subgroup_config.pistol_adjust, enabled)
                        ui.set_visible(subgroup_config.rifle_adjust, enabled)
                        ui.set_visible(subgroup_config.dynamic_switch, enabled)
                        ui.set_visible(subgroup_config.switch_speed, enabled and ui.get(subgroup_config.dynamic_switch))
                    elseif selected_subgroup == "Prediction" then
                        ui.set_visible(subgroup_config.ticks, enabled)
                        ui.set_visible(subgroup_config.accel_factor, enabled)
                        ui.set_visible(subgroup_config.yaw_boost, enabled)
                        ui.set_visible(subgroup_config.velocity_scale, enabled)
                        ui.set_visible(subgroup_config.wall_aware, enabled)
                    elseif selected_subgroup == "Latency Compensation" then
                        ui.set_visible(subgroup_config.ping_threshold, enabled)
                        ui.set_visible(subgroup_config.high_ping_shift, enabled)
                        ui.set_visible(subgroup_config.choke_factor, enabled)
                        ui.set_visible(subgroup_config.smooth_transition, enabled)
                    elseif selected_subgroup == "Override" then
                        ui.set_visible(subgroup_config.condition, enabled)
                        ui.set_visible(subgroup_config.yaw_value, enabled)
                        local condition = ui.get(subgroup_config.condition)
                        ui.set_visible(subgroup_config.miss_threshold, enabled and condition == "On Miss")
                        ui.set_visible(subgroup_config.choke_threshold, enabled and condition == "On High Choke")
                        ui.set_visible(subgroup_config.stability_threshold, enabled and condition == "On Low Stability")
                    end
                end
            end
        end
    
        
        if selected_cat == "visuals" then
            for k, v in pairs(menu["visuals"]) do
                if type(v) == "table" then
                    for sub_k, sub_v in pairs(v) do
                        ui.set_visible(sub_v, true)
                    end
                else
                    ui.set_visible(v, true)
                end
            end
        end
    
        
        if selected_cat == "misc" then
            for sub_k, sub_v in pairs(menu["misc"]) do
                if type(sub_v) == "table" then
                    for sub_sub_k, sub_sub_v in pairs(sub_v) do
                        if sub_k == "exploits" and sub_sub_k == "smart_backtrack" then
                            ui.set_visible(sub_sub_v, true)
                        elseif sub_k == "other" and sub_sub_k == "spammer" then
                            ui.set_visible(sub_sub_v, ui.get(menu["misc"].other.leg_spammer))
                        elseif sub_k == "other" and sub_sub_k == "ClanTagAnimation" then
                            ui.set_visible(sub_sub_v, ui.get(menu["misc"].other.ClanTags)) 
                        elseif sub_k == "other" and sub_sub_k == "AutobuyWeapon" then
                            ui.set_visible(sub_sub_v, ui.get(menu["misc"].other.Autobuy))
                        else
                            ui.set_visible(sub_sub_v, true)
                        end
                    end
                end
            end
        end
    
        
        if selected_cat == "home" then
            for k, v in pairs(menu["home"]) do
                ui.set_visible(v, true)
            end
        end
    
        
        ui.set_visible(menu["other"].socials_label, true)
        ui.set_visible(menu["other"].youtube_button, true)
        ui.set_visible(menu["other"].discord_button, true)
        ui.set_visible(menu["other"].telegram_button, true)
    
        ui.set_visible(menu["fake lag"].NameVer, true)
        ui.set_visible(menu["fake lag"].Stroka, true)
        ui.set_visible(menu["fake lag"].Changelog, true)
        ui.set_visible(menu["fake lag"].Realnyoprobel, true)
        ui.set_visible(menu["fake lag"].Clpage1, true)
        ui.set_visible(menu["fake lag"].Clpage2, true)
        ui.set_visible(menu["fake lag"].Clpage3, true)
        ui.set_visible(menu["fake lag"].Clpage4, true)
        ui.set_visible(menu["fake lag"].Clpage5, true)
        ui.set_visible(menu["fake lag"].Clpage6, true)
        ui.set_visible(menu["fake lag"].Clpage7, true)  
    
        last_cat = selected_cat
        ui.set_visible(tbl.items.roll[1], false)
    end)
end


main({
    ref = function(a, b, c) return { ui.reference(a, b, c) } end,
    extrapolate = function(player, ticks, x, y, z)
        local v = entity.get_prop(player, "m_vecVelocity")
        local vx, vy, vz = v[1], v[2], v[3]
        return x + (vx or 0) * globals.tickinterval() * ticks, y + (vy or 0) * globals.tickinterval() * ticks, z + (vz or 0) * globals.tickinterval() * ticks
    end
})

client.set_event_callback("setup_command", function(cmd)
    handle_manual_and_freestand(cmd)
    apply_anti_aim(cmd)
    other_logic(cmd)
    fast_ladder(cmd)
end)


client.set_event_callback("paint", smart_backtrack)

client.set_event_callback("shutdown", function()
    hooked_vtable[38] = vtable[38]
    pointer[0] = vtable
    for _, v in pairs(tbl.items) do 
        for _, ref in pairs(v) do 
            ui.set_visible(ref, true) 
        end 
    end
    ui.set(tbl.items.enabled[1], true)
    ui.set(tbl.items.pitch[1], "default")
    ui.set(tbl.items.jitter[1], "off")
    ui.set(tbl.items.body[1], "opposite")
    ui.set(tbl.items.roll[1], 0)
    reset_smart_backtrack()
end)

client.color_log(221, 160, 221, "[Insanity] Loading Successfully, Enjoy")

-- я бы мог написать больше комитов, но лучше пойду пилить апдейт, удачной игры!
-- Спасибо за использование луа, я ценю твой выбор <3