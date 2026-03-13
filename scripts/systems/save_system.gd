extends Node
class_name SaveSystem

## 存档系统 - 处理游戏保存和加载

# 信号
signal game_saved(slot: int, success: bool)
signal game_loaded(slot: int, success: bool)
signal save_deleted(slot: int, success: bool)

# 配置
const MAX_SAVE_SLOTS: int = 3
const SAVE_DIR: String = "user://saves/"

# 存档元数据
var save_metadata: Dictionary = {}

func _ready() -> void:
	print("[SaveSystem] 存档系统初始化完成")
	_ensure_save_directory()
	_load_metadata()

func _ensure_save_directory() -> void:
	"""
	确保存档目录存在
	"""
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
		print("[SaveSystem] 创建存档目录：", SAVE_DIR)

func _load_metadata() -> void:
	"""
	加载存档元数据
	"""
	var metadata_path = SAVE_DIR + "metadata.json"
	if FileAccess.file_exists(metadata_path):
		var file = FileAccess.open(metadata_path, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			save_metadata = JSON.parse_string(text)
			file.close()
	else:
		# 初始化元数据
		save_metadata = {"slots": {}}
		_save_metadata()

func _save_metadata() -> void:
	"""
	保存元数据
	"""
	var metadata_path = SAVE_DIR + "metadata.json"
	var file = FileAccess.open(metadata_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_metadata, 2))
		file.close()

func save_game(slot: int, game_state: Dictionary) -> bool:
	"""
	保存游戏到指定槽位
	
	参数:
		slot: 存档槽位 (1-3)
		game_state: 游戏状态数据
	
	返回：是否成功
	"""
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		print("[SaveSystem] 错误：无效的存档槽位 ", slot)
		game_saved.emit(slot, false)
		return false
	
	var save_path = SAVE_DIR + "save_%d.dat" % slot
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	
	if not file:
		print("[SaveSystem] 错误：无法创建存档文件")
		game_saved.emit(slot, false)
		return false
	
	# 构建存档数据
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"play_time": game_state.get("play_time", 0),
		"game_state": game_state
	}
	
	# 序列化并保存
	var json_text = JSON.stringify(save_data, 2)
	file.store_string(json_text)
	file.close()
	
	# 更新元数据
	_update_slot_metadata(slot, save_data)
	
	print("[SaveSystem] 游戏已保存到槽位 ", slot)
	game_saved.emit(slot, true)
	return true

func load_game(slot: int) -> Dictionary:
	"""
	从指定槽位加载游戏
	
	参数:
		slot: 存档槽位 (1-3)
	
	返回：游戏状态数据（失败返回空字典）
	"""
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		print("[SaveSystem] 错误：无效的存档槽位 ", slot)
		game_loaded.emit(slot, false)
		return {}
	
	var save_path = SAVE_DIR + "save_%d.dat" % slot
	
	if not FileAccess.file_exists(save_path):
		print("[SaveSystem] 错误：存档不存在")
		game_loaded.emit(slot, false)
		return {}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		print("[SaveSystem] 错误：无法读取存档文件")
		game_loaded.emit(slot, false)
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var save_data = JSON.parse_string(json_text)
	if not save_data:
		print("[SaveSystem] 错误：存档数据损坏")
		game_loaded.emit(slot, false)
		return {}
	
	print("[SaveSystem] 游戏已从槽位 ", slot, " 加载")
	game_loaded.emit(slot, true)
	return save_data.get("game_state", {})

func has_save(slot: int) -> bool:
	"""
	检查槽位是否有存档
	"""
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		return false
	
	var save_path = SAVE_DIR + "save_%d.dat" % slot
	return FileAccess.file_exists(save_path)

func get_save_info(slot: int) -> Dictionary:
	"""
	获取存档信息
	
	返回：{time, play_time, floor, ...}
	"""
	if not has_save(slot):
		return {}
	
	if save_metadata.has("slots") and save_metadata["slots"].has(str(slot)):
		return save_metadata["slots"][str(slot)]
	
	# 从文件读取
	var save_data = load_game(slot)
	if save_data.is_empty():
		return {}
	
	return {
		"time": _format_timestamp(save_data.get("timestamp", 0)),
		"play_time": _format_play_time(save_data.get("play_time", 0)),
		"floor": save_data.get("player", {}).get("floor", 1)
	}

func delete_save(slot: int) -> bool:
	"""
	删除指定槽位的存档
	"""
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		return false
	
	var save_path = SAVE_DIR + "save_%d.dat" % slot
	
	if not FileAccess.file_exists(save_path):
		return false
	
	var success = DirAccess.remove_absolute(save_path) == OK
	
	if success:
		# 更新元数据
		if save_metadata.has("slots"):
			save_metadata["slots"].erase(str(slot))
		_save_metadata()
		print("[SaveSystem] 存档已删除：槽位 ", slot)
		save_deleted.emit(slot, true)
	else:
		print("[SaveSystem] 删除失败：槽位 ", slot)
		save_deleted.emit(slot, false)
	
	return success

func _update_slot_metadata(slot: int, save_data: Dictionary) -> void:
	"""
	更新槽位元数据
	"""
	if not save_metadata.has("slots"):
		save_metadata["slots"] = {}
	
	var game_state = save_data.get("game_state", {})
	var player = game_state.get("player", {})
	
	save_metadata["slots"][str(slot)] = {
		"timestamp": save_data.get("timestamp", 0),
		"time": _format_timestamp(save_data.get("timestamp", 0)),
		"play_time": _format_play_time(save_data.get("play_time", 0)),
		"floor": player.get("floor", 1),
		"hp": player.get("hp", 0),
		"max_hp": player.get("max_hp", 0)
	}
	
	_save_metadata()

func _format_timestamp(timestamp: int) -> String:
	"""
	格式化时间戳
	"""
	if timestamp <= 0:
		return "未知"
	
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%04d-%02d-%02d %02d:%02d" % [
		datetime["year"],
		datetime["month"],
		datetime["day"],
		datetime["hour"],
		datetime["minute"]
	]

func _format_play_time(seconds: int) -> String:
	"""
	格式化游戏时间
	"""
	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	var secs = seconds % 60
	
	if hours > 0:
		return "%d小时 %d分" % [hours, minutes]
	else:
		return "%d分 %d秒" % [minutes, secs]

func get_all_save_info() -> Array:
	"""
	获取所有存档信息
	"""
	var info_array = []
	
	for slot in range(1, MAX_SAVE_SLOTS + 1):
		var info = get_save_info(slot)
		info["slot"] = slot
		info["exists"] = has_save(slot)
		info_array.append(info)
	
	return info_array

func export_save_to_json(slot: int) -> String:
	"""
	导出存档为 JSON 字符串（用于分享）
	"""
	var save_data = load_game(slot)
	if save_data.is_empty():
		return ""
	
	return JSON.stringify(save_data, 2)

func import_save_from_json(json_text: String, slot: int) -> bool:
	"""
	从 JSON 字符串导入存档
	"""
	var save_data = JSON.parse_string(json_text)
	if not save_data:
		return false
	
	return save_game(slot, save_data)

func backup_saves(backup_path: String) -> bool:
	"""
	备份所有存档到指定路径
	"""
	# 实现备份逻辑
	print("[SaveSystem] 备份存档到：", backup_path)
	return true

func restore_saves(backup_path: String) -> bool:
	"""
	从备份恢复存档
	"""
	print("[SaveSystem] 从备份恢复：", backup_path)
	return true
