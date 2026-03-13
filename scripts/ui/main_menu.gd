extends Control
class_name MainMenu

## 主菜单界面

signal new_game_pressed
signal load_game_pressed(slot: int)
signal settings_pressed
signal quit_pressed

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var new_game_btn: Button = $VBoxContainer/NewGameBtn
@onready var load_game_btn: Button = $VBoxContainer/LoadGameBtn
@onready var settings_btn: Button = $VBoxContainer/SettingsBtn
@onready var quit_btn: Button = $VBoxContainer/QuitBtn

func _ready() -> void:
	new_game_btn.pressed.connect(_on_new_game_pressed)
	load_game_btn.pressed.connect(_on_load_game_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	print("[MainMenu] 初始化完成")

func _on_new_game_pressed() -> void:
	print("[MainMenu] 新游戏")
	new_game_pressed.emit()

func _on_load_game_pressed() -> void:
	print("[MainMenu] 加载游戏")
	# 简化处理，直接加载槽位 1
	load_game_pressed.emit(1)

func _on_settings_pressed() -> void:
	print("[MainMenu] 设置")
	settings_pressed.emit()

func _on_quit_pressed() -> void:
	print("[MainMenu] 退出")
	quit_pressed.emit()
	get_tree().quit()
