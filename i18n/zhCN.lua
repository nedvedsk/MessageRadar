local _addonName, _addon = ...;
local L = _addon:AddLocalization("zhCN", true);
if L == nil then return; end

L["Anti-spam Interval"] = "防刷屏间隔";
L["Time window to suppress repeated notifications (seconds)"] = "设置相同消息在多少秒内不重复提醒";



L["FIRST_START_MSG"] = "|cFF00FF00" .. _addonName .. "|r|cFFffb178: 打开设置界面命令:/mr, 或点击地图按钮(设置可隐藏)";

L["CHAT_NOTIFY_FOUND_SAYYELL"] = "找到 |cFF00FF00%s|r! |cFFFF66FF|H玩家:%s|h[%s]|h|r: %s";
L["CHAT_NOTIFY_FOUND_CHANNEL"] = "找到 |cFF00FF00%s|r! |cFFFF66FF|H玩家:%s|h[%s]|h|r in %s: %s";

L["CHAT_NOTIFY_FORMAT"] = "<<ccaaaa>>[{T}] 找到 <00ff00>{K}<>! [{S}]<ff66ff>[{P}]<>: <ffffaa>{MS}<00ff00>{MF}<ffffaa>{ME}";
L["ERR_NOTIFY_FORMAT_MISSING"] = "通知格式没有设置,请到设置界面建立一个通知格式,或重置默认格式.";

L["SOUND_NO_SOUND"] = "- 无声 -";

L["SETTINGS_HEAD_GENERAL"] = "普通";
L["SETTINGS_PLAY_SOUND"] = "启用声音提示";
L["SETTINGS_PLAY_SOUND_TT"] = "找到关键词后发出声音提示.";
L["SETTINGS_TEST_CHAT"] = "测试通知";
L["SETTINGS_CHATFRAME"] = "通知发送频道:";
L["SETTINGS_CHATFRAME_TT"] = "选择显示通知的频道(聊天框名).";
L["SETTINGS_SNAP_MINIMAP"] = "图标依附小地图";
L["SETTINGS_SNAP_MINIMAP_TT"] = "图标依附至小地图框的边缘.";
L["SETTINGS_MINIMAP"] = "显示小地图图标";
L["SETTINGS_MINIMAP_TT"] = "显示地图按钮. 或者你可以使用 /mr.";
L["SETTINGS_SOUNDID"] = "提示音:";
L["SETTINGS_SOUNDID_TT"] = "选择通知提示音.";
L["SETTINGS_HEAD_FORMAT"] = "通知格式";
L["SETTINGS_FORMAT_DESC"] = 
[[用户可以自定义通知格式,可以参考默认的格式进行修改.

|cFFFFFF00定义颜色使用:
|cFF00FFFF<RRGGBB>|r 颜色字段. RRGGBB是16进制颜色码, 说明参见百度.
|cFF00FFFF<<RRGGBB>>|r 定义默认颜色,未设置即为白色.
|cFF00FFFF<>|r 后续字段采用默认颜色.

|cFFFFFF00字段占位符:
|cFF00FFFF{K}|r 搜索的关键字.
|cFF00FFFF{S}|r 信息的频道源.
|cFF00FFFF{P}|r 信息发送者的玩家名链接.
|cFF00FFFF{MS}|r 信息开始处.
|cFF00FFFF{MF}|r 信息中找到的关键字.
|cFF00FFFF{ME}|r 信息中其余文字
|cFF00FFFF{T}|r 当前服务器时间hh:mm.]];
L["SETTINGS_FORMAT_RESET"] = "重置默认格式";

L["VICINITY"] = "附近";

L["UI_ADDFORM_TITLE"] = "新建搜索";
L["UI_ADDFORM_NAME"] = "输入关键词，用&匹配多个词条，用-排除词条：";
L["UI_ADDFORM_ADD_BUTTON"] = "添加";
L["UI_BACK"] = "返回";
L["UI_ADDFORM_ERR_NO_INPUT"] = "词条还是空的!";

L["UI_RMALL_TITLE"] = "删除所有关键字段";
L["UI_RMALL_DESC"] = "确认列表中所有项目都被删除?";
L["UI_RMALL_REMOVE"] = "删除";
L["UI_CANCEL"] = "取消";

L["UI_MMB_OPEN"] = "打开 " .. _addonName;

L["UI_EDITFORM_TITLE"] = "编辑搜索";
L["UI_EDITFORM_CONFIRM_BUTTON"] = "确认修改";

L["SETTINGS_HEAD_CONFIG"] = "配置管理";
L["SETTINGS_EXPORT"] = "导出配置";
L["SETTINGS_EXPORT_TT"] = "点击生成配置字符串，可跨账号/角色分享。";
L["SETTINGS_IMPORT"] = "导入配置";
L["SETTINGS_IMPORT_TT"] = "粘贴配置字符串以覆盖当前角色的关键词和设置。";

L["IMPORT_TITLE"] = "导入 MessageRadar 配置";
L["IMPORT_DESC"] = "|cffff0000警告：|r 导入将覆盖当前角色的所有设置和关键词。粘贴字符串并确认：";
L["IMPORT_SUCCESS"] = "配置导入成功！正在重载界面...";
L["IMPORT_ERROR"] = "无效的配置字符串，导入失败。";
L["EXPORT_TITLE"] = "导出 MessageRadar 配置";
L["EXPORT_DESC"] = "这是您的配置字符串。请按 Ctrl+C 复制。";