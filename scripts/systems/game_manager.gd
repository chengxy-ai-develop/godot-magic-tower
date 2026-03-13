extends Node
class_name GameManager

## 游戏管理器 - 全局游戏状态管理

# 信号
signal game_started()
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal floor_changed(floor_id: int)

# 单例实例
static var instance: GameManager

# 游戏状态
var current_floor: int = 1
var game_state: Dictionary = {}
var save_slots: int = 3  # 存档槽数量

# 游戏配置
var game_config: Dictionary = {
	"screen_width": 1280,
	"screen_height": 720,
	"fullscreen": false,
	"sound_enabled": true,
	"music_enabled": true,
	"auto_battle": false
}

func _ready() -> void:
	# 设置为单例
	instance = self
	print("[GameManager] 游戏管理器初始化完成")
	
	# 加载配置
	_load_config()

func _load_config() -> void:
	"""
	加载游戏配置
	"""
	var config_path = "user://game_config.cfg"
	if FileAccess.file_exists(config_path):
		var config = ConfigFile.new()
		config.load(config_path)
		# 加载配置项...

func start_new_game() -> void:
	"""
	开始新游戏
	"""
	game_state = {
		"player": {
			"hp": 1000,
			"max_hp": 1000,
			"attack": 10,
			"defense": 10,
			"gold": 0,
			"experience": 0,
			"floor": 1,
			"keys": {"yellow": 0, "blue": 0, "red": 0}
		},
		"inventory": [],
		"flags": {},
		"play_time": 0
	}
	
	current_floor = 1
	game_started.emit()
	print("[GameManager] 新游戏开始")

func save_game(slot: int) -> bool:
	"""
	保存游戏
	"""
	var save_path = "user://save_%d.dat" % slot
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": game_state,
		"current_floor": current_floor
	}
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		game_saved.emit(slot)
		print("[GameManager] 游戏已保存到槽位 ", slot)
		return true
	else:
		print("[GameManager] 保存失败：", save_path)
		return false

func load_game(slot: int) -> bool:
	"""
	加载游戏
	"""
	var save_path = "user://save_%d.dat" % slot
	if not FileAccess.file_exists(save_path):
		print("[GameManager] 存档不存在：", save_path)
		return false
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		game_state = save_data["game_state"]
		current_floor = save_data["current_floor"]
		
		game_loaded.emit(slot)
		print("[GameManager] 游戏已从槽位 ", slot, " 加载")
		return true
	
	return false

func has_save(slot: int) -> bool:
	"""
	检查存档是否存在
	"""
	var save_path = "user://save_%d.dat" % slot
	return FileAccess.file_exists(save_path)

func change_floor(new_floor: int) -> void:
	"""
	切换楼层
	"""
	current_floor = new_floor
	floor_changed.emit(new_floor)
	print("[GameManager] 切换到第 ", new_floor, " 层")

func get_game_state() -> Dictionary:
	"""
	获取游戏状态
	"""
	return game_state.duplicate(true)

func set_flag(flag_name: String, value: Variant) -> void:
	"""
	设置游戏标记
	"""
	game_state["flags"][flag_name] = value

func get_flag(flag_name: String, default: Variant = null) -> Variant:
	"""
	获取游戏标记
	"""
	return game_state["flags"].get(flag_name, default)

func update_play_time(delta: float) -> void:
	"""
	更新游戏时间
	"""
	if game_state.has("play_time"):
		game_state["play_time"] += delta

func quit_game() -> void:
	"""
	退出游戏
	"""
	print("[GameManager] 游戏退出")
	get_tree().quit()
