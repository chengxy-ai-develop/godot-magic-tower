extends Node
class_name GameManagerClass

## 游戏管理器 - 核心游戏逻辑和状态管理

signal game_started
signal game_won
signal game_lost
signal floor_changed(floor_id: int)
signal player_died

const game_version := "1.0.0"
const max_floor := 50

var current_floor: int = 1
var is_game_active: bool = false


func _ready() -> void:
	print("[GameManager] 初始化完成 (版本：", game_version, ")")


func start_new_game() -> void:
	print("[GameManager] 开始新游戏")
	current_floor = 1
	is_game_active = true
	game_started.emit()


func continue_game() -> void:
	print("[GameManager] 继续游戏")
	is_game_active = true


func change_floor(floor_id: int) -> void:
	if floor_id < 1 or floor_id > max_floor:
		return
	current_floor = floor_id
	floor_changed.emit(floor_id)


func player_death() -> void:
	print("[GameManager] 玩家死亡")
	is_game_active = false
	game_lost.emit()


func win_game() -> void:
	print("[GameManager] 游戏胜利!")
	is_game_active = false
	game_won.emit()


func get_current_floor() -> int:
	return current_floor


func is_active() -> bool:
	return is_game_active
