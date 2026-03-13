extends Node
class_name SaveSystem

## 存档系统 - 负责游戏存档的保存和加载
## 支持多槽位存档、JSON 序列化、自动存档

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)

const SAVE_DIR := "user://saves"
const MAX_SLOTS := 3

var save_data: Dictionary = {}

func _ready() -> void:
	_ensure_save_dir()
	print("[SaveSystem] 初始化完成，存档目录：%s" % SAVE_DIR)

func _ensure_save_dir() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(SAVE_DIR):
		dir.make_dir(SAVE_DIR)

func save_game(slot: int, game_data: Dictionary) -> bool:
	print("[SaveSystem] 保存游戏到槽位 %d" % slot)
	
	var file_path = _get_save_path(slot)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		print("[SaveSystem] 保存失败：无法创建文件")
		save_completed.emit(slot, false)
		return false
	
	# 添加元数据
	var full_data = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"slot": slot,
		"data": game_data
	}
	
	var json_string = JSON.stringify(full_data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("[SaveSystem] 保存成功：%s" % file_path)
	save_completed.emit(slot, true)
	return true

func load_game(slot: int) -> Dictionary:
	print("[SaveSystem] 从槽位 %d 加载游戏" % slot)
	
	var file_path = _get_save_path(slot)
	
	if not FileAccess.file_exists(file_path):
		print("[SaveSystem] 加载失败：存档不存在")
		load_completed.emit(slot, false)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("[SaveSystem] 加载失败：无法读取文件")
		load_completed.emit(slot, false)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("[SaveSystem] 加载失败：JSON 解析错误")
		load_completed.emit(slot, false)
		return {}
	
	var data = json.get_data()
	save_data = data.get("data", {})
	
	print("[SaveSystem] 加载成功")
	load_completed.emit(slot, true)
	return save_data

func delete_save(slot: int) -> bool:
	var file_path = _get_save_path(slot)
	
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		print("[SaveSystem] 删除存档：槽位 %d" % slot)
		return true
	
	return false

func has_save(slot: int) -> bool:
	var file_path = _get_save_path(slot)
	return FileAccess.file_exists(file_path)

func get_save_info(slot: int) -> Dictionary:
	var file_path = _get_save_path(slot)
	
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) == OK:
		var data = json.get_data()
		return {
			"exists": true,
			"version": data.get("version", "unknown"),
			"timestamp": data.get("timestamp", "unknown"),
			"slot": data.get("slot", slot),
			"floor": data.get("data", {}).get("current_floor", 1),
			"play_time": data.get("data", {}).get("play_time", 0)
		}
	
	return {}

func _get_save_path(slot: int) -> String:
	return SAVE_DIR + "/save_slot_%d.json" % slot

func get_all_save_info() -> Array:
	var info_list = []
	for slot in range(1, MAX_SLOTS + 1):
		info_list.append(get_save_info(slot))
	return info_list

func auto_save(game_data: Dictionary) -> bool:
	# 自动保存到槽位 0
	return save_game(0, game_data)
