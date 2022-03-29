script_name('UIF Organizer')
script_author('Nasif')
require "lib.moonloader"
local SE = require 'lib.samp.events'
local imgui = require 'mimgui'
local inicfg = require 'inicfg'
local fa = require("fAwesome5")

local new = imgui.new
local sizeX, sizeY = getScreenResolution()
local pmArray = {}
local adminArray = {}

-- Variables
local messageStream = 'pm'
local haveNewPMs = false
local haveNewAdminMessages = false

-- IniCfg
local mainIni = inicfg.load({
    settings = {
      showReplyButton = true,
      blockMessagesInChat = false,
      notificationsEnabled = true,
    }
  })

-- Mimgui variables
local shouldShowMenu = new.bool(false)
local shouldShowNotification = new.bool(false)
local showReplyButton = new.bool(mainIni.settings.showReplyButton)
local blockMessagesInChat = new.bool(mainIni.settings.blockMessagesInChat)
local notificationsEnabled = new.bool(mainIni.settings.notificationsEnabled)

local colorSwitchTime = 0
local colorSwitch = true

-- FontAwesome
imgui.OnInitialize(function()
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    local iconRanges = imgui.new.ImWchar[3](fa.min_range, fa.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromFileTTF('trebucbd.ttf', 14.0, nil, glyph_ranges)
    icon = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 14.0, config, iconRanges)
    imgui.GetIO().FontGlobalScale = 1.10
end)

function getFlashingColor(firstColor, secondColor)
    local color = colorSwitch and 
    firstColor or 
    secondColor -- Ternary in Lua
    local curTime = localClock()
    if curTime - 1.5 > colorSwitchTime then
        colorSwitch = not colorSwitch
        colorSwitchTime = curTime
    end
    return color
end

local colors = {
    red = imgui.ImVec4(1.0, 0.0, 0.0, 1.0),
    yellow = imgui.ImVec4(1.0, 1.0, 0.0, 1.0),
    white = imgui.ImVec4(1.0, 1.0, 1.0, 1.0),
    mutedYellow = imgui.ImVec4(0.8, 0.8, 0.0, 1.0),
    grey = imgui.ImVec4(0.8, 0.8, 0.8, 0.8),
}

-- Notification frame
local notificationFrame = imgui.OnFrame(function() return shouldShowNotification[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 1.07, sizeY / 1.13), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(150, 25), imgui.Cond.FirstUseEver)
    imgui.Begin('Notifications', shouldShowNotification, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize)
    if haveNewPMs then
        imgui.TextColored(getFlashingColor(colors.red, colors.yellow), 'You have new PMs')
    end
    if haveNewAdminMessages then
        imgui.Text('New admin actions')
    end
    player.HideCursor = true
    imgui.End()
end)

