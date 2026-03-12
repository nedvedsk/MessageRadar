local _addonName, _addon = ...;
local L = _addon:GetLocalization();

local HEIGHT_NO_CONTENT = 71;
local listItemHeight = MRUI_MainUI.scrollFrame.items[1]:GetHeight();
local listElementCount = #MRUI_MainUI.scrollFrame.items;
local maxElementCount = listElementCount;

local sortedEntries = {};
local entryCount = 0;

----------------------------------------------------------------------------------------------------------------
-- Top bar button actions
----------------------------------------------------------------------------------------------------------------

--- Open settings menu
MRUI_MainUI.settingsBtn:SetScript("OnClick", function(self) 
    if Settings and Settings.OpenToCategory then
        -- 新版本界面系统
        if _G.MR_Category and _G.MR_Category.ID then
            Settings.OpenToCategory(_G.MR_Category.ID)
        else
            -- 尝试获取插件设置对象
            local settingsBuilder = _addon:GetSettingsBuilder()
            if settingsBuilder and settingsBuilder.categoryID then
                Settings.OpenToCategory(settingsBuilder.categoryID.ID)
            else
                Settings.OpenToCategory(_addonName)
            end
        end
    elseif InterfaceOptionsFrame_OpenToCategory then
        -- 旧版本界面系统
        InterfaceOptionsFrame_OpenToCategory(_addonName);
        InterfaceOptionsFrame_OpenToCategory(_addonName); -- 调用两次是为了解决某些版本的WoW中的已知问题
    else
        -- 如果都不存在，使用替代方法
        if InterfaceOptionsFrame and InterfaceOptionsFrame.Show then
            InterfaceOptionsFrame:Show()
        end
        print("|cFF00FF00MessageRadar|r: 请在界面选项中找到MessageRadar进行设置")
    end
end);

--- Open add frame
MRUI_MainUI.addBtn:SetScript("OnClick", function(self)
    _addon:MainUI_ShowAddForm();
end);

--- Toggle addon on/off
MRUI_MainUI.toggleBtn:SetScript("OnClick", function(self) 
    -- 切换设置
    MessageRadar_settings.isActive = not MessageRadar_settings.isActive
    
    -- 根据新状态显示不同的提示信息
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
        print("|cFF00FF00MessageRadar|r: 已关闭聊天监控")
    end
    
    -- 更新界面状态
    MRUI_MainUI:UpdateAddonState()
    
    -- 调用主函数中的 UpdateAddonState 来处理事件注册
    _addon:UpdateAddonState()
end);

--- Open delete frame
MRUI_MainUI.deleteBtn:SetScript("OnClick", function(self) 
    MRUI_MainUI:ShowContent("RM");
end);


----------------------------------------------------------------------------------------------------------------
-- Content frame button actions
----------------------------------------------------------------------------------------------------------------

-- Delete all frame buttons
MRUI_MainUI.deleteAllFrame.okbutton:SetScript("OnClick", function(self) 
    _addon:ClearList();
    MRUI_MainUI:ShowContent("LIST");
end);
MRUI_MainUI.deleteAllFrame.backbutton:SetScript("OnClick", function(self) 
    MRUI_MainUI:ShowContent("LIST");
end);

-- Add frame buttons
MRUI_MainUI.addFrame.okbutton:SetScript("OnClick", function (self)
    local sstring = MRUI_MainUI.addFrame.searchEdit:GetText();
    sstring = strtrim(sstring);
    if string.len(sstring) == 0 then
        _addon:PrintError(L["UI_ADDFORM_ERR_NO_INPUT"]);
		return;
    end
	_addon:AddToList(sstring);
	MRUI_MainUI:ShowContent("LIST");
end);
MRUI_MainUI.addFrame.backbutton:SetScript("OnClick", function (self)
	MRUI_MainUI:ShowContent("LIST");
end);


----------------------------------------------------------------------------------------------------------------
-- Control functions
----------------------------------------------------------------------------------------------------------------

--- Show the add form
-- @param search A search string to prefill (optional)
function _addon:MainUI_ShowAddForm(search)
    if search == nil and MRUI_MainUI:IsShown() and MRUI_MainUI.addFrame:IsShown() then 
        return; 
    end
    
	MRUI_MainUI.addFrame.searchEdit:SetText("");
	if search ~= nil then
		MRUI_MainUI.addFrame.searchEdit:SetText(search);
		MRUI_MainUI.addFrame.searchEdit:SetCursorPosition(0);
    else
        MRUI_MainUI.addFrame.searchEdit:SetFocus();
    end
    
    MRUI_MainUI:Show();
    MRUI_MainUI:ShowContent("ADD");
end

