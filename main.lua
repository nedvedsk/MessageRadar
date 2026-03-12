local _addonName, _addon = ...;
local L = _addon:GetLocalization();

local frame = CreateFrame("Frame");
local handlers = {};
local playerName = UnitName("player");

---- { keep spam from entering the notifier channel
local anti_spam = CreateFrame("Frame")
local lasttenseconds = {}
local function lasttenseconds_updater()
    if not lasttenseconds then return end
    if not anti_spam.lastcheck then anti_spam.lastcheck = GetTime() end
    
    -- 使用保存的设置值而不是硬编码的值
    local antiSpamWindow = MessageRadar_settings and MessageRadar_settings.antiSpamWindow or 10
    
    if GetTime() - anti_spam.lastcheck < antiSpamWindow*2 then return end
    for s, t in pairs(lasttenseconds) do
        if GetTime()-t > antiSpamWindow then
            lasttenseconds[s] = nil
        end
    end
    anti_spam.lastcheck = GetTime()
end
anti_spam:SetScript("OnUpdate", lasttenseconds_updater)
---- hk }

---- { For searching efficiency 
local searchcache = {}
searchcache.blocker = {}

local function addToCache(search)
    local t = {}
    t["block"] = {}
    t["match"] = {}
    t.blocker = false
    for k in string.gmatch(search, "-([^&%-]+)") do
        table.insert(t.block, k)
    end
    for k in string.gmatch(search, "&([^&%-]+)") do
        table.insert(t.match, k)
    end

    if string.sub(search, 1, 1) ~= "-" then     
        local head = string.match(search, "^(.-)[&%-]")
        if head then 
            table.insert(t.match, head) 
        end
    end
    if next(t.match)==nil then t.isBlocker = true end
    searchcache[search] = t
end

local function _hfind(msglow, search)
    local fstart, fend
    if string.find(search,"[&%-]") then
        if not searchcache[search] then addToCache(search) end
        local t = searchcache[search]
        if t.isBlocker then return nil, nil end
        for _, k in pairs(t.block) do
            fstart = string.find(msglow, k)
            if fstart then return nil, nil end
        end
        for _, k in pairs(t.match) do
            fstart, fend = string.find(msglow, k)
            if not fstart then return nil, nil end
        end
        return fstart, fend
    end
    return string.find(msglow, search)
end

local function ShouldBlock(msg)
    for _, data in pairs(MessageRadar_data) do
        if data.active then
            for _, search in pairs(data.words) do
                if string.sub(search, 1, 1) == "-" and not string.find(search,"&") then
                    for k in string.gmatch(search, "-([^%-]+)") do
                        if string.find(msg, k) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false;
end
---- hk }



--- Add new entry to the list
-- @param search The string to search for
function _addon:AddToList(search)
    local ntable = {
        active = true,
        words = {}
    };
    
    for found in string.gmatch(search, "([^,]+)") do
        table.insert(ntable.words, strtrim(found):lower());
    end

    MessageRadar_data[search] = ntable;
    _addon:MainUI_UpdateList();
    -- 添加这一行，确保在添加新关键词后更新插件状态
    _addon:UpdateAddonState();
end

--- Remove entry from list
-- @param search The string to remove
function _addon:RemoveFromList(search)
    MessageRadar_data[search] = nil;
    _addon:MainUI_UpdateList();
end

--- Toggle entry active state
-- @param search The search string to toggle
-- @return the new state
function _addon:ToggleEntry(search)
    if MessageRadar_data[search] ~= nil then
        MessageRadar_data[search].active = not MessageRadar_data[search].active;
        -- 添加这一行，确保在切换关键词状态后更新插件状态
        _addon:UpdateAddonState();
        return MessageRadar_data[search].active;
    end
    return false;
end

--- Clear the whole list
function _addon:ClearList()
    wipe(MessageRadar_data);
    _addon:MainUI_UpdateList();
    -- 添加这一行，确保在清空列表后更新插件状态
    _addon:UpdateAddonState();
