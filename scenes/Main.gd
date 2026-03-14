extends Control
class_name MainMenuUI

## 主菜单 UI 控制

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	_update_version()
	_update_continue_button()
	print("[MainMenu] Ready")


func _update_version() -> void:
	if version_label:
		version_label.text = "Version 1.0.0"


func _update_continue_button() -> void:
	if continue_button:
		continue_button.disabled = true


func _on_start_pressed() -> void:
	print("[MainMenu] Start new game")
	if SceneManager:
		SceneManager.change_to_game()


func _on_continue_pressed() -> void:
	print("[MainMenu] Continue game")


func _on_settings_pressed() -> void:
	print("[MainMenu] Settings")
	if SceneManager:
		SceneManager.change_to_settings()


func _on_quit_pressed() -> void:
	print("[MainMenu] Quit")
	get_tree().quit()
