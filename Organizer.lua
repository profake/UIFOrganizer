script_name('UIF Organizer')
script_author('Nasif')
require "lib.moonloader"
local fa = require 'fAwesome5'
local SE = require 'lib.samp.events'
local imgui = require 'mimgui'

local new = imgui.new
local sizeX, sizeY = getScreenResolution()
local pmArray = {}
local adminArray = {}

-- Mimgui variables
local shouldShowMenu = new.bool(true)

-- Variables
local messageStream = 'pm'
local haveNewPMs = false
local haveNewAdminMessages = false

local messagesFrame = imgui.OnFrame(function()
    return shouldShowMenu[0]
end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 1.174, sizeY / 1.23), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(500, 250), imgui.Cond.FirstUseEver)
    imgui.Begin('Organizer', shouldShowMenu)
    player.HideCursor = true

    if imgui.IsAnyItemHovered() then haveNewPMs = false end
    if imgui.IsAnyItemHovered() then haveNewAdminMessages = false end

    -- Selectors
    -- PM
    imgui.BeginChild("Selectors", imgui.ImVec2(130, 50), true)
    if haveNewPMs then
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 0.0, 0.0, 1.0))
    else
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
    end
    if imgui.Selectable('Private Messages', (function () return messageStream == 'pm' end)()) then
        messageStream = 'pm'
    end
    imgui.PopStyleColor()

    -- Admin
    if haveNewAdminMessages then
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.8, 0.8, 0.0, 1.0))
    else
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.8, 0.8, 0.8, 0.8))
    end
    if imgui.Selectable('Admin Messages', (function () return messageStream ~= 'pm' end)()) then
        messageStream = 'admin'
    end
    imgui.PopStyleColor()

    imgui.EndChild()

    imgui.SameLine(0)

    -- Messages
    imgui.BeginChild("Messages", imgui.ImVec2(340, 190), true, imgui.WindowFlags.AlwaysHorizontalScrollbar)
    if messageStream == 'pm' then
        for i, message in reversedipairs(pmArray) do
            if startsWith(message, "->") then
                imgui.TextWrapped(message)
            else
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 0.0, 0.0, 1.0));
                imgui.TextWrapped(message)
                imgui.PopStyleColor()
               
                if imgui.Button('Reply') then
                    sampSetChatInputEnabled(true)
                    playerId = getPlayerIdFromText(message)
                    sampSetChatInputText('/pm ' .. playerId .. ' ')
                end
            end
        end
    else
        for i, message in reversedipairs(adminArray) do
            imgui.Text(message)
        end
    end
    imgui.EndChild()

    imgui.End()
end)

local function reversedipairsiter(t, i)
    i = i - 1
    if i ~= 0 then
        return i, t[i]
    end
end
function reversedipairs(t)
    return reversedipairsiter, t, #t + 1
end

function startsWith(str, start)
    return str:sub(1, #start) == start
end

function getPlayerIdFromText(text)
    return string.match(text, '%(([0-9]+)%)')
end

function toggleShowMenu()
    shouldShowMenu[0] = not shouldShowMenu[0]
end

function SE.onServerMessage(arg1, text)
    processServerMessage(text)
end

function processServerMessage(text) 
    if startsWith(text, 'ADMIN:') then
        local nameAction = string.match(text, 'ADMIN: (.*)')
        table.insert(adminArray, nameAction)
        haveNewAdminMessages = true
    elseif startsWith(text, '>> PM from') then
        local playerName, pmMessage = string.match(text, '>> PM from (.*) %(.*: (.*)')
        local privateMessage = playerName .. ': ' .. pmMessage
        table.insert(pmArray, privateMessage)
        haveNewPMs = true
    elseif startsWith(text, '>> PM to') then
        local playerName, pmMessage = string.match(text, '>> PM to (.*) .*:(.*)')
        local privateMessage = "->" .. playerName .. ': ' .. pmMessage
        table.insert(pmArray, privateMessage)
    end
end

function main()
    while not isSampAvailable() do
        wait(0)
    end

    while true do
        wait(10)
        if wasKeyPressed(VK_PAUSE) then
            toggleShowMenu()
        end
    end
    
    if sampGetCurrentServerAddress() ~= "51.254.85.134" then
        return
    end
end