end

--- Form notification msg from msg format template
-- @param search The found keyword
-- @param source The source of the message
-- @param from The player it is from
-- @param msg The message from chat
-- @param searchstart Start position of found keyword in message
-- @param searchend End position of found keyword in message
-- @param guid The GUID of the player (for class color)
-- @return The finished message string
function _addon:FormNotifyMsg(search, source, from, msg, searchstart, searchend, guid)
    local formed = MessageRadar_settings.outputFormat;
    
    -- Default color
    local fstart, fend = string.find(formed, "<<%x%x%x%x%x%x>>");
    local defaultColor = "|r";
    if fstart ~= nil then
        defaultColor = "|cFF" .. string.sub(formed, fstart+2, fend-2);
        formed = string.gsub(formed, "<<%x%x%x%x%x%x>>", defaultColor);
    end
    formed = string.gsub(formed, "<>", defaultColor);

    -- Colors
    fstart, fend = string.find(formed, "<%x%x%x%x%x%x>");
    while fstart ~= nil do
        formed = string.gsub(formed, string.sub(formed, fstart, fend), "|cFF"..string.sub(formed, fstart+1, fend-1));
        fstart, fend = string.find(formed, "<%x%x%x%x%x%x>");
    end

    -- remove server dash
    local dashLoc = string.find(from, "-");
    if dashLoc ~= nil then
        from = string.sub(from, 1, dashLoc-1);
    end

    -- 应用职业着色
    local playerStr = from
    if guid then
        local _, englishClass = GetPlayerInfoByGUID(guid)
        if englishClass then
            -- 定义职业颜色表
            local CLASS_COLORS = {
                ["WARRIOR"] = "C79C6E",
                ["PALADIN"] = "F58CBA",
                ["HUNTER"] = "ABD473",
                ["ROGUE"] = "FFF569",
                ["PRIEST"] = "FFFFFF",
                ["SHAMAN"] = "0070DE",
                ["MAGE"] = "69CCF0",
                ["WARLOCK"] = "9482C9",
                ["DRUID"] = "FF7D0A",
            }
            
            -- 尝试使用游戏内置的职业颜色
            local colorStr
            if RAID_CLASS_COLORS and RAID_CLASS_COLORS[englishClass] then
                colorStr = RAID_CLASS_COLORS[englishClass].colorStr
                if colorStr and string.sub(colorStr, 1, 2) == "ff" then
                    colorStr = string.sub(colorStr, 3)
                end
            end
            
            -- 如果游戏内置颜色不可用，使用我们自定义的颜色
            if not colorStr and CLASS_COLORS[englishClass] then
                colorStr = CLASS_COLORS[englishClass]
            end
            
            if colorStr then
                playerStr = "|cff" .. colorStr .. playerStr .. "|r"
            end
        end
    end

    -- 创建一个安全的玩家链接
    local playerLink = string.format("|Hplayer:%s|h%s|h", from, playerStr)
    
    -- 准备所有替换值
    local timeStr = date("%H:%M")
    local msText = ""
    if searchstart > 1 then
        msText = string.sub(msg, 1, searchstart-1)
    end
    
    local mfText = string.sub(msg, searchstart, searchend)
    
    local meText = ""
    if searchend < msg:len() then
        meText = string.sub(msg, searchend+1, msg:len())
    end
    
    -- 使用字符串连接而不是gsub进行替换
    -- 首先创建一个替换表
    local replacements = {
        ["{K}"] = search,
        ["{S}"] = source,
        ["{T}"] = timeStr,
        ["{P}"] = playerLink,
        ["{MS}"] = msText,
        ["{MF}"] = mfText,
        ["{ME}"] = meText
    }
    
    -- 然后使用一个安全的方式进行替换
    for pattern, replacement in pairs(replacements) do
        -- 使用普通字符串查找和替换，而不是正则表达式
        local startPos, endPos = string.find(formed, pattern, 1, true)
        while startPos do
            formed = string.sub(formed, 1, startPos-1) .. replacement .. string.sub(formed, endPos+1)
            startPos, endPos = string.find(formed, pattern, 1, true)
        end
    end

    return formed