--- Update scroll frame 
local function UpdateScrollFrame()
    local scrollHeight = 0;
	if entryCount > 0 then
        scrollHeight = (entryCount - listElementCount) * listItemHeight;
        if scrollHeight < 0 then
            scrollHeight = 0;
        end
    end

    local maxRange = (entryCount - listElementCount) * listItemHeight;
    if maxRange < 0 then
        maxRange = 0;
    end

    MRUI_MainUI.scrollFrame.ScrollBar:SetMinMaxValues(0, maxRange);
    MRUI_MainUI.scrollFrame.ScrollBar:SetValueStep(listItemHeight);
    MRUI_MainUI.scrollFrame.ScrollBar:SetStepsPerPage(listElementCount-1);

    if MRUI_MainUI.scrollFrame.ScrollBar:GetValue() == 0 then
        MRUI_MainUI.scrollFrame.ScrollBar.ScrollUpButton:Disable();
    else
        MRUI_MainUI.scrollFrame.ScrollBar.ScrollUpButton:Enable();
    end

    if (MRUI_MainUI.scrollFrame.ScrollBar:GetValue() - scrollHeight) == 0 then
        MRUI_MainUI.scrollFrame.ScrollBar.ScrollDownButton:Disable();
    else
        MRUI_MainUI.scrollFrame.ScrollBar.ScrollDownButton:Enable();
    end	

    for line = 1, listElementCount, 1 do
      local offsetLine = line + FauxScrollFrame_GetOffset(MRUI_MainUI.scrollFrame);
      local item = MRUI_MainUI.scrollFrame.items[line];
      if offsetLine <= entryCount then
        curdta = MessageRadar_data[sortedEntries[offsetLine]];
        item.searchString:SetText(sortedEntries[offsetLine]);
		if curdta.active then
			item.disb:SetNormalTexture([[Interface\AddOns\MessageRadar\img\on]]);
            item.disb:SetHighlightTexture([[Interface\AddOns\MessageRadar\img\on]]);
            item.disb:GetParent():SetBackdropColor(0.2,0.2,0.2,0.8);
            item.searchString:SetTextColor(1, 1, 1, 1);
		else
			item.disb:SetNormalTexture([[Interface\AddOns\MessageRadar\img\off]]);
            item.disb:SetHighlightTexture([[Interface\AddOns\MessageRadar\img\off]]);
            item.disb:GetParent():SetBackdropColor(0.2,0.2,0.2,0.4);
            item.searchString:SetTextColor(0.5, 0.5, 0.5, 1);
        end
        item:Show();
      else
        item:Hide();
      end
    end
end

--- Recalculates height and shown item count
-- @param ignoreHeight If true will not resize and reanchor UI
local function RecalculateSize(ignoreHeight)
    local oldHeight = MRUI_MainUI:GetHeight();
    local showCount = math.floor((oldHeight - HEIGHT_NO_CONTENT + (listItemHeight/2 + 2)) / listItemHeight);

    if ignoreHeight ~= true then
        local newHeight = showCount * listItemHeight + HEIGHT_NO_CONTENT;

        MRUI_MainUI:SetHeight(newHeight);

        local point, relTo, relPoint, x, y = MRUI_MainUI:GetPoint(1);
        local yadjust = 0;

        if point == "CENTER" or point == "LEFT" or point == "RIGHT" then
            yadjust = (oldHeight - newHeight) / 2;
        elseif point == "BOTTOM" or point == "BOTTOMRIGHT" or point == "BOTTOMLEFT" then
            yadjust = oldHeight - newHeight;
        end

        MRUI_MainUI:ClearAllPoints();
        MRUI_MainUI:SetPoint(point, relTo, relPoint, x, y + yadjust);
    end

    for i = 1, maxElementCount, 1 do
        if i > showCount then
            MRUI_MainUI.scrollFrame.items[i]:Hide();
        end
    end

    listElementCount = showCount;
    UpdateScrollFrame();
end

--- Fill list from SV data
function _addon:MainUI_UpdateList()
	entryCount = 0;
	wipe(sortedEntries);
	for k in pairs(MessageRadar_data) do 
		table.insert(sortedEntries, k);
		entryCount = entryCount + 1;
	end
    table.sort(sortedEntries);
    UpdateScrollFrame();
end

--- Open the main list frame
function _addon:MainUI_OpenList()
    MRUI_MainUI:Show();
    MRUI_MainUI:ShowContent("LIST");
    MRUI_MainUI:UpdateAddonState();
    RecalculateSize(true);
    UpdateScrollFrame();
end


----------------------------------------------------------------------------------------------------------------
-- Resize behaviour
----------------------------------------------------------------------------------------------------------------

-- Trigger update on scroll action
MRUI_MainUI.scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, listItemHeight, UpdateScrollFrame);
end);

MRUI_MainUI.resizeBtn:SetScript("OnMouseDown", function(self, button) 
    MRUI_MainUI:StartSizing("BOTTOMRIGHT"); 
end);

-- Resize snaps to full list items shown, updates list accordingly
MRUI_MainUI.resizeBtn:SetScript("OnMouseUp", function(self, button) 
    MRUI_MainUI:StopMovingOrSizing(); 
    RecalculateSize();
end);