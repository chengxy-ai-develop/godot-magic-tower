extends Node
class_name GameManagerClass

## 游戏管理器 - 核心游戏逻辑和状态管理
## 单例模式，通过 GameManager 全局访问

signal game_started
signal game_won
signal game_lost
signal floor_changed(floor_id: int)
signal player_died

const game_version := "1.0.0"
const max_floor := 50

var current_floor: int = 1
var is_game_active: bool = false
var game_state: Dictionary = {}


func _ready() -> void:
	print("[GameManager] 初始化完成 (版本：", game_version, ")")


## 开始新游戏
func start_new_game() -> void:
	print("[GameManager] 开始新游戏")
	current_floor = 1
	is_game_active = true
	game_state = {
		"started_at": Time.get_unix_time_from_system(),
		"deaths": 0,
		"saves_used": 0
	}
	game_started.emit()


## 继续游戏
func continue_game() -> void:
	print("[GameManager] 继续游戏")
	is_game_active = true


## 改变楼层
func change_floor(floor_id: int) -> void:
	if floor_id < 1 or floor_id > max_floor:
		print("[GameManager] 无效的楼层：", floor_id)
		return
	
	current_floor = floor_id
	print("[GameManager] 到达第 ", floor_id, " 层")
	floor_changed.emit(floor_id)


## 玩家死亡
func player_death() -> void:
	print("[GameManager] 玩家死亡")
	is_game_active = false
	if game_state.has("deaths"):
		game_state["deaths"] += 1
	game_lost.emit()


## 游戏胜利
func win_game() -> void:
	print("[GameManager] 游戏胜利!")
	is_game_active = false
	game_won.emit()


## 获取当前楼层
func get_current_floor() -> int:
	return current_floor


## 检查游戏是否激活
func is_active() -> bool:
	return is_game_active


## 获取游戏统计
func get_stats() -> Dictionary:
	return game_state.duplicate()
