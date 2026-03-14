extends Node
class_name SaveSystem

## 存档系统
## 管理游戏存档的保存和加载

# ==================== 信号 ====================
signal save_started(slot: int)
signal save_completed(slot: int)
signal save_failed(slot: int, error: String)
signal load_started(slot: int)
signal load_completed(slot: int)
signal load_failed(slot: int, error: String)
signal save_deleted(slot: int)

# ==================== 存档配置 ====================
var save_directory: String = "user://saves/"
var max_save_slots: int = 3
var auto_save_enabled: bool = true
var auto_save_interval: float = 300.0  # 5 分钟

# ==================== 存档元数据 ====================
var save_metadata: Dictionary = {}

# ==================== 自动保存计时器 ====================
var auto_save_timer: Timer = null


func _ready():
	_initialize_save_directory()
	_load_metadata()
	_setup_auto_save()


## 初始化存档目录
func _initialize_save_directory():
	var dir = DirAccess.open(save_directory)
	if dir == null:
		DirAccess.make_dir_recursive_absolute(save_directory)
		print("[SaveSystem] Created save directory: " + save_directory)


## 加载存档元数据
func _load_metadata():
	var metadata_path = save_directory + "metadata.json"
	if FileAccess.file_exists(metadata_path):
		var file = FileAccess.open(metadata_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			var json = JSON.new()
			var error = json.parse(content)
			if error == OK:
				save_metadata = json.data
				print("[SaveSystem] Metadata loaded")
			file.close()


## 保存存档元数据
func _save_metadata():
	var metadata_path = save_directory + "metadata.json"
	var json = JSON.new()
	var content = json.stringify(save_metadata, "  ")
	
	var file = FileAccess.open(metadata_path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()


## 设置自动保存
func _setup_auto_save():
	if auto_save_enabled:
		auto_save_timer = Timer.new()
		auto_save_timer.wait_time = auto_save_interval
		auto_save_timer.timeout.connect(_on_auto_save_timeout)
		add_child(auto_save_timer)
		auto_save_timer.start()
		print("[SaveSystem] Auto-save enabled, interval: %d seconds" % int(auto_save_interval))


## 保存游戏
func save_game(slot: int, extra_data: Dictionary = {}) -> bool:
	print("[SaveSystem] Saving game to slot %d..." % slot)
	emit_signal("save_started", slot)
	
	if slot < 1 or slot > max_save_slots:
		emit_signal("save_failed", slot, "Invalid slot number")
		push_error("[SaveSystem] Invalid slot number: %d" % slot)
		return false
	
	# 收集存档数据
	var save_data = _collect_save_data(extra_data)
	
	# 验证存档数据
	if not _validate_save_data(save_data):
		emit_signal("save_failed", slot, "Invalid save data")
		return false
	
	# 保存到文件
	var file_path = _get_save_file_path(slot)
	var success = _write_save_file(file_path, save_data)
	
	if success:
		# 更新元数据
		_update_metadata(slot, save_data)
		emit_signal("save_completed", slot)
		EventBus.emit_signal("game_saved", slot)
		print("[SaveSystem] Game saved to slot %d" % slot)
	else:
		emit_signal("save_failed", slot, "Failed to write file")
	
	return success


## 加载游戏
func load_game(slot: int) -> bool:
	print("[SaveSystem] Loading game from slot %d..." % slot)
	emit_signal("load_started", slot)
	
	if slot < 1 or slot > max_save_slots:
		emit_signal("load_failed", slot, "Invalid slot number")
		push_error("[SaveSystem] Invalid slot number: %d" % slot)
		return false
	
	# 检查存档文件是否存在
	var file_path = _get_save_file_path(slot)
	if not FileAccess.file_exists(file_path):
		emit_signal("load_failed", slot, "Save file not found")
		push_error("[SaveSystem] Save file not found: %s" % file_path)
		return false
	
	# 读取存档文件
	var save_data = _read_save_file(file_path)
	if save_data.is_empty():
		emit_signal("load_failed", slot, "Failed to read save file")
		return false
	
	# 加载存档数据
	var success = _apply_save_data(save_data)
	
	if success:
		emit_signal("load_completed", slot)
		EventBus.emit_signal("game_loaded", slot)
		print("[SaveSystem] Game loaded from slot %d" % slot)
	else:
		emit_signal("load_failed", slot, "Failed to apply save data")
	
	return success


## 删除存档
func delete_save(slot: int) -> bool:
	print("[SaveSystem] Deleting save from slot %d..." % slot)
	
	if slot < 1 or slot > max_save_slots:
		push_error("[SaveSystem] Invalid slot number: %d" % slot)
		return false
	
	var file_path = _get_save_file_path(slot)
	if FileAccess.file_exists(file_path):
		var error = DirAccess.remove_absolute(file_path)
		if error == OK:
			# 从元数据中删除
			save_metadata.erase(str(slot))
			_save_metadata()
			
			emit_signal("save_deleted", slot)
			print("[SaveSystem] Save deleted from slot %d" % slot)
			return true
		else:
			push_error("[SaveSystem] Failed to delete save file: %s" % str(error))
			return false
	else:
		print("[SaveSystem] Save file not found: %s" % file_path)
		return false


## 检查存档是否存在
func has_save(slot: int) -> bool:
	if slot < 1 or slot > max_save_slots:
		return false
	
	var file_path = _get_save_file_path(slot)
	return FileAccess.file_exists(file_path)


## 获取存档列表
func get_save_list() -> Array:
	var saves = []
	
	for slot in range(1, max_save_slots + 1):
		var save_info = {
			"slot": slot,
			"exists": has_save(slot),
			"metadata": save_metadata.get(str(slot), {})
		}
		saves.append(save_info)
	
	return saves


## 获取存档元数据
func get_save_metadata(slot: int) -> Dictionary:
	return save_metadata.get(str(slot), {})


## 收集存档数据
func _collect_save_data(extra_data: Dictionary) -> Dictionary:
	var save_data = {
		"version": FrameworkConfig.FRAMEWORK_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"play_time": GameManager.total_play_time if GameManager else 0.0,
		"player": GameManager.get_player_data() if GameManager else {},
		"game_state": {
			"current_floor": GameManager.player_current_floor if GameManager else 1,
			"unlocked_floors": GameManager.unlocked_floors if GameManager else 1
		},
		"extra": extra_data
	}
	
	return save_data


## 验证存档数据
func _validate_save_data(save_data: Dictionary) -> bool:
	if not save_data.has("version"):
		push_error("[SaveSystem] Save data missing version")
		return false
	if not save_data.has("player"):
		push_error("[SaveSystem] Save data missing player data")
		return false
	return true


## 写入存档文件
func _write_save_file(file_path: String, save_data: Dictionary) -> bool:
	var json = JSON.new()
	var content = json.stringify(save_data, "  ")
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		return true
	else:
		push_error("[SaveSystem] Failed to open file for writing: %s" % file_path)
		return false


## 读取存档文件
func _read_save_file(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			return json.data
		else:
			push_error("[SaveSystem] Failed to parse save file: %s" % str(error))
			return {}
	else:
		push_error("[SaveSystem] Failed to open file for reading: %s" % file_path)
		return {}


## 应用存档数据
func _apply_save_data(save_data: Dictionary) -> bool:
	# 加载玩家数据
	if save_data.has("player"):
		GameManager.load_player_data(save_data["player"])
	
	# 加载游戏状态
	if save_data.has("game_state"):
		var game_state = save_data["game_state"]
		GameManager.player_current_floor = game_state.get("current_floor", 1)
		GameManager.unlocked_floors = game_state.get("unlocked_floors", 1)
	
	# 加载游戏时间
	if save_data.has("play_time"):
		GameManager.total_play_time = save_data["play_time"]
	
	# 加载楼层
	GameManager.load_floor(GameManager.player_current_floor)
	
	return true


## 更新元数据
func _update_metadata(slot: int, save_data: Dictionary):
	var metadata = {
		"slot": slot,
		"timestamp": save_data.get("timestamp", 0),
		"play_time": save_data.get("play_time", 0.0),
		"player_level": save_data.get("player", {}).get("level", 1),
		"current_floor": save_data.get("game_state", {}).get("current_floor", 1),
		"version": save_data.get("version", "unknown")
	}
	
	save_metadata[str(slot)] = metadata
	_save_metadata()


## 获取存档文件路径
func _get_save_file_path(slot: int) -> String:
	return save_directory + "save_%d.json" % slot


## 自动保存回调
func _on_auto_save_timeout():
	if GameManager.current_state == GameManager.GameState.PLAYING:
		print("[SaveSystem] Auto-saving...")
		save_game(1)  # 自动保存到槽位 1


## 手动保存
func quick_save() -> bool:
	return save_game(1)


## 快速加载
func quick_load() -> bool:
	return load_game(1)


## 获取存档统计
func get_statistics() -> Dictionary:
	var total_saves = 0
	var total_play_time = 0.0
	
	for slot in range(1, max_save_slots + 1):
		if has_save(slot):
			total_saves += 1
			var metadata = get_save_metadata(slot)
			total_play_time += metadata.get("play_time", 0.0)
	
	return {
		"total_saves": total_saves,
		"total_play_time": total_play_time,
		"auto_save_enabled": auto_save_enabled,
		"auto_save_interval": auto_save_interval
	}