-- Message frame
local messagesFrame = imgui.OnFrame(function() return shouldShowMenu[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 1.174, sizeY / 1.23), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(500, 250), imgui.Cond.FirstUseEver)
    imgui.Begin('Organizer', shouldShowMenu)
    player.HideCursor = true

    if imgui.IsAnyItemHovered() then
        clearNewMessagesIndicator()
    end

    -- Selectors
    -- PM
    imgui.BeginChild("Div", imgui.ImVec2(130, 90))
        imgui.BeginChild("Selectors", imgui.ImVec2(130, 50), true)
            if haveNewPMs then
                imgui.PushStyleColor(imgui.Col.Text, getFlashingColor(colors.red, colors.yellow))
            else
                imgui.PushStyleColor(imgui.Col.Text, colors.white)
            end
            if imgui.Selectable('Private Messages', messageStream == 'pm') then
                messageStream = 'pm'
            end
            imgui.PopStyleColor()

            -- Admin
            if haveNewAdminMessages then
                imgui.PushStyleColor(imgui.Col.Text, colors.mutedYellow)
            else
                imgui.PushStyleColor(imgui.Col.Text, colors.grey)
            end
            if imgui.Selectable('Admin Actions', messageStream == 'admin') then
                messageStream = 'admin'
            end
            imgui.PopStyleColor()
        imgui.EndChild()

        imgui.BeginChild(fa.ICON_FA_COG .."Settings", imgui.ImVec2(90, 35), true)
            if imgui.Selectable('Settings', messageStream == 'settings') then
                messageStream = 'settings'
            end
        imgui.EndChild()

    imgui.EndChild()
    imgui.SameLine(0)

    -- Messages
    imgui.BeginChild("Messages", imgui.ImVec2(340, 190), true)
    if messageStream == 'pm' then
        for i, message in reversedipairs(pmArray) do
            if string.find(message, ">to", 1) ~= nil then
                if string.find(message, ">toInactive", 1) ~= nil then 
                    message = string.gsub(message, ">toInactive", "")
                    imgui.PushStyleColor(imgui.Col.Text, colors.grey);
                else 
                    message = string.gsub(message, ">to", "")
                    imgui.PushStyleColor(imgui.Col.Text, colors.white);
                end
                imgui.TextWrapped(message)
                imgui.PopStyleColor()
            else
                imgui.PushStyleColor(imgui.Col.Text, colors.red);
                imgui.TextWrapped(message)
                imgui.PopStyleColor()
                if showReplyButton[0] then 
                    if imgui.Button(fa.ICON_FA_REPLY) then
                        sampSetChatInputEnabled(true)
                        playerId = getPlayerIdFromText(message)
                        sampSetChatInputText('/pm ' .. playerId .. ' ')
                    end 
                end
            end
        end
    elseif messageStream == 'admin' then
        for i, message in reversedipairs(adminArray) do
            local adminMessageColor = string.find(message, 'spectating') ~= nil and imgui.ImVec4(1.0, 1.0, 1.0, 1.0) or imgui.ImVec4(1.0, 0.0, 0.0, 1.0)
            imgui.PushStyleColor(imgui.Col.Text, adminMessageColor);
            imgui.TextWrapped(message)
            imgui.PopStyleColor()
        end
    else 
        imgui.Checkbox('Show reply button', showReplyButton)
        mainIni.settings.showReplyButton = showReplyButton[0]

        imgui.Checkbox('Block messages in chat', blockMessagesInChat)
        imgui.Text('Will be saved in chatlog')
        mainIni.settings.blockMessagesInChat = blockMessagesInChat[0]

        imgui.Checkbox('Show notifications', notificationsEnabled)
        mainIni.settings.notificationsEnabled = notificationsEnabled[0]

        inicfg.save(mainIni)
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
    return processServerMessage(text)
end

function writeToChatLog(text) 
    chatlog = io.open(getFolderPath(5).."\\GTA San Andreas User Files\\SAMP\\chatlog.txt", "a")
    chatlog:write(os.date("[%H:%M:%S] ")..text)
    chatlog:write("\n")
    chatlog:close()
    return false
end

function processServerMessage(text)
    timestamp = '[' .. os.date("%H:%M:%S") .. '] '
    if startsWith(text, 'ADMIN:') then
        local nameAction = string.match(text, 'ADMIN: (.*)')
        table.insert(adminArray, timestamp .. nameAction)
        haveNewAdminMessages = true
        if blockMessagesInChat[0] then
             writeToChatLog(text) 
             return false
        end
    elseif startsWith(text, '>> PM ') then
        local inactive = ''
        local to = ''
        
        if string.find(text, "(Not Active)") ~= nil then 
            inactive = 'Inactive'
        end
        
        if string.find(text, '>> PM to') ~= nil then
            to = '>to'
            clearNewMessagesIndicator()
        else 
            haveNewPMs = true
        end

        local playerName, pmMessage = string.match(text, '>> PM .* (.*) %(.*%): (.*)')
        local privateMessage = playerName .. ': ' .. pmMessage
        table.insert(pmArray, to .. inactive .. timestamp .. privateMessage)
        if blockMessagesInChat[0] then
            writeToChatLog(text) 
            return false
       end
    end
    return true
end

function clearNewMessagesIndicator() 
    haveNewPMs = false
    haveNewAdminMessages = false
    shouldShowNotification[0] = false
end

function toggleMessageStream()
    clearNewMessagesIndicator()
    messageStream = messageStream == 'pm' and 'admin' or 'pm'
end


function toggleNotification()
    shouldShowNotification[0] = true
end

function main()
    while not isSampAvailable() do
        wait(0)
    end

    while true do
        wait(10)
        if wasKeyPressed(VK_PAUSE) then
            if shouldShowMenu[0] then
                lua_thread.create(function()
                    wait(500)
                    if isKeyDown(VK_PAUSE) then
                        toggleShowMenu()
                    end
                end)
                toggleMessageStream()
            else
                toggleShowMenu()
            end
        end
        if isGamePaused() then shouldShowMenu[0] = false end

        if notificationsEnabled[0] and haveNewAdminMessages and not shouldShowMenu[0] then toggleNotification() end
        if notificationsEnabled[0] and haveNewPMs and not shouldShowMenu[0] then toggleNotification() end
    end

    if sampGetCurrentServerAddress() ~= "51.254.85.134" then
        return
    end
end

