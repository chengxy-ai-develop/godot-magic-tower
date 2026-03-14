extends Control
class_name SettingsUI

## 设置界面控制

@onready var back_button: Button = %BackButton


func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	print("[SettingsUI] Ready")


func _on_back_pressed() -> void:
	print("[SettingsUI] Back pressed")
	if SceneManager:
		SceneManager.change_to_main()
