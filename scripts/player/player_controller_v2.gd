extends CharacterBody2D
class_name PlayerController

## 玩家控制器 v2

signal player_damaged(damage: int)
signal player_healed(amount: int)
signal player_died
signal item_picked_up(item_id: String)
signal floor_changed(floor_id: int)

@export var max_hp: int = 1000
@export var attack: int = 10
@export var defense: int = 10
@export var gold: int = 0

var current_hp: int = 1000
var current_floor: int = 1
var position_grid: Vector2i = Vector2i(7, 7)
var keys: Dictionary = {"yellow": 0, "blue": 0, "red": 0}
var inventory: Array = []

@export var move_speed: float = 200.0
@export var tile_size: int = 32
var is_moving: bool = false
var is_in_battle: bool = false

func _ready() -> void:
	print("[Player] 初始化完成")
	current_hp = max_hp

func _physics_process(delta: float) -> void:
	if is_moving or is_in_battle:
		return
	_handle_input()

func _handle_input() -> void:
	var direction = Vector2.ZERO
	if Input.is_action_just_pressed("ui_up"):
		direction = Vector2.UP
	elif Input.is_action_just_pressed("ui_down"):
		direction = Vector2.DOWN
	elif Input.is_action_just_pressed("ui_left"):
		direction = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_right"):
		direction = Vector2.RIGHT
	
	if direction != Vector2.ZERO:
		_try_move(direction)

func _try_move(direction: Vector2) -> void:
	var new_pos = position_grid + Vector2i(direction)
	if not _is_walkable(new_pos):
		return
	_execute_move(direction, new_pos)

func _execute_move(direction: Vector2, new_pos: Vector2i) -> void:
	is_moving = true
	position_grid = new_pos
	var target_pos = Vector2(new_pos.x * tile_size, new_pos.y * tile_size)
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.15)
	tween.tween_callback(func(): is_moving = false)

func _is_walkable(pos: Vector2i) -> bool:
	return true

func take_damage(damage: int) -> void:
	var actual_damage = max(0, damage - defense)
	current_hp -= actual_damage
	player_damaged.emit(actual_damage)
	if current_hp <= 0:
		_die()

func _die() -> void:
	player_died.emit()

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	player_healed.emit(amount)

func gain_gold(amount: int) -> void:
	gold += amount

func gain_experience(amount: int) -> void:
	print("[Player] 获得 ", amount, " 经验")

func get_stats() -> Dictionary:
	return {
		"hp": current_hp,
		"max_hp": max_hp,
		"attack": attack,
		"defense": defense,
		"gold": gold,
		"floor": current_floor,
		"position": position_grid,
		"keys": keys.duplicate()
	}
