extends RefCounted
class_name FrameworkConfig

## 框架配置
## 管理框架的全局配置和常量

# ==================== 框架版本 ====================
const FRAMEWORK_VERSION: String = "1.0.0"
const FRAMEWORK_NAME: String = "Magic Tower Framework"
const FRAMEWORK_AUTHOR: String = "Chengxy AI Develop"

# ==================== 游戏配置 ====================
const DEFAULT_SCREEN_WIDTH: int = 1280
const DEFAULT_SCREEN_HEIGHT: int = 720
const DEFAULT_FPS: int = 60
const DEFAULT_LANGUAGE: String = "zh_CN"

# ==================== 存档配置 ====================
const MAX_SAVE_SLOTS: int = 3
const SAVE_DIRECTORY: String = "user://saves/"
const CONFIG_FILE: String = "user://game_config.cfg"

# ==================== 数据配置 ====================
const DATA_DIRECTORY: String = "res://data/"
const MOD_DIRECTORY: String = "res://mods/"
const PLUGIN_DIRECTORY: String = "res://plugins/"
const ASSET_DIRECTORY: String = "res://assets/"

# ==================== 战斗配置 ====================
const BATTLE_ANIMATION_SPEED: float = 1.0
const BATTLE_TURN_TIMEOUT: int = 30  # 秒
const MAX_BATTLE_LOG: int = 50

# ==================== 玩家基础属性 ====================
const PLAYER_BASE_HP: int = 1000
const PLAYER_BASE_ATTACK: int = 10
const PLAYER_BASE_DEFENSE: int = 10
const PLAYER_BASE_GOLD: int = 0
const PLAYER_BASE_LEVEL: int = 1

# ==================== 楼层配置 ====================
const DEFAULT_FLOOR_SIZE: int = 17
const BOSS_FLOOR_SIZE: int = 21
const MAX_FLOOR_ID: int = 50
const MIN_FLOOR_ID: int = 1

# ==================== 输入配置 ====================
const INPUT_MOVE_UP: String = "move_up"
const INPUT_MOVE_DOWN: String = "move_down"
const INPUT_MOVE_LEFT: String = "move_left"
const INPUT_MOVE_RIGHT: String = "move_right"
const INPUT_INTERACT: String = "interact"
const INPUT_INVENTORY: String = "inventory"
const INPUT_STATUS: String = "status"
const INPUT_PAUSE: String = "pause"
const INPUT_CONFIRM: String = "confirm"
const INPUT_CANCEL: String = "cancel"

# ==================== 自动加载节点 ====================
const AUTOLOAD_NAMES: Array = [
	"GameManager",
	"EventBus",
	"SceneManager",
	"DataManager",
	"MapLoader",
	"SaveSystem",
	"ModManager",
	"PluginManager"
]

# ==================== 日志配置 ====================
const LOG_LEVEL_DEBUG: int = 0
const LOG_LEVEL_INFO: int = 1
const LOG_LEVEL_WARNING: int = 2
const LOG_LEVEL_ERROR: int = 3
const DEFAULT_LOG_LEVEL: int = LOG_LEVEL_INFO

# ==================== 性能配置 ====================
const ENABLE_CACHE: bool = true
const ENABLE_PRELOAD: bool = true
const MAX_CACHE_SIZE: int = 100  # MB
const GC_INTERVAL: float = 60.0  # 秒

# ==================== UI 配置 ====================
const UI_SCALE: float = 1.0
const UI_FONT_SIZE: int = 16
const UI_ANIMATION_ENABLED: bool = true
const UI_PARTICLE_ENABLED: bool = true

# ==================== 音频配置 ====================
const AUDIO_MAX_CHANNELS: int = 32
const AUDIO_DEFAULT_MUSIC_VOLUME: float = 0.8
const AUDIO_DEFAULT_SFX_VOLUME: float = 0.6

# ==================== 调试配置 ====================
static var debug_mode: bool = false
static var show_fps: bool = false
static var show_hitboxes: bool = false
static var log_level: int = DEFAULT_LOG_LEVEL

# ==================== 方法 ====================

## 初始化框架配置
static func initialize():
	print("[FrameworkConfig] Initializing...")
	print("[FrameworkConfig] Version: %s" % FRAMEWORK_VERSION)
	print("[FrameworkConfig] Debug Mode: %s" % str(debug_mode))
	
	# 创建必要的目录
	_create_directories()


