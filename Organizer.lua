script_name('UIF Organizer')
script_author('Nasif')
require "lib.moonloader"

local SE = require 'lib.samp.events'
local imgui = require 'mimgui'
local new = imgui.new
local sizeX, sizeY = getScreenResolution()
local pmArray = {}
local adminArray = {}

local shouldShowMenu = new.bool(true)

local messageStream = 'pm'

local messagesFrame = imgui.OnFrame(function()
    return shouldShowMenu[0]
end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 1.174, sizeY / 1.23), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(500, 250), imgui.Cond.FirstUseEver)
    imgui.Begin('Organizer', shouldShowMenu)
    player.HideCursor = true

    -- Selectors
    imgui.BeginChild("Selectors", imgui.ImVec2(130, 50), true)
    if imgui.Selectable('Private Messages') then
        messageStream = 'pm'
    end

    if imgui.Selectable('Admin Messages') then
        messageStream = 'admin'
    end
    imgui.EndChild()

    imgui.SameLine(0)

    -- Messages
    imgui.BeginChild("Messages", imgui.ImVec2(340, 190), true, imgui.WindowFlags.AlwaysHorizontalScrollbar)
    if messageStream == 'pm' then
        for i, message in reversedipairs(pmArray) do
            if startsWith(message, "->") then
                imgui.Text(message)
            else
                if imgui.Button(message) then
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
    if startsWith(text, 'ADMIN:') then
        local nameAction = string.match(text, 'ADMIN: (.*)')
        table.insert(adminArray, nameAction)
    elseif startsWith(text, '>> PM from') then
        local playerName, pmMessage = string.match(text, '>> PM from (.*) %(.*: (.*)')
        local privateMessage = playerName .. ': ' .. pmMessage
        table.insert(pmArray, privateMessage)
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
