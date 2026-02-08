-- 全局函数.
local mytable = {}

function mytable.invert(t)
    local result = {}
    for k, v in pairs(t) do
        local values = result[v]
        if values == nil then
            values = {}
            result[v] = values
        end
        table.insert(values, k)
    end
    return result
end

function mytable.contains_all(t, elements)
    for _, v in pairs(elements) do
        if not table.contains(t, v) then
            return false
        end
    end
    return true
end

-- Assets.
local IMAGE = "images/equip_slots.tex"
local ATLAS = "images/equip_slots.xml"
Assets = {
    Asset("IMAGE", IMAGE),
    Asset("ATLAS", ATLAS),
}

-- 一些全局变量.
EQUIP_TYPES = {
    HEAVY    = "heavy",
    BACKPACK = "backpack",
    BAND     = "band",
    SHELL    = "shell",
    LIFEVEST = "lifevest",
    ARMOR    = "armor",
    CLOTHING = "clothing",
    AMULET   = "amulet",
}

EQUIPSLOTS_MAP = {
    HEAVY    = GetModConfigData("slot_heavy"   ) or GLOBAL.EQUIPSLOTS.BODY,
    BACKPACK = GetModConfigData("slot_backpack") or GLOBAL.EQUIPSLOTS.BODY,
    BAND     = GetModConfigData("slot_band"    ) or GLOBAL.EQUIPSLOTS.BODY,
    -- SHELL    = GetModConfigData("slot_shell"   ) or GLOBAL.EQUIPSLOTS.BODY,
    LIFEVEST = GetModConfigData("slot_lifevest") or GLOBAL.EQUIPSLOTS.BODY,
    ARMOR    = GetModConfigData("slot_armor"   ) or GLOBAL.EQUIPSLOTS.BODY,
    CLOTHING = GetModConfigData("slot_clothing") or GLOBAL.EQUIPSLOTS.BODY,
    AMULET   = GetModConfigData("slot_amulet"  ) or GLOBAL.EQUIPSLOTS.BODY,
}

EQUIPSLOTS_MAP_INVERSE = mytable.invert(EQUIPSLOTS_MAP)

EXTRA_EQUIPSLOTS = table.getkeys(EQUIPSLOTS_MAP_INVERSE)
table.removearrayvalue(EXTRA_EQUIPSLOTS, GLOBAL.EQUIPSLOTS.BODY)
table.sort(EXTRA_EQUIPSLOTS)


-- 1. 添加新装备插槽.
-- See `scripts/constants.lua:473`.
for _, v in ipairs(EXTRA_EQUIPSLOTS) do
    GLOBAL.EQUIPSLOTS[string.upper(v)] = v
end

-- 2. 将新装备插槽添加到库存栏.
-- See `scripts/widgets/inventorybar.lua:92`.
local function get_eslot_image(eslot)
    local types = EQUIPSLOTS_MAP_INVERSE[eslot]
    if mytable.contains_all(types, {'BACKPACK', 'ARMOR'}) then
        return {ATLAS, "backpack+armor.tex"}
    elseif table.contains(types, 'BACKPACK') then
        return {ATLAS, "backpack.tex"}
    elseif table.contains(types, 'ARMOR') then
        return {ATLAS, "armor.tex"}
    elseif table.contains(types, 'CLOTHING') then
        return {ATLAS, "clothing.tex"}
    elseif table.contains(types, 'AMULET') then
        return {ATLAS, "amulet.tex"}
    else
        return {GLOBAL.HUD_ATLAS, "equip_slot_body.tex"}
    end
end

Inv = require "widgets/inventorybar"

