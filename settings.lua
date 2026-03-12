local _addonName, _addon = ...;
local L = _addon:GetLocalization();

-- 兼容性处理 GetAddOnMetadata
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

local DEFAULTSETTINGS = {
    ["firstStart"] = true,
    ["isActive"] = true,
    ["chatFrame"] = 1,
    ["soundId"] = "sound/interface/itellmessage.ogg",
    ["showMinimapButton"] = true,
    ["snapToMinimap"] = true,
    ["outputFormat"] = "", -- fill from localization
    ["version"] = GetAddOnMetadata(_addonName, "Version"),
    ["antiSpamWindow"] = 10, -- 默认10秒的防刷屏间隔
    ["classColor"] = true,
};

local SOUNDS = {
    [""] = L["SOUND_NO_SOUND"],
    ["sound/Doodad/LightHouseFogHorn.ogg"] = "Fog horn", 		                    -- 567094
    ["sound/interface/itellmessage.ogg"] = "Whisper", 		                        -- 567421
    ["sound/character/dwarf/dwarfmale/dwarfmaledeatha.ogg"] = "Dwarf", 		        -- 539885
    ["sound/item/weapons/bow/arrowhitc.ogg"] = "Something", 	                    -- 567671
    ["sound/item/weapons/bow/arrowhita.ogg"] = "Something2",                        -- 567672
    ["sound/item/weapons/axe2h/m2haxehitmetalweaponcrit.ogg"] = "Hurts my ears"     -- 567653
};

--- Handle stuff after settings changed, if needed
local function AfterSettingsChange()
    _addon:MinimapButtonUpdate();
    if MessageRadar_settings.snapToMinimap then
        _addon:MinimapButtonSnap();
    end
end

