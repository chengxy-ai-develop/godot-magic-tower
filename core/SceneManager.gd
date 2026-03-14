extends Node
class_name SceneManagerClass

## 场景管理器 - 处理场景切换

signal scene_changed(scene_name: String)

const SCENE_MAIN := "res://scenes/Main.tscn"
const SCENE_GAME := "res://scenes/Game.tscn"
const SCENE_SETTINGS := "res://scenes/Settings.tscn"


func _ready() -> void:
	print("[SceneManager] 初始化完成")


func change_to_main() -> void:
	_change_scene(SCENE_MAIN)


func change_to_game() -> void:
	_change_scene(SCENE_GAME)


func change_to_settings() -> void:
	_change_scene(SCENE_SETTINGS)


func _change_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		print("[SceneManager] 场景文件不存在：", scene_path)
		return
	get_tree().change_scene_to_file(scene_path)