end

--- Output message to set chatframe
-- @param notiMsg The message to post to chat
-- @param frameNum The chat tab to output to
function _addon:PostNotification(notiMsg, frameNum)
    if strtrim(notiMsg):len() == 0 then
        _addon:PrintError(L["ERR_NOTIFY_FORMAT_MISSING"]);
    else
        -- 检查聊天框是否存在
        local chatFrame = _G["ChatFrame"..frameNum];
        if chatFrame then
            chatFrame:AddMessage(notiMsg);
        else
            DEFAULT_CHAT_FRAME:AddMessage(notiMsg);
        end
    end

    -- 播放声音
    if MessageRadar_settings.soundId ~= "" then
        PlaySoundFile(MessageRadar_settings.soundId, "Master");
    end
    
    -- 闪烁聊天标签
    local chatFrame = _G["ChatFrame"..frameNum];
    if chatFrame then
        FCF_StartAlertFlash(chatFrame);
    else
        FCF_StartAlertFlash(DEFAULT_CHAT_FRAME);
    end
end

-- 修改 SearchMessage 函数，将其作为 _addon 的方法，并恢复复杂搜索功能
function _addon:SearchMessage(msg, from, source, guid)
    local msglow = string.lower(msg);
    if ShouldBlock(msglow) then return end
    
    -- 添加反刷屏检查
    local message_hash = from .. ":" .. msglow
    local currentTime = GetTime()
    
    -- 使用保存的设置值而不是直接访问可能尚未初始化的设置
    local antiSpamWindow = MessageRadar_settings and MessageRadar_settings.antiSpamWindow or 10
    
    if lasttenseconds[message_hash] and (currentTime - lasttenseconds[message_hash] < antiSpamWindow) then
        return -- 在设置的时间窗口内，忽略此消息
    end
    lasttenseconds[message_hash] = currentTime
    
    local fstart, fend;
    for _, data in pairs(MessageRadar_data) do
        if data.active then
            for _, search in pairs(data.words) do
                fstart, fend = _hfind(msglow, search);
                if fstart ~= nil then
                    if from == playerName then
                        return;
                    end
                    
                    local notiMsg = self:FormNotifyMsg(search, source, from, msg, fstart, fend, guid)
                    self:PostNotification(notiMsg, MessageRadar_settings.chatFrame)
                    return;
                end
            end
        end
    end
end

-- 修复 UpdateAddonState 函数结构
function _addon:UpdateAddonState()
    -- 更新小地图按钮图标
    if self.MinimapButtonUpdate then
        self:MinimapButtonUpdate()
    end
    
    -- 如果主界面存在，更新其状态
    if MRUI_MainUI then
        MRUI_MainUI:UpdateAddonState()
    end
    
    -- 检查插件是否激活
    if MessageRadar_settings.isActive then
        -- 检查是否有任何关键词处于激活状态
        local hasActiveKeywords = false
        for _, data in pairs(MessageRadar_data or {}) do
            if data.active then
                hasActiveKeywords = true
                break
            end
        end
        
        -- 根据是否有激活的关键词来注册或取消注册事件
        if hasActiveKeywords then
            frame:RegisterEvent("CHAT_MSG_CHANNEL")
            frame:RegisterEvent("CHAT_MSG_SAY")
            frame:RegisterEvent("CHAT_MSG_YELL")
            -- 不在这里打印提示信息
        else
            frame:UnregisterEvent("CHAT_MSG_CHANNEL")
            frame:UnregisterEvent("CHAT_MSG_SAY")
            frame:UnregisterEvent("CHAT_MSG_YELL")
            -- 不在这里打印提示信息
        end
    else
        frame:UnregisterEvent("CHAT_MSG_CHANNEL")
        frame:UnregisterEvent("CHAT_MSG_SAY")
        frame:UnregisterEvent("CHAT_MSG_YELL")
        -- 不在这里打印提示信息
    end
