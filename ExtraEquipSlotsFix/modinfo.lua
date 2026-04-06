local isCh = locale == "zh" or locale == "zhr"--是否为中文
name = isCh and "四/五/六格装备栏 个人修复版" or "Extra Equip Slots+1/2/3 self fix"
description = isCh and [[四/五/六格装备栏 适配了拳击袋，修复了虚空长袍，亮茄甲，荆棘茄甲修复之后变成背包槽位的版本]] 
or 
[[ Personalized customization，Original mod: 2950481491]]
author = "[Geraint小白、冷逸修、凛子不是林子、xingmot星莫]"
version = "4.7.3.6"

api_version = 10

priority = 100

-- This mod is both server and client.
all_clients_require_mod = true
client_only_mod = false

-- This mod is functional with Don't Starve Together only.
dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true

-- These tags allow the server running this mod to be found with filters from the server listing screen.
server_filter_tags = {"equip equipment slot body backpack armor clothing amulet"}

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

-- Configuration options.
local slot_options_not_implemented = isCh and {
    {data = false       , description = "不可调"}, 
} or
{
    {data = false       , description = "Disabled"}, 
}
local slot_options = isCh and {
    {data = false       , description = "关闭"},
    {data = "extrabody1", description = "插槽1"},
    {data = "extrabody2", description = "插槽2"},
    {data = "extrabody3", description = "插槽3"},
} or
{
    {data = false       , description = "OFF"},
    {data = "extrabody1", description = "Num 1"},
    {data = "extrabody2", description = "Num 2"},
    {data = "extrabody3", description = "Num 3"}, 
}

local function Subtitle(name)
    return {
        name = name,
        label = name,
        options = { {description = "", data = false}, },
        default = false,
    }
end

configuration_options = isCh and {
    Subtitle("插槽位置"),
    {
        name = "slot_armor",
        label = "(启用护甲特效修复请关闭)护甲栏",
        hover = "您想让你的护甲穿在那个位置？",
        default = "extrabody1",
        options = slot_options,
    },
    {
        name = "slot_clothing",
        label = "服装栏",
        hover = "您想让你的服装穿在那个位置？",
        default = "extrabody2",
        options = slot_options,
    },
    {
        name = "slot_amulet",
        label = "护符栏",
        hover = "您想让你的护符穿在那个位置？",
        default = "extrabody3",
        options = slot_options,
    },
    Subtitle("UI相关"),
    {
        name = "config_render",
        label = "人物是否显示所有装备外形？",
        hover = "如果选否，则仅显示最后装备或未装备的人物外表。 "
             .. "如果有模组物品不显示外形，请选否",
        default = true,
        options = {
            {data = false, description = "否"},
            {data = true,  description = "是"},
        },
    },
    Subtitle("测试内容(会崩)"),
    {
        name = "slot_backpack",
        label = "MOD护甲特效修复",
        hover = "开启后，[请将护甲槽位调整为关闭]，开启后会将护甲和背包槽位互换，并且会出现诸多bug",
        default = false,
        options = {
            {data = false, description = "关闭"},
            {data = "extrabody1",  description = "启用"},
        },
    },
    {
        name = "slot_heavy",
        label = "重型物品",
        hover = "您想在哪个插槽中装备重型物品？(骑牛崩溃)",
        default = false,
        options = slot_options,
    },
    {
        name = "slot_band",
        label = "独奏乐器",
        hover = "您想在哪个插槽中装备独奏乐器？",
        default = false,
        options = slot_options,
    },
    -- {
    --     name = "slot_shell",
    --     label = "蜗壳护甲",
    --     hover = "您想在哪个插槽中装备蜗壳护甲？",
    --     default = false,
    --     options = slot_options_not_implemented,
    -- },
    {
        name = "slot_lifevest",
        label = "救生衣",
        hover = "您想在哪个插槽中装备救生衣？",
        default = false,
        options = slot_options,
    },
} or
{
    Subtitle("Slot Position"),
    {
        name = "slot_armor",
        label = "Armor slot",
        hover = "Where do you want your armor to be worn?",
        default = "extrabody1",
        options = slot_options,
    },
    {
        name = "slot_clothing",
        label = "Clothing slot",
        hover = "Where do you want your clothing to be worn?",
        default = "extrabody2",
        options = slot_options,
    },
    {
        name = "slot_amulet",
        label = "Amulet slot",
        hover = "Where do you want your amulet to be worn?",
        default = "extrabody3",
        options = slot_options,
    },
    Subtitle("UI related"),
    {
        name = "config_render",
        label = "Does the character display all equipment shapes?",
        hover = "If false, only the last equipped or unequipped character appearance will be displayed."
             .. "If there are mod items that do not display their appearance, please select No",
        default = true,
        options = {
            {data = false, description = "No"},
            {data = true, description = "Yes"},
        },
    },
    Subtitle("Test content (may crash)"),
    {
        name = "slot_backpack",
        label = "MOD Armor Special Effect Repair",
        hover = "After opening, [please adjust the Armor slot to OFF], after opening, the armor and backpack slots will be swapped, and many bugs will appear",
        default = false,
        options = {
            {data = false, description = "OFF"},
            {data = "extrabody1", description = "Enabled"},
        },
    },
    {
        name = "slot_heavy",
        label = "Heavy Items",
        hover = "Which slot would you like to equip a heavy item in? (Crashes while beefalo riding)",
        default = false,
        options = slot_options,
    },
    {
        name = "slot_band",
        label = "Solo Instrument",
        hover = "Which slot would you like to equip the solo instrument?",
        default = false,
        options = slot_options,
    },
    -- {
    --name = "Snurtle Shell Armor",
    -- label = "Snurtle Shell Armor",
    --hover = "Which slot would you like to equip the Snurtle Shell Armor?",
    --default = false,
    --options = slot_options_not_implemented,
    -- },
    {
        name = "slot_lifevest",
        label = "Lifejacket",
        hover = "Which slot do you want to equip the lifejacket in?",
        default = false,
        options = slot_options,
    },
}