extends CharacterBody2D
class_name PlayerController

## 玩家控制器 - 处理玩家移动和输入
## 附加到 Player.tscn

@export var speed: float = 200.0
@export var hp: int = 100
@export var max_hp: int = 100
@export var attack: int = 10
@export var defense: int = 10

var keys: Dictionary = {}
var items: Array = []


func _ready() -> void:
	print("[Player] 初始化完成")
	print("[Player] HP: ", hp, "/", max_hp)
	print("[Player] ATK: ", attack, " DEF: ", defense)


func _physics_process(_delta: float) -> void:
	_handle_input()
	move_and_slide()


func _handle_input() -> void:
	var input_direction := Vector2.ZERO
	
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_direction.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_direction.x += 1
	
	velocity = input_direction.normalized() * speed


## 受到伤害
func take_damage(amount: int) -> int:
	var actual_damage = max(1, amount - defense)
	hp = max(0, hp - actual_damage)
	print("[Player] 受到伤害：", actual_damage, " 剩余 HP: ", hp)
	
	if hp <= 0:
		_on_death()
	
	return actual_damage


## 治疗
func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	print("[Player] 治疗：", amount, " 当前 HP: ", hp)


## 死亡处理
func _on_death() -> void:
	print("[Player] 死亡!")
	if GameManager:
		GameManager.player_death()


## 添加钥匙
func add_key(key_type: String, count: int = 1) -> void:
	if not keys.has(key_type):
		keys[key_type] = 0
	keys[key_type] += count
	print("[Player] 获得钥匙：", key_type, " x", count)


## 使用钥匙
func use_key(key_type: String) -> bool:
	if keys.has(key_type) and keys[key_type] > 0:
		keys[key_type] -= 1
		print("[Player] 使用钥匙：", key_type)
		return true
	return false


## 添加物品
func add_item(item_id: String) -> void:
	if not items.has(item_id):
		items.append(item_id)
	print("[Player] 获得物品：", item_id)


## 检查是否有物品
func has_item(item_id: String) -> bool:
	return items.has(item_id)


## 获取玩家数据 (用于存档)
func get_data() -> Dictionary:
	return {
		"hp": hp,
		"max_hp": max_hp,
		"attack": attack,
		"defense": defense,
		"keys": keys.duplicate(),
		"items": items.duplicate()
	}


## 设置玩家数据 (用于读档)
func set_data(data: Dictionary) -> void:
	if data.has("hp"):
		hp = data["hp"]
	if data.has("max_hp"):
		max_hp = data["max_hp"]
	if data.has("attack"):
		attack = data["attack"]
	if data.has("defense"):
		defense = data["defense"]
	if data.has("keys"):
		keys = data["keys"].duplicate()
	if data.has("items"):
		items = data["items"].duplicate()
	
	print("[Player] 数据已加载")
