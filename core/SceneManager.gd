extends Node
class_name SceneManager

## 场景管理器
## 管理场景切换和加载

# ==================== 场景路径 ====================
var scene_paths: Dictionary = {
	"main_menu": "res://scenes/Main.tscn",
	"game": "res://scenes/Game.tscn",
	"battle": "res://scenes/Battle.tscn",
	"game_over": "res://scenes/GameOver.tscn",
	"victory": "res://scenes/Victory.tscn",
	"editor": "res://scenes/Editor.tscn",
	"settings": "res://scenes/Settings.tscn",
	"load_game": "res://scenes/LoadGame.tscn"
}

# ==================== 当前场景 ====================
var current_scene: String = ""
var previous_scene: String = ""
var is_loading: bool = false

# ==================== 加载回调 ====================
signal scene_load_started(scene_name: String)
signal scene_load_completed(scene_name: String)
signal scene_load_failed(scene_name: String, error: String)


func _ready():
	# 获取当前场景
	var root = get_tree().root
	current_scene = root.get_current_scene().scene_file_path
	print("[SceneManager] Initial scene: " + current_scene)


## 切换到场景
func change_scene(scene_name: String, fade_duration: float = 0.5):
	if is_loading:
		push_warning("[SceneManager] Already loading a scene")
		return
	
	previous_scene = current_scene
	current_scene = scene_name
	
	var scene_path = get_scene_path(scene_name)
	if scene_path.is_empty():
		emit_signal("scene_load_failed", scene_name, "Scene path not found")
		push_error("[SceneManager] Scene not found: " + scene_name)
		return
	
	print("[SceneManager] Changing to scene: " + scene_name)
	emit_signal("scene_load_started", scene_name)
	is_loading = true
	
	# 使用 Godot 的场景切换
	var error = get_tree().change_scene_to_file(scene_path)
	
	is_loading = false
	if error == OK:
		emit_signal("scene_load_completed", scene_name)
		EventBus.emit_signal("scene_changed", scene_name)
		print("[SceneManager] Scene changed successfully")
	else:
		emit_signal("scene_load_failed", scene_name, "Error: " + str(error))
		push_error("[SceneManager] Failed to change scene: " + str(error))


## 切换到主菜单
func change_to_main_menu():
	change_scene("main_menu")


## 切换到游戏场景
func change_to_game():
	change_scene("game")


## 切换到战斗场景
func change_to_battle():
	change_scene("battle")


## 切换到编辑器
func change_to_editor():
	change_scene("editor")
	EventBus.emit_signal("editor_opened")


## 切换到设置
func change_to_settings():
	change_scene("settings")


## 获取场景路径
func get_scene_path(scene_name: String) -> String:
	if scene_paths.has(scene_name):
		return scene_paths[scene_name]
	
	# 尝试直接路径
	if FileAccess.file_exists(scene_name):
		return scene_name
	
	return ""


## 注册场景路径
func register_scene(scene_name: String, scene_path: String):
	scene_paths[scene_name] = scene_path
	print("[SceneManager] Registered scene: " + scene_name + " -> " + scene_path)


## 预加载场景
func preload_scene(scene_name: String):
	var scene_path = get_scene_path(scene_name)
	if scene_path.is_empty():
		push_error("[SceneManager] Cannot preload, scene not found: " + scene_name)
		return
	
	# 使用 ResourceLoader 预加载
	ResourceLoader.load(scene_path)
	print("[SceneManager] Preloaded scene: " + scene_name)


## 预加载所有场景
func preload_all_scenes():
	for scene_name in scene_paths.keys():
		preload_scene(scene_name)
	print("[SceneManager] All scenes preloaded")


## 获取当前场景名称
func get_current_scene_name() -> String:
	return current_scene


## 获取前一个场景名称
func get_previous_scene_name() -> String:
	return previous_scene


## 检查场景是否存在
func scene_exists(scene_name: String) -> bool:
	var scene_path = get_scene_path(scene_name)
	if scene_path.is_empty():
		return false
	return FileAccess.file_exists(scene_path)


## 获取所有已注册场景
func get_all_scenes() -> Array:
	return scene_paths.keys()


## 获取场景统计
func get_statistics() -> Dictionary:
	var stats = {
		"total_scenes": scene_paths.size(),
		"current_scene": current_scene,
		"previous_scene": previous_scene,
		"is_loading": is_loading
	}
	
	# 检查每个场景是否存在
	var existing = 0
	var missing = 0
	for scene_name in scene_paths.keys():
		if scene_exists(scene_name):
			existing += 1
		else:
			missing += 1
	
	stats["existing_scenes"] = existing
	stats["missing_scenes"] = missing
	
	return stats