end


function handlers.ADDON_LOADED(addonName)
    if addonName ~= _addonName then 
        return; 
    end
    frame:UnregisterEvent("ADDON_LOADED");
    
    -- 首先调用 SetupSettings 来确保 MessageRadar_settings 被正确初始化
    _addon:SetupSettings();
    
    -- 确保 antiSpamWindow 设置有效
    if MessageRadar_settings.antiSpamWindow == nil or MessageRadar_settings.antiSpamWindow < 0 then
        MessageRadar_settings.antiSpamWindow = 10;
    end
    
    -- 确保 chatFrame 设置有效
    if not MessageRadar_settings.chatFrame then
        MessageRadar_settings.chatFrame = 1;
    end
    
    _addon:MainUI_UpdateList();
    _addon:UpdateAddonState();

    -- 添加插件加载时的提示逻辑
    if MessageRadar_settings.isActive then
        -- 检查是否有任何关键词处于激活状态
        local hasActiveKeywords = false
        for _, data in pairs(MessageRadar_data or {}) do
            if data.active then
                hasActiveKeywords = true
                break
            end
        end
        
        if hasActiveKeywords then
            print("|cFF00FF00MessageRadar|r: 已启用聊天监控")
        else
            print("|cFF00FF00MessageRadar|r: 没有启用任何关键词监控")
        end
    else
        print("|cFF00FF00MessageRadar|r: 聊天监控已关闭")
    end

    if MessageRadar_settings.firstStart then
        _addon:MainUI_OpenList();
        print(L["FIRST_START_MSG"]);
        MessageRadar_settings.firstStart = false;
        -- 仅在用户没有自定义格式时设置默认格式
        if MessageRadar_settings.outputFormat == "" then
            MessageRadar_settings.outputFormat = L["CHAT_NOTIFY_FORMAT"];
        end
    end
end

-- 修改事件处理函数，确保它们调用 _addon:SearchMessage
-- 修改事件处理函数，移除调试代码
function handlers.CHAT_MSG_CHANNEL(text, playerName, _, channelName, _, _, _, _, _, _, _, guid)
    _addon:SearchMessage(text, playerName, channelName, guid);
end

function handlers.CHAT_MSG_SAY(text, playerName, _, _, _, _, _, _, _, _, _, guid)
    _addon:SearchMessage(text, playerName, L["VICINITY"], guid);
end

function handlers.CHAT_MSG_YELL(text, playerName, _, _, _, _, _, _, _, _, _, guid)
    _addon:SearchMessage(text, playerName, L["VICINITY"], guid);
end

frame:SetScript("OnEvent", function(self, event, ...) 
    if handlers[event] then
        handlers[event](...);
    end
end)

frame:RegisterEvent("ADDON_LOADED");


------------------------------------------------
-- Slash command
------------------------------------------------

SLASH_MESSAGERADAR1 = "/mr";
SlashCmdList["MESSAGERADAR"] = function(arg)
    _addon:MainUI_OpenList();
end;


SLASH_MRFRAME1 = "/mrframe";
SlashCmdList["MRFRAME"] = function(arg)
    -- 显示当前聊天框信息
    local currentFrame = MessageRadar_settings.chatFrame;
    local currentName = GetChatWindowInfo(currentFrame);
    
    -- 如果名称为空或无效，使用默认名称
    if not currentName or currentName == "" then
        currentName = "聊天窗口"..currentFrame;
    end
    
    print("|cFF00FF00MessageRadar|r: 当前使用的聊天窗口: " .. currentFrame .. " (" .. currentName .. ")");
    print("可用的聊天窗口:");
    
    local foundFrames = false;
    for i = 1, NUM_CHAT_WINDOWS do
        local name, _, _, _, _, _, shown, _, docked = GetChatWindowInfo(i);
        if (shown or docked) then
            foundFrames = true;
            -- 如果名称为空或无效，使用默认名称
            if not name or name == "" then
                name = "聊天窗口"..i;
            end
            
            if i == currentFrame then
                print("  |cFF00FF00" .. i .. ": " .. name .. " (当前选择)|r");
           else
                print("  " .. i .. ": " .. name);
            end
        end
    end
    
    if not foundFrames then
        print("  未检测到任何聊天窗口");
    end
