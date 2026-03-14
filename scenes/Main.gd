extends Control
class_name MainMenuUI

## 主菜单 UI 控制
## 处理主菜单按钮事件和界面显示

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	# 连接按钮信号
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# 更新版本显示
	_update_version()
	
	# 检查存档
	_update_continue_button()
	
	print("[MainMenu] Ready")


func _update_version() -> void:
	if version_label:
		if GameManager:
			version_label.text = "Version " + GameManager.game_version
		else:
			version_label.text = "Version 1.0.0"


func _update_continue_button() -> void:
	if continue_button and SaveSystem:
		var has_save: bool = false
		for slot in range(1, SaveSystem.max_save_slots + 1):
			if SaveSystem.has_save(slot):
				has_save = true
				break
		continue_button.disabled = not has_save
	elif continue_button:
		continue_button.disabled = true


## 开始新游戏
func _on_start_pressed() -> void:
	print("[MainMenu] Start new game pressed")
	if GameManager:
		GameManager.start_new_game()
		if SceneManager:
			SceneManager.change_to_game()


## 继续游戏
func _on_continue_pressed() -> void:
	print("[MainMenu] Continue game pressed")
	if SaveSystem:
		for slot in range(1, SaveSystem.max_save_slots + 1):
			if SaveSystem.has_save(slot):
				SaveSystem.load_game(slot)
				break
	if GameManager:
		GameManager.continue_game()
	if SceneManager:
		SceneManager.change_to_game()


## 打开设置
func _on_settings_pressed() -> void:
	print("[MainMenu] Settings pressed")
	if SceneManager:
		SceneManager.change_to_settings()


## 退出游戏
func _on_quit_pressed() -> void:
	print("[MainMenu] Quit pressed")
	get_tree().quit()
