extends Node
class_name GameManager

## 游戏管理器 - 单例
## 管理游戏全局状态和核心逻辑

# ==================== 单例实例 ====================
static var instance: GameManager = null

# ==================== 游戏状态 ====================
enum GameState {
	NONE,
	INITIALIZING,
	MENU,
	PLAYING,
	PAUSED,
	IN_BATTLE,
	GAME_OVER,
	VICTORY,
	EDITOR
}

var current_state: GameState = GameState.NONE
var game_version: String = "1.0.0"
var framework_version: String = "1.0.0"

# ==================== 玩家数据 ====================
var player_hp: int = 1000
var player_max_hp: int = 1000
var player_attack: int = 10
var player_defense: int = 10
var player_gold: int = 0
var player_level: int = 1
var player_experience: int = 0
var player_keys: Dictionary = {}
var player_items: Array = []
var player_current_floor: int = 1

# ==================== 游戏配置 ====================
var current_language: String = "zh_CN"
var is_music_enabled: bool = true
var is_sfx_enabled: bool = true
var music_volume: float = 0.8
var sfx_volume: float = 0.6

# ==================== 进度数据 ====================
var unlocked_floors: int = 1
var total_play_time: float = 0.0
var achievements_unlocked: Array = []


func _init():
	# 确保单例
	if instance != null:
		push_error("GameManager already exists! Use GameManager.instance instead.")
		queue_free()
		return
	instance = self


func _ready():
	# 初始化游戏
	initialize_game()


## 初始化游戏
func initialize_game():
	current_state = GameState.INITIALIZING
	print("[GameManager] Initializing game...")
	
	# 加载配置
	load_config()
	
	# 初始化数据管理器
	DataManager.initialize()
	
	# 初始化事件总线
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)
	
	current_state = GameState.MENU
	print("[GameManager] Game initialized, version: %s" % game_version)


## 开始新游戏
func start_new_game():
	print("[GameManager] Starting new game...")
	reset_player_data()
	current_state = GameState.PLAYING
	EventBus.emit_signal("game_started")
	load_floor(1)


## 继续游戏
func continue_game():
	current_state = GameState.PLAYING
	EventBus.emit_signal("game_resumed")


## 暂停游戏
func pause_game():
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		EventBus.emit_signal("game_paused")
		print("[GameManager] Game paused")


## 恢复游戏
func resume_game():
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		EventBus.emit_signal("game_resumed")
		print("[GameManager] Game resumed")


## 结束游戏
func end_game(victory: bool = false):
	current_state = GameState.GAME_OVER if not victory else GameState.VICTORY
	EventBus.emit_signal("game_ended", victory)
	print("[GameManager] Game ended, victory: %s" % str(victory))


## 重置玩家数据
func reset_player_data():
	player_hp = 1000
	player_max_hp = 1000
	player_attack = 10
	player_defense = 10
	player_gold = 0
	player_level = 1
	player_experience = 0
	player_keys = {}
	player_items = []
	player_current_floor = 1
	unlocked_floors = 1
	print("[GameManager] Player data reset")


## 加载楼层
func load_floor(floor_id: int):
	print("[GameManager] Loading floor %d..." % floor_id)
	player_current_floor = floor_id
	EventBus.emit_signal("floor_entered", floor_id)
	
	# 通过 MapLoader 加载楼层
	if MapLoader:
		MapLoader.load_floor(floor_id)


## 玩家移动
func player_move_to(x: int, y: int):
	EventBus.emit_signal("player_moved", x, y)


## 玩家获得道具
func player_obtain_item(item_id: String):
	player_items.append(item_id)
	EventBus.emit_signal("player_item_obtained", item_id)
	EventBus.emit_signal("item_picked_up", item_id)
	print("[GameManager] Player obtained item: %s" % item_id)


## 玩家使用道具
func player_use_item(item_id: String):
	if item_id in player_items:
		player_items.erase(item_id)
		EventBus.emit_signal("player_item_used", item_id)
		print("[GameManager] Player used item: %s" % item_id)


