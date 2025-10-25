--[[
    ____        _     ____  ____  ______ 
   / __ \____ _(_)___/ / / / / / / / __ \
  / /_/ / __ `/ / __  / /_/ / / / / / / /
 / _, _/ /_/ / / /_/ / __  / /_/ / /_/ / 
/_/ |_|\__,_/_/\__,_/_/ /_/\____/_____/  

- from hytiek
Let's collaborate; submit PR to https://github.com/hytiek/raidhud

]]
--- @type Mq
local mq = require('mq')
--- @type ImGui
require('ImGui')

local terminate, isOpen, shouldDraw = false, true, true

local Raids = require('raidhud.raid-list')

local titleText = "RaidHUD (" .. mq.TLO.Me.CleanName() .. ")"

local function updateRaidStatus()
    for i, era in ipairs(Raids) do
        for ii, event in ipairs(era.events) do
            local eventIndex = mq.TLO.Window("DynamicZoneWnd/DZ_TimerList").List("=" .. event.name ..",3")()
            if eventIndex ~= nil then
                Raids[i].events[ii].available = false
                Raids[i].events[ii].lockedout = tostring(mq.TLO.Window("DynamicZoneWnd/DZ_TimerList").List(eventIndex,1))
            end
        end
    end
end

local function updateUI()
    if not isOpen then return end
    isOpen, shouldDraw = ImGui.Begin(titleText, isOpen)
    if shouldDraw then
        for _, era in ipairs(Raids) do
            if (ImGui.CollapsingHeader(era.era)) then
                for _, event in ipairs(era.events) do
                    if event.available == true then
                        ImGui.BulletText(event.name);
                        if ImGui.IsItemHovered() then
                            ImGui.SetTooltip(event.tooltip);
                        end
                    else
                        ImGui.Bullet()
                        ImGui.TextDisabled(event.name);
                        if ImGui.IsItemHovered() then
                            ImGui.SetTooltip("Lockout time: " .. event.lockedout);
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