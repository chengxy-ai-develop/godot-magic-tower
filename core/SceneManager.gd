extends Node
class_name SceneManagerClass

## 场景管理器 - 处理场景切换
## 单例模式，通过 SceneManager 全局访问

signal scene_changed(scene_name: String)

const SCENE_MAIN := "res://scenes/Main.tscn"
const SCENE_GAME := "res://scenes/Game.tscn"
const SCENE_SETTINGS := "res://scenes/Settings.tscn"

var current_scene: String = ""


func _ready() -> void:
	print("[SceneManager] 初始化完成")


## 切换到主菜单
func change_to_main() -> void:
	_change_scene(SCENE_MAIN)
	print("[SceneManager] 切换到主菜单")


## 切换到游戏场景
func change_to_game() -> void:
	_change_scene(SCENE_GAME)
	print("[SceneManager] 切换到游戏场景")


## 切换到设置场景
func change_to_settings() -> void:
	_change_scene(SCENE_SETTINGS)
	print("[SceneManager] 切换到设置")


## 内部场景切换实现
func _change_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		print("[SceneManager] 场景文件不存在：", scene_path)
		return
	
	var err = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		print("[SceneManager] 场景切换失败：", err)
		return
	
	current_scene = scene_path
	scene_changed.emit(scene_path)


## 获取当前场景
func get_current_scene() -> String:
	return current_scene