end;

------------------------------------------------
-- Import/Export Logic
------------------------------------------------
function _addon:ExportConfig()
    if not LibStub then
        print("|cFFFF0000MessageRadar Error: LibStub not found!|r")
        return ""
    end

    local LibSerialize = LibStub("LibSerialize", true)
    local LibDeflate = LibStub("LibDeflate", true)
    
    if not LibSerialize or not LibDeflate then
        print("|cFFFF0000MessageRadar Error: Libraries not found (LibSerialize or LibDeflate)|r")
        return ""
    end
    
    local exportTable = {
        settings = MessageRadar_settings,
        data = MessageRadar_data,
        version = 1 -- Internal version for future compatibility
    }
    
    local success, serialized = pcall(LibSerialize.Serialize, LibSerialize, exportTable)
    if not success then
        print("|cFFFF0000MessageRadar Error: Serialization failed: |r" .. tostring(serialized))
        return ""
    end
    
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    
    return encoded
end

function _addon:ImportConfig(encoded)
    if not LibStub then
        print("|cFFFF0000MessageRadar Error: LibStub not found!|r")
        return false
    end

    local LibSerialize = LibStub("LibSerialize", true)
    local LibDeflate = LibStub("LibDeflate", true)
    
    if not LibSerialize or not LibDeflate then
        print("|cFFFF0000MessageRadar Error: Libraries not found (LibSerialize or LibDeflate)|r")
        return false
    end
    
    if not encoded or encoded == "" then return false end
    
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then return false end
    
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return false end
    
    local success, importTable = LibSerialize:Deserialize(decompressed)
    if not success or type(importTable) ~= "table" then return false end
    
    -- Basic validation
    if not importTable.settings or not importTable.data then return false end
    
    -- Overwrite settings and data
    _G["MessageRadar_settings"] = importTable.settings
    _G["MessageRadar_data"] = importTable.data
    
    return true
end

-- StaticPopupDialogs
StaticPopupDialogs["MESSAGERADAR_EXPORT"] = {
    text = L["EXPORT_TITLE"] .. "\n\n" .. L["EXPORT_DESC"],
    button1 = CLOSE,
    hasEditBox = true,
    maxLetters = 0,
    OnShow = function(self)
        local editBox = self.editBox or _G[self:GetName().."EditBox"]
        if editBox then
            local encoded = _addon:ExportConfig()
            editBox:SetText(encoded)
            editBox:HighlightText()
            editBox:SetFocus()
        end
    end,
    EditBoxOnEnterPressed = function(self)
        self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
};

StaticPopupDialogs["MESSAGERADAR_IMPORT"] = {
    text = L["IMPORT_TITLE"] .. "\n\n" .. L["IMPORT_DESC"],
    button1 = OKAY,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 0,
    OnAccept = function(self)
        local editBox = self.editBox or _G[self:GetName().."EditBox"]
        if not editBox then return end
        local encoded = editBox:GetText()
        if _addon:ImportConfig(encoded) then
            print("|cFF00FF00MessageRadar|r: " .. L["IMPORT_SUCCESS"])
            ReloadUI()
        else
            print("|cFFFF0000MessageRadar|r: " .. L["IMPORT_ERROR"])
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        if StaticPopupDialogs[parent.which].OnAccept then
            StaticPopupDialogs[parent.which].OnAccept(parent)
        end
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
};