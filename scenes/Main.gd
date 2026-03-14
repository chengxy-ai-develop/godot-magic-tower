extends Control
class_name MainMenu

## 主菜单场景
## 处理主菜单 UI 和按钮事件

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var version_label: Label = $VersionLabel


func _ready():
	# 连接按钮信号
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 更新版本显示
	if GameManager:
		version_label.text = "Version " + GameManager.game_version
	else:
		version_label.text = "Version 1.0.0"
	
	# 检查是否有存档
	_update_continue_button()
	
	print("[MainMenu] Ready")


func _update_continue_button():
	# 如果没有存档，禁用继续按钮
	if SaveSystem:
		var has_save = false
		for slot in range(1, SaveSystem.max_save_slots + 1):
			if SaveSystem.has_save(slot):
				has_save = true
				break
		continue_button.disabled = not has_save
	else:
		continue_button.disabled = true


## 开始新游戏
func _on_start_pressed():
	print("[MainMenu] Start new game pressed")
	if GameManager:
		GameManager.start_new_game()
		if SceneManager:
			SceneManager.change_to_game()


## 继续游戏
func _on_continue_pressed():
	print("[MainMenu] Continue game pressed")
	if SaveSystem:
		# 加载第一个可用的存档
		for slot in range(1, SaveSystem.max_save_slots + 1):
			if SaveSystem.has_save(slot):
				SaveSystem.load_game(slot)
				break
	if GameManager:
		GameManager.continue_game()
	if SceneManager:
		SceneManager.change_to_game()


## 打开设置
func _on_settings_pressed():
	print("[MainMenu] Settings pressed")
	if SceneManager:
		SceneManager.change_to_settings()


## 退出游戏
func _on_quit_pressed():
	print("[MainMenu] Quit pressed")
	get_tree().quit()


## 处理游戏结束事件
func _on_game_ended(victory: bool):
	print("[MainMenu] Game ended, victory: %s" % str(victory))
	_update_continue_button()


## 处理存档变化
func _on_save_changed():
	_update_continue_button()
