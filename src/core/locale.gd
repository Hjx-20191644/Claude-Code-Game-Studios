extends Node

## Translation utility. Autoload "Locale" — access via Locale.t("key").

enum Lang { EN, ZH }

static var _current: int = Lang.ZH

static var _dict_en := {
	# Main menu
	"hunting_ground": "Hunting Ground",
	"arena_survival": "Arena Survival Roguelite",
	"start_game": "Start Game",
	"meta_upgrades": "Meta Upgrades",
	"leaderboard": "Leaderboard",
	"quit": "Quit",
	# Settings
	"settings": "Settings",
	"master_volume": "Master Volume",
	"sfx_volume": "SFX Volume",
	"window_mode": "Window Mode",
	"windowed": "Windowed",
	"fullscreen": "Fullscreen",
	"maximized": "Maximized",
	"language": "Language",
	"lang_en": "English",
	"lang_zh": "Chinese",
	"back": "Back",
	# Pause
	"resume": "Resume",
	"return_main_menu": "Return to Main Menu",
	"quit_desktop": "Quit to Desktop",
	"paused": "Paused",
	"player_stats": "Player Stats",
	"survival": "Survival",
	"offense": "Offense",
	"utility": "Utility",
	"weapons": "Weapons",
	"hp": "HP",
	"hp_regen": "HP Regen",
	"lifesteal": "Lifesteal",
	"thorns": "Thorns",
	"dodge_cd": "Dodge CD",
	"atk_speed": "Atk Speed",
	"melee_dmg": "Melee Dmg",
	"ranged_dmg": "Ranged Dmg",
	"crit_chance": "Crit Chance",
	"dmg_aura": "Dmg Aura",
	"move_speed": "Move Speed",
	"pickup": "Pickup",
	# HUD
	"wave": "Wave",
	"kills": "Kills",
	"shards": "Shards",
	"score": "Score",
	"time": "Time",
	# Game Over
	"hunt_over": "Hunt Over",
	"continue": "Continue",
	"play_again": "Play Again",
	"shards_earned": "Shards Earned",
	# Upgrade
	"choose_upgrade": "Choose an Upgrade",
	"acquired": "Acquired",
	"none": "(none)",
	# Weapon select
	"select_weapons": "Select Weapons",
	"left_hand": "Left Hand",
	"right_hand": "Right Hand",
	"dmg": "DMG",
	"cd": "CD",
	"angle": "Angle",
	"range": "Range",
	"ammo": "Ammo",
	"pierce": "Pierce",
	"explosive": "Explosive",
	"melee_icon": "⚔",
	"ranged_icon": "➹",
	# Boss
	"phase": "Phase",
	# Unlock tree
	"unlocked": "Unlocked",
	"requires": "Requires",
	"cost": "Cost",
	"purchase": "Purchase",
	"purchased": "Purchased!",
	"cannot_purchase": "Cannot purchase",
	"no_unlock_data": "Unlock data not available",
	"shard_unit": "shards",
	# Leaderboard
	"no_records": "No records yet",
	"rank_col": "#",
	"wave_col": "Wave",
	"kills_col": "Kills",
	"time_col": "Time",
}

static var _dict_zh := {
	# Main menu
	"hunting_ground": "猎场",
	"arena_survival": "竞技场生存 Roguelite",
	"start_game": "开始游戏",
	"meta_upgrades": "元升级",
	"leaderboard": "排行榜",
	"quit": "退出",
	# Settings
	"settings": "设置",
	"master_volume": "主音量",
	"sfx_volume": "音效音量",
	"window_mode": "窗口模式",
	"windowed": "窗口",
	"fullscreen": "全屏",
	"maximized": "最大化",
	"language": "语言",
	"lang_en": "English",
	"lang_zh": "中文",
	"back": "返回",
	# Pause
	"resume": "继续游戏",
	"return_main_menu": "返回主菜单",
	"quit_desktop": "退出游戏",
	"paused": "已暂停",
	"player_stats": "玩家属性",
	"survival": "生存",
	"offense": "攻击",
	"utility": "功能",
	"weapons": "武器",
	"hp": "生命",
	"hp_regen": "生命回复",
	"lifesteal": "吸血",
	"thorns": "反伤",
	"dodge_cd": "闪避冷却",
	"atk_speed": "攻击速度",
	"melee_dmg": "近战伤害",
	"ranged_dmg": "远程伤害",
	"crit_chance": "暴击率",
	"dmg_aura": "伤害光环",
	"move_speed": "移动速度",
	"pickup": "拾取范围",
	# HUD
	"wave": "波次",
	"kills": "击杀",
	"shards": "碎片",
	"score": "分数",
	"time": "时间",
	# Game Over
	"hunt_over": "狩猎结束",
	"continue": "返回主菜单",
	"play_again": "再来一局",
	"shards_earned": "获得碎片",
	# Upgrade
	"choose_upgrade": "选择升级",
	"acquired": "已获得",
	"none": "（无）",
	# Weapon select
	"select_weapons": "选择武器",
	"left_hand": "左手",
	"right_hand": "右手",
	"dmg": "伤害",
	"cd": "冷却",
	"angle": "角度",
	"range": "范围",
	"ammo": "弹药",
	"pierce": "穿透",
	"explosive": "爆炸",
	"melee_icon": "⚔",
	"ranged_icon": "➹",
	# Boss
	"phase": "阶段",
	# Unlock tree
	"unlocked": "已解锁",
	"requires": "需要",
	"cost": "花费",
	"purchase": "购买",
	"purchased": "购买成功！",
	"cannot_purchase": "无法购买",
	"no_unlock_data": "升级数据不可用",
	"shard_unit": "碎片",
	# Leaderboard
	"no_records": "暂无记录",
	"rank_col": "#",
	"wave_col": "波次",
	"kills_col": "击杀",
	"time_col": "时间",
}


static func lang() -> int:
	return _current


static func set_lang(lg: int) -> void:
	_current = lg


static func t(key: String) -> String:
	match _current:
		Lang.ZH:
			return _dict_zh.get(key, key)
	return _dict_en.get(key, key)
