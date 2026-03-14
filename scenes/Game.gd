extends Node2D
class_name GameScene

## 游戏场景控制
## 处理游戏内逻辑和 UI 更新

@onready var floor_label: Label = %FloorLabel
@onready var hp_label: Label = %HPLabel
@onready var attack_label: Label = %AttackLabel
@onready var defense_label: Label = %DefenseLabel
@onready var pause_button: Button = %PauseButton


func _ready() -> void:
	print("[GameScene] Ready")
	
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)
	
	_update_ui()


func _process(_delta: float) -> void:
	_update_ui()


func _update_ui() -> void:
	if GameManager:
		if floor_label:
			floor_label.text = "Floor: " + str(GameManager.get_current_floor())


func _on_pause_pressed() -> void:
	print("[GameScene] Pause pressed")
	get_tree().paused = true
