--[[
    ____        _     ____  ____  ______ 
   / __ \____ _(_)___/ / / / / / / / __ \
  / /_/ / __ `/ / __  / /_/ / / / / / / /
 / _, _/ /_/ / / /_/ / __  / /_/ / /_/ / 
/_/ |_|\__,_/_/\__,_/_/ /_/\____/_____/  

- from hytiek (version 1.0)
Let's collaborate; submit PR to https://github.com/hytiek/raidhud

]]
--- @type Mq
local mq = require('mq')
--- @type ImGui
require('ImGui')

local terminate, isOpen, shouldDraw = false, true, true
local debug = false  -- Set this to false to disable debug prints

local Raids = require('raidhud.raid-list')

local function updateRaidStatus()
    for i, era in ipairs(Raids) do
        for ii, event in ipairs(era.events) do
            local eventIndex = mq.TLO.Window("DynamicZoneWnd/DZ_TimerList").List("=" .. event.name ..",3")()
            if eventIndex ~= nil then
                Raids[i].events[ii].available = false
                Raids[i].events[ii].lockedout = tostring(mq.TLO.Window("DynamicZoneWnd/DZ_TimerList").List(eventIndex,1))
                Raids[i].events[ii].expedition = tostring(mq.TLO.Window("DynamicZoneWnd/DZ_TimerList").List(eventIndex,2))
            end
        end
    end
end

local function updateUI()
    if not isOpen then return end
    isOpen, shouldDraw = ImGui.Begin('RaidHUD', isOpen)
    if shouldDraw then
        local io = ImGui.GetIO()
        local ctrl_down = io.KeyCtrl
        
        for _, era in ipairs(Raids) do
            if (ImGui.CollapsingHeader(era.era)) then
                for _, event in ipairs(era.events) do
                    if event.available == true then
                        ImGui.BulletText(event.name)
                        if ImGui.IsItemHovered() then
                            ImGui.SetTooltip(event.tooltip)
                        end
                        if ImGui.IsItemClicked() then
                            if debug then print("Item clicked: " .. event.name) end
                            if ctrl_down then
                                if debug then print("Control key is down") end
                                local travelto_command = event.tooltip:match("/travelto (%w+)")
                                if travelto_command then
                                    if debug then print("Executing command: /travelto " .. travelto_command) end
                                    mq.cmdf("/travelto %s", travelto_command)
                                end
                            else
                                if debug then print("Hold the control key to execute the travelto command") end
                            end
                        end
                    else
                        ImGui.Bullet()
                        ImGui.TextDisabled(event.name)
                        if ImGui.IsItemHovered() then
                            ImGui.SetTooltip("Lockout time: " .. event.lockedout .. "\nExpedition: " .. event.expedition)
                        end
                        if ImGui.IsItemClicked() then
                            if debug then print("Item clicked: " .. event.name) end
                            if ctrl_down then
                                if debug then print("Control key is down") end
                                local travelto_command = event.tooltip:match("/travelto (%w+)")
                                if travelto_command then
                                    if debug then print("Executing command: /travelto " .. travelto_command) end
                                    mq.cmdf("/travelto %s", travelto_command)
                                end
                            else
                                if debug then print("Hold the control key to execute the travelto command") end
                            end
                        end
                    end
                end
            end
        end
    end
    ImGui.End()
end

local function toggleUI()
    isOpen = not isOpen
end

mq.imgui.init('RaidHUD', updateUI)
mq.bind('/raidhud', toggleUI)

-- open DZ window for a moment so we can fetch info
while mq.TLO.Window("DynamicZoneWnd").Open() ~= true do
    mq.TLO.Window("DynamicZoneWnd").DoOpen()
    mq.delay(100)
end
mq.TLO.Window("DynamicZoneWnd").DoClose()
updateRaidStatus()

while not terminate and mq.TLO.MacroQuest.GameState() == "INGAME" do
    mq.delay("60s", function() return terminate end)
    updateRaidStatus()
end