## 创建必要的目录
static func _create_directories():
	var directories = [
		SAVE_DIRECTORY,
		MOD_DIRECTORY,
		PLUGIN_DIRECTORY
	]
	
	for dir_path in directories:
		var dir = DirAccess.open(dir_path)
		if dir == null:
			DirAccess.make_dir_recursive_absolute(dir_path)
			print("[FrameworkConfig] Created directory: " + dir_path)


## 检查是否调试模式
static func is_debug() -> bool:
	return debug_mode or OS.is_debug_build()


## 设置调试模式
static func set_debug_mode(enabled: bool):
	debug_mode = enabled
	print("[FrameworkConfig] Debug mode: " + str(enabled))


## 获取日志前缀
static func get_log_prefix(level: int) -> String:
	match level:
		LOG_LEVEL_DEBUG: return "[DEBUG]"
		LOG_LEVEL_INFO: return "[INFO]"
		LOG_LEVEL_WARNING: return "[WARNING]"
		LOG_LEVEL_ERROR: return "[ERROR]"
		_: return "[LOG]"


## 日志输出
static func log(message: String, level: int = LOG_LEVEL_INFO):
	if level >= log_level:
		var prefix = get_log_prefix(level)
		print("%s %s" % [prefix, message])


## 获取框架信息
static func get_framework_info() -> Dictionary:
	return {
		"name": FRAMEWORK_NAME,
		"version": FRAMEWORK_VERSION,
		"author": FRAMEWORK_AUTHOR,
		"debug_mode": debug_mode,
		"godot_version": Engine.get_version_info().string
	}


## 获取性能配置
static func get_performance_config() -> Dictionary:
	return {
		"enable_cache": ENABLE_CACHE,
		"enable_preload": ENABLE_PRELOAD,
		"max_cache_size": MAX_CACHE_SIZE,
		"gc_interval": GC_INTERVAL
	}


## 验证配置
static func validate() -> bool:
	var is_valid = true
	
	# 检查必填的自动加载
	for autoload_name in AUTOLOAD_NAMES:
		if not Engine.has_singleton(autoload_name):
			push_warning("[FrameworkConfig] Autoload not found: " + autoload_name)
			# 不返回 false，因为有些可能是可选的
	
	# 检查目录
	var required_dirs = [DATA_DIRECTORY, ASSET_DIRECTORY]
	for dir_path in required_dirs:
		if not DirAccess.dir_exists_absolute(dir_path):
			push_warning("[FrameworkConfig] Directory not found: " + dir_path)
	
	return is_valid


## 导出配置到文件
static func export_config(output_path: String) -> bool:
	var config = ConfigFile.new()
	
	# 游戏配置
	config.set_value("game", "version", FRAMEWORK_VERSION)
	config.set_value("game", "debug_mode", debug_mode)
	config.set_value("game", "language", DEFAULT_LANGUAGE)
	
	# 显示配置
	config.set_value("display", "width", DEFAULT_SCREEN_WIDTH)
	config.set_value("display", "height", DEFAULT_SCREEN_HEIGHT)
	config.set_value("display", "fps", DEFAULT_FPS)
	
	# 音频配置
	config.set_value("audio", "music_volume", AUDIO_DEFAULT_MUSIC_VOLUME)
	config.set_value("audio", "sfx_volume", AUDIO_DEFAULT_SFX_VOLUME)
	
	# 性能配置
	config.set_value("performance", "enable_cache", ENABLE_CACHE)
	config.set_value("performance", "enable_preload", ENABLE_PRELOAD)
	
	var error = config.save(output_path)
	if error == OK:
		print("[FrameworkConfig] Config exported to: " + output_path)
		return true
	else:
		push_error("[FrameworkConfig] Failed to export config: " + str(error))
		return false


## 从文件导入配置
static func import_config(input_path: String) -> bool:
	if not FileAccess.file_exists(input_path):
		push_error("[FrameworkConfig] Config file not found: " + input_path)
		return false
	
	var config = ConfigFile.new()
	var error = config.load(input_path)
	if error != OK:
		push_error("[FrameworkConfig] Failed to load config: " + str(error))
		return false
	
	# 读取配置
	debug_mode = config.get_value("game", "debug_mode", debug_mode)
	log_level = config.get_value("game", "log_level", DEFAULT_LOG_LEVEL)
	
	print("[FrameworkConfig] Config imported from: " + input_path)
	return true