## 玩家获得金币
func player_gain_gold(amount: int):
	player_gold += amount
	EventBus.emit_signal("player_gold_changed", player_gold)
	print("[GameManager] Player gained %d gold, total: %d" % [amount, player_gold])


## 玩家升级
func player_gain_experience(amount: int):
	player_experience += amount
	# 检查是否升级
	var exp_needed = player_level * 100
	if player_experience >= exp_needed:
		level_up()


## 玩家升级
func level_up():
	player_level += 1
	player_max_hp += 50
	player_attack += 5
	player_defense += 5
	player_hp = player_max_hp
	EventBus.emit_signal("player_level_up", player_level)
	EventBus.notify("升级了！当前等级：%d" % player_level, "success")
	print("[GameManager] Player leveled up to %d" % player_level)


## 战斗胜利
func on_battle_victory(enemy_id: String, gold_reward: int, exp_reward: int):
	player_gain_gold(gold_reward)
	player_gain_experience(exp_reward)
	EventBus.emit_signal("enemy_defeated", enemy_id, {"gold": gold_reward, "exp": exp_reward})


## 加载配置
func load_config():
	# 从配置文件加载
	var config = ConfigFile.new()
	var err = config.load("user://game_config.cfg")
	if err == OK:
		current_language = config.get_value("game", "language", "zh_CN")
		is_music_enabled = config.get_value("audio", "music_enabled", true)
		is_sfx_enabled = config.get_value("audio", "sfx_enabled", true)
		music_volume = config.get_value("audio", "music_volume", 0.8)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.6)
		print("[GameManager] Config loaded")
	else:
		print("[GameManager] Config not found, using defaults")
		save_config()


## 保存配置
func save_config():
	var config = ConfigFile.new()
	config.set_value("game", "language", current_language)
	config.set_value("audio", "music_enabled", is_music_enabled)
	config.set_value("audio", "sfx_enabled", is_sfx_enabled)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save("user://game_config.cfg")
	print("[GameManager] Config saved")


## 获取游戏状态字符串
func get_state_string() -> String:
	match current_state:
		GameState.NONE: return "NONE"
		GameState.INITIALIZING: return "INITIALIZING"
		GameState.MENU: return "MENU"
		GameState.PLAYING: return "PLAYING"
		GameState.PAUSED: return "PAUSED"
		GameState.IN_BATTLE: return "IN_BATTLE"
		GameState.GAME_OVER: return "GAME_OVER"
		GameState.VICTORY: return "VICTORY"
		GameState.EDITOR: return "EDITOR"
	return "UNKNOWN"


## 获取玩家数据字典 (用于存档)
func get_player_data() -> Dictionary:
	return {
		"hp": player_hp,
		"max_hp": player_max_hp,
		"attack": player_attack,
		"defense": player_defense,
		"gold": player_gold,
		"level": player_level,
		"experience": player_experience,
		"keys": player_keys.duplicate(),
		"items": player_items.duplicate(),
		"current_floor": player_current_floor,
		"unlocked_floors": unlocked_floors,
		"achievements": achievements_unlocked.duplicate(),
		"play_time": total_play_time
	}


## 加载玩家数据 (用于读档)
func load_player_data(data: Dictionary):
	player_hp = data.get("hp", 1000)
	player_max_hp = data.get("max_hp", 1000)
	player_attack = data.get("attack", 10)
	player_defense = data.get("defense", 10)
	player_gold = data.get("gold", 0)
	player_level = data.get("level", 1)
	player_experience = data.get("experience", 0)
	player_keys = data.get("keys", {})
	player_items = data.get("items", [])
	player_current_floor = data.get("current_floor", 1)
	unlocked_floors = data.get("unlocked_floors", 1)
	achievements_unlocked = data.get("achievements", [])
	total_play_time = data.get("play_time", 0.0)
	print("[GameManager] Player data loaded")


# ==================== 事件回调 ====================
func _on_game_started():
	total_play_time = 0.0
	print("[GameManager] Game started, play time reset")


func _on_game_paused():
	print("[GameManager] Game paused callback")


func _on_game_resumed():
	print("[GameManager] Game resumed callback")