AddClassPostConstruct("widgets/inventorybar", function(self)
    if GLOBAL.TheNet:GetServerGameMode() == "quagmire" then
        return
    end

    -- 更改旧装备插槽的图像.
    for _, info in ipairs(self.equipslotinfo) do
        if info.slot == GLOBAL.EQUIPSLOTS.BODY then
            local atlas_and_image = get_eslot_image(info.slot)
            info.atlas = atlas_and_image[1]
            info.image = atlas_and_image[2]
        end
    end

    -- 添加新装备插槽.
    local sortkey_start = 1 -- 在第一个插槽之后（“身体”）
    local sortkey_delta = 1 / (#EXTRA_EQUIPSLOTS + 1)
    for i, eslot in ipairs(EXTRA_EQUIPSLOTS) do
        local atlas_and_image = get_eslot_image(eslot)
        self:AddEquipSlot(eslot, atlas_and_image[1], atlas_and_image[2], sortkey_start + i * sortkey_delta)
    end

    -- 固定库存条的背景宽度.
    local Inv_Rebuild_Base = Inv.Rebuild
    function Inv:Rebuild()
        Inv_Rebuild_Base(self)

        local num_slots = self.owner.replica.inventory:GetNumSlots()
        local do_self_inspect = not (self.controller_build or GLOBAL.GetGameModeProperty("no_avatar_popup"))

        local total_w_default = self:CalcTotalWidth(num_slots, 3, 1)
        local total_w_real    = self:CalcTotalWidth(num_slots, #self.equipslotinfo, do_self_inspect and 1 or 0)
        local scale_default = 1.22 -- See `scripts/widgets/inventorybar.lua:261-262`.
        local scale_real = scale_default *  total_w_real / total_w_default
        self.bg:SetScale(scale_real, 1, 1)
        self.bgcover:SetScale(scale_real,1, 1)
    end

    function Inv:CalcTotalWidth(num_slots, num_equip, num_buttons)
        -- See `scripts/widgets/inventorybar.lua:212-217`.
        local W = 68
        local SEP = 12
        local INTERSEP = 28
        local num_slotintersep = math.ceil(num_slots / 5)
        local num_equipintersep = num_buttons > 0 and 1 or 0
        return (num_slots + num_equip + num_buttons) * W + (num_slots + num_equip + num_buttons - num_slotintersep - num_equipintersep - 1) * SEP + (num_slotintersep + num_equipintersep) * INTERSEP
    end
end)


-- 3. 为物品分配新装备插槽.
-- See `scripts/prefabs/*.lua`.
local items_types = {
    -- 救生衣
    ["balloonvest"]       = EQUIP_TYPES.LIFEVEST, --充气背心

    -- Armors护甲栏
    ["armor_bramble"]     = EQUIP_TYPES.ARMOR, -- 荆棘甲
    ["armordragonfly"]    = EQUIP_TYPES.ARMOR, -- 鳞甲
    ["armorgrass"]        = EQUIP_TYPES.ARMOR, -- 草甲
    ["armormarble"]       = EQUIP_TYPES.ARMOR, -- 大理石甲
    ["armorruins"]        = EQUIP_TYPES.ARMOR, -- 铥矿甲
    ["armor_sanity"]      = EQUIP_TYPES.ARMOR, -- 影甲
    ["armorskeleton"]     = EQUIP_TYPES.ARMOR, -- 骨甲
    ["armorwood"]         = EQUIP_TYPES.ARMOR, -- 木甲
    ["armor_lunarplant"]           = EQUIP_TYPES.ARMOR, -- 亮影盔甲
    ["armor_lunarplant_husk"]      = EQUIP_TYPES.ARMOR, -- 荆棘茄甲
    ["armordreadstone"]            = EQUIP_TYPES.ARMOR, -- 绝望石盔甲
    ["armor_voidcloth"]            = EQUIP_TYPES.ARMOR, -- 暗影长袍
    -- ["armorwagpunk"]               = EQUIP_TYPES.ARMOR, -- W.A.R.B.I.S盔甲
    
    ["armor_medal_obsidian"]       = EQUIP_TYPES.ARMOR, -- 能力勋章
    ["armor_blue_crystal"]         = EQUIP_TYPES.ARMOR, -- 能力勋章
    ["armor_medal_space_time"]     = EQUIP_TYPES.ARMOR, -- 能力勋章
    
    ["golden_armor_mk"]            = EQUIP_TYPES.ARMOR, -- 神话书说
    ["yangjian_armor"]             = EQUIP_TYPES.ARMOR, -- 神话书说
    ["nz_damask"]                  = EQUIP_TYPES.ARMOR, -- 神话书说
    ["armorsiving"]                = EQUIP_TYPES.ARMOR, -- 神话书说
    ["myth_iron_battlegear"]       = EQUIP_TYPES.ARMOR, -- 神话书说
    
    ["xe_bag"]                     = EQUIP_TYPES.ARMOR, -- 璇儿
    
    ["icearmor"]                   = EQUIP_TYPES.ARMOR, -- 玉子yuki
    
    ["yuanzi_armor_lv1"]           = EQUIP_TYPES.ARMOR, -- 乃木園子
    ["yuanzi_armor_lv2"]           = EQUIP_TYPES.ARMOR, -- 乃木園子
    
    ["monvfu"]                     = EQUIP_TYPES.ARMOR, -- 伊蕾娜
    ["red_fairyskirt"]             = EQUIP_TYPES.ARMOR, -- 伊蕾娜
    ["bule_fairyskirt"]            = EQUIP_TYPES.ARMOR, -- 伊蕾娜
    ["elaina_bq"]                  = EQUIP_TYPES.ARMOR, -- 伊蕾娜
    ["elaina_hlq"]                 = EQUIP_TYPES.ARMOR, -- 伊蕾娜
    
    ["sora2armor"]                 = EQUIP_TYPES.ARMOR, -- 小穹
    ["soraclothes"]                = EQUIP_TYPES.ARMOR, -- 小穹
    
    ["purgatory_armor"]            = EQUIP_TYPES.ARMOR, -- 艾露莎
    
    ["wharang_amulet_sack"]        = EQUIP_TYPES.ARMOR, -- 千年狐
    
    ["ndnr_armorobsidian"]         = EQUIP_TYPES.ARMOR, -- 富贵
    
    ["uniform_firemoths"]          = EQUIP_TYPES.ARMOR, -- 希儿-逐火之蛾制服
    
    ["changchunjz"]                = EQUIP_TYPES.ARMOR, -- 战舰少女-长春的舰装
    ["veneto_jz"]                  = EQUIP_TYPES.ARMOR, -- 战舰少女-维内托的舰装
    ["veneto_jzyf"]                = EQUIP_TYPES.ARMOR, -- 战舰少女-豪华意式舰装
    ["fubuki_jz"]                  = EQUIP_TYPES.ARMOR, -- 战舰少女-吹雪的舰装
    ["lijie_jz"]                   = EQUIP_TYPES.ARMOR, -- 战舰少女补给包-黎塞留的舰装
    ["jianzhuang"]                 = EQUIP_TYPES.ARMOR, -- 战舰少女补给包-欧根的舰装
    ["fbk_jz"]                     = EQUIP_TYPES.ARMOR, -- 战舰少女补给包-吹雪的舰装
    ["lex_jz"]                     = EQUIP_TYPES.ARMOR, -- 战舰少女补给包-列克星敦的舰装
    ["yukikaze_jz"]                = EQUIP_TYPES.ARMOR, -- 战舰少女补给包-火炮鱼雷并联舰装
    
    ["kahiro_dress"]               = EQUIP_TYPES.ARMOR, --kahiro学院袍 
    
    ["bf_nightmarearmor"]          = EQUIP_TYPES.ARMOR, --恶魔花护甲
    
    ["bf_rosearmor"]               = EQUIP_TYPES.ARMOR, --玫瑰护甲
    
    ["aria_armor_red"]             = EQUIP_TYPES.ARMOR, --艾丽娅·克莉丝塔露（RE）
    ["aria_armor_blue"]            = EQUIP_TYPES.ARMOR, --艾丽娅·克莉丝塔露（RE）
    ["aria_armor_green"]           = EQUIP_TYPES.ARMOR, --艾丽娅·克莉丝塔露（RE）
    ["aria_armor_purple"]          = EQUIP_TYPES.ARMOR, --艾丽娅·克莉丝塔露（RE）
    
    ["armorlimestone"]             = EQUIP_TYPES.ARMOR, --海难石灰岩套装
    ["armorcactus"]                = EQUIP_TYPES.ARMOR, --海难仙人掌护甲
    ["armorobsidian"]              = EQUIP_TYPES.ARMOR, --海难黑曜石护甲
    ["armorseashell"]              = EQUIP_TYPES.ARMOR, --海难海套贝壳
    
    ["suozi"]                      = EQUIP_TYPES.ARMOR, --更多武器
    ["bingxin"]                    = EQUIP_TYPES.ARMOR, --更多武器
    ["zhenfen"]                    = EQUIP_TYPES.ARMOR, --更多武器
    ["huomu"]                      = EQUIP_TYPES.ARMOR, --更多武器
    ["landun"]                     = EQUIP_TYPES.ARMOR, --更多武器
    ["riyan"]                      = EQUIP_TYPES.ARMOR, --更多武器
    ["kj"]                         = EQUIP_TYPES.ARMOR, --更多武器
    ["banjia"]                     = EQUIP_TYPES.ARMOR, --更多武器
    
    ["kemomiminewyifu"]            = EQUIP_TYPES.ARMOR, --小狐狸
    
    ["featheredtunic"]             = EQUIP_TYPES.ARMOR, --熔炉
    ["forge_woodarmor"]            = EQUIP_TYPES.ARMOR, --熔炉
    ["jaggedarmor"]                = EQUIP_TYPES.ARMOR, --熔炉
    ["silkenarmor"]                = EQUIP_TYPES.ARMOR, --熔炉
    ["splintmail"]                 = EQUIP_TYPES.ARMOR, --熔炉
    ["steadfastarmor"]             = EQUIP_TYPES.ARMOR, --熔炉
    ["armor_hpextraheavy"]         = EQUIP_TYPES.ARMOR, --熔炉
    ["armor_hpdamager"]            = EQUIP_TYPES.ARMOR, --熔炉
    ["armor_hprecharger"]          = EQUIP_TYPES.ARMOR, --熔炉
    ["armor_hppetmastery"]         = EQUIP_TYPES.ARMOR, --熔炉
    ["reedtunic"]                  = EQUIP_TYPES.ARMOR, --熔炉
    
    ["ov_armor"]                   = EQUIP_TYPES.ARMOR, --和平鸽
    
    ["armor_glassmail"]            = EQUIP_TYPES.ARMOR, --不妥协
    ["feather_frock_fancy"]        = EQUIP_TYPES.ARMOR, --不妥协
    ["feather_frock"]              = EQUIP_TYPES.ARMOR, --不妥协
    
    ["xianrenzhangjia"]            = EQUIP_TYPES.ARMOR, --泰拉物品
    ["nanguahujia"]                = EQUIP_TYPES.ARMOR, --泰拉物品
    ["jinjia"]                     = EQUIP_TYPES.ARMOR, --泰拉物品
    
    ["seele_twinsdress"]           = EQUIP_TYPES.ARMOR, --希儿
    
    ["forceshield"]                = EQUIP_TYPES.ARMOR, --力场护盾
    
    --["goldship_dress1"]            = EQUIP_TYPES.ARMOR, --锦衣玉食
    --["goldship_dress2"]            = EQUIP_TYPES.ARMOR, --锦衣玉食
    
    --lz
    ["armor_cherry"]               = EQUIP_TYPES.ARMOR, -- 樱花林 Rayal Mantle
    ["armor_cherry"]               = EQUIP_TYPES.ARMOR, -- 樱花林 Broken Heart
    ["shenshenghujia"]             = EQUIP_TYPES.ARMOR, -- 泰拉物品
    ["anyingxiongjia"]             = EQUIP_TYPES.ARMOR, -- 泰拉物品
    ["xinghongxiongjia"]           = EQUIP_TYPES.ARMOR, -- 泰拉物品包-猩红鳞甲
    ["zhizhuhujia"]                = EQUIP_TYPES.ARMOR, -- 泰拉物品-蜘蛛护甲
    ["yifu"]                       = EQUIP_TYPES.ARMOR, -- 新护甲
    ["yifubm"]                     = EQUIP_TYPES.ARMOR, -- 新护甲
    ["yifubn"]                     = EQUIP_TYPES.ARMOR, -- 新护甲
    ["yifufy"]                     = EQUIP_TYPES.ARMOR, -- 新护甲
    ["yifugr"]                     = EQUIP_TYPES.ARMOR, -- 新护甲
    ["blackdragon_armor"]          = EQUIP_TYPES.ARMOR, -- 黑龙
    ["carney_ruanjia"]             = EQUIP_TYPES.ARMOR, -- 卡尼猫-内衬软甲
    ["carney_huanyingjia"]         = EQUIP_TYPES.ARMOR, -- 卡尼猫-浅影
    ["armor_tungsten"]             = EQUIP_TYPES.ARMOR, -- 钨矿时代-绝对零度甲 
    ["whyearmor_incomplete"]       = EQUIP_TYPES.ARMOR, -- Ancient Dreams - ACT 1
    ["krm_zafkiel"]                = EQUIP_TYPES.ARMOR, -- 狂三-刻刻帝
    ["krm_armor"]                  = EQUIP_TYPES.ARMOR, -- 狂三-狂狂帝 
    ["armor_elepheetle"]           = EQUIP_TYPES.ARMOR, -- 棱镜-犀金护甲 
    ["armor_mushaa"]               = EQUIP_TYPES.ARMOR, -- 精灵公主Musha-原型盔甲
    ["armor_metalplate_75"]        = EQUIP_TYPES.ARMOR, -- 天体修仙-修仙铠甲75
    ["armor_metalplate_80"]        = EQUIP_TYPES.ARMOR, -- 天体修仙-修仙铠甲80
    ["armor_metalplate_85"]        = EQUIP_TYPES.ARMOR, -- 天体修仙-修仙铠甲85
    ["armor_metalplate_90"]        = EQUIP_TYPES.ARMOR, -- 天体修仙-修仙铠甲90
    ["armor_metalplate_97"]        = EQUIP_TYPES.ARMOR, -- 天体修仙-修仙铠甲97
    ["armor_metalplate_98"]        = EQUIP_TYPES.ARMOR, -- 天体修仙-修仙铠甲98
    ["hl_wheatpack"]               = EQUIP_TYPES.ARMOR, -- 贤狼赫萝-麦穗袋
    ["gg_armor"]                   = EQUIP_TYPES.ARMOR, -- 澄闪的喜夜侍者套装
    ["marbled_armor"]              = EQUIP_TYPES.ARMOR, -- Level and Achievement By Chasni (2023)-战神胸甲
    ["thunder_armor"]              = EQUIP_TYPES.ARMOR, -- Level and Achievement By Chasni (2023)-雷神斗篷
    ["distortion"]                 = EQUIP_TYPES.ARMOR, -- Kanade_AngelBeats!-扭曲护盾
    ["myxl_dreambook"]             = EQUIP_TYPES.ARMOR, -- 璇儿-遗梦芸典
    ["armorlswq"]                  = EQUIP_TYPES.ARMOR, -- 神圣羽衣
    ["armor_leaf"]                 = EQUIP_TYPES.ARMOR, -- Albe物品包-翠绿哨兵
    ["mmiko_armor"]                = EQUIP_TYPES.ARMOR, -- M.louls-巫女长袍
    ["daidai_armor"]               = EQUIP_TYPES.ARMOR, -- 袋袋daidai-钢羊毛背心
    ["armor_victoria"]             = EQUIP_TYPES.ARMOR, -- 袋袋daidai-钢羊毛外套
    ["asa_drone"]                  = EQUIP_TYPES.ARMOR, -- 义体人-防御无人机
    ["armor_moonglass"]            = EQUIP_TYPES.ARMOR, -- Celestial Tools-Moon Suit
    ["rei_armor"]                  = EQUIP_TYPES.ARMOR, -- 怜rei-板甲
    ["rei_yifu2"]                  = EQUIP_TYPES.ARMOR, -- 怜rei-苍天之袍
    ["armor_sharksuit_um"]         = EQUIP_TYPES.ARMOR, -- 永不妥协-Rock Hide Armor
    ["armor_reed_um"]              = EQUIP_TYPES.ARMOR, -- 永不妥协-Reed Suit
    ["yuanzi_armor_lv3"]           = EQUIP_TYPES.ARMOR, -- 乃木園子升级组件-园子的半神服
    ["armor_honey"]                = EQUIP_TYPES.ARMOR, -- Wuzzy The Buzzy-honey suit
    ["tz_fh_fl"]                   = EQUIP_TYPES.ARMOR, -- 太真-番号风雷
    -- ["tz_fh_ys"]                   = EQUIP_TYPES.ARMOR, -- 太真-番号忆思
    
    
    
    --Gemstone Armor V.N
    ["armor_orangegem"]            = EQUIP_TYPES.ARMOR, -- Armor Breastplate
    ["armor_bluegem"]              = EQUIP_TYPES.ARMOR, -- Armor Cuirass
    ["armor_redgem"]               = EQUIP_TYPES.ARMOR, -- Armor Chestplate
    ["armor_greengem"]             = EQUIP_TYPES.ARMOR, -- Armor Mail
    ["armor_opalgem"]              = EQUIP_TYPES.ARMOR, -- Armor Suit
    ["armor_yellowgem"]            = EQUIP_TYPES.ARMOR, -- Armor Brigandine
    ["armor_purplegem"]            = EQUIP_TYPES.ARMOR, -- Armor Hauberk

    ["lavaarena_armormediumrecharger"]             = EQUIP_TYPES.ARMOR, -- 热带体验-丝带木甲
    ["lavaarena_armormedium"]                      = EQUIP_TYPES.ARMOR, -- 热带体验-木质护甲
    ["lavaarena_armorlightspeed"]                  = EQUIP_TYPES.ARMOR, -- 热带体验-羽饰芦苇外衣
    ["lavaarena_armormediumdamager"]               = EQUIP_TYPES.ARMOR, -- 热带体验-锯齿木甲
    ["lavaarena_armor_hpextraheavy"]               = EQUIP_TYPES.ARMOR, -- 热带体验-华丽坚固盔甲
    ["lavaarena_armor_hpdamager"]                  = EQUIP_TYPES.ARMOR, -- 热带体验-华丽巨齿盔甲
    ["armor_seashell"]                             = EQUIP_TYPES.ARMOR, -- 热带体验-海贝甲
    ["lavaarena_armor_hppetmastery"]               = EQUIP_TYPES.ARMOR, -- 热带体验-华丽低语盔甲
    ["lavaarena_armor_hprecharger"]                = EQUIP_TYPES.ARMOR, -- 热带体验-华丽丝带盔甲
    ["armor_metalplate"]                           = EQUIP_TYPES.ARMOR, -- 热带体验-合金盔甲
    ["lavaarena_armorextraheavy"]                  = EQUIP_TYPES.ARMOR, -- 热带体验-坚固的石质护甲
    ["lavaarena_armorheavy"]                       = EQUIP_TYPES.ARMOR, -- 热带体验-石头板甲
    ["armor_weevole"]                              = EQUIP_TYPES.ARMOR, -- 热带体验-象鼻鼠披风
    ["lavaarena_armorlight"]                       = EQUIP_TYPES.ARMOR, -- 热带体验-芦苇束腰外衣
    ["helltaker_businesssuit"]                     = EQUIP_TYPES.ARMOR, -- 地狱把妹王-西装外套
    

    -- Armors: from the mod "More Armor" (<https://steamcommunity.com/sharedfiles/filedetails/?id=1153998909>)
    ["armor_bone"]                 = EQUIP_TYPES.ARMOR, -- Bone Suit
    ["armor_stone"]                = EQUIP_TYPES.ARMOR, -- Stone Suit

    -- Clothing服装栏
    ["armorslurper"]     = EQUIP_TYPES.CLOTHING, -- 饥饿腰带
    ["beargervest"]      = EQUIP_TYPES.CLOTHING, -- 熊皮背心
    ["hawaiianshirt"]    = EQUIP_TYPES.CLOTHING, -- 花衬衫
    ["raincoat"]         = EQUIP_TYPES.CLOTHING, -- 雨衣
    ["reflectivevest"]   = EQUIP_TYPES.CLOTHING, -- 清凉夏装
    ["sweatervest"]      = EQUIP_TYPES.CLOTHING, -- 犬牙背心
    ["trunkvest_summer"] = EQUIP_TYPES.CLOTHING, -- 透气背心
    ["trunkvest_winter"] = EQUIP_TYPES.CLOTHING, -- 松软背心
    ["carnival_vest_a"]  = EQUIP_TYPES.CLOTHING, -- 叽叽喳喳的围巾
    ["carnival_vest_b"]  = EQUIP_TYPES.CLOTHING, -- 叽叽喳喳的斗篷
    ["carnival_vest_c"]  = EQUIP_TYPES.CLOTHING, -- 叽叽喳喳的披肩
    
    ["down_filled_coat"]    = EQUIP_TYPES.CLOTHING, -- 能力勋章
    
    ["cassock"]             = EQUIP_TYPES.CLOTHING, -- 神话书说
    ["kam_lan_cassock"]     = EQUIP_TYPES.CLOTHING, -- 神话书说
    ["madameweb_armor"]     = EQUIP_TYPES.CLOTHING, -- 神话书说
    
    ["sachet"]              = EQUIP_TYPES.CLOTHING, -- 棱镜
    
    ["veneto_yifu"]         = EQUIP_TYPES.CLOTHING, -- 战舰少女维内托-小时候的衣服
    ["zhifu"]               = EQUIP_TYPES.CLOTHING, -- 战舰少女补给包-秋冬制服
    
    ["dress_sea"]           = EQUIP_TYPES.CLOTHING, -- 希儿-幻海梦蝶
    ["seele_swimsuit"]      = EQUIP_TYPES.CLOTHING, -- 希儿-夏雪铃兰
    
    ["balloonvest"]         = EQUIP_TYPES.CLOTHING, -- 救生衣
    ["armor_lifejacket"]    = EQUIP_TYPES.CLOTHING, -- 救生衣
    ["tarsuit"]             = EQUIP_TYPES.CLOTHING, -- 焦油套装
    ["armor_windbreaker"]   = EQUIP_TYPES.CLOTHING, -- 防风衣
    ["blubbersuit"]         = EQUIP_TYPES.CLOTHING, -- 鲸脂套装
    ["armor_snakeskin"]     = EQUIP_TYPES.CLOTHING, -- 蛇皮夹克
    
    ["amiya_fengyi1"]               = EQUIP_TYPES.CLOTHING, -- 领导者风衣α-阿米娅
    ["amiya_fengyi2"]               = EQUIP_TYPES.CLOTHING, -- 领导者风衣β-阿米娅
    ["amiya_fengyi3"]               = EQUIP_TYPES.CLOTHING, -- 领导者风衣γ-阿米娅
    
    -- ["gura_floaties"]              = EQUIP_TYPES.CLOTHING, --古拉
    
    ["hanfu1"]                     = EQUIP_TYPES.CLOTHING, --锦衣玉食
    ["hanfu2"]                     = EQUIP_TYPES.CLOTHING, --锦衣玉食
    
    -- lz
    -- ["elaina_most_brooch"]         = EQUIP_TYPES.CLOTHING, -- 魔女之旅-最强胸针
    ["m_scarf"]                    = EQUIP_TYPES.CLOTHING, -- M.louls-黑围巾
    ["krm_uniform"]                = EQUIP_TYPES.CLOTHING, -- 狂三-校服
    ["cherryvest"]                 = EQUIP_TYPES.CLOTHING, -- 樱花林 Royle Mantle
    ["mandrake_capelet"]           = EQUIP_TYPES.CLOTHING, -- 曼德拉斗篷
    ["wedding_dress"]              = EQUIP_TYPES.CLOTHING, -- 那年花嫁-凤夙霞披
    ["wedding_dress"]              = EQUIP_TYPES.CLOTHING, -- 那年花嫁-凤夙霞披
    ["goldship_dress1"]            = EQUIP_TYPES.CLOTHING, -- 黄金船-外星人决胜服
    ["goldship_dress2"]            = EQUIP_TYPES.CLOTHING, -- 黄金船-黄金黄金星泳衣
    ["skirt_x"]                    = EQUIP_TYPES.CLOTHING, -- 大狐狸-狐狸裙子
    ["hl_travelerwindbreaker"]     = EQUIP_TYPES.CLOTHING, -- 贤狼赫萝-旅行者风衣
    ["satori_eye"]                 = EQUIP_TYPES.CLOTHING, -- satori-普通眼
    ["satori_eye2"]                = EQUIP_TYPES.CLOTHING, -- satori-增幅眼
    ["armor_tiddlesapron"]         = EQUIP_TYPES.CLOTHING, -- 黑死病-Sanitation Apron
    -- ["abigail_flower"]             = EQUIP_TYPES.CLOTHING, -- 阿比盖尔之花|增强
    ["rei_yifu"]                   = EQUIP_TYPES.CLOTHING, -- 怜rei-妖丽虚像
    ["um_armor_pyre_nettles"]      = EQUIP_TYPES.CLOTHING, -- 永不妥协-Pyre Mantle
    ["ccs_skirt1"]                 = EQUIP_TYPES.CLOTHING, -- 魔法小樱-衣服
    ["diana_armor_level_1"]        = EQUIP_TYPES.CLOTHING, -- 枝江往事-小驴装1
    ["diana_armor_level_2"]        = EQUIP_TYPES.CLOTHING, -- 枝江往事-小驴装2
    ["diana_armor_level_3"]        = EQUIP_TYPES.CLOTHING, -- 枝江往事-小驴装3
    ["delieverrobe"]               = EQUIP_TYPES.CLOTHING, -- The lamb-Devotee's robe
    ["third_eye"]                  = EQUIP_TYPES.CLOTHING, -- 古明地恋（重置版）- 恋恋的第三只眼
    ["third_eye2"]                 = EQUIP_TYPES.CLOTHING, -- 古明地恋（重置版）- 恋恋的增幅第三只眼
    ["woolen_sweater"]             = EQUIP_TYPES.CLOTHING, -- 山海秘藏-羊毛衫
    ["lg_fufeng"]                  = EQUIP_TYPES.CLOTHING, -- 海洋传说-雨花·扶风

    --璇儿-伞
    ["myxl_san_ll"]                   = EQUIP_TYPES.CLOTHING,
    ["myxl_san_xj"]                   = EQUIP_TYPES.CLOTHING, 
    ["myxl_san_ss"]                   = EQUIP_TYPES.CLOTHING,
    ["myxl_san_ts"]                   = EQUIP_TYPES.CLOTHING, 
    

    --一出好戏的戏服
    ["costume_blacksmith_body"]                   = EQUIP_TYPES.CLOTHING, -- 铁匠服
    ["costume_doll_body"]                         = EQUIP_TYPES.CLOTHING, -- 玩偶服
    ["costume_foal_body"]                         = EQUIP_TYPES.CLOTHING, -- 小丑服
    ["costume_king_body"]                         = EQUIP_TYPES.CLOTHING, -- 国王服
    ["costume_mirror_body"]                       = EQUIP_TYPES.CLOTHING, -- 镜子服
    ["costume_queen_body"]                        = EQUIP_TYPES.CLOTHING, -- 女王服
    ["costume_tree_body"]                         = EQUIP_TYPES.CLOTHING, -- 树木服




    -- Amulets护符栏
    ["amulet"]       = EQUIP_TYPES.AMULET, -- 重生护符
    ["blueamulet"]   = EQUIP_TYPES.AMULET, -- 寒冰护符
    ["purpleamulet"] = EQUIP_TYPES.AMULET, -- 梦魇护符
    ["orangeamulet"] = EQUIP_TYPES.AMULET, -- 懒人护符
    ["greenamulet"]  = EQUIP_TYPES.AMULET, -- 建造护符
    ["yellowamulet"] = EQUIP_TYPES.AMULET, -- 魔光护符
    
    ["brooch1"]                  = EQUIP_TYPES.AMULET, -- 伊蕾娜
    ["brooch2"]                  = EQUIP_TYPES.AMULET, -- 伊蕾娜
    ["brooch4"]                  = EQUIP_TYPES.AMULET, -- 伊蕾娜
    ["brooch5"]                  = EQUIP_TYPES.AMULET, -- 伊蕾娜
    ["brooch6"]                  = EQUIP_TYPES.AMULET, -- 伊蕾娜
    ["brooch7"]                  = EQUIP_TYPES.AMULET, -- 伊蕾娜
    ["brooch8"]                  = EQUIP_TYPES.AMULET, -- 伊蕾娜
    ["brooch9"]                  = EQUIP_TYPES.AMULET, -- 伊蕾娜
    ["moon_brooch"]              = EQUIP_TYPES.AMULET, -- 伊蕾娜
    ["star_brooch"]              = EQUIP_TYPES.AMULET, -- 伊蕾娜
    
    ["sora2amulet"]              = EQUIP_TYPES.AMULET, -- 小穹
    ["sorabowknot"]              = EQUIP_TYPES.AMULET, -- 小穹
    
    ["luckamulet"]               = EQUIP_TYPES.AMULET, -- 经济学
    
    ["wharang_amulet"]           = EQUIP_TYPES.AMULET, -- 千年狐
    
    ["ndnr_opalpreciousamulet"]  = EQUIP_TYPES.AMULET, -- 富贵
    
    ["terraprisma"]              = EQUIP_TYPES.AMULET, -- 光棱剑
    
    ["aria_seaamulet"]           = EQUIP_TYPES.AMULET, --艾丽娅
    
    ["kemomimi_new_xianglian"]   = EQUIP_TYPES.AMULET, --小狐狸
    ["kemomimi_bell"]            = EQUIP_TYPES.AMULET, --小狐狸
    ["kemomimi_utr_xl"]          = EQUIP_TYPES.AMULET, --小狐狸
    
    ["philosopherstone"]         = EQUIP_TYPES.AMULET, --托托莉
    
    ["ov_amulet1"]               = EQUIP_TYPES.AMULET, --和平鸽
    ["ov_amulet2"]               = EQUIP_TYPES.AMULET, --和平鸽
    ["ov_bag2"]                  = EQUIP_TYPES.AMULET, --和平鸽
    
    ["klaus_amulet"]                       = EQUIP_TYPES.AMULET, --不妥协
    ["ancient_amulet_red_demoneye"]        = EQUIP_TYPES.AMULET, --不妥协
    ["oculet"]                             = EQUIP_TYPES.AMULET, --不妥协
    ["ancient_amulet_red"]                 = EQUIP_TYPES.AMULET, --不妥协
    
    --["jinshudaikou"]                  = EQUIP_TYPES.AMULET, --泰拉物品
    --["zaishengshouhuan"]              = EQUIP_TYPES.AMULET, --泰拉物品
    --["ruchongweijin"]                 = EQUIP_TYPES.AMULET, --泰拉物品
    
    ["elaina_most_brooch"]       = EQUIP_TYPES.AMULET, -- 伊蕾娜
    
    ["ysyu"]                     = EQUIP_TYPES.AMULET, -- 花千骨
    ["tsd"]                      = EQUIP_TYPES.AMULET, -- 花千骨
    
    -- lz
    ["cherryamulet"]               = EQUIP_TYPES.AMULET, -- 樱花林 Friendship Necklace
    ["moonamulet"]                 = EQUIP_TYPES.AMULET, -- 月光护符
    ["tsd"]                        = EQUIP_TYPES.AMULET, -- 花千骨-天水滴
    ["carney_hushenfu"]            = EQUIP_TYPES.AMULET, -- 卡尼猫-护身符
    ["yushou"]                     = EQUIP_TYPES.AMULET, -- 八重神子-御守
    ["squidamulet"]                = EQUIP_TYPES.AMULET, -- 鱿鱼之心-鱿鱼的庇护
    ["wedding_necklace"]           = EQUIP_TYPES.AMULET, -- 那年花嫁-繁华坠
    ["teng_amult"]                 = EQUIP_TYPES.AMULET, -- 疼的工具-疼の护符
    ["goldship_eye"]               = EQUIP_TYPES.AMULET, -- 黄金船-宇宙合金眼角膜
    ["breath_wind"]                = EQUIP_TYPES.AMULET, -- 乃木園子-优雅的思念
    ["fire_bless"]                 = EQUIP_TYPES.AMULET, -- 乃木園子-风度翩翩
    ["health_rune"]                = EQUIP_TYPES.AMULET, -- 乃木園子-清纯之心
    ["krm_spirit_crystal"]         = EQUIP_TYPES.AMULET, -- 狂三-二亚的灵结晶  
    ["aria_rabbitfoot"]            = EQUIP_TYPES.AMULET, -- 艾丽娅·克莉丝塔露（RE）|幸运的兔子脚
    ["baiseamulet"]                = EQUIP_TYPES.AMULET, -- 超越证明
    ["daidai_hat"]                 = EQUIP_TYPES.AMULET, -- 袋袋daidai-小狗别针
    ["rei_icon"]                   = EQUIP_TYPES.AMULET, -- 怜rei-爱梅斯的守护
    ["myxl_hairpin"]               = EQUIP_TYPES.AMULET, -- 璇儿-簪子
    ["myxl_ribbon"]                = EQUIP_TYPES.AMULET, -- 璇儿-簪子
    ["nanashi_mumei_lantern"]      = EQUIP_TYPES.AMULET, -- MUMEI-蓝灯
    ["ccs_card_box"]               = EQUIP_TYPES.AMULET, -- 魔法小樱-卡牌盒
    ["ccs_amulet"]                 = EQUIP_TYPES.AMULET, -- 魔法小樱-护符
    ["tz_fh_ns"]                   = EQUIP_TYPES.AMULET, -- 太真-番号海洋女神的祝福
    ["tz_fh_ly"]                   = EQUIP_TYPES.AMULET, -- 太真-番号两仪
    

    --海洋传说
    ["lg_fuzhui_1"]                = EQUIP_TYPES.AMULET, -- 印法符坠
    ["lg_fuzhui_2"]                = EQUIP_TYPES.AMULET, 
    ["lg_fuzhui_3"]                = EQUIP_TYPES.AMULET, 
    ["lg_fuzhui_4"]                = EQUIP_TYPES.AMULET, 
    ["lg_fuzhui_5"]                = EQUIP_TYPES.AMULET, 
    ["lg_jiezhi1"]                 = EQUIP_TYPES.AMULET, -- 戒指
    ["lg_jiezhi2"]                 = EQUIP_TYPES.AMULET, 
    ["lg_jiezhi3"]                 = EQUIP_TYPES.AMULET, 
    ["lg_jiezhi4"]                 = EQUIP_TYPES.AMULET, 
    ["lg_jiezhi5"]                 = EQUIP_TYPES.AMULET, 
    ["lg_jiezhi6"]                 = EQUIP_TYPES.AMULET, 
    ["lg_jiezhi7"]                 = EQUIP_TYPES.AMULET, 
    

    --LZ-背包
    ["musha_bigbag"]      = EQUIP_TYPES.BACKPACK, --musha大背包
    
    
}

AddPrefabPostInitAny(function(inst)
    -- 如果缺少类型，请将其添加为标记.
    local type = items_types[inst.prefab]
    if type ~= nil and not inst:HasTag(type) then
        inst:AddTag(type)
    end

    -- 按类型/标签获取装备槽.
    local eslot = nil
    for k, v in pairs(EQUIP_TYPES) do
        if inst:HasTag(v) then
            eslot = EQUIPSLOTS_MAP[k]
            break
        end
    end
    if (eslot ~= nil) and (eslot ~= GLOBAL.EQUIPSLOTS.BODY) then
        -- 分配新装备插槽.
        -- See `scripts/prefabs/*.lua`.
        if GLOBAL.TheWorld.ismastersim then
            inst.components.equippable.equipslot = eslot
        end

        -- 4. 修复湿前缀.
        -- See `scripts/entityscript.lua:594`.
        if not inst.no_wet_prefix and inst.wet_prefix == nil then
            inst.wet_prefix = GLOBAL.STRINGS.WET_PREFIX.CLOTHING
        end
    end
end)


if EQUIPSLOTS_MAP.CLOTHING ~= GLOBAL.EQUIPSLOTS.BODY then

    -- 5. 当你给“寄居蟹隐士”一件外套时，她会尝试使用旧的装备槽。让我们也用新的.
    -- See `scripts/prefabs/hermitcrab.lua`.
    AddPrefabPostInit("hermitcrab", function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            return
        end

        local function iscoat(item)
            return item.components.insulator and
                    item.components.insulator:GetInsulation() >= GLOBAL.TUNING.INSULATION_SMALL and
                    item.components.insulator:GetType() == GLOBAL.SEASONS.WINTER and
                    item.components.equippable and
                    item.components.equippable.equipslot == EQUIPSLOTS_MAP.CLOTHING
        end

        local function getcoat(inst1)
            local equipped = inst1.components.inventory:GetEquippedItem(EQUIPSLOTS_MAP.CLOTHING)
            return inst1.components.inventory:FindItem(function(testitem) return iscoat(testitem) end)
                    or (equipped and iscoat(equipped) and equipped)
        end

        -- 添加一个额外的项目监听器.
        -- See `scripts/prefabs/hermitcrab.lua:1011`.
        inst:ListenForEvent("itemget", function(_, data)
            if iscoat(data.item) and GLOBAL.TheWorld.state.issnowing then
                local TASKS_GIVE_PUFFY_VEST = 11 -- Copy from `prefabs/hermitcrab.lua:57`.
                inst.components.inventory:Equip(data.item)
                inst.components.friendlevels:CompleteTask(TASKS_GIVE_PUFFY_VEST)
            end
        end)

        -- 覆盖 `ShouldAcceptItem`.
        -- See `scripts/prefabs/hermitcrab.lua:122-123,127`.
        local ShouldAcceptItem_Base = inst.components.trader.test
        inst.components.trader:SetAcceptTest(function(inst1, item)
            return (iscoat(item) and GLOBAL.TheWorld.state.issnowing and not getcoat(inst1))
                    or ShouldAcceptItem_Base(inst1, item)
        end)

        -- 覆盖 `OnRefuseItem`.
        -- See `scripts/prefabs/hermitcrab.lua:144-146`.
        local OnRefuseItem_Base = inst.components.trader.onrefuse
        inst.components.trader.onrefuse = function(inst1, giver, item)
            if iscoat(item) then
                if getcoat(inst1) then
                    inst1.components.npc_talker:Say(GLOBAL.STRINGS.HERMITCRAB_REFUSE_COAT_HASONE[math.random(#GLOBAL.STRINGS.HERMITCRAB_REFUSE_COAT_HASONE)])
                elseif not GLOBAL.TheWorld.state.issnowing then
                    inst1.components.npc_talker:Say(GLOBAL.STRINGS.HERMITCRAB_REFUSE_COAT[math.random(#GLOBAL.STRINGS.HERMITCRAB_REFUSE_COAT)])
                end
            end
            OnRefuseItem_Base(inst, giver, item)
        end

        -- 覆盖 `iscoat`.
        -- See `scripts/prefabs/hermitcrab.lua:1363`.
        inst.iscoat = iscoat
        inst.getcoat = getcoat
    end)


    -- 6. “寄居蟹隐士”有一个大脑，可以让她在旧装备槽中装备/取消装备外套。让我们也用新的.
    -- See `scripts/brains/hermitcrabbrain.lua`.
    AddBrainPostInit("hermitcrabbrain", function(brain)
        local function using_coat(inst)
            local equipped = inst.components.inventory:GetEquippedItem(EQUIPSLOTS_MAP.CLOTHING)
            return equipped and inst.iscoat(equipped) or nil
        end

        local function has_coat(inst)
            return inst.components.inventory:FindItem(function(testitem) return inst.iscoat(testitem) end)
        end

        local function EquipCoat(inst)
            local coat = inst.getcoat(inst)
            if coat then
                inst.components.inventory:Equip(coat)
            end
        end

        local function UnequipCoat(inst)
            local item = inst.components.inventory:Unequip(EQUIPSLOTS_MAP.CLOTHING)
            inst.components.inventory:GiveItem(item)
        end

        local new_children = {}
        for _, child in ipairs(brain.bt.root.children) do
            if child.name == "Sequence" and child.children[1].name == "coat" then
                table.insert(new_children,
                        GLOBAL.IfNode(function() return not brain.inst.sg:HasStateTag("busy") and GLOBAL.TheWorld.state.issnowing and has_coat(brain.inst) and not using_coat(brain.inst) end,
                                "coat",
                                GLOBAL.DoAction(brain.inst, EquipCoat, "coat", true))
                )
            elseif child.name == "Sequence" and child.children[1].name == "stop coat" then
                table.insert(new_children,
                        GLOBAL.IfNode(function() return not brain.inst.sg:HasStateTag("busy") and not GLOBAL.TheWorld.state.issnowing and using_coat(brain.inst) end,
                                "stop coat",
                                GLOBAL.DoAction(brain.inst, UnequipCoat, "stop coat", true))
                )
            else
                table.insert(new_children, child)
            end
        end
        brain.bt = GLOBAL.BT(brain.inst, GLOBAL.PriorityNode(new_children, 0.5))
    end)

end


if EQUIPSLOTS_MAP.AMULET ~= GLOBAL.EQUIPSLOTS.BODY then

    -- 7. 有一个状态与旧插槽中配备的“赋予生命的护身符”有关。让我们也使用新的插槽.
    -- See `scripts/stategraphs/SGwilson.lua`.
    AddStategraphPostInit("wilson", function(self)
        local amulet_rebirth_state = self.states["amulet_rebirth"]

        -- Override `onenter` for the "amulet_rebirth" state.
        -- See `scripts/stategraphs/SGwilson.lua:9372`.
        local amulet_rebirth_state_onenter_base = amulet_rebirth_state.onenter
        amulet_rebirth_state.onenter = function(inst)
            amulet_rebirth_state_onenter_base(inst)
            local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS_MAP.AMULET)
            if item ~= nil and item.prefab == "amulet" then
                item = inst.components.inventory:RemoveItem(item)
                if item ~= nil then
                    item:Remove()
                    inst.sg.statemem.usedamulet_2 = true -- Mod note: `usedamulet_2` is set instead of `usedamulet`.
                end
            end
        end

        -- Override `onexit` for the "amulet_rebirth" state.
        -- See `scripts/stategraphs/SGwilson.lua:9414`.
        local amulet_rebirth_state_onexit_base = amulet_rebirth_state.onexit
        amulet_rebirth_state.onexit = function(inst)
            -- Mod note: `usedamulet_2` is checked instead of `usedamulet`.
            if inst.sg.statemem.usedamulet_2 and inst.components.inventory:GetEquippedItem(EQUIPSLOTS_MAP.AMULET) == nil then
                inst.AnimState:ClearOverrideSymbol("swap_body")
            end
            amulet_rebirth_state_onexit_base(inst)
        end
    end)

    -- 8. 在配方弹出窗口中，当施工护身符安装在旧插槽中时，会显示施工护身符的图标。让我们也使用新的插槽。
    -- See `scripts/widgets/recipepopup.lua:334`.

    RecipePopup = GLOBAL.require "widgets/recipepopup"

    AddGlobalClassPostConstruct("widgets/recipepopup", "RecipePopup", function(self)
        local RecipePopup_Refresh_Base = RecipePopup.Refresh
        function RecipePopup:Refresh()
            RecipePopup_Refresh_Base(self)
            if self.button:IsVisible() then
                local equipped = self.owner.replica.inventory:GetEquippedItem(EQUIPSLOTS_MAP.AMULET)
                local showamulet = equipped and equipped.prefab == "greenamulet"
                if showamulet then
                    self.amulet:Show()
                end
            end
        end
    end)

end

require "standardcomponents"

if EQUIP_TYPES.ARMOR ~= GLOBAL.EQUIPSLOTS.BODY then
    local function MakePunchingbag(name)
        AddPrefabPostInit(name, function(inst)
            if not GLOBAL.TheWorld.ismastersim then
                return
            end
    
            local function new_should_accept_item(inst, item, doer)
                return item.components.equippable ~= nil
                and (item.components.equippable.equipslot == GLOBAL.EQUIPSLOTS.HEAD
                    or item.components.equippable.equipslot == EQUIPSLOTS_MAP.ARMOR),
                "GENERIC"
            end
            inst.components.trader:SetAbleToAcceptTest(new_should_accept_item)
        end)
    end
    MakePunchingbag("punchingbag")
    MakePunchingbag("punchingbag_lunar")
    MakePunchingbag("punchingbag_shadow")

    local function MakeRepairableFix(name)
        AddPrefabPostInit(name, function(inst)
            if not GLOBAL.TheWorld.ismastersim then
                return
            end
            local old_fn = inst.components.forgerepairable.onrepaired
            local function NewOnRepaired(inst)
                old_fn(inst)
                inst.components.equippable.equipslot = EQUIPSLOTS_MAP.ARMOR
            end
            inst.components.forgerepairable:SetOnRepaired(NewOnRepaired)
        end)
    end

    MakeRepairableFix("armor_voidcloth")
    MakeRepairableFix("armor_lunarplant")
    MakeRepairableFix("armor_lunarplant_husk")
    -- MakeRepairableFix("armor_medal_obsidian")
    -- MakeRepairableFix("armor_blue_crystal")
    -- MakeRepairableFix("armor_medal_space_time")
end


-- 9. 渲染新装备插槽中的项目.
if GetModConfigData("config_render") then

    local anim_build_symbols = {
        -- 背包
        ["backpack"]     = {"swap_backpack",     "swap_body"}, -- 背包
        ["candybag"]     = {"candybag",          "swap_body"}, -- 糖果袋
        ["icepack"]      = {"swap_icepack",      "swap_body"}, -- 保鲜背包
        ["krampus_sack"] = {"swap_krampus_sack", "swap_body"}, -- 坎普斯背包
        ["piggyback"]    = {"swap_piggyback",    "swap_body"}, -- 小猪背包
        ["seedpouch"]    = {"seedpouch",         "swap_body"}, -- 种子袋
        ["spicepack"]    = {"swap_chefpack",     "swap_body"}, -- 厨师袋
        
        ["onemanband"]        = {"swap_one_man_band",  "swap_body_tall"}, -- 独奏乐器

        ["armorsnurtleshell"] = {"armor_slurtleshell", "swap_body_tall"}, -- 蜗牛护甲

        ["balloonvest"]     = {"balloonvest",     "swap_body"}, -- 充气背心

        -- Armors护甲
        ["armor_bramble"]   = {"armor_bramble",   "swap_body"}, -- 荆棘甲
        ["armordragonfly"]  = {"torso_dragonfly", "swap_body"}, -- 鳞甲
        ["armorgrass"]      = {"armor_grass",     "swap_body"}, -- 草甲
        ["armormarble"]     = {"armor_marble",    "swap_body"}, -- 大理石甲
        ["armorruins"]      = {"armor_ruins",     "swap_body"}, -- 铥矿甲
        ["armor_sanity"]    = {"armor_sanity",    "swap_body"}, -- 影甲
        ["armorskeleton"]   = {"armor_skeleton",  "swap_body"}, -- 骨甲
        ["armorwood"]       = {"armor_wood",      "swap_body"}, -- 木甲

        -- 护甲: 来自模组 "More Armor" (<https://steamcommunity.com/sharedfiles/filedetails/?id=1153998909>)
        ["armor_bone"]  = {"armor_bone",  "armor_my_folder"}, -- Bone Suite
        ["armor_stone"] = {"armor_stone", "armor_my_folder"}, -- Stone Suite

        -- Clothing服装
        ["armorslurper"]     = {"armor_slurper",          "swap_body"}, -- Belt of Hunger
        ["beargervest"]      = {"torso_bearger",          "swap_body"}, -- Hibearnation Vest
        ["hawaiianshirt"]    = {"torso_hawaiian",         "swap_body"}, -- Floral Shirt
        ["raincoat"]         = {"torso_rain",             "swap_body"}, -- Rain Coat
        ["reflectivevest"]   = {"torso_reflective",       "swap_body"}, -- Summer Frest
        ["sweatervest"]      = {"armor_sweatervest",      "swap_body"}, -- Dapper Vest
        ["trunkvest_summer"] = {"armor_trunkvest_summer", "swap_body"}, -- Breezy Vest
        ["trunkvest_winter"] = {"armor_trunkvest_winter", "swap_body"}, -- Puffy Vest
        ["carnival_vest_a"]  = {"carnival_vest_a",        "swap_body"}, -- Chirpy Scarf
        ["carnival_vest_b"]  = {"carnival_vest_b",        "swap_body"}, -- Chirpy Cloak
        ["carnival_vest_c"]  = {"carnival_vest_c",        "swap_body"}, -- Chirpy Capelet
        
        -- Amulets护符
        ["amulet"]       = {"torso_amulets", "redamulet"   }, -- Life Giving Amulet
        ["blueamulet"]   = {"torso_amulets", "blueamulet"  }, -- Chilled Amulet
        ["purpleamulet"] = {"torso_amulets", "purpleamulet"}, -- Nightmare Amulet
        ["orangeamulet"] = {"torso_amulets", "orangeamulet"}, -- The Lazy Forager
        ["greenamulet"]  = {"torso_amulets", "greenamulet" }, -- Construction Amulet
        ["yellowamulet"] = {"torso_amulets", "yellowamulet"}, -- Magiluminescence

        -- 重物
        ["cavein_boulder"]       = {"swap_cavein_boulder", "swap_body"}, -- Boulder -- TODO: variations.
        ["glassspike_short"]     = {"swap_glass_spike", "swap_body_short"}, -- Glass Spike - Short
        ["glassspike_med"]       = {"swap_glass_spike", "swap_body_med"},   -- Glass Spike - Medium
        ["glassspike_tall"]      = {"swap_glass_spike", "swap_body_tall"},  -- Glass Spike - Tall
        ["glassblock"]           = {"swap_glass_block", "swap_body"},       -- Glass Castle
        ["moon_altar_idol"]      = {"swap_altar_idolpiece",  "swap_body"}, -- Celestial Altar Idol
        ["moon_altar_glass"]     = {"swap_altar_glasspiece", "swap_body"}, -- Celestial Altar Base
        ["moon_altar_seed"]      = {"swap_altar_seedpiece",  "swap_body"}, -- Celestial Altar Orb
        ["moon_altar_crown"]     = {"swap_altar_crownpiece", "swap_body"}, -- Inactive Celestial Tribute
        ["moon_altar_ward"]      = {"swap_altar_wardpiece",  "swap_body"}, -- Celestial Sanctum Ward
        ["moon_altar_icon"]      = {"swap_altar_iconpiece",  "swap_body"}, -- Celestial Sanctum Icon
        ["sculpture_knighthead"] = {"swap_sculpture_knighthead", "swap_body"}, -- Suspicious Marble - Knight Head
        ["sculpture_bishophead"] = {"swap_sculpture_bishophead", "swap_body"}, -- Suspicious Marble - Bishop Head
        ["sculpture_rooknose"]   = {"swap_sculpture_rooknose",   "swap_body"}, -- Suspicious Marble - Rook Nose
        ["shell_cluster"]        = {"singingshell_cluster", "swap_body"}, -- Shell Cluster
        ["sunkenchest"]          = {"swap_sunken_treasurechest", "swap_body"}, -- Sunken Chest
        ["oceantreenut"]         = {"oceantreenut", "swap_body"}, -- Knobbly Tree Nut

        -- 重物: 来自模组"Moving Box" (<https://steamcommunity.com/sharedfiles/filedetails/?id=1079538195>)
        ["moving_box_full"]      = {"swap_box_full", "swap_body"} -- Moving Box (Full)
    }

    -- 重物：棋子雕像
    local CHESS_PIESES = {
        "pawn", "rook", "knight", "bishop", "muse", "formal", "hornucopia", "pipe", "deerclops", "bearger",
        "moosegoose", "dragonfly", "clayhound", "claywarg", "butterfly", "anchor", "moon", "carrat", "crabking",
        "malbatross", "toadstool", "stalker", "klaus", "beequeen", "antlion", "minotaur"
    }
    local CHESS_MATERIALS = {"marble", "stone", "moonglass"}
    for _, p in ipairs(CHESS_PIESES) do
        anim_build_symbols["chesspiece_" .. p] = {"swap_chesspiece_" .. p, "swap_body"}
        for _, m in ipairs(CHESS_MATERIALS) do
            anim_build_symbols["chesspiece_" .. p .. "_" .. m] = {"swap_chesspiece_" .. p .. "_" .. m, "swap_body"}
        end
    end

    -- 重物：蔬菜
    local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
    for name, def in pairs(PLANT_DEFS) do
        local build_symbol = {def.build or "farm_plant_" .. name, "swap_body"}
        anim_build_symbols[name .. "_oversized"]       = build_symbol
        anim_build_symbols[name .. "_oversized_waxed"] = build_symbol
    end

    local function get_equipped_item(inventory, type)
        local candidate = inventory:GetEquippedItem(EQUIPSLOTS_MAP[string.upper(type)])
        return ((candidate ~= nil) and candidate:HasTag(type)) and candidate or nil
    end

    local function render_equipped_item(owner, render_slot, item)
        if item ~= nil then
            local build_symbol = anim_build_symbols[item.prefab]
            if build_symbol ~= nil then
                local skin_build = item:GetSkinBuild()
                if skin_build ~= nil then
                    owner.AnimState:OverrideItemSkinSymbol(render_slot, skin_build, "swap_body", item.GUID, build_symbol[1])
                else
                    owner.AnimState:OverrideSymbol(render_slot, build_symbol[1], build_symbol[2])
                end
            end
        else
            owner.AnimState:ClearOverrideSymbol(render_slot)
        end
    end

    local function render_body_equipment(owner)
        local inventory = owner.replica.inventory

        local item1 =
                   get_equipped_item(inventory, EQUIP_TYPES.BACKPACK)
                or get_equipped_item(inventory, EQUIP_TYPES.BAND)
                or get_equipped_item(inventory, EQUIP_TYPES.SHELL)
        local item2 =
                   get_equipped_item(inventory, EQUIP_TYPES.HEAVY)
                or get_equipped_item(inventory, EQUIP_TYPES.LIFEVEST)
                or get_equipped_item(inventory, EQUIP_TYPES.ARMOR)
                or get_equipped_item(inventory, EQUIP_TYPES.CLOTHING)
                or get_equipped_item(inventory, EQUIP_TYPES.AMULET)

        render_equipped_item(owner, "swap_body_tall", item1)
        render_equipped_item(owner, "swap_body",      item2)
    end

    local function on_equip_or_unequip(owner, data)
        if (data.eslot == GLOBAL.EQUIPSLOTS.BODY) or table.contains(EXTRA_EQUIPSLOTS, data.eslot) then
            render_body_equipment(owner)
        end
    end

    AddComponentPostInit("inventory", function(_, inst)
        inst:ListenForEvent("equip",   on_equip_or_unequip)
        inst:ListenForEvent("unequip", on_equip_or_unequip)
    end)

end

--修复假人互动bug
local function new_has_any_equipment(inst)
    return inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS) ~= nil
        or inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD) ~= nil
        or inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.BODY) ~= nil
        or inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.EXTRABODY1) ~= nil
        or inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.EXTRABODY2) ~= nil
        or inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.EXTRABODY3) ~= nil
end

local function newCanSwap(inst, doer)
    -- We can perform a swap if either of our head/body slots are filled,
    -- or either of the doer's are filled.
    return new_has_any_equipment(inst)
        or (doer.components.inventory ~= nil and new_has_any_equipment(doer))
end

local function swapEquipment(inst,doer,equipslot)
    if equipslot == nil then
        return false
    end
    local doer_item = doer.components.inventory:Unequip(equipslot)
    local inst_item = inst.components.inventory:Unequip(equipslot)
    if doer_item == nil and inst_item == nil then
        return false
    end
    if inst_item ~= nil and not inst_item.components.equippable:IsRestricted(doer)then
        doer.components.inventory:Equip(inst_item)
    end
    if doer_item ~= nil and not doer_item.components.equippable:IsRestricted(inst)then
        inst.components.inventory:Equip(doer_item)
    end
    return true
end

local function new_should_accept_item(inst, item, doer)
    return item.components.equippable ~= nil
        and (item.components.equippable.equipslot == GLOBAL.EQUIPSLOTS.HANDS
            or item.components.equippable.equipslot == GLOBAL.EQUIPSLOTS.HEAD
            or item.components.equippable.equipslot == GLOBAL.EQUIPSLOTS.BODY
            or item.components.equippable.equipslot == GLOBAL.EQUIPSLOTS.EXTRABODY1
            or item.components.equippable.equipslot == GLOBAL.EQUIPSLOTS.EXTRABODY2
            or item.components.equippable.equipslot == GLOBAL.EQUIPSLOTS.EXTRABODY3),
        "GENERIC"
end

if GLOBAL.TheNet:GetIsServer() then --这段代码只能在服务端运行，所以加了这个判断
    AddPrefabPostInit("sewing_mannequin", function(inst)
        local function newOnActivate(inst, doer)
            local function become_inactive(inst)
                inst.components.activatable.inactive = true
            end
            inst:DoTaskInTime(5*GLOBAL.FRAMES, become_inactive)

            if newCanSwap(inst, doer) then
                local handswap_success = swapEquipment(inst, doer, GLOBAL.EQUIPSLOTS.HANDS)
                local headswap_success = swapEquipment(inst, doer, GLOBAL.EQUIPSLOTS.HEAD)
                local body_success = swapEquipment(inst, doer, GLOBAL.EQUIPSLOTS.BODY)
                local extrabody1_success = swapEquipment(inst, doer, GLOBAL.EQUIPSLOTS.EXTRABODY1)
                local extrabody2_success = swapEquipment(inst, doer, GLOBAL.EQUIPSLOTS.EXTRABODY2)
                local extrabody3_success = swapEquipment(inst, doer, GLOBAL.EQUIPSLOTS.EXTRABODY3)
                if (handswap_success or headswap_success or body_success or extrabody1_success or extrabody2_success or extrabody3_success) then
                    inst.AnimState:PlayAnimation("swap")
                    inst.SoundEmitter:PlaySound("stageplay_set/mannequin/swap")
                    inst.AnimState:PushAnimation("idle", false)
        
                    return true
                else
                    return false, "MANNEQUIN_EQUIPSWAPFAILED"
                end
            else
                -- This should be exceedingly rare because we shouldn't have been activatable
                -- if we didn't have anything to swap.
                return false
            end
        end
        inst.components.activatable.OnActivate = newOnActivate
        inst.components.trader:SetAbleToAcceptTest(new_should_accept_item)
    end)
end