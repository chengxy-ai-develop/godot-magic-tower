extends Node
class_name SaveSystemClass

## 存档系统 - 处理游戏存档和读档
## 单例模式，通过 SaveSystem 全局访问

signal save_loaded(slot: int)
signal save_created(slot: int)

const max_save_slots := 3
const save_directory := "user://saves/"


func _ready() -> void:
	_ensure_save_directory()
	print("[SaveSystem] 初始化完成 (存档槽位：", max_save_slots, ")")


## 确保存档目录存在
func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("saves"):
			dir.make_dir("saves")


## 检查存档是否存在
func has_save(slot: int) -> bool:
	if slot < 1 or slot > max_save_slots:
		return false
	
	var save_path = _get_save_path(slot)
	return FileAccess.file_exists(save_path)


## 保存游戏
func save_game(slot: int) -> bool:
	if slot < 1 or slot > max_save_slots:
		print("[SaveSystem] 无效的存档槽位：", slot)
		return false
	
	var save_path = _get_save_path(slot)
	var save_data = _collect_save_data()
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		print("[SaveSystem] 无法创建存档文件")
		return false
	
	file.store_var(save_data)
	file.close()
	
	print("[SaveSystem] 存档成功 (槽位：", slot, ")")
	save_created.emit(slot)
	return true


## 加载游戏
func load_game(slot: int) -> bool:
	if slot < 1 or slot > max_save_slots:
		print("[SaveSystem] 无效的存档槽位：", slot)
		return false
	
	var save_path = _get_save_path(slot)
	if not FileAccess.file_exists(save_path):
		print("[SaveSystem] 存档不存在 (槽位：", slot, ")")
		return false
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		print("[SaveSystem] 无法读取存档文件")
		return false
	
	var save_data = file.get_var()
	file.close()
	
	_apply_save_data(save_data)
	
	print("[SaveSystem] 读档成功 (槽位：", slot, ")")
	save_loaded.emit(slot)
	return true


## 删除存档
func delete_save(slot: int) -> bool:
	if slot < 1 or slot > max_save_slots:
		return false
	
	var save_path = _get_save_path(slot)
	if FileAccess.file_exists(save_path):
		var err = DirAccess.remove_absolute(save_path)
		if err != OK:
			print("[SaveSystem] 删除存档失败：", err)
			return false
		print("[SaveSystem] 存档已删除 (槽位：", slot, ")")
		return true
	
	return false


## 获取存档路径
func _get_save_path(slot: int) -> String:
	return save_directory + "save_" + str(slot) + ".dat"


## 收集存档数据
func _collect_save_data() -> Dictionary:
	var data = {
		"version": GameManager.game_version if GameManager else "1.0.0",
		"timestamp": Time.get_unix_time_from_system(),
		"floor": GameManager.get_current_floor() if GameManager else 1,
		"player": _get_player_data()
	}
	return data


## 获取玩家数据
func _get_player_data() -> Dictionary:
	# 从玩家节点收集数据
	return {
		"hp": 100,
		"max_hp": 100,
		"attack": 10,
		"defense": 10,
		"keys": {},
		"items": []
	}


## 应用存档数据
func _apply_save_data(data: Dictionary) -> void:
	if data.has("floor") and GameManager:
		GameManager.change_floor(data["floor"])
	
	if data.has("player"):
		_set_player_data(data["player"])


## 设置玩家数据
func _set_player_data(data: Dictionary) -> void:
	# 应用到玩家节点
	print("[SaveSystem] 应用玩家数据")