--- Setup SV tables, check settings and setup settings menu
function _addon:SetupSettings()
	if MessageRadar_data == nil then
		MessageRadar_data = {};
	end
    
    if MessageRadar_settings == nil then
        MessageRadar_settings = DEFAULTSETTINGS;
    else
        for k, v in pairs(DEFAULTSETTINGS) do
            if MessageRadar_settings[k] == nil then
                MessageRadar_settings[k] = v;
            end
        end
    end
    
    -- 确保 outputFormat 不会被意外清空
    if MessageRadar_settings.outputFormat == "" then
        MessageRadar_settings.outputFormat = L["CHAT_NOTIFY_FORMAT"];
    end
        
    local settings = _addon:GetSettingsBuilder();
    settings:Setup(MessageRadar_settings, DEFAULTSETTINGS, nil, [[Interface\AddOns\MessageRadar\img\logos]], 192, 48, nil, 16);
    settings:SetAfterSaveCallback(AfterSettingsChange);

    settings:MakeHeading(L["SETTINGS_HEAD_GENERAL"]);
    


    -- 修改聊天窗口下拉菜单的创建方式
    settings:MakeDropdown("chatFrame", L["SETTINGS_CHATFRAME"], L["SETTINGS_CHATFRAME_TT"], 100, function() 
        local chatWindows = {};
        
        -- 确保 MessageRadar_settings 不为 nil
        local currentSettings = MessageRadar_settings or DEFAULTSETTINGS;
        
        -- 改进聊天窗口检测方法
        for i = 1, NUM_CHAT_WINDOWS do
            local name, _, _, _, _, _, shown, _, docked = GetChatWindowInfo(i);
            local chatFrame = _G["ChatFrame"..i];
            
            -- 检查聊天窗口是否存在且是显示或停靠状态
            if chatFrame and (shown or docked) then
                -- 如果名称为空或是"NOTSET!"，使用默认名称
                if not name or name == "" or name == "NOTSET!" then
                    name = "聊天窗口"..i;
                end
                chatWindows[i] = name;
            end
        end
        
        -- 如果当前设置的聊天窗口不在列表中，手动添加它
        if currentSettings.chatFrame and not chatWindows[currentSettings.chatFrame] then
            local frameNum = currentSettings.chatFrame;
            local name, _, _, _, _, _, shown, _, docked = GetChatWindowInfo(frameNum);
            
            -- 只有当窗口是显示或停靠状态时才添加
            if shown or docked then
                -- 如果名称为空或是"NOTSET!"，使用默认名称
                if not name or name == "" or name == "NOTSET!" then
                    name = "聊天窗口"..frameNum;
                end
                chatWindows[frameNum] = name;
            end
        end
        
        -- 如果列表为空，至少添加默认聊天窗口
        if next(chatWindows) == nil then
            local name = GetChatWindowInfo(1);
            if not name or name == "" or name == "NOTSET!" then
                name = "聊天窗口1";
            end
            chatWindows[1] = name;
        end
        
        return chatWindows;
    end, 138);

    
    -- 移除有问题的HookScript代码
    
    settings:MakeDropdown("soundId", L["SETTINGS_SOUNDID"], L["SETTINGS_SOUNDID_TT"], 100, function() 
        return SOUNDS;
    end, 138);

    -- 在适当的位置添加反刷屏设置
    local row = settings:MakeSettingsRow();
    local antispam = settings:MakeSliderOption("antiSpamWindow", L["Anti-spam Interval"], L["Time window to suppress repeated notifications (seconds)"], 0, 60, 1, row)
    settings:MakeCheckboxOption("showMinimapButton", L["SETTINGS_MINIMAP"], L["SETTINGS_MINIMAP_TT"], row);

    settings:MakeHeading(L["SETTINGS_HEAD_FORMAT"]);
    settings:MakeStringRow(L["SETTINGS_FORMAT_DESC"], "LEFT");

    local formatEdit = settings:MakeEditBoxOption("outputFormat", nil, 200, false, nil, nil, 0);
    local prevString = settings:MakeStringRow();
    
    -- 修改 OnTextChanged 事件处理
    formatEdit:SetScript("OnTextChanged", function(self) 
        local newFormat = formatEdit:GetText();
        MessageRadar_settings.outputFormat = newFormat;  -- 直接保存新格式
        local preview = _addon:FormNotifyMsg("mankrik", "1. General", GetUnitName("player"), "LFM mankriks wife exploration team!", 5, 11);
        prevString:SetText(preview);
    end);

    row = settings:MakeSettingsRow();

    -- 修改测试按钮，确保它使用正确的聊天窗口
    settings:MakeButton(L["SETTINGS_TEST_CHAT"], function() 
        local oldSound = MessageRadar_settings.soundId;
        local oldFormat = MessageRadar_settings.outputFormat;
        MessageRadar_settings.outputFormat = formatEdit:GetText();
        if settings:GetTempSettings().soundId then
            MessageRadar_settings.soundId = settings:GetTempSettings().soundId;
        end
        
        -- 直接使用当前保存的聊天窗口设置
        local chatFrameToUse = MessageRadar_settings.chatFrame;
        
        _addon:PostNotification(_addon:FormNotifyMsg("mankrik", L["VICINITY"], GetUnitName("player"), 
            "LFM mankriks wife exploration team!", 5, 11), chatFrameToUse);
        MessageRadar_settings.soundId = oldSound;
        MessageRadar_settings.outputFormat = oldFormat;
    end, row);

    settings:MakeButton(L["SETTINGS_FORMAT_RESET"], function() 
        MessageRadar_settings.outputFormat = L["CHAT_NOTIFY_FORMAT"];
        formatEdit:SetText(MessageRadar_settings.outputFormat);
        formatEdit:SetCursorPosition(0);
    end, row);

    -- 增加间距
    local spacer = CreateFrame("Frame", nil, row);
    spacer:SetSize(40, 10);
    row:AddElement(spacer, 40);

    settings:MakeButton(L["SETTINGS_EXPORT"], function() 
        StaticPopup_Show("MESSAGERADAR_EXPORT");
    end, row, 100);

    settings:MakeButton(L["SETTINGS_IMPORT"], function() 
        StaticPopup_Show("MESSAGERADAR_IMPORT");
    end, row, 100);
end