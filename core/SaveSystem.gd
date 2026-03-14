extends Node
class_name SaveSystemClass

## 存档系统 - 处理游戏存档和读档

signal save_loaded(slot: int)
signal save_created(slot: int)

const max_save_slots := 3
const save_directory := "user://saves/"


func _ready() -> void:
	_ensure_save_directory()
	print("[SaveSystem] 初始化完成")


func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")


func has_save(slot: int) -> bool:
	if slot < 1 or slot > max_save_slots:
		return false
	return FileAccess.file_exists(_get_save_path(slot))


func save_game(slot: int) -> bool:
	if slot < 1 or slot > max_save_slots:
		return false
	var file = FileAccess.open(_get_save_path(slot), FileAccess.WRITE)
	if not file:
		return false
	file.store_var({"slot": slot, "time": Time.get_unix_time_from_system()})
	file.close()
	save_created.emit(slot)
	return true


func load_game(slot: int) -> bool:
	if slot < 1 or slot > max_save_slots:
		return false
	if not FileAccess.file_exists(_get_save_path(slot)):
		return false
	var file = FileAccess.open(_get_save_path(slot), FileAccess.READ)
	if not file:
		return false
	file.get_var()
	file.close()
	save_loaded.emit(slot)
	return true


func _get_save_path(slot: int) -> String:
	return save_directory + "save_" + str(slot) + ".dat"
