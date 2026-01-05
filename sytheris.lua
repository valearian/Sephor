--Sytheris.lua
local vector = require("vector")
local base64 = require("gamesense/base64")
local clipboard = require("gamesense/clipboard")
local c_entity = require("gamesense/entity")
local pui = require("gamesense/pui")

local function animate_gradient_text(text, time, color1, color2)
    local output = {}
    local length = #text
    
    for i = 1, length do
        local progress = (i - 1) / math.max(length - 1, 1)
        local wave = math.abs(math.sin(time * 2 + progress * math.pi * 2))
        
        local r = color1[1] + (color2[1] - color1[1]) * wave
        local g = color1[2] + (color2[2] - color1[2]) * wave
        local b = color1[3] + (color2[3] - color1[3]) * wave
        local a = color1[4] + (color2[4] - color1[4]) * wave
        
        output[#output + 1] = string.format("\a%02x%02x%02x%02x", r, g, b, a)
        output[#output + 1] = text:sub(i, i)
    end
    
    return table.concat(output)
end

local events do
    local event_mt = { } do
        event_mt.__call = function(self, fn, bool)
            local action = bool and client.set_event_callback or client.unset_event_callback
            action(self[1], fn)
        end

        event_mt.set = function(self, fn)
            client.set_event_callback(self[1], fn)
        end

        event_mt.unset = function(self, fn)
            client.unset_event_callback(self[1], fn)
        end

        event_mt.__index = event_mt
    end

    events = setmetatable({}, {
        __index = function (self, index)
            self[index] = setmetatable({index}, event_mt)
            return self[index]
        end,
    })
end

math.clamp = function(x)
    if x == nil then return 0 end
    x = (x % 360 + 360) % 360
    return x > 180 and x - 360 or x
end

lerp = function(a, b, t)
    return a + t * (b - a)
end

local animations = { } do
    animations.max_lerp_low_fps = (1 / 45) * 100
    animations.color_lerp = function(start, end_pos, time)
        local frametime = globals.frametime() * 100
        time = time * math.min(frametime, animations.max_lerp_low_fps)
        return lerp(start, end_pos, time)
    end

    animations.lerp = function(start, end_pos, time)
        if start == end_pos then
            return end_pos
        end

        local frametime = globals.frametime() * 170
        time = time * math.min(frametime, animations.max_lerp_low_fps)

        local val = start + (end_pos - start) * math.clamp(time, 0.01, 1)

        if(math.abs(val - end_pos) < 0.01) then
            return end_pos
        end

        return val
    end

    animations.base_speed = 0.095
    animations._list = {}

    animations.new = function(name, new_value, speed, init)
        speed = speed or animations.base_speed

        local is_color = type(new_value) == "userdata"

        if animations._list[name] == nil then
            animations._list[name] = (init and init) or (is_color and color(255) or 0)
        end

        local interp_func

        if is_color then
            interp_func = animations.color_lerp
        else
            interp_func = animations.lerp
        end

        animations._list[name] = interp_func(animations._list[name], new_value, speed)

        return animations._list[name]
    end
end

local tween=(function()local a={}local b,c,d,e,f,g,h=math.pow,math.sin,math.cos,math.pi,math.sqrt,math.abs,math.asin;local function i(j,k,l,m)return l*j/m+k end;local function n(j,k,l,m)return l*b(j/m,2)+k end;local function o(j,k,l,m)j=j/m*2;if j<1 then return l/2*b(j,2)+k end;return-l/2*((j-1)*(j-3)-1)+k end;local function p(j,k,l,m)if j<m/2 then return o(j*2,k,l/2,m)end;return n(j*2-m,k+l/2,l/2,m)end;local function q(j,k,l,m)return l*b(j/m,3)+k end;local function r(j,k,l,m)return l*(b(j/m-1,3)+1)+k end;local function s(j,k,l,m)j=j/m*2;if j<1 then return l/2*j*j*j+k end;j=j-2;return l/2*(j*j*j+2)+k end;local function t(j,k,l,m)if j<m/2 then return r(j*2,k,l/2,m)end;return q(j*2-m,k+l/2,l/2,m)end;local function u(j,k,l,m)return l*b(j/m,4)+k end;local function v(j,k,l,m)return-l*(b(j/m-1,4)-1)+k end;local function w(j,k,l,m)j=j/m*2;if j<1 then return l/2*b(j,4)+k end;return-l/2*(b(j-2,4)-2)+k end;local function x(j,k,l,m)if j<m/2 then return v(j*2,k,l/2,m)end;return u(j*2-m,k+l/2,l/2,m)end;local function y(j,k,l,m)return l*b(j/m,5)+k end;local function z(j,k,l,m)return l*(b(j/m-1,5)+1)+k end;local function A(j,k,l,m)j=j/m*2;if j<1 then return l/2*b(j,5)+k end;return l/2*(b(j-2,5)+2)+k end;local function B(j,k,l,m)if j<m/2 then return z(j*2,k,l/2,m)end;return y(j*2-m,k+l/2,l/2,m)end;local function C(j,k,l,m)return-l*d(j/m*e/2)+l+k end;local function D(j,k,l,m)return l*c(j/m*e/2)+k end;local function E(j,k,l,m)return-l/2*(d(e*j/m)-1)+k end;local function F(j,k,l,m)if j<m/2 then return D(j*2,k,l/2,m)end;return C(j*2-m,k+l/2,l/2,m)end;local function G(j,k,l,m)if j==0 then return k end;return l*b(2,10*(j/m-1))+k-l*0.001 end;local function H(j,k,l,m)if j==m then return k+l end;return l*1.001*(-b(2,-10*j/m)+1)+k end;local function I(j,k,l,m)if j==0 then return k end;if j==m then return k+l end;j=j/m*2;if j<1 then return l/2*b(2,10*(j-1))+k-l*0.0005 end;return l/2*1.0005*(-b(2,-10*(j-1))+2)+k end;local function J(j,k,l,m)if j<m/2 then return H(j*2,k,l/2,m)end;return G(j*2-m,k+l/2,l/2,m)end;local function K(j,k,l,m)return-l*(f(1-b(j/m,2))-1)+k end;local function L(j,k,l,m)return l*f(1-b(j/m-1,2))+k end;local function M(j,k,l,m)j=j/m*2;if j<1 then return-l/2*(f(1-j*j)-1)+k end;j=j-2;return l/2*(f(1-j*j)+1)+k end;local function N(j,k,l,m)if j<m/2 then return L(j*2,k,l/2,m)end;return K(j*2-m,k+l/2,l/2,m)end;local function O(Q,R,l,m)Q,R=Q or m*0.3,R or 0;if R<g(l)then return Q,l,Q/4 end;return Q,R,Q/(2*e)*h(l/R)end;local function P(j,k,l,m,R,Q)local T;if j==0 then return k end;j=j/m;if j==1 then return k+l end;Q,R,T=O(Q,R,l,m)j=j-1;return-(R*b(2,10*j)*c((j*m-T)*2*e/Q))+k end;local function U(j,k,l,m,R,Q)local T;if j==0 then return k end;j=j/m;if j==1 then return k+l end;Q,R,T=O(Q,R,l,m)return R*b(2,-10*j)*c((j*m-T)*2*e/Q)+l+k end;local function V(j,k,l,m,R,Q)local T;if j==0 then return k end;j=j/m*2;if j==2 then return k+l end;Q,R,T=O(Q,R,l,m)j=j-1;if j<0 then return-0.5*R*b(2,10*j)*c((j*m-T)*2*e/Q)+k end;return R*b(2,-10*j)*c((j*m-T)*2*e/Q)*0.5+l+k end;local function W(j,k,l,m,R,Q)if j<m/2 then return U(j*2,k,l/2,m,R,Q)end;return P(j*2-m,k+l/2,l/2,m,R,Q)end;local function X(j,k,l,m,T)T=T or 1.70158;j=j/m;return l*j*j*((T+1)*j-T)+k end;local function Y(j,k,l,m,T)T=T or 1.70158;j=j/m-1;return l*(j*j*((T+1)*j+T)+1)+k end;local function Z(j,k,l,m,T)T=(T or 1.70158)*1.525;j=j/m*2;if j<1 then return l/2*j*j*((T+1)*j-T)+k end;j=j-2;return l/2*(j*j*((T+1)*j+T)+2)+k end;local function _(j,k,l,m,T)if j<m/2 then return Y(j*2,k,l/2,m,T)end;return X(j*2-m,k+l/2,l/2,m,T)end;local function a0(j,k,l,m)j=j/m;if j<1/2.75 then return l*7.5625*j*j+k end;if j<2/2.75 then j=j-1.5/2.75;return l*(7.5625*j*j+0.75)+k elseif j<2.5/2.75 then j=j-2.25/2.75;return l*(7.5625*j*j+0.9375)+k end;j=j-2.625/2.75;return l*(7.5625*j*j+0.984375)+k end;local function a1(j,k,l,m)return l-a0(m-j,0,l,m)+k end;local function a2(j,k,l,m)if j<m/2 then return a1(j*2,0,l,m)*0.5+k end;return a0(j*2-m,0,l,m)*0.5+l*.5+k end;local function a3(j,k,l,m)if j<m/2 then return a0(j*2,k,l/2,m)end;return a1(j*2-m,k+l/2,l/2,m)end;a.easing={linear=i,inQuad=n,outQuad=o,inOutQuad=p,outInQuad=q,inCubic=r,outCubic=s,inOutCubic=t,outInCubic=u,inQuart=v,outQuart=w,inOutQuart=x,outInQuart=y,inQuint=z,outQuint=A,inOutQuint=B,outInQuint=C,inSine=D,outSine=E,inOutSine=F,outInSine=G,inExpo=H,outExpo=I,inOutExpo=J,outInExpo=K,inCirc=L,outCirc=M,inOutCirc=N,outInCirc=O,inElastic=P,outElastic=U,inOutElastic=V,outInElastic=W,inBack=X,outBack=Y,inOutBack=Z,outInBack=_,inBounce=a1,outBounce=a0,inOutBounce=a2,outInBounce=a3}local function a4(a5,a6,a7)a7=a7 or a6;local a8=getmetatable(a6)if a8 and getmetatable(a5)==nil then setmetatable(a5,a8)end;for a9,aa in pairs(a6)do if type(aa)=="table"then a5[a9]=a4({},aa,a7[a9])else a5[a9]=a7[a9]end end;return a5 end;local function ab(ac,ad,ae)ae=ae or{}local af,ag;for a9,ah in pairs(ad)do af,ag=type(ah),a4({},ae)table.insert(ag,tostring(a9))if af=="number"then assert(type(ac[a9])=="number","Parameter '"..table.concat(ag,"/").."' is missing from subject or isn't a number")elseif af=="table"then ab(ac[a9],ah,ag)else assert(af=="number","Parameter '"..table.concat(ag,"/").."' must be a number or table of numbers")end end end;local function ai(aj,ac,ad,ak)assert(type(aj)=="number"and aj>0,"duration must be a positive number. Was "..tostring(aj))local al=type(ac)assert(al=="table"or al=="userdata","subject must be a table or userdata. Was "..tostring(ac))assert(type(ad)=="table","target must be a table. Was "..tostring(ad))assert(type(ak)=="function","easing must be a function. Was "..tostring(ak))ab(ac,ad)end;local function am(ak)ak=ak or"linear"if type(ak)=="string"then local an=ak;ak=a.easing[an]if type(ak)~="function"then error("The easing function name '"..an.."' is invalid")end end;return ak end;local function ao(ac,ad,ap,aq,aj,ak)local j,k,l,m;for a9,aa in pairs(ad)do if type(aa)=="table"then ao(ac[a9],aa,ap[a9],aq,aj,ak)else j,k,l,m=aq,ap[a9],aa-ap[a9],aj;ac[a9]=ak(j,k,l,m)end end end;local ar={}local as={__index=ar}function ar:set(aq)assert(type(aq)=="number","clock must be a positive number or 0")self.initial=self.initial or a4({},self.target,self.subject)self.clock=aq;if self.clock<=0 then self.clock=0;a4(self.subject,self.initial)elseif self.clock>=self.duration then self.clock=self.duration;a4(self.subject,self.target)else ao(self.subject,self.target,self.initial,self.clock,self.duration,self.easing)end;return self.clock>=self.duration end;function ar:reset()return self:set(0)end;function ar:update(at)assert(type(at)=="number","dt must be a number")return self:set(self.clock+at)end;function a.new(aj,ac,ad,ak)ak=am(ak)ai(aj,ac,ad,ak)return setmetatable({duration=aj,subject=ac,target=ad,easing=ak,clock=0},as)end;return a end)()

local tween_tbl = { }
local tween_data = {
    scoped = 0,
    indicator_alpha = 0,
}

local screen_x, screen_y = client.screen_size()


local drag_system = {
    elements = {},
    dragging = nil,
    drag_start_pos = {x = 0, y = 0},
    last_alpha = 0,
    guide_alpha = 0,
    dot_alpha = 0,
    animate_menu = 0,
    watermark_x = screen_x / 2,
    watermark_y = screen_y - 10
}

function drag_system:get_width()
    local w = self.element.w
    return type(w) == 'function' and w() or w
end

function drag_system:get_height()
    local h = self.element.h
    return type(h) == 'function' and h() or h
end

function drag_system:clamp_position(x, y)
    local screen_w, screen_h = client.screen_size()
    local elem_w, elem_h = self:get_width(), self:get_height()

    x = math.max(10, math.min(x, screen_w - elem_w - 10))
    y = math.max(10, math.min(y, screen_h - elem_h - 10))

    return x, y
end

function drag_system:get_pos()
    local elem_w, elem_h = self:get_width(), self:get_height()
    local x = math.floor(drag_system.watermark_x - elem_w / 2)
    local y = math.floor(drag_system.watermark_y - elem_h / 2)
    
    return x, y
end

function drag_system.new(name, default_x, default_y, drag_axes, align, options)
    local self = setmetatable({}, {__index = drag_system})

    self.name = name
    self.element = {
        default_x = default_x,
        default_y = default_y,
        w = options and (options.w or 60) or 60,
        h = options and (options.h or 20) or 20,
        align_x = options and options.align_x or 'center',
        align_y = options and options.align_y or 'center',
    }

    self.drag_axes = drag_axes:lower()
    self.align = align:lower()
    self.options = {
        show_guides = options and options.show_guides,
        show_highlight = options and options.show_highlight,
        align_left = options and options.align_left,
        align_right = options and options.align_right,
        align_bottom = options and options.align_bottom,
        align_top = options and options.align_top,
        snap_distance = options and options.snap_distance or 15,
        highlight_color = options and options.highlight_color or {150, 150, 150, 80}
    }

    self.hover_progress = 0
    self.click_progress = 0

    table.insert(drag_system.elements, self)
    return self
end

function drag_system:update()
    if not ui.is_menu_open() then return end

    local elem = self.element
    local x, y = self:get_pos()
    local mx, my = ui.mouse_position()
    local mp_x, mp_y = ui.menu_position()
    local ms_w, ms_h = ui.menu_size()
    local screen_w, screen_h = client.screen_size()
    local elem_w, elem_h = self:get_width(), self:get_height()

    if mx >= mp_x and mx <= mp_x + ms_w and my >= mp_y and my <= mp_y + ms_h then
        self.dragging = false
        drag_system.dragging = false
        return
    end

    local is_hovered = mx >= x and mx <= x + elem_w and my >= y and my <= y + elem_h
    self.hover_progress = animations.lerp(self.hover_progress or 0, is_hovered and 1 or 0, 0.2)

    local mouse_left = client.key_state(0x01) == true
    
    if mouse_left then
        if not self.dragging and not drag_system.dragging then
            if is_hovered then
                self.dragging = true
                drag_system.dragging = true
                self.drag_start_pos.x = mx - x
                self.drag_start_pos.y = my - y
                self.click_progress = 0
            end
        elseif self.dragging then
            self.click_progress = animations.lerp(self.click_progress or 0, 1, 0.2)
            
            local new_x = mx - self.drag_start_pos.x
            local new_y = my - self.drag_start_pos.y
            local snap = self.options.snap_distance
            local elem_center_x = new_x + elem_w/2
            local elem_center_y = new_y + elem_h/2

            if self.drag_axes:find('x') then
   
                if self.options.align_left then
                    if math.abs(elem_center_x - 0) < snap then
                        new_x = 0 - elem_w/2 + 10
                    end
                end
                

                if self.options.align_right then
                    if math.abs(elem_center_x - screen_w) < snap then
                        new_x = screen_w - elem_w/2 - 10
                    end
                end
                
 
                if math.abs(elem_center_x - screen_w/2) < snap then
                    new_x = screen_w/2 - elem_w/2
                end
                
                new_x = math.max(10, math.min(new_x, screen_w - elem_w - 10))
                drag_system.watermark_x = new_x + elem_w/2
            end


            if self.drag_axes:find('y') then

                if self.options.align_top then
                    if math.abs(elem_center_y - 0) < snap then
                        new_y = 0 - elem_h/2 + 10
                    end
                end

                if self.options.align_bottom then
                    if math.abs(elem_center_y - screen_h) < snap then
                        new_y = screen_h - elem_h/2 - 10
                    end
                end

                if math.abs(elem_center_y - screen_h/2) < snap then
                    new_y = screen_h/2 - elem_h/2
                end
                
                new_y = math.max(10, math.min(new_y, screen_h - elem_h - 10))
                drag_system.watermark_y = new_y + elem_h/2
            end
        end
    else
        self.click_progress = animations.lerp(self.click_progress or 0, 0, 0.2)
        self.dragging = false
        drag_system.dragging = false
    end
end

function drag_system:draw_guides()
    local x, y = self:get_pos()
    local elem = self.element
    local elem_w, elem_h = self:get_width(), self:get_height()
    local screen_w, screen_h = client.screen_size()

    local menu_open_factor = ui.is_menu_open() and 1 or 0

    local target_guide_alpha = self.dragging and 255 or 0
    self.guide_alpha = animations.lerp(self.guide_alpha or 0, (target_guide_alpha) * menu_open_factor, 0.2)

    local target_dot_alpha = self.dragging and 255 or 0  
    self.dot_alpha = animations.lerp(self.dot_alpha or 0, (target_dot_alpha) * menu_open_factor, 0.2)

    local target_alpha = self.dragging and 120 or 0
    self.last_alpha = animations.lerp(self.last_alpha or 0, (target_alpha) * menu_open_factor, 0.2)

    if self.last_alpha > 1 then
        renderer.rectangle(0, 0, screen_w, screen_h, 0, 0, 0, self.last_alpha)
    end

    if self.options.show_highlight then
        local hc = self.options.highlight_color
        local base_alpha = hc[4] 
        local hover_alpha = base_alpha * (0.5 + self.hover_progress * 0.5)
        local click_alpha = base_alpha * (1 + self.click_progress * 0.3)
        
        local final_alpha = hover_alpha + (click_alpha - hover_alpha) * self.click_progress
        self.animate_menu = animations.lerp(self.animate_menu or 0, (final_alpha) * menu_open_factor, 0.2)
        
        renderer.rectangle(x, y, elem_w, elem_h, hc[1], hc[2], hc[3], self.animate_menu)
    end

    if self.options.show_guides then
        local ga = math.floor(self.guide_alpha)
        local da = math.floor(self.dot_alpha)


        renderer.line(screen_w/2, 0, screen_w/2, screen_h, 255, 255, 255, da * 0.2)
        renderer.circle(screen_w/2, screen_h/2, 255, 255, 255, da, 3, 0, 1)

        renderer.line(0, screen_h/2, screen_w, screen_h/2, 255, 255, 255, da * 0.2)


        if self.options.align_left then
            renderer.circle(10, screen_h/2, 255, 255, 255, da, 3, 0, 1)
            renderer.line(0, screen_h/2, screen_w/4, screen_h/2, 255, 255, 255, da * 0.3)
        end

  
        if self.options.align_right then
            renderer.circle(screen_w - 10, screen_h/2, 255, 255, 255, da, 3, 0, 1)
            renderer.line(screen_w*3/4, screen_h/2, screen_w, screen_h/2, 255, 255, 255, da * 0.3)
        end


        if self.options.align_top then
            renderer.circle(screen_w/2, 10, 255, 255, 255, da, 3, 0, 1)
            renderer.line(screen_w/2, 0, screen_w/2, screen_h/4, 255, 255, 255, da * 0.3)
        end

 
        if self.options.align_bottom then
            renderer.circle(screen_w/2, screen_h - 10, 255, 255, 255, da, 3, 0, 1)
            renderer.line(screen_w/2, screen_h*3/4, screen_w/2, screen_h, 255, 255, 255, da * 0.3)
        end

        
        renderer.circle(elem.default_x, elem.default_y, 255, 255, 255, da, 3, 0, 1)
    end
end

local vars = { } do
    vars.anti_aim = { }

    vars.anti_aim.states = {"Global", "Standing", "Walking", "Jump", "Jump+", "Crouch", "Crouch+", "Slow-walk", "Freestand", "Manual"}
    vars.anti_aim.references = {
        pitch = {'Off', 'Default', 'Up', 'Down', 'Minimal', 'Random'},
        yaw = {'Off', '180', 'Spin', 'Static', '180 Z', 'Crosshair'},
        yaw_base = {"Local view", "At targets"},
        elements = {
            anti_aim = {pui.reference("AA", "Anti-aimbot angles", "Enabled")},
            pitch = {pui.reference("AA", "Anti-aimbot angles", "Pitch")},
            yaw = {pui.reference("AA", "Anti-aimbot angles", "Yaw")},
            yawbase = pui.reference("AA", "Anti-aimbot angles", "Yaw Base"),
            yawjitter = { pui.reference("AA", "Anti-aimbot angles", "Yaw jitter") },
            bodyyaw = { pui.reference("AA", "Anti-aimbot angles", "Body yaw") },
            fs_body_yaw = pui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw"),
            roll = pui.reference("AA", "Anti-aimbot angles", "Roll"),
            freeStand = pui.reference("AA", "Anti-aimbot angles", "Freestanding"),
            edgeyaw = pui.reference("AA", "Anti-aimbot angles", "Edge yaw"),
            fake_duck = pui.reference("RAGE", "Other", "Duck peek assist"),
            slow_motion = pui.reference("AA", "Other", "Slow motion"),
            fake_lag = {
                enabled = pui.reference("AA", "Fake lag", "Enabled"),
                amount = pui.reference("AA", "Fake lag", "Amount"),
                variance = pui.reference("AA", "Fake lag", "Variance"),
                limit = pui.reference("AA", "Fake lag", "Limit"),
            },
            other = {
                leg_movement = pui.reference("AA", "Other", "Leg movement"),
                os_aa = pui.reference("AA", "Other", "On shot anti-aim"),
                fake_peek = pui.reference("AA", "Other", "Fake peek"),
            },
        },
    }

    vars.rage_bot = { }
    vars.rage_bot.references = {
        double_tap = pui.reference('RAGE', 'Aimbot', 'Double tap'),
        hide_shots = pui.reference('AA', 'Other', 'On shot anti-aim'),
        minimum_damage = {pui.reference('RAGE', 'Aimbot', 'Minimum damage')},
        minimum_damage_override = {pui.reference('RAGE', 'Aimbot', 'Minimum damage override')}
    }

    vars.visuals = { }
    vars.visuals.references = {
        scope_overlay = pui.reference('VISUALS', 'Effects', 'Remove scope overlay'),
    }
end

local menu = { } do
    menu.tabs_path = {
        anti_aim = {
            general = pui.group("AA", "Anti-aimbot angles"),
            fake_lag = pui.group("AA", "Fake lag"),
            other = pui.group("AA", "Other"),
        }
    }

    local menu_tabs = {"Home", "Anti-aim", "Other"}
	
	
--------логика стима юзернейма--------
local function get_steam_username()
    local methods = {
        function()
            return panorama.loadstring([[
                return MyPersonaAPI.GetName();
            ]])()
        end,
        function()
            return panorama.loadstring([[
                return FriendsListAPI.GetLocalPlayerName();
            ]])()
        end,
        function()
            local name = entity.get_player_name(entity.get_local_player())
            return name
        end
    }
    
    for _, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result and type(result) == "string" and result ~= "" then
            return result
        end
    end
    
    return "Unknown"
end

local steam_username = get_steam_username()
------------------------------------------

-------логика кастом меню иконки0--------------
local ffi = require("ffi")
local http = require("gamesense/http")

ffi.cdef[[
    typedef struct {
        int x;
        int y;
    } Vec2;
    typedef struct {
        char pad0[0x4];
        int TextureId;
        int TextureOffset;
        char pad1[0x4];
        Vec2 Size;
    } IconTab;
]]

local icon_url = "https://storage.imgbly.com/imgbly/wr9SRs9iNN.png"
local target_width = 32
local target_height = 32
local aa_index = 1  

local tabsptr = ffi.cast("intptr_t*", 0x434799AC + 0x54)
local tabs_array = ffi.cast("int*", tabsptr[0])
local aa_tab = tabs_array[aa_index]
local aa_icon = ffi.cast("IconTab*", aa_tab + 0x7C)


local original = {
    TextureId = aa_icon.TextureId,
    TextureOffset = aa_icon.TextureOffset,
    SizeX = aa_icon.Size.x,
    SizeY = aa_icon.Size.y
}

local function set_custom_aa_icon()
    http.get(icon_url, function(success, response)
        if not success or response.status ~= 200 then
            return
        end

        local texture_id = renderer.load_png(response.body, target_width, target_height)
        if texture_id == nil then
            return
        end

        aa_icon.TextureId = texture_id
        aa_icon.TextureOffset = 0     
        aa_icon.Size.x = target_width
        aa_icon.Size.y = target_height
    end)
end


set_custom_aa_icon()


defer(function()
    aa_icon.TextureId = original.TextureId
    aa_icon.TextureOffset = original.TextureOffset
    aa_icon.Size.x = original.SizeX
    aa_icon.Size.y = original.SizeY
end)
----------------------конец--------------------------------







----------------------кастом меню анимация-----------------
local ffi       = require("ffi")
local vector    = require("vector")

local base = ffi.cast("int*", 0x43479A04)
local rclass = ffi.cast("int*", ffi.cast("int*", 0x43479A00)[0]) 

local tabs = { [0] = {} }

tabs[0].enabled = ffi.cast("char*", rclass[0] + 0x15)
tabs[0].pos     = vector(ffi.cast("int*", rclass[0] + 0x20)[0], ffi.cast("int*", rclass[0] + 0x24)[0])
tabs[0].size    = vector(ffi.cast("int*", rclass[0] + 0x28)[0], ffi.cast("int*", rclass[0] + 0x2C)[0])
for i=1, 8 do
    local tabclass  = ffi.cast("int*", base[0] - (0x20 - 0x4*(i-1)))
    tabs[i]         = {}
    tabs[i].enabled = ffi.cast("char*", tabclass[0] + 0x15)
    tabs[i].pos     = vector(ffi.cast("int*", tabclass[0] + 0x20)[0], ffi.cast("int*", tabclass[0] + 0x24)[0])
    tabs[i].size    = vector(ffi.cast("int*", tabclass[0] + 0x28)[0], ffi.cast("int*", tabclass[0] + 0x2C)[0])
end


local minw = ffi.cast("int*", 0x434799C8)
local minh = ffi.cast("int*", 0x434799CC)
local oldminw, oldminh;
local function set_minsize(w, h)
    if oldminw == nil or oldminh == nil then
        oldminw = minw[0]
        oldminh = minh[0]
    end
    minw[0] = w
    minh[0] = h
end
set_minsize(560, 660)
local menux_ptr = ffi.cast("int*", 0x434799B8)
local menuy_ptr = ffi.cast("int*", 0x434799BC)
local function set_pos(x, y)
    menux_ptr[0] = x
    menuy_ptr[0] = y
end

local menuh_ptr = ffi.cast("int*", 0x434799C4)
local menuw_ptr = ffi.cast("int*", 0x434799C0)
local menuact_ptr = ffi.cast("char*", 0x434799E0)
local menu_fademode = ffi.cast("int*", 0x43479A38)

local function set_size(w, h)
    menuw_ptr[0] = w
    menuh_ptr[0] = h
end

local function tabicons_fix(force)
    if menuact_ptr[0] == 0x00 then return end
    local menuh = menuh_ptr[0]
    for i=0, #tabs do
        if tabs[i].pos.y + tabs[i].size.y > menuh then
            tabs[i].enabled[0] = 0x00
        else
            tabs[i].enabled[0] = force
        end
    end
end

local fade_speed = ffi.cast("float*", 0x4346F920)


local function ease_out_cubic(t)
    return 1 - math.pow(1 - t, 3)
end

local function ease_out_quart(t)
    return 1 - math.pow(1 - t, 4)
end

local function ease_out_quint(t)
    return 1 - math.pow(1 - t, 5)
end

local function ease_out_sine(t)
    return math.sin((t * math.pi) / 2)
end

local function ease_out_expo(t)
    return t == 1 and 1 or 1 - math.pow(2, -10 * t)
end

local function ease_out_elastic(t)
    if t == 0 or t == 1 then return t end
    local p = 0.3
    return math.pow(2, -10 * t) * math.sin((t - p / 4) * (2 * math.pi) / p) + 1
end

local function ease_out_back(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
end

local function ease_out_bounce(t)
    if t < 1/2.75 then
        return 7.5625 * t * t
    elseif t < 2/2.75 then
        t = t - 1.5/2.75
        return 7.5625 * t * t + 0.75
    elseif t < 2.5/2.75 then
        t = t - 2.25/2.75
        return 7.5625 * t * t + 0.9375
    else
        t = t - 2.625/2.75
        return 7.5625 * t * t + 0.984375
    end
end


local function ease_out_smooth(t)

    local cubic = ease_out_cubic(t)
    local sine = ease_out_sine(t)
    return (cubic * 0.7 + sine * 0.3)
end

local function ease_out_premium(t)

    if t < 0.5 then
        return ease_out_sine(t * 2) * 0.5
    else
        return (1 - ease_out_expo(1 - t) * 0.5) * 0.5 + 0.5
    end
end

local function get_eased_value(t)
    return ease_out_smooth(t) 
end


local csize = vector(menuw_ptr[0], menuh_ptr[0])
local cpos = vector(menux_ptr[0], menuy_ptr[0])
local cscreen = vector(client.screen_size())
local menu_fade = ffi.cast("float*", 0x43479A5C)
local lmode = 0
local last_fade = 0
local animation_time = 0
local start_time = 0

local function main()
    local mode = menu_fademode[0]
    local current_time = globals.realtime()
    local fade = menu_fade[0]
    
   
    if mode == 0 and menuact_ptr[0] > 0 and lmode == 0 then
        csize = vector(menuw_ptr[0], menuh_ptr[0])
        cpos = vector(menux_ptr[0], menuy_ptr[0])
        set_minsize(oldminw, oldminh)
        tabicons_fix(0x01)
        start_time = current_time
        return
    elseif lmode ~= 0 then
        set_size(csize:unpack())
        set_pos(cpos:unpack())
    end
    
    lmode = mode
    

    local eased_fade = get_eased_value(fade)
    

    local target_size_x = csize.x * eased_fade
    local target_size_y = csize.y * eased_fade
    
    set_minsize(0, 0)
    set_size(target_size_x, target_size_y)
    
  
    local center_x = cscreen.x / 2 - target_size_x / 2
    local center_y = cscreen.y / 2 - target_size_y / 2
    local breath_scale = 1 + math.sin(eased_fade * math.pi) * 0.05
    local soft_x = center_x + (cpos.x - center_x) * eased_fade * breath_scale
    local soft_y = center_y + (cpos.y - center_y) * eased_fade * breath_scale
    set_pos(soft_x, soft_y)
    
    tabicons_fix(0x00)
    last_fade = fade
end
client.set_event_callback("paint_ui", main)


defer(function() set_minsize(oldminw, oldminh) end)




local function get_steam_username()
    local methods = {
        function()
            return panorama.loadstring([[
                return MyPersonaAPI.GetName();
            ]])()
        end,
        function()
            return panorama.loadstring([[
                return FriendsListAPI.GetLocalPlayerName();
            ]])()
        end,
        function()
            local name = entity.get_player_name(entity.get_local_player())
            return name
        end
    }
    
    for _, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result and type(result) == "string" and result ~= "" then
            return result
        end
    end
    
    return "Unknown"
end
-------------консоль залупа хддд-------------------------

local function print_logo()

    local username = get_steam_username()
    local email = username .. "@gamesense.pub"
    

    local screen_width, screen_height = client.screen_size()
    local resolution = screen_width .. "x" .. screen_height
    
    local lines = {
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡀⠀⠀⠀⠈⠉⠛⢶⣤⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣧⠀⠀⠀⠀⠀⠀⢈⣿⠇⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⡆⠀⠀⠀⠀⠀⣼⡟⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⡀⠀⠀⢀⣼⠟⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠲⣶⣶⣶⣶⣶⣶⣶⣿⣿⣿⣿⣿⣷⣶⣶⡿⢋⣴⣶⡶⠒⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠙⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢋⣴⡿⠟⠉⠀⠀⠀⠀⠀",
        "⠀⠀⠀⡌⠀⠀⠀⠀⠀⠈⠛⢿⣿⣿⣿⣿⣿⠟⣩⣴⠟⠋⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⣧⠀⠀⠀⠀⠀⠀⢀⣿⣿⡿⠟⣋⣴⣾⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠻⢿⣶⣶⣶⡾⠿⠛⣋⣥⣶⡿⠛⠻⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⡿⠟⠉⠀⠀⠀⠀⠙⠿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠞⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠇⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    }
    
    local info = {
        "lua:Sytheris",
        "username: " .. email,
    }
    

    for i = 1, #lines do
   
        local line_text = lines[i]
        
       
        if i >= 2 and i <= 3 then
            local info_line = info[i - 1]
            if info_line then
                line_text = line_text .. "    " .. info_line
            end
        end
        
   
        client.color_log(255, 192, 203, line_text)
    end
end


print_logo()
-----------------------------------------

menu.tab_icons_label = menu.tabs_path.anti_aim.fake_lag:label("\a7D7D7DFF •  • ")
local menu_tabs = {"Home", "Anti-aim", "Other"}
menu.tab_switcher = menu.tabs_path.anti_aim.fake_lag:combobox("\n_tab_switch", menu_tabs)






menu.tab_switcher:set_callback(function(self)
    local value = self:get()
    
    if value == "Home" then
       menu.tab_icons_label:set("\v \a7D7D7DFF•  • ")
    elseif value == "Anti-aim" then
        menu.tab_icons_label:set("\a7D7D7DFF • \v \a7D7D7DFF• ")
    elseif value == "Other" then
        menu.tab_icons_label:set("\a7D7D7DFF •  • \v")
    end
end, true)

menu.configs = { } do
    menu.configs.user_name = menu.tabs_path.anti_aim.fake_lag:label("\v \rUser  \v" .. steam_username)
    menu.configs.user_separator_label = menu.tabs_path.anti_aim.fake_lag:label("\v \rUpdated \v??.01.2026")
    menu.configs.user_separator_label_home = menu.tabs_path.anti_aim.fake_lag:label("\rThanks for using \vUs!")
    menu.configs.user_label_home = menu.tabs_path.anti_aim.fake_lag:label("\rSpecial thanks to: ")
    menu.configs.user_home = menu.tabs_path.anti_aim.fake_lag:label("\v@hardwick")

    menu.configs.label_home = menu.tabs_path.anti_aim.general:label("\v \rHome")
    menu.configs.separator = menu.tabs_path.anti_aim.general:label("\v━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    menu.configs.list = menu.tabs_path.anti_aim.general:listbox("\n", {})
    menu.configs.name = menu.tabs_path.anti_aim.general:textbox("\n") 
	
    menu.configs.create = menu.tabs_path.anti_aim.other:button("\v\a7D7D7DFFCreate", function() end)
    menu.configs.load = menu.tabs_path.anti_aim.other:button("\v\a7D7D7DFFLoad", function() end)
    menu.configs.save = menu.tabs_path.anti_aim.other:button("\v\a7D7D7DFFSave", function() end)
    menu.configs.delete = menu.tabs_path.anti_aim.other:button("\v\a7D7D7DFFDelete", function() end)
    menu.configs.import = menu.tabs_path.anti_aim.other:button("\v\a7D7D7DFFImport", function() end)
    menu.configs.export = menu.tabs_path.anti_aim.other:button("\v\a7D7D7DFFExport", function() end)
end

menu.anti_aim = {} do
		
    menu.anti_aim.label_anti_aim = menu.tabs_path.anti_aim.general:label("\v \rAnti-aim")
    menu.anti_aim.current_state = menu.tabs_path.anti_aim.general:combobox("\v━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", vars.anti_aim.states)
    

    menu.anti_aim.tabs_icons_label = menu.tabs_path.anti_aim.other:label("\a7D7D7DFF •  • ")
    local menu_tabs = {"Misc", "Phases", "Fake lag"}
    menu.anti_aim.tabs_switcher = menu.tabs_path.anti_aim.other:combobox("\n_tab_switch", menu_tabs, "Misc")


	menu.anti_aim.manual_yaw_left = menu.tabs_path.anti_aim.other:hotkey("\v\rLeft")
    menu.anti_aim.manual_yaw_right = menu.tabs_path.anti_aim.other:hotkey("\v\rRight")
    menu.anti_aim.manual_yaw_forward = menu.tabs_path.anti_aim.other:hotkey("\v\rForward")
    menu.anti_aim.freestand_hotkey = menu.tabs_path.anti_aim.other:hotkey("\v\rFreestand")
    menu.anti_aim.tweaks = menu.tabs_path.anti_aim.general:multiselect("Tweaks", {"Avoid backstab", "Safe head"})
    menu.anti_aim.avoid_backstab_distance = menu.tabs_path.anti_aim.general:slider("\vDistance", 150, 400, 250, true, "ft", 1)
    menu.anti_aim.safe_head_states = menu.tabs_path.anti_aim.general:multiselect("\vSafe head", {"Knife", "Taser", "Above enemy"})
    menu.anti_aim.height_difference = menu.tabs_path.anti_aim.general:slider("\vHeight difference", 50, 150, 70, true, "ft", 1)
    




    menu.anti_aim.tabs_switcher:set_callback(function(self)
        local value = self:get()
        

        if value == "Misc" then
            menu.anti_aim.tabs_icons_label:set("\v \a7D7D7DFF•  • ")
        elseif value == "Phases" then
            menu.anti_aim.tabs_icons_label:set("\a7D7D7DFF • \v \a7D7D7DFF• ")
        elseif value == "Fake lag" then
            menu.anti_aim.tabs_icons_label:set("\a7D7D7DFF •  • \v")
        end
        


		  menu.anti_aim.manual_yaw_left:set_visible(value == "Misc")
          menu.anti_aim.manual_yaw_right:set_visible(value == "Misc")
          menu.anti_aim.manual_yaw_forward:set_visible(value == "Misc")
          menu.anti_aim.freestand_hotkey:set_visible(value == "Misc")
    end)
    

    local init_value = menu.anti_aim.tabs_switcher:get()
    menu.anti_aim.manual_yaw_left:set_visible(init_value == "Misc")
    menu.anti_aim.manual_yaw_right:set_visible(init_value == "Misc")
    menu.anti_aim.manual_yaw_forward:set_visible(init_value == "Misc")
    menu.anti_aim.freestand_hotkey:set_visible(init_value == "Misc")
    
    if init_value == "Misc" then
        menu.anti_aim.tabs_icons_label:set("\v \a7D7D7DFF•  • ")
    elseif init_value == "Phases" then
        menu.anti_aim.tabs_icons_label:set("\a7D7D7DFF • \v \a7D7D7DFF• ")
    elseif init_value == "Fake lag" then
        menu.anti_aim.tabs_icons_label:set("\a7D7D7DFF •  • \v")
    end

end

    menu.anti_aim.builder = { }

    for k, v in ipairs(vars.anti_aim.states) do
        menu.anti_aim.builder[k] = {
            enable_state = menu.tabs_path.anti_aim.general:checkbox("Enable \v" .. vars.anti_aim.states[k]),
            pitch = menu.tabs_path.anti_aim.general:combobox("\v \rPitch\n" .. vars.anti_aim.states[k], vars.anti_aim.references.pitch),
            yaw_amount = menu.tabs_path.anti_aim.general:slider("\v \rYaw Amount\n" .. vars.anti_aim.states[k], -180, 180, 0, true, "°", 1),
            add_left_right = menu.tabs_path.anti_aim.general:checkbox("\v \rleft/right\n" .. vars.anti_aim.states[k]),
            yaw_left = menu.tabs_path.anti_aim.general:slider("\v \rAdd Left\n" .. vars.anti_aim.states[k], -180, 180, 0, true, "°", 1),
            yaw_right = menu.tabs_path.anti_aim.general:slider("\v \rAdd Right\n" .. vars.anti_aim.states[k], -180, 180, 0, true, "°", 1),
            yaw_randomize = menu.tabs_path.anti_aim.general:slider("\v \rRandomize\n" .. vars.anti_aim.states[k], 0, 100, 0, true, "%", 1),
            yaw_jitter = menu.tabs_path.anti_aim.general:combobox("\v\rYaw jitter\n" .. vars.anti_aim.states[k], {"Off", "Center", "Random", "3-way", "5-way", "Offset", "Spin", "X-Way"}),
            yaw_jitter_3way_angle1 = menu.tabs_path.anti_aim.general:slider("\v\r3-Way Angle 1\n" .. vars.anti_aim.states[k], -180, 180, 0, true, "°", 1),
            yaw_jitter_3way_angle2 = menu.tabs_path.anti_aim.general:slider("\v\r3-Way Angle 2\n" .. vars.anti_aim.states[k], -180, 180, 0, true, "°", 1),
            yaw_jitter_3way_angle3 = menu.tabs_path.anti_aim.general:slider("\v\r3-Way Angle 3\n" .. vars.anti_aim.states[k], -180, 180, 0, true, "°", 1),
            yaw_jitter_5way_angle1 = menu.tabs_path.anti_aim.general:slider("\v\r5-Way Angle 1\n" .. vars.anti_aim.states[k], -180, 180, 0, true, "°", 1),
            yaw_jitter_5way_angle2 = menu.tabs_path.anti_aim.general:slider("\v\r5-Way Angle 2\n" .. vars.anti_aim.states[k], -180, 180, 0, true, "°", 1),
            yaw_jitter_5way_angle3 = menu.tabs_path.anti_aim.general:slider("\v\r5-Way Angle 3\n" .. vars.anti_aim.states[k], -180, 180, 0, true, "°", 1),
            yaw_jitter_5way_angle4 = menu.tabs_path.anti_aim.general:slider("\v\r5-Way Angle 4\n" .. vars.anti_aim.states[k], -180, 180, 0, true, "°", 1),
            yaw_jitter_5way_angle5 = menu.tabs_path.anti_aim.general:slider("\v\r5-Way Angle 5\n" .. vars.anti_aim.states[k], -180, 180, 0, true, "°", 1),
            yaw_jitter_center_angle = menu.tabs_path.anti_aim.general:slider("\v\rCenter\n" .. vars.anti_aim.states[k], -90, 90, 0, true, "°", 1),
            yaw_jitter_offset_angle = menu.tabs_path.anti_aim.general:slider("\v\rOffset\n" .. vars.anti_aim.states[k], -90, 90, 0, true, "°", 1),
            yaw_jitter_random_angle = menu.tabs_path.anti_aim.general:slider("\v\rRandom\n" .. vars.anti_aim.states[k], -180, 180, 0, true, "°", 1),
            yaw_jitter_spin_angle = menu.tabs_path.anti_aim.general:slider("\v\rSpin\n" .. vars.anti_aim.states[k], -90, 90, 0, true, "°", 1),
            yaw_jitter_xway_points = menu.tabs_path.anti_aim.general:slider("\v\rX-Way Points\n" .. vars.anti_aim.states[k], 2, 8, 3, true, "pts", 1),
            yaw_jitter_xway_custom = menu.tabs_path.anti_aim.general:textbox("\v\rX-Way Custom\n" .. vars.anti_aim.states[k], "3"),
            body_yaw = menu.tabs_path.anti_aim.general:combobox("\v \rBody\n" .. vars.anti_aim.states[k], {"Off", "Opposite", "Jitter", "Static"}),
            jitter_delay = menu.tabs_path.anti_aim.general:slider("\v\rJitter Delay\n" .. vars.anti_aim.states[k], 1, 15, 0, true, "t", 1),
            force_defensive = menu.tabs_path.anti_aim.general:checkbox("\v\rForce defensive\n" .. vars.anti_aim.states[k])
        }
    end

    menu.other = { } do
menu.other.visuals = { } do
    menu.other.label_other = menu.tabs_path.anti_aim.general:label("\v\rOther ")
    menu.other.separator = menu.tabs_path.anti_aim.general:label("\v━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    menu.other.visuals.watermark = menu.tabs_path.anti_aim.general:checkbox("\v\rWatermark", false)
    menu.other.visuals.watermark_label = menu.tabs_path.anti_aim.general:label("\vWatermark\r ~ custom text")
    menu.other.visuals.watermark_custom_text = menu.tabs_path.anti_aim.general:textbox("\vWatermark\r ~ text", "SYTHERIS")
    menu.other.visuals.watermark_color = menu.tabs_path.anti_aim.general:color_picker("\vWatermark\r ~ text", 255, 255, 255, 255)

    menu.other.visuals.damage_indicator = menu.tabs_path.anti_aim.general:checkbox("\v\rDamage indicator")

    menu.other.visuals.manual_arrows = menu.tabs_path.anti_aim.general:checkbox("\v\rManual Arrows")
    menu.other.visuals.manual_arrows_style = menu.tabs_path.anti_aim.general:combobox("\vStyle", {"Classic", "Mini"})

    menu.other.visuals.cross_marker = menu.tabs_path.anti_aim.general:checkbox("\v\rCross marker")

    menu.other.visuals.custom_scope_overlay = menu.tabs_path.anti_aim.general:checkbox("\v\rCustom scope")
    menu.other.visuals.custom_scope_overlay_color = menu.tabs_path.anti_aim.general:color_picker("\vColor", 255, 255, 255, 255)
    menu.other.visuals.custom_scope_overlay_gap = menu.tabs_path.anti_aim.general:slider("\vGap", 0, 50, 5)
    menu.other.visuals.custom_scope_overlay_size = menu.tabs_path.anti_aim.general:slider("\vLine", 15, 300, 100)
end

        menu.other.misc = { } do
            menu.other.misc.aimbot_logs = menu.tabs_path.anti_aim.other:checkbox("\v\rAimbot logs")
            menu.other.misc.custom_logs = menu.tabs_path.anti_aim.other:checkbox("\vCustom text", false)
            menu.other.misc.logs_custom_prefix = menu.tabs_path.anti_aim.other:textbox("\vAimbot logs\r ~ prefix", "Sytheris")
            menu.other.misc.logs_custom_prefix:depend({ menu.other.misc.aimbot_logs, true }, { menu.other.misc.custom_logs, true })
            
            menu.other.misc.notify_output = menu.tabs_path.anti_aim.other:checkbox("\vIndicator")
            menu.other.misc.hit_color_label = menu.tabs_path.anti_aim.other:label("\vNotify\r ~ Hit color")
            menu.other.misc.hit_color = menu.tabs_path.anti_aim.other:color_picker("\vNotify\r ~ Hit color", 255, 255, 255, 255)
            menu.other.misc.miss_color_label = menu.tabs_path.anti_aim.other:label("\vNotify\r ~ Miss color")
            menu.other.misc.miss_color = menu.tabs_path.anti_aim.other:color_picker("\vNotify\r ~ Miss color", 255, 255, 255, 255)

            menu.other.misc.animations = menu.tabs_path.anti_aim.other:checkbox("\v\rAnimations")
            menu.other.misc.ground_legs = menu.tabs_path.anti_aim.other:combobox("\vlegs", {"Walking", "Jitter", "Moonwalk"})
            menu.other.misc.ground_legs_type = menu.tabs_path.anti_aim.other:combobox("\vType", {"Full", "Randomized", "Flex"})
            menu.other.misc.air_legs = menu.tabs_path.anti_aim.other:combobox("\vAir", {"Disabled", "Static", "Jitter", "Moonwalk"})
            menu.other.misc.addons = menu.tabs_path.anti_aim.other:multiselect("\vAddons", {"Body Lean", "Earthquake", "Pitch 0 on land"})

            menu.other.misc.console_filter = menu.tabs_path.anti_aim.other:checkbox("\v\rConsole filter")
			menu.other.misc.fast_ladder = menu.tabs_path.anti_aim.other:checkbox("\v\rFast ladder")
        end
    end

    local menu_depends do
        for k, v in ipairs(vars.anti_aim.states) do
            local is_state = { menu.anti_aim.current_state, vars.anti_aim.states[k] }
            local is_state_enabled = { menu.anti_aim.builder[k].enable_state, function() if k == 1 then return true else return menu.anti_aim.builder[k].enable_state.value end end }
            local can_enable_state = { menu.anti_aim.builder[k].enable_state, function() return k ~= 1 end }

            local is_left_right = { menu.anti_aim.builder[k].add_left_right, true }

            local is_jitter = { menu.anti_aim.builder[k].yaw_jitter, function() return menu.anti_aim.builder[k].yaw_jitter.value ~= "Off" end }
            local is_3way = { menu.anti_aim.builder[k].yaw_jitter, function() return menu.anti_aim.builder[k].yaw_jitter.value == "3-way" end }
            local is_5way = { menu.anti_aim.builder[k].yaw_jitter, function() return menu.anti_aim.builder[k].yaw_jitter.value == "5-way" end }
            local is_center = { menu.anti_aim.builder[k].yaw_jitter, function() return menu.anti_aim.builder[k].yaw_jitter.value == "Center" end }
            local is_offset = { menu.anti_aim.builder[k].yaw_jitter, function() return menu.anti_aim.builder[k].yaw_jitter.value == "Offset" end }
            local is_random = { menu.anti_aim.builder[k].yaw_jitter, function() return menu.anti_aim.builder[k].yaw_jitter.value == "Random" end }
            local is_spin = { menu.anti_aim.builder[k].yaw_jitter, function() return menu.anti_aim.builder[k].yaw_jitter.value == "Spin" end }
            local is_xway = { menu.anti_aim.builder[k].yaw_jitter, function() return menu.anti_aim.builder[k].yaw_jitter.value == "X-Way" end }

            local is_body_yaw = { menu.anti_aim.builder[k].body_yaw, function() return menu.anti_aim.builder[k].body_yaw.value ~= "Off" end }
            local is_jitter_body = { menu.anti_aim.builder[k].body_yaw, function() return menu.anti_aim.builder[k].body_yaw.value == "Jitter" end }

            menu.anti_aim.builder[k].enable_state:depend( is_state, can_enable_state )
            menu.anti_aim.builder[k].pitch:depend( is_state, is_state_enabled )
            menu.anti_aim.builder[k].yaw_amount:depend( is_state, is_state_enabled )
            menu.anti_aim.builder[k].add_left_right:depend( is_state, is_state_enabled )
            menu.anti_aim.builder[k].yaw_left:depend( is_state, is_state_enabled, is_left_right )
            menu.anti_aim.builder[k].yaw_right:depend( is_state, is_state_enabled, is_left_right )
            menu.anti_aim.builder[k].yaw_randomize:depend( is_state, is_state_enabled, is_left_right )
            menu.anti_aim.builder[k].yaw_jitter:depend( is_state, is_state_enabled )    

            menu.anti_aim.builder[k].yaw_jitter_3way_angle1:depend( is_state, is_state_enabled, is_3way )
            menu.anti_aim.builder[k].yaw_jitter_3way_angle2:depend( is_state, is_state_enabled, is_3way )
            menu.anti_aim.builder[k].yaw_jitter_3way_angle3:depend( is_state, is_state_enabled, is_3way )
  
            menu.anti_aim.builder[k].yaw_jitter_5way_angle1:depend( is_state, is_state_enabled, is_5way )
            menu.anti_aim.builder[k].yaw_jitter_5way_angle2:depend( is_state, is_state_enabled, is_5way )
            menu.anti_aim.builder[k].yaw_jitter_5way_angle3:depend( is_state, is_state_enabled, is_5way )
            menu.anti_aim.builder[k].yaw_jitter_5way_angle4:depend( is_state, is_state_enabled, is_5way )
            menu.anti_aim.builder[k].yaw_jitter_5way_angle5:depend( is_state, is_state_enabled, is_5way )
  
            menu.anti_aim.builder[k].yaw_jitter_center_angle:depend( is_state, is_state_enabled, is_center )
 
            menu.anti_aim.builder[k].yaw_jitter_offset_angle:depend( is_state, is_state_enabled, is_offset )
 
            menu.anti_aim.builder[k].yaw_jitter_random_angle:depend( is_state, is_state_enabled, is_random )
   
            menu.anti_aim.builder[k].yaw_jitter_spin_angle:depend( is_state, is_state_enabled, is_spin )
    
            menu.anti_aim.builder[k].yaw_jitter_xway_points:depend( is_state, is_state_enabled, is_xway )
         
            menu.anti_aim.builder[k].yaw_jitter_xway_custom:depend( is_state, is_state_enabled, is_xway )
            menu.anti_aim.builder[k].body_yaw:depend( is_state, is_state_enabled )
            menu.anti_aim.builder[k].jitter_delay:depend( is_state, is_state_enabled, is_body_yaw, is_jitter_body )
            menu.anti_aim.builder[k].force_defensive:depend( is_state, is_state_enabled )
        end

        menu.anti_aim.avoid_backstab_distance:depend({ menu.anti_aim.tweaks, "Avoid backstab" })

        menu.anti_aim.safe_head_states:depend({ menu.anti_aim.tweaks, "Safe head" })
        menu.anti_aim.height_difference:depend({ menu.anti_aim.tweaks, "Safe head" }, { menu.anti_aim.safe_head_states, "Above enemy" })

        menu.other.visuals.manual_arrows_style:depend({ menu.other.visuals.manual_arrows, true })

        menu.other.visuals.custom_scope_overlay_gap:depend({ menu.other.visuals.custom_scope_overlay, true })
        menu.other.visuals.custom_scope_overlay_size:depend({ menu.other.visuals.custom_scope_overlay, true })
        menu.other.visuals.custom_scope_overlay_color:depend({ menu.other.visuals.custom_scope_overlay, true })
        menu.other.visuals.watermark_label:depend({ menu.other.visuals.watermark, true })
        menu.other.visuals.watermark_custom_text:depend({ menu.other.visuals.watermark, true })
        menu.other.visuals.watermark_color:depend({ menu.other.visuals.watermark, true })

        menu.other.misc.custom_logs:depend({ menu.other.misc.aimbot_logs, true })
        menu.other.misc.notify_output:depend({ menu.other.misc.aimbot_logs, true })
        menu.other.misc.hit_color_label:depend({ menu.other.misc.aimbot_logs, true }, { menu.other.misc.notify_output, true })
        menu.other.misc.miss_color_label:depend({ menu.other.misc.aimbot_logs, true }, { menu.other.misc.notify_output, true })
        menu.other.misc.hit_color:depend({ menu.other.misc.aimbot_logs, true }, { menu.other.misc.notify_output, true })
        menu.other.misc.miss_color:depend({ menu.other.misc.aimbot_logs, true }, { menu.other.misc.notify_output, true })

        menu.other.misc.ground_legs:depend({ menu.other.misc.animations, true })
        menu.other.misc.ground_legs_type:depend({ menu.other.misc.animations, true })
        menu.other.misc.air_legs:depend({ menu.other.misc.animations, true })
        menu.other.misc.addons:depend({ menu.other.misc.animations, true })
    end
end


local watermark_drag = drag_system.new(
    'watermark',
    screen_x / 2, screen_y - 10,
    'xy',
    'xy',
    {
        w = function() 
            local watermark_text = "SYTHERIS"
            if menu.custom_watermark and menu.custom_watermark:get() then
                local custom_text = menu.watermark_custom_text:get()
                if custom_text and custom_text ~= "" then
                    custom_text = custom_text:gsub("%s+", ""):upper()
                    if #custom_text > 0 then
                        watermark_text = custom_text
                    end
                end
            end
            return renderer.measure_text("c-", watermark_text)
        end,
        h = 15,
        align_x = 'center',
        align_y = 'center',
        snap_distance = 10,
        show_guides = true,
        show_highlight = true,
        align_left = true,
        align_right = true,
        align_top = true,
        align_bottom = true,
        highlight_color = {150, 150, 150, 50}
    }
)

local anti_aim = { } do
    anti_aim.data = {
        state_id = 0,
        inverter = false,
        ticks = 0,
        switch = false,
        manual_yaw_direction = 0,
        last_pushed_button = 0,
        pitch = "Off",
        yaw = {
            base = "At targets",
            type = "Off",
            degree = 0,
            jitter = {
                type = "Off",
                amount = 0
            }
        },
        body_yaw = {
            type = "Off",
            amount = 0
        },
        freestanding = false
    }

    anti_aim.condition_func =
    {
        onground_ticks = 0,
        in_air = function (indx)
            flags = entity.get_prop(indx, "m_fFlags")

            return bit.band(flags, 1) == 0
        end,
        on_ground = function (indx, limit)
            flags = entity.get_prop(indx, "m_fFlags")

            if not bit.band(flags, 1) == 0 then return false end

            local onground = bit.band(flags, 1)

            if onground == 1 then
                anti_aim.condition_func.onground_ticks = anti_aim.condition_func.onground_ticks + 1
            else
                anti_aim.condition_func.onground_ticks = 0
            end

            return anti_aim.condition_func.onground_ticks > limit
        end,
        velocity = function(indx)
            vel_x, vel_y = entity.get_prop(indx, "m_vecVelocity")
            local velocity = math.sqrt(vel_x * vel_x + vel_y * vel_y)

            return velocity
        end,
        is_crouching = function (indx)
            return entity.get_prop(indx, "m_flDuckAmount") > 0.8
        end
    }

    anti_aim.get_desync_side = function(cmd)
        local lp = entity.get_local_player()
        if lp == nil then return end

        local body_yaw = entity.get_prop(lp, "m_flPoseParameter", 11) * 120 - 60

        return body_yaw > 0
    end

    anti_aim.get_state = function()
        local lp = entity.get_local_player()
        if lp == nil then return end

        if anti_aim.data.manual_yaw_direction ~= 0 then
            return 10
        end

        local freestand_hotkey = menu.anti_aim.freestand_hotkey:get()

        if freestand_hotkey then
            return 9
        end

        if not anti_aim.condition_func.on_ground(lp, 5) then
            if anti_aim.condition_func.is_crouching(lp) then
                return 5
            else
                return 4
            end
        end

        local fake_duck_state = vars.anti_aim.references.elements.fake_duck:get()

        if anti_aim.condition_func.is_crouching(lp) or fake_duck_state then
            if anti_aim.condition_func.velocity(lp) > 4 then
                return 7
            else
                return 6
            end
        end

        local slow_motion_state = vars.anti_aim.references.elements.slow_motion.hotkey:get()

        if slow_motion_state then
            return 8
        end

        if anti_aim.condition_func.velocity(lp) > 4 then
            return 3
        end

        return 2
    end

    anti_aim.run = function(cmd)
        local lp = entity.get_local_player()
        if lp == nil or not entity.is_alive(lp) then return end

        if cmd.chokedcommands ~= 0 then return end

        state_id = anti_aim.get_state()

        if menu.anti_aim.builder[state_id].enable_state.value == false and state_id ~= 1 then
            state_id = 1
        end

        anti_aim.data.pitch = menu.anti_aim.builder[state_id].pitch.value
        anti_aim.data.yaw.type = "180"

        anti_aim.data.inverter = anti_aim.get_desync_side(cmd)

        if menu.anti_aim.builder[state_id].jitter_delay.value > 1 then
            if globals.chokedcommands() == 0 then
                anti_aim.data.ticks = anti_aim.data.ticks + 1

                if anti_aim.data.ticks % (menu.anti_aim.builder[state_id].jitter_delay.value) == 0 then
                    anti_aim.data.switch = not anti_aim.data.switch
                end
            end

            anti_aim.data.inverter = anti_aim.data.switch
        end

        if globals.chokedcommands() == 0 then
            if menu.anti_aim.builder[state_id].add_left_right:get() then
                anti_aim.data.yaw.degree = ((anti_aim.data.inverter and menu.anti_aim.builder[state_id].yaw_left.value or menu.anti_aim.builder[state_id].yaw_right.value) + menu.anti_aim.builder[state_id].yaw_amount.value) + math.random(0, menu.anti_aim.builder[state_id].yaw_randomize.value / 2)
            else
                anti_aim.data.yaw.degree = menu.anti_aim.builder[state_id].yaw_amount.value
            end

            if menu.anti_aim.builder[state_id].yaw_jitter.value ~= "Off" then
                if menu.anti_aim.builder[state_id].yaw_jitter.value == "Center" then
                    anti_aim.data.yaw.degree = (anti_aim.data.inverter and -menu.anti_aim.builder[state_id].yaw_jitter_amount.value / 2 or menu.anti_aim.builder[state_id].yaw_jitter_amount.value / 2) + anti_aim.data.yaw.degree
                else
                    anti_aim.data.yaw.degree = (anti_aim.data.inverter and (-menu.anti_aim.builder[state_id].yaw_jitter_amount.value / 2 + math.random(0, 15)) or (menu.anti_aim.builder[state_id].yaw_jitter_amount.value / 2 - math.random(0, 15))) + anti_aim.data.yaw.degree
                end
            end
        end

        if menu.anti_aim.builder[state_id].jitter_delay.value > 1 and menu.anti_aim.builder[state_id].body_yaw:get() == "Jitter" then
            anti_aim.data.body_yaw.type = "Static"

            if globals.chokedcommands() == 0 then
                anti_aim.data.body_yaw.amount = anti_aim.data.inverter and -1 or 1
            end
        else
            anti_aim.data.body_yaw.type = menu.anti_aim.builder[state_id].body_yaw.value
            anti_aim.data.body_yaw.amount = -1
        end

        cmd.force_defensive = menu.anti_aim.builder[state_id].force_defensive.value

        anti_aim.data.freestanding = menu.anti_aim.freestand_hotkey:get() and true or false
        vars.anti_aim.references.elements.freeStand:set(anti_aim.data.freestanding)

        if anti_aim.data.freestanding then
            vars.anti_aim.references.elements.freeStand:set_hotkey("Always on")
        else
            vars.anti_aim.references.elements.freeStand:set_hotkey("On hotkey")
        end

        if anti_aim.data.manual_yaw_direction ~= 0 then
            vars.anti_aim.references.elements.freeStand:set(false)
        end

        if menu.anti_aim.manual_yaw_right:get() and anti_aim.data.last_pushed_button + 0.1 < globals.curtime() then
            anti_aim.data.manual_yaw_direction = anti_aim.data.manual_yaw_direction == 2 and 0 or 2
            anti_aim.data.last_pushed_button = globals.curtime()
        elseif menu.anti_aim.manual_yaw_left:get() and anti_aim.data.last_pushed_button + 0.1 < globals.curtime() then
            anti_aim.data.manual_yaw_direction = anti_aim.data.manual_yaw_direction == 1 and 0 or 1
            anti_aim.data.last_pushed_button = globals.curtime()
        elseif menu.anti_aim.manual_yaw_forward:get() and anti_aim.data.last_pushed_button + 0.1 < globals.curtime() then
            anti_aim.data.manual_yaw_direction = anti_aim.data.manual_yaw_direction == 3 and 0 or 3
            anti_aim.data.last_pushed_button = globals.curtime()
        elseif anti_aim.data.last_pushed_button > globals.curtime() then
            anti_aim.data.last_pushed_button = globals.curtime()
        end

        if anti_aim.data.manual_yaw_direction == 1 then
            anti_aim.data.yaw.degree = -90
        elseif anti_aim.data.manual_yaw_direction == 2 then
            anti_aim.data.yaw.degree = 90
        elseif anti_aim.data.manual_yaw_direction == 3 then
            anti_aim.data.yaw.degree = 180
        end

        anti_aim.avoid_backstab = { }

        anti_aim.avoid_backstab.run = function(cmd)
            if not menu.anti_aim.tweaks:get("Avoid backstab") then return end

            local lp = entity.get_local_player()
            if lp == nil or not entity.is_alive(lp) then return end

            local lp_threat = client.current_threat()
            if lp_threat == nil then return end

            local threat_weapon = entity.get_player_weapon(lp_threat)
            if threat_weapon == nil then return end

            local threat_origin = vector(entity.get_prop(lp_threat, "m_vecOrigin"))

            local lp_origin = vector(entity.get_prop(lp, "m_vecOrigin"))

            local dist = lp_origin:dist(threat_origin)

            local avoid_distance = menu.anti_aim.avoid_backstab_distance:get()

            if dist < avoid_distance and entity.get_classname(threat_weapon) == "CKnife" then
                anti_aim.data.yaw.base = "At targets"
                anti_aim.data.yaw.degree = -180
                anti_aim.data.freestanding = false

                cmd.force_defensive = false
            end
        end

        anti_aim.avoid_backstab.run(cmd)

        anti_aim.safe_head = { }

        anti_aim.safe_head.states = {
            ["Knife"] = function(weapon)
                return state_id == 5 and weapon == "CKnife"
            end,
            ["Taser"] = function(weapon)
                return state_id == 5 and weapon == "CWeaponTaser"
            end
        }

        anti_aim.safe_head.run = function(cmd)
            if not menu.anti_aim.tweaks:get("Safe head") then return end

            local lp = entity.get_local_player()
            if lp == nil or not entity.is_alive(lp) then return end

            local weapon = entity.get_player_weapon(lp)
            if weapon == nil then return end

            local lp_threat = client.current_threat()
            if lp_threat == nil then return end

            local threat_origin = vector(entity.get_prop(lp_threat, "m_vecOrigin"))
            local lp_origin = vector(entity.get_prop(lp, "m_vecOrigin"))

            local is_knife = entity.get_classname(weapon) == "CKnife"
            local is_taser = entity.get_classname(weapon) == "CWeaponTaser"

            local state_id = anti_aim.get_state()

            local height_difference = lp_origin.z - threat_origin.z > menu.anti_aim.height_difference:get()
            if menu.anti_aim.height_difference:get() ~= 0 and not height_difference then return end

            local knife_state = menu.anti_aim.safe_head_states:get("Knife") and state_id == 5 and is_knife
            local taser_state = menu.anti_aim.safe_head_states:get("Taser") and state_id == 5 and is_taser
            local above_enemy_state = menu.anti_aim.safe_head_states:get("Above enemy") and height_difference

            if knife_state or taser_state or above_enemy_state then
                anti_aim.data.yaw.base = "At targets"
                anti_aim.data.yaw.degree = 0
                anti_aim.data.yaw.jitter.amount = 0
                anti_aim.data.body_yaw.type = "Static"
                anti_aim.data.body_yaw.amount = 0
                anti_aim.data.freestanding = false

                cmd.force_defensive = false
            end
        end

        anti_aim.safe_head.run(cmd)

        anti_aim.fast_ladder = { }

        anti_aim.fast_ladder.run = function(cmd)
            if not menu.other.misc.fast_ladder:get() then return end

            local lp = entity.get_local_player()
            if lp == nil or not entity.is_alive(lp) then return end

            local pitch, yaw = client.camera_angles()

            local move_type = entity.get_prop(lp, "m_MoveType")
            if move_type ~= 9 then return end

            cmd.yaw = math.floor(cmd.yaw + 0.5)
            cmd.roll = 0

            if cmd.forwardmove == 0 then
                if cmd.sidemove ~= 0 then
                    cmd.pitch = 89
                    cmd.yaw = cmd.yaw + 180
                    if cmd.sidemove < 0 then
                        cmd.in_moveleft = 0
                        cmd.in_moveright = 1
                    end
                    if cmd.sidemove > 0 then
                        cmd.in_moveleft = 1
                        cmd.in_moveright = 0
                    end
                end
            end

            if cmd.forwardmove > 0 then
                if pitch < 45 then
                    cmd.pitch = 89
                    cmd.in_moveright = 1
                    cmd.in_moveleft = 0
                    cmd.in_forward = 0
                    cmd.in_back = 1
                    if cmd.sidemove == 0 then
                        cmd.yaw = cmd.yaw + 90
                    end
                    if cmd.sidemove < 0 then
                        cmd.yaw = cmd.yaw + 150
                    end
                    if cmd.sidemove > 0 then
                        cmd.yaw = cmd.yaw + 30
                    end
                end
            end

            if cmd.forwardmove < 0 then
                cmd.pitch = 89
                cmd.in_moveleft = 1
                cmd.in_moveright = 0
                cmd.in_forward = 1
                cmd.in_back = 0

                if cmd.sidemove == 0 then
                    cmd.yaw = cmd.yaw + 90
                end

                if cmd.sidemove > 0 then
                    cmd.yaw = cmd.yaw + 150
                end

                if cmd.sidemove < 0 then
                    cmd.yaw = cmd.yaw + 30
                end
            end
        end

        anti_aim.fast_ladder.run(cmd)

        local yaw_degree = anti_aim.data.yaw.degree
        if yaw_degree > 180 then
            yaw_degree = yaw_degree - 360
        elseif yaw_degree < -180 then
            yaw_degree = yaw_degree + 360
        end

        vars.anti_aim.references.elements.pitch[1]:set(anti_aim.data.pitch)
        vars.anti_aim.references.elements.yaw[1]:set(anti_aim.data.yaw.type)
        vars.anti_aim.references.elements.yaw[2]:set(yaw_degree)
        vars.anti_aim.references.elements.yawbase:set(anti_aim.data.yaw.base)
        vars.anti_aim.references.elements.yawjitter[1]:set(anti_aim.data.yaw.jitter.type)
        vars.anti_aim.references.elements.yawjitter[2]:set(anti_aim.data.yaw.jitter.amount)
        vars.anti_aim.references.elements.bodyyaw[1]:set(anti_aim.data.body_yaw.type)
        vars.anti_aim.references.elements.bodyyaw[2]:set(anti_aim.data.body_yaw.amount)
    end
end

local visuals = { } do
    visuals.RGBAtoHEX = function(redArg, greenArg, blueArg, alphaArg)
        return string.format('%.2x%.2x%.2x%.2x', redArg, greenArg, blueArg, alphaArg)
    end

    visuals.gradient_text = function(time, string, r, g, b, a, r2, g2, b2, a2)
        local t_out, t_out_iter = {}, 1

        local r_add = (r2 - r)
        local g_add = (g2 - g)
        local b_add = (b2 - b)
        local a_add = (a2 - a)

        for i = 1, #string do
            local iter = (i - 1)/(#string - 1) + time
            t_out[t_out_iter] = "\a" .. visuals.RGBAtoHEX(r + r_add * math.abs(math.cos(iter)), g + g_add * math.abs(math.cos(iter)), b + b_add * math.abs(math.cos(iter)), a + a_add * math.abs(math.cos(iter)))

            t_out[t_out_iter + 1] = string:sub(i, i)

            t_out_iter = t_out_iter + 2
        end

        return table.concat(t_out)
    end

    visuals.rec = function(x, y, w, h, radius, color)
        radius = math.min(x/2, y/2, radius)
        local r, g, b, a = unpack(color)
        renderer.rectangle(x, y + radius, w, h - radius*2, r, g, b, a)
        renderer.rectangle(x + radius, y, w - radius*2, radius, r, g, b, a)
        renderer.rectangle(x + radius, y + h - radius, w - radius*2, radius, r, g, b, a)
        renderer.circle(x + radius, y + radius, r, g, b, a, radius, 180, 0.25)
        renderer.circle(x - radius + w, y + radius, r, g, b, a, radius, 90, 0.25)
        renderer.circle(x - radius + w, y - radius + h, r, g, b, a, radius, 0, 0.25)
        renderer.circle(x + radius, y - radius + h, r, g, b, a, radius, -90, 0.25)
    end

    visuals.rec_outline = function(x, y, w, h, radius, thickness, color)
        radius = math.min(w/2, h/2, radius)
        local r, g, b, a = unpack(color)
        if radius == 1 then
            renderer.rectangle(x, y, w, thickness, r, g, b, a)
            renderer.rectangle(x, y + h - thickness, w , thickness, r, g, b, a)
        else
            renderer.rectangle(x + radius, y, w - radius*2, thickness, r, g, b, a)
            renderer.rectangle(x + radius, y + h - thickness, w - radius*2, thickness, r, g, b, a)
            renderer.rectangle(x, y + radius, thickness, h - radius*2, r, g, b, a)
            renderer.rectangle(x + w - thickness, y + radius, thickness, h - radius*2, r, g, b, a)
            renderer.circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, thickness)
            renderer.circle_outline(x + radius, y + h - radius, r, g, b, a, radius, 90, 0.25, thickness)
            renderer.circle_outline(x + w - radius, y + radius, r, g, b, a, radius, -90, 0.25, thickness)
            renderer.circle_outline(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25, thickness)
        end
    end

    visuals.glow_module = function(x, y, w, h, width, rounding, accent, accent_inner)
        local thickness = 1
        local offset = 1
        local r, g, b, a = unpack(accent)

        if accent_inner then
            visuals.rec(x , y, w, h + 1, rounding, accent_inner)
        end

        for k = 0, width do
            if a * (k/width)^(1) > 5 then
                local accent = {r, g, b, a * (k/width)^(2)}

                visuals.rec_outline(x + (k - width - offset)*thickness, y + (k - width - offset) * thickness, w - (k - width - offset)*thickness*2, h + 1 - (k - width - offset)*thickness*2, rounding + thickness * (width - k + offset), thickness, accent)
            end
        end
    end

    visuals.watermark = function()
    if not menu.other.visuals.watermark:get() then
        return
    end

    local lp = entity.get_local_player()
    if lp == nil or not entity.is_alive(lp) then return end

    local watermark_color_r, watermark_color_g, watermark_color_b, watermark_color_a = menu.other.visuals.watermark_color:get()
    
    local watermark_text = "SYTHERIS"
    
    local custom_text = menu.other.visuals.watermark_custom_text:get()
    if custom_text and custom_text ~= "" then
        custom_text = custom_text:gsub("%s+", ""):upper()
        if #custom_text > 0 then
            watermark_text = custom_text
        end
    end

    local pos_x = drag_system.watermark_x
    local pos_y = drag_system.watermark_y
    
    renderer.text(pos_x, pos_y, watermark_color_r, watermark_color_g, watermark_color_b, watermark_color_a, "c", 0, watermark_text)
end

    visuals.damage_indicator = function()
        if not menu.other.visuals.damage_indicator:get() then return end

        local lp = entity.get_local_player()
        if lp == nil or not entity.is_alive(lp) then return end

        local damage = vars.rage_bot.references.minimum_damage_override[1].hotkey:get() and vars.rage_bot.references.minimum_damage_override[2]:get() or vars.rage_bot.references.minimum_damage[1]:get()

        renderer.text(screen_x / 2 + 5, screen_y / 2 - 15, 255, 255, 255, 255, nil, 0, damage)
    end

    visuals.cross_marker = { } do
        visuals.cross_marker.queue = {}

        visuals.cross_marker.aim_fire = function(c)
            visuals.cross_marker.queue[globals.tickcount()] = {c.x,c.y,c.z, globals.curtime() + 2}
        end

        visuals.cross_marker.paint = function(c)
            if not menu.other.visuals.cross_marker:get() then return end

            for tick, data in pairs(visuals.cross_marker.queue) do
                if globals.curtime() <= data[4] then
                    local screen_x, screen_y = renderer.world_to_screen(data[1], data[2], data[3])

                    if screen_x ~= nil and screen_y ~= nil then
                        renderer.line(screen_x - 4 * 2, screen_y - 4 * 2, screen_x - ( 4 ), screen_y - ( 4 ), 255, 255, 255, 255)
                        renderer.line(screen_x - 4 * 2, screen_y + 4 * 2, screen_x - ( 4 ), screen_y + ( 4 ), 255, 255, 255, 255)
                        renderer.line(screen_x + 4 * 2, screen_y + 4 * 2, screen_x + ( 4 ), screen_y + ( 4 ), 255, 255, 255, 255)
                        renderer.line(screen_x + 4 * 2, screen_y - 4 * 2, screen_x + ( 4 ), screen_y - ( 4 ), 255, 255, 255, 255)
                    end
                end
            end
        end
    end

    visuals.manual_arrows = { } do
        visuals.manual_arrows.paint = function(c)
            if not menu.other.visuals.manual_arrows:get() then return end

            local lp = entity.get_local_player()
            if lp == nil or not entity.is_alive(lp) then return end

            local main_color = { arrows_r, arrows_g, arrows_b, arrows_a }
            local disabled_color = { 255, 255, 255, 150 }

            local arrows_color_left = anti_aim.data.manual_yaw_direction == 1 and main_color or disabled_color
            local arrows_color_right = anti_aim.data.manual_yaw_direction == 2 and main_color or disabled_color

            local classic_style = menu.other.visuals.manual_arrows_style:get() == "Classic"
            local measure_arrow = renderer.measure_text(classic_style and "+" or "", classic_style and ">" or "❱")

            renderer.text(screen_x / 2 + 40, screen_y / 2 -  (classic_style and 16 or 7), arrows_color_right[1], arrows_color_right[2], arrows_color_right[3], arrows_color_right[4], classic_style and "+" or "", 0, classic_style and ">" or "❱")
            renderer.text(screen_x / 2 - measure_arrow / 2 - 41, screen_y / 2 - (classic_style and 16 or 7), arrows_color_left[1], arrows_color_left[2], arrows_color_left[3], arrows_color_left[4], classic_style and "+" or "", 0, classic_style and "<" or "❰")
        end
    end

    visuals.custom_scope_overlay = { } do
        visuals.custom_scope_overlay.paint = function()
            if not menu.other.visuals.custom_scope_overlay:get() then return end

            local lp = entity.get_local_player()
            if lp == nil or not entity.is_alive(lp) then return end

            vars.visuals.references.scope_overlay:override(false)

            local scoped = entity.get_prop(lp, "m_bIsScoped") == 1
            if not scoped then return end

            local scope_r, scope_g, scope_b, scope_a = menu.other.visuals.custom_scope_overlay_color:get()

            local gap = menu.other.visuals.custom_scope_overlay_gap:get()
            local size = menu.other.visuals.custom_scope_overlay_size:get()

            renderer.gradient(screen_x / 2, screen_y / 2 + gap, 1, size, scope_r, scope_g, scope_b, scope_a, 0, 0, 0, 0, false)
            renderer.gradient(screen_x / 2, screen_y / 2 - gap, 1, -size, scope_r, scope_g, scope_b, scope_a, 0, 0, 0, 0, false)

            renderer.gradient(screen_x / 2 + gap, screen_y / 2, size, 1, scope_r, scope_g, scope_b, scope_a, 0, 0, 0, 0, true)
            renderer.gradient(screen_x / 2 - gap, screen_y / 2, -size, 1, scope_r, scope_g, scope_b, scope_a, 0, 0, 0, 0, true)
        end
    end
end

local misc = { } do
    misc.aimbot_logs = { } do
        misc.aimbot_logs.hitgroup = {'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', 'gear'}
        misc.aimbot_logs.fire_data = { }
        misc.aimbot_logs.last_shot_tick = 0
        misc.aimbot_logs.backtrack_ticks = 0

        misc.aimbot_logs.aim_fire = function(c)
            misc.aimbot_logs.fire_data.damage = c.damage
            misc.aimbot_logs.fire_data.hitgroup = misc.aimbot_logs.hitgroup[c.hitgroup + 1] or "?"
            misc.aimbot_logs.fire_data.hitchance = math.floor(c.hit_chance)
            misc.aimbot_logs.last_shot_tick = globals.tickcount()
            misc.aimbot_logs.backtrack_ticks = c.backtrack
        end
        
        misc.aimbot_logs.hit = { } do
    misc.aimbot_logs.hit.aim_hit = function(c)
        if not menu.other.misc.aimbot_logs:get() then return end

        local target = entity.get_player_name(c.target)
        local hitgroup = misc.aimbot_logs.hitgroup[c.hitgroup + 1] or '?'
        local damage = c.damage
        local hitchance = misc.aimbot_logs.fire_data.hitchance or 0
        local backtrack = misc.aimbot_logs.backtrack_ticks or 0

        local prefix = "Sytheris"
        if menu.other.misc.custom_logs and menu.other.misc.custom_logs:get() then
            local custom_prefix = menu.other.misc.logs_custom_prefix:get()
            if custom_prefix and custom_prefix ~= "" then
                prefix = custom_prefix
            end
        end

        print(string.format("[%s] Hit %s in the %s for %s damage (hc: %s%% bt: %st)", 
            prefix, target, hitgroup, damage, hitchance, backtrack))
        
        if menu.other.misc.notify_output:get() then
            local r, g, b, a = menu.other.misc.hit_color:get()
            misc.aimbot_logs.add_notification(string.format("Hit %s in the %s for %s damage (hc: %s%% bt: %st)", target, hitgroup, damage, hitchance, backtrack), {r, g, b, a})
        end
    end
end


        misc.aimbot_logs.miss = { } do
        misc.aimbot_logs.miss.aim_miss = function(c)
        if not menu.other.misc.aimbot_logs:get() then return end
        
        local target = entity.get_player_name(c.target)
        local hitchance = misc.aimbot_logs.fire_data.hitchance or 0
        local hitgroup = misc.aimbot_logs.hitgroup[c.hitgroup + 1] or '?'
        local reason = c.reason
        local damage = misc.aimbot_logs.fire_data.damage or 0
        local backtrack = misc.aimbot_logs.backtrack_ticks or 0
        
        local display_reason = reason
        if reason == "spread" then
            display_reason = "spread"
        end
        
        local prefix = "Sytheris"
        if menu.other.misc.custom_logs and menu.other.misc.custom_logs:get() then
            local custom_prefix = menu.other.misc.logs_custom_prefix:get()
            if custom_prefix and custom_prefix ~= "" then
                prefix = custom_prefix
            end
        end
        
        print(string.format("[%s] Missed shot due to %s at %s in the %s for %s damage (hc: %s%% bt: %st)", 
            prefix, display_reason, target, hitgroup, damage, hitchance, backtrack))
        
        local r, g, b, a = menu.other.misc.miss_color:get()
        if menu.other.misc.notify_output:get() then
            misc.aimbot_logs.add_notification(string.format("Missed shot due to %s at %s in the %s for %s damage (hc: %s%% bt: %st)", display_reason, target, hitgroup, damage, hitchance, backtrack), {r, g, b, a})
        end
    end
end

        misc.aimbot_logs.notify_data = { }

        misc.aimbot_logs.add_notification = function(text, color)
            table.insert(misc.aimbot_logs.notify_data, 1, {
                text = text,
                color = color,
                time = globals.realtime(),
                alpha = 0,
                alpha_text = 0,
                add_x = 0,
                add_y = 0
            })
        end

        misc.aimbot_logs.notifications = function()
            for i, logs in ipairs(misc.aimbot_logs.notify_data) do
                if logs.time + 1 > globals.realtime() and i <= 5 then
                    logs.alpha = animations.lerp(logs.alpha, 255, 0.05)
                    logs.alpha_text = animations.lerp(logs.alpha_text, 255, 0.05)
                    logs.add_x = animations.lerp(logs.add_x, 1, 0.05)
                end

                local string = tostring(logs.text)
                local size = renderer.measure_text("", string)

                if logs.alpha <= 0 then
                    logs[i] = nil
                else
                    logs.add_y = animations.lerp(logs.add_y, i * 40, 0.05)

                    visuals.glow_module(screen_x / 2 - size / 2 - 12, screen_y - 68 - logs.add_y, size + 24, 25, 17, 7, { logs.color[1], logs.color[2], logs.color[3], logs.alpha * 0.33 }, { logs.color[1], logs.color[2], logs.color[3], logs.alpha * 0.33 })
                    visuals.rec(screen_x / 2 - size / 2 - 12, screen_y - 68 - logs.add_y, size + 24, 25, 7, { 15, 15, 15, logs.alpha })

                    renderer.text(screen_x / 2, screen_y - 57 - logs.add_y, 255, 255, 255, logs.alpha_text, "c", 0, logs.text)

                    if logs.time + 3 < globals.realtime() or i > 5 then
                        logs.alpha = animations.lerp(logs.alpha, 0, 0.05)
                        logs.alpha_text = animations.lerp(logs.alpha_text, 0, 0.05)
                        logs.add_x = animations.lerp(logs.add_x, 0, 0.05)
                        logs.add_y = animations.lerp(logs.add_y, i * 60, 0.05)
                    end
                end

                if logs.alpha < 1 then
                    table.remove(misc.aimbot_logs.notify_data, i)
                end
            end
        end
    end

    misc.animations = { } do
        misc.animations.pose_parameters = {
            STRAFE_YAW = 0,
            STAND = 1,
            LEAN_YAW = 2,
            SPEED = 3,
            LADDER_YAW = 4,
            LADDER_SPEED = 5,
            JUMP_FALL = 6,
            MOVE_YAW = 7,
            MOVE_BLEND_CROUCH = 8,
            MOVE_BLEND_WALK = 9,
            MOVE_BLEND_RUN = 10,
            BODY_YAW = 11,
            BODY_PITCH = 12,
            AIM_BLEND_STAND_IDLE = 13,
            AIM_BLEND_STAND_WALK = 14,
            AIM_BLEND_STAND_RUN = 14,
            AIM_BLEND_CROUCH_IDLE = 16,
            AIM_BLEND_CROUCH_WALK = 17,
            DEATH_YAW = 18
        }

        misc.animations.pre_render = function()
            if not menu.other.misc.animations:get() then return end

            local lp = entity.get_local_player()
            if not lp or not entity.is_alive(lp) then return end

            local self_index = c_entity.new(lp)

            local self_anim_state = self_index:get_anim_state()
            if not self_anim_state then return end

            if menu.other.misc.ground_legs:get() == "Walking" then
                vars.anti_aim.references.elements.other.leg_movement:set("Never slide")
            elseif menu.other.misc.ground_legs:get() == "Jitter" then
                vars.anti_aim.references.elements.other.leg_movement:set(globals.tickcount() % 4 > 1 and "Off" or "Always slide")
                
                if menu.other.misc.ground_legs_type:get() == "Full" then
                    entity.set_prop(lp, "m_flPoseParameter", globals.tickcount() % 4 > 1 and 1 or 0.5, misc.animations.pose_parameters.STRAFE_YAW)
                elseif menu.other.misc.ground_legs_type:get() == "Randomized" then
                    entity.set_prop(lp, "m_flPoseParameter", client.random_float(0.1, 1), misc.animations.pose_parameters.STRAFE_YAW)
                else
                    entity.set_prop(lp, "m_flPoseParameter", globals.tickcount() % client.random_float(3, 5) > 1 and client.random_float(0.5, 0.8) or 0, misc.animations.pose_parameters.STRAFE_YAW)
                end
            elseif menu.other.misc.ground_legs:get() == "Moonwalk" then
                vars.anti_aim.references.elements.other.leg_movement:set("Never slide")
                entity.set_prop(lp, "m_flPoseParameter", 0.5, 7)
            end

            if menu.other.misc.air_legs:get() == "Static" then
                entity.set_prop(lp, "m_flPoseParameter", 1, misc.animations.pose_parameters.JUMP_FALL)
            elseif menu.other.misc.air_legs:get() == "Jitter" then
                entity.set_prop(lp, "m_flPoseParameter", globals.tickcount() % 4 > 1 and 1 or 0, misc.animations.pose_parameters.JUMP_FALL)
            elseif menu.other.misc.air_legs:get() == "Moonwalk" then
                local self_anim_overlay = self_index:get_anim_overlay(6)
                if not self_anim_overlay then return end

                local x_velocity = entity.get_prop(lp, "m_vecVelocity[0]")

                if math.abs(x_velocity) >= 3 then
                    self_anim_overlay.weight = 1
                end
            else
                entity.set_prop(lp, "m_flPoseParameter", 0, misc.animations.pose_parameters.JUMP_FALL)
            end
            
            if menu.other.misc.addons:get("Body Lean") then
                local self_anim_overlay = self_index:get_anim_overlay(12)
                if not self_anim_overlay then return end
        
                local x_velocity = entity.get_prop(lp, "m_vecVelocity[0]")

                if math.abs(x_velocity) >= 3 then
                    self_anim_overlay.weight = 1
                end
            end

            if menu.other.misc.addons:get("Earthquake") then
                local self_anim_overlay = self_index:get_anim_overlay(12)
                if not self_anim_overlay then return end
        
                self_anim_overlay.weight = client.random_float(0, 1)
            end
        
            if menu.other.misc.addons:get("Pitch 0 on land") then
                if not self_anim_state.hit_in_ground_animation then return end

                entity.set_prop(lp, "m_flPoseParameter", 0.5, misc.animations.pose_parameters.BODY_PITCH)
            end 
        end
    end

    misc.console_filter = { } do
        menu.other.misc.console_filter:set_callback(function(self)
            if self:get() then
                cvar.developer:set_int(0)
                cvar.con_filter_enable:set_int(1)
                cvar.con_filter_text:set_string("IrWL5106TZZKNFPz4P4Gl3pSN?J370f5hi373ZjPg%VOVh6lN")
                client.exec("con_filter_enable 1")
            else
                cvar.con_filter_enable:set_int(0)
                cvar.con_filter_text:set_string("")
                client.exec("con_filter_enable 0")
            end
        end)
        
        events.shutdown:set(function()
            cvar.con_filter_enable:set_int(0)
            cvar.con_filter_text:set_string("")
            client.exec("con_filter_enable 0")
        end)
    end
end

local cfg_system = { } do
    cfg_system.db = "sytheris_gs"
		
    local configs_db = database.read(cfg_system.db) or { 
        cfg_list = {{'Default', ""}},
        menu_list = {'Default'}
    }

    cfg_system.save_config = function(id)
        if id == 1 then
            client.color_log(255, 165, 0, "Cannot save default config!")
            return
        end
        if configs_db.cfg_list[id] == nil then
            client.color_log(255, 165, 0, "Config not found!")
            return
        end

        local save_data = {
            anti_aim = {},
            other = {}
        }

 
        for k, v in ipairs(vars.anti_aim.states) do
            save_data.anti_aim[k] = {
                enable_state = menu.anti_aim.builder[k].enable_state:get(),
                pitch = menu.anti_aim.builder[k].pitch:get(),
                yaw_amount = menu.anti_aim.builder[k].yaw_amount:get(),
                add_left_right = menu.anti_aim.builder[k].add_left_right:get(),
                yaw_left = menu.anti_aim.builder[k].yaw_left:get(),
                yaw_right = menu.anti_aim.builder[k].yaw_right:get(),
                yaw_randomize = menu.anti_aim.builder[k].yaw_randomize:get(),
                yaw_jitter = menu.anti_aim.builder[k].yaw_jitter:get(),
                yaw_jitter_amount = menu.anti_aim.builder[k].yaw_jitter_amount:get(),
                body_yaw = menu.anti_aim.builder[k].body_yaw:get(),
                jitter_delay = menu.anti_aim.builder[k].jitter_delay:get(),
                force_defensive = menu.anti_aim.builder[k].force_defensive:get()
            }
        end
		
		menu.configs.list:update(configs_db.menu_list)

        save_data.current_state = menu.anti_aim.current_state:get()
        save_data.tweaks = menu.anti_aim.tweaks:get()
        save_data.avoid_backstab_distance = menu.anti_aim.avoid_backstab_distance:get()
        save_data.safe_head_states = menu.anti_aim.safe_head_states:get()
        save_data.height_difference = menu.anti_aim.height_difference:get()


        save_data.visuals = {
            damage_indicator = menu.other.visuals.damage_indicator:get(),
            manual_arrows = menu.other.visuals.manual_arrows:get(),
            manual_arrows_style = menu.other.visuals.manual_arrows_style:get(),
            cross_marker = menu.other.visuals.cross_marker:get(),
            custom_scope_overlay = menu.other.visuals.custom_scope_overlay:get(),
            custom_scope_overlay_color = {menu.other.visuals.custom_scope_overlay_color:get()},
            custom_scope_overlay_gap = menu.other.visuals.custom_scope_overlay_gap:get(),
            custom_scope_overlay_size = menu.other.visuals.custom_scope_overlay_size:get()
        }


        save_data.misc = {
            aimbot_logs = menu.other.misc.aimbot_logs:get(),
            custom_logs = menu.other.misc.custom_logs:get(),
            logs_custom_prefix = menu.other.misc.logs_custom_prefix:get(),
            notify_output = menu.other.misc.notify_output:get(),
            hit_color = {menu.other.misc.hit_color:get()},
            miss_color = {menu.other.misc.miss_color:get()},
            animations = menu.other.misc.animations:get(),
            ground_legs = menu.other.misc.ground_legs:get(),
            ground_legs_type = menu.other.misc.ground_legs_type:get(),
            air_legs = menu.other.misc.air_legs:get(),
            addons = menu.other.misc.addons:get(),
            console_filter = menu.other.misc.console_filter:get()
        }

        local json_string = json.stringify(save_data)
        configs_db.cfg_list[id][2] = base64.encode(json_string)
        database.write(cfg_system.db, configs_db)
        client.color_log(144, 238, 144, "[Sytheris] Config saved successfully!")
    end
    
    cfg_system.create_config = function(name)
        if type(name) ~= 'string' then return end
        if name == nil or name == '' or name == ' ' then
            client.color_log(255, 165, 0, "[Sytheris] Config name cannot be empty!")
            return
        end
        for i= #configs_db.menu_list, 1, -1 do
            if configs_db.menu_list[i] == name then
                client.color_log(255, 165, 0, "[Sytheris] Config with this name already exists!")
                return
            end
        end

        if #configs_db.cfg_list > 6 then
            client.color_log(255, 165, 0, "[Sytheris] Maximum number of configs reached!")
            return
        end

        local completed = {name, ''}
        client.color_log(144, 238, 144, "[Sytheris] Config created successfully!")
        table.insert(configs_db.cfg_list, completed)
        table.insert(configs_db.menu_list, name)
        database.write(cfg_system.db, configs_db)
    end
    
    cfg_system.remove_config = function(id)
        if id == 1 then
            client.color_log(255, 165, 0, "[Sytheris] Cannot delete default config!")
            return
        end
        local item = configs_db.cfg_list[id][1]
        for i= #configs_db.cfg_list, 1, -1 do
            if configs_db.cfg_list[i][1] == item then
                table.remove(configs_db.cfg_list, i)
                table.remove(configs_db.menu_list, i)
            end
        end
        client.color_log(144, 238, 144, "[Sytheris] Config deleted successfully!")
        database.write(cfg_system.db, configs_db)
    end
    
    cfg_system.load_config = function(id)
        if id > #configs_db.cfg_list then
            client.color_log(255, 165, 0, "[Sytheris] Config not found!")
            return
        end
        
        if configs_db.cfg_list[id][2] == nil or configs_db.cfg_list[id][2] == '' then
            client.color_log(255, 165, 0, "[Sytheris] Config data is empty!")
            return
        end
        
        local config_data = configs_db.cfg_list[id][2]
        local decoded = base64.decode(config_data)
        if not decoded then
            client.color_log(255, 165, 0, "[Sytheris] Failed to decode config!")
            return
        end
        
        local parsed = json.parse(decoded)
        if not parsed then
            client.color_log(255, 165, 0, "[Sytheris] Failed to parse config JSON!")
            return
        end
        

        if parsed.anti_aim then
            for k, v in ipairs(parsed.anti_aim) do
                if k <= #vars.anti_aim.states then
                    menu.anti_aim.builder[k].enable_state:set(v.enable_state)
                    menu.anti_aim.builder[k].pitch:set(v.pitch)
                    menu.anti_aim.builder[k].yaw_amount:set(v.yaw_amount)
                    menu.anti_aim.builder[k].add_left_right:set(v.add_left_right)
                    menu.anti_aim.builder[k].yaw_left:set(v.yaw_left)
                    menu.anti_aim.builder[k].yaw_right:set(v.yaw_right)
                    menu.anti_aim.builder[k].yaw_randomize:set(v.yaw_randomize)
                    menu.anti_aim.builder[k].yaw_jitter:set(v.yaw_jitter)
                    menu.anti_aim.builder[k].yaw_jitter_amount:set(v.yaw_jitter_amount)
                    menu.anti_aim.builder[k].body_yaw:set(v.body_yaw)
                    menu.anti_aim.builder[k].jitter_delay:set(v.jitter_delay)
                    menu.anti_aim.builder[k].force_defensive:set(v.force_defensive)
                end
            end
        end


        if parsed.current_state then menu.anti_aim.current_state:set(parsed.current_state) end
        if parsed.tweaks then menu.anti_aim.tweaks:set(parsed.tweaks) end
        if parsed.avoid_backstab_distance then menu.anti_aim.avoid_backstab_distance:set(parsed.avoid_backstab_distance) end
        if parsed.safe_head_states then menu.anti_aim.safe_head_states:set(parsed.safe_head_states) end
        if parsed.height_difference then menu.anti_aim.height_difference:set(parsed.height_difference) end

   
        if parsed.visuals then
            local v = parsed.visuals
            menu.other.visuals.damage_indicator:set(v.damage_indicator)
            menu.other.visuals.manual_arrows:set(v.manual_arrows)
            menu.other.visuals.manual_arrows_style:set(v.manual_arrows_style)
            if v.manual_arrows_color then menu.other.visuals.manual_arrows_color:set(unpack(v.manual_arrows_color)) end
            menu.other.visuals.cross_marker:set(v.cross_marker)
            menu.other.visuals.custom_scope_overlay:set(v.custom_scope_overlay)
            if v.custom_scope_overlay_color then menu.other.visuals.custom_scope_overlay_color:set(unpack(v.custom_scope_overlay_color)) end
            menu.other.visuals.custom_scope_overlay_gap:set(v.custom_scope_overlay_gap)
            menu.other.visuals.custom_scope_overlay_size:set(v.custom_scope_overlay_size)
        end

        if parsed.misc then
            local m = parsed.misc
            menu.other.misc.aimbot_logs:set(m.aimbot_logs)
            menu.other.misc.custom_logs:set(m.custom_logs)
            menu.other.misc.logs_custom_prefix:set(m.logs_custom_prefix)
            menu.other.misc.notify_output:set(m.notify_output)
            if m.hit_color then menu.other.misc.hit_color:set(unpack(m.hit_color)) end
            if m.miss_color then menu.other.misc.miss_color:set(unpack(m.miss_color)) end
            menu.other.misc.animations:set(m.animations)
            menu.other.misc.ground_legs:set(m.ground_legs)
            menu.other.misc.ground_legs_type:set(m.ground_legs_type)
            menu.other.misc.air_legs:set(m.air_legs)
            menu.other.misc.addons:set(m.addons)
            menu.other.misc.console_filter:set(m.console_filter)
        end

        client.color_log(144, 238, 144, "[Sytheris] Config loaded successfully!")
    end

    menu.configs.create:set_callback(function()
        cfg_system.create_config(menu.configs.name:get())
        menu.configs.list:update(configs_db.menu_list)
    end)
    menu.configs.load:set_callback(function()
        cfg_system.load_config(menu.configs.list:get() + 1)
        menu.configs.list:update(configs_db.menu_list)
    end)
    menu.configs.save:set_callback(function()
        cfg_system.save_config(menu.configs.list:get() + 1)
    end)
    menu.configs.delete:set_callback(function()
        cfg_system.remove_config(menu.configs.list:get() + 1)
        menu.configs.list:update(configs_db.menu_list)
    end)
    menu.configs.import:set_callback(function()
        local clipboard_data = clipboard.get()
        if clipboard_data and clipboard_data ~= "" then
            local decoded = base64.decode(clipboard_data)
            if decoded then
                local parsed = json.parse(decoded)
                if parsed then
                    if parsed.anti_aim then
                        for k, v in ipairs(parsed.anti_aim) do
                            if k <= #vars.anti_aim.states then
                                menu.anti_aim.builder[k].enable_state:set(v.enable_state)
                                menu.anti_aim.builder[k].pitch:set(v.pitch)
                                menu.anti_aim.builder[k].yaw_amount:set(v.yaw_amount)
                                menu.anti_aim.builder[k].add_left_right:set(v.add_left_right)
                                menu.anti_aim.builder[k].yaw_left:set(v.yaw_left)
                                menu.anti_aim.builder[k].yaw_right:set(v.yaw_right)
                                menu.anti_aim.builder[k].yaw_randomize:set(v.yaw_randomize)
                                menu.anti_aim.builder[k].yaw_jitter:set(v.yaw_jitter)
                                menu.anti_aim.builder[k].yaw_jitter_amount:set(v.yaw_jitter_amount)
                                menu.anti_aim.builder[k].body_yaw:set(v.body_yaw)
                                menu.anti_aim.builder[k].jitter_delay:set(v.jitter_delay)
                                menu.anti_aim.builder[k].force_defensive:set(v.force_defensive)
                            end
                        end
                    end
                    
                    client.color_log(144, 238, 144, "[Sytheris] Config imported successfully!")
                else
                    client.color_log(255, 165, 0, "[Sytheris] Failed to parse config JSON!")
                end
            else
                client.color_log(255, 165, 0, "[Sytheris] Failed to decode config!")
            end
        else
            client.color_log(255, 165, 0, "[Sytheris] Clipboard is empty!")
        end
    end)
    menu.configs.export:set_callback(function()
        local save_data = {
            anti_aim = {},
            other = {}
        }

        for k, v in ipairs(vars.anti_aim.states) do
            save_data.anti_aim[k] = {
                enable_state = menu.anti_aim.builder[k].enable_state:get(),
                pitch = menu.anti_aim.builder[k].pitch:get(),
                yaw_amount = menu.anti_aim.builder[k].yaw_amount:get(),
                add_left_right = menu.anti_aim.builder[k].add_left_right:get(),
                yaw_left = menu.anti_aim.builder[k].yaw_left:get(),
                yaw_right = menu.anti_aim.builder[k].yaw_right:get(),
                yaw_randomize = menu.anti_aim.builder[k].yaw_randomize:get(),
                yaw_jitter = menu.anti_aim.builder[k].yaw_jitter:get(),
                yaw_jitter_amount = menu.anti_aim.builder[k].yaw_jitter_amount:get(),
                body_yaw = menu.anti_aim.builder[k].body_yaw:get(),
                jitter_delay = menu.anti_aim.builder[k].jitter_delay:get(),
                force_defensive = menu.anti_aim.builder[k].force_defensive:get()
            }
        end

        save_data.current_state = menu.anti_aim.current_state:get()
        save_data.tweaks = menu.anti_aim.tweaks:get()
        save_data.avoid_backstab_distance = menu.anti_aim.avoid_backstab_distance:get()
        save_data.safe_head_states = menu.anti_aim.safe_head_states:get()
        save_data.height_difference = menu.anti_aim.height_difference:get()

        save_data.visuals = {
            damage_indicator = menu.other.visuals.damage_indicator:get(),
            manual_arrows = menu.other.visuals.manual_arrows:get(),
            manual_arrows_style = menu.other.visuals.manual_arrows_style:get(),
            cross_marker = menu.other.visuals.cross_marker:get(),
            custom_scope_overlay = menu.other.visuals.custom_scope_overlay:get(),
            custom_scope_overlay_color = {menu.other.visuals.custom_scope_overlay_color:get()},
            custom_scope_overlay_gap = menu.other.visuals.custom_scope_overlay_gap:get(),
            custom_scope_overlay_size = menu.other.visuals.custom_scope_overlay_size:get()
        }

        save_data.misc = {
            aimbot_logs = menu.other.misc.aimbot_logs:get(),
            custom_logs = menu.other.misc.custom_logs:get(),
            logs_custom_prefix = menu.other.misc.logs_custom_prefix:get(),
            notify_output = menu.other.misc.notify_output:get(),
            hit_color = {menu.other.misc.hit_color:get()},
            miss_color = {menu.other.misc.miss_color:get()},
            animations = menu.other.misc.animations:get(),
            ground_legs = menu.other.misc.ground_legs:get(),
            ground_legs_type = menu.other.misc.ground_legs_type:get(),
            air_legs = menu.other.misc.air_legs:get(),
            addons = menu.other.misc.addons:get(),
            console_filter = menu.other.misc.console_filter:get()
        }

        local json_string = json.stringify(save_data)
        clipboard.set(base64.encode(json_string))
        client.color_log(144, 238, 144, "[Sytheris] Config copied to clipboard!")
    end)
    
    menu.configs.list:update(configs_db.menu_list)
end

pui.traverse(menu.configs, function(item)
    item:depend({menu.tab_switcher, "Home"})
end)

pui.traverse(menu.anti_aim, function(item)
    item:depend({menu.tab_switcher, "Anti-aim"})
end)

pui.traverse(menu.other, function(item)
    item:depend({menu.tab_switcher, "Other"})
end)

events.paint_ui:set(function()
    vars.visuals.references.scope_overlay:override(true)
end)

events.paint:set(function(c)
    for _, t in pairs(tween_tbl) do
        t:update(globals.frametime())
    end

    if ui.is_menu_open() then
        for _, drag in ipairs(drag_system.elements) do
            drag:update()
        end
    end

    if ui.is_menu_open() then
        for _, drag in ipairs(drag_system.elements) do
            drag:draw_guides()
        end
    end

    visuals.watermark()
    visuals.damage_indicator()
    visuals.cross_marker.paint(c)
    visuals.manual_arrows.paint()
    visuals.custom_scope_overlay.paint()
    misc.aimbot_logs.notifications()
end)





events.setup_command:set(function(cmd)
    anti_aim.run(cmd)
end)

events.aim_fire:set(function(c)
    visuals.cross_marker.aim_fire(c)
    misc.aimbot_logs.aim_fire(c)
end)

events.aim_hit:set(function(c)
    misc.aimbot_logs.hit.aim_hit(c)
end)

events.aim_miss:set(function(c)
    misc.aimbot_logs.miss.aim_miss(c)
end)

events.round_prestart:set(function()
    visuals.cross_marker.queue = {}
end)

events.paint_ui:set(function()
    pui.traverse(vars.anti_aim.references.elements, function(item)
        item:set_visible(false)
    end)
    

    if menu.tab_switcher:get() == "Home" then
        if menu.anti_aim.manual_yaw_left then
            menu.anti_aim.manual_yaw_left:set_visible(false)
        end
        if menu.anti_aim.manual_yaw_right then
            menu.anti_aim.manual_yaw_right:set_visible(false)
        end
        if menu.anti_aim.manual_yaw_forward then
            menu.anti_aim.manual_yaw_forward:set_visible(false)
        end
        if menu.anti_aim.freestand_hotkey then
            menu.anti_aim.freestand_hotkey:set_visible(false)
        end
    end
end)

events.shutdown:set(function()
    pui.traverse(vars.anti_aim.references.elements, function(item)
        item:set_visible(true)
    end)
end)