extends Node
class_name DataManager

## 数据管理器
## 管理所有游戏数据 (敌人、道具、楼层等)

# ==================== 数据缓存 ====================
var enemy_database: Dictionary = {}
var item_database: Dictionary = {}
var floor_database: Dictionary = {}
var npc_database: Dictionary = {}
var skill_database: Dictionary = {}
var achievement_database: Dictionary = {}

# ==================== 数据路径 ====================
var data_directory: String = "res://data/"
var enemy_data_path: String = "res://data/enemies.json"
var item_data_path: String = "res://data/items.json"
var floor_data_path: String = "res://data/floors/"


func _ready():
	initialize()


## 初始化数据管理器
func initialize():
	print("[DataManager] Initializing...")
	load_all_data()
	print("[DataManager] Initialization complete")


## 加载所有数据
func load_all_data():
	load_enemy_data()
	load_item_data()
	load_floor_data()
	print("[DataManager] All data loaded")


## 加载敌人数据
func load_enemy_data():
	enemy_database.clear()
	
	# 从多个文件加载敌人数据
	var enemy_files = [
		"res://data/enemies_base.json",
		"res://data/enemies_mist.json",
		"res://data/enemies_ice.json",
		"res://data/enemies_fire.json",
		"res://data/enemies_void.json"
	]
	
	for file_path in enemy_files:
		if FileAccess.file_exists(file_path):
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var content = file.get_as_text()
				var json = JSON.new()
				var error = json.parse(content)
				if error == OK:
					var enemies = json.data
					if enemies is Array:
						for enemy in enemies:
							if enemy is Dictionary and enemy.has("id"):
								enemy_database[enemy.id] = enemy
					elif enemies is Dictionary:
						for key in enemies.keys():
							enemy_database[key] = enemies[key]
					print("[DataManager] Loaded enemies from: " + file_path)
				file.close()
	
	print("[DataManager] Total enemies loaded: %d" % enemy_database.size())


## 加载道具数据
func load_item_data():
	item_database.clear()
	
	var item_files = [
		"res://data/items_base.json",
		"res://data/items_mist.json",
		"res://data/items_ice.json",
		"res://data/items_fire.json",
		"res://data/items_void.json"
	]
	
	for file_path in item_files:
		if FileAccess.file_exists(file_path):
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var content = file.get_as_text()
				var json = JSON.new()
				var error = json.parse(content)
				if error == OK:
					var items = json.data
					if items is Array:
						for item in items:
							if item is Dictionary and item.has("id"):
								item_database[item.id] = item
					elif items is Dictionary:
						for key in items.keys():
							item_database[key] = items[key]
					print("[DataManager] Loaded items from: " + file_path)
				file.close()
	
	print("[DataManager] Total items loaded: %d" % item_database.size())


## 加载楼层数据
func load_floor_data():
	floor_database.clear()
	
	# 从 JSON 文件加载楼层数据
	var floor_files = [
		"res://data/floors_1-5_detailed.json",
		"res://data/floors_6-10_detailed.json",
		"res://data/floors_11-20_detailed.json",
		"res://data/floors_21-30_detailed.json",
		"res://data/floors_31-40_detailed.json",
		"res://data/floors_41-50_detailed.json"
	]
	
	for file_path in floor_files:
		if FileAccess.file_exists(file_path):
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var content = file.get_as_text()
				var json = JSON.new()
				var error = json.parse(content)
				if error == OK:
					var floors = json.data
					if floors is Array:
						for floor in floors:
							if floor is Dictionary and floor.has("id"):
								floor_database[floor.id] = floor
					elif floors is Dictionary:
						for key in floors.keys():
							floor_database[key] = floors[key]
					print("[DataManager] Loaded floors from: " + file_path)
				file.close()
	
	print("[DataManager] Total floors loaded: %d" % floor_database.size())


## 获取敌人数据
func get_enemy(enemy_id: String) -> Dictionary:
	if enemy_database.has(enemy_id):
		return enemy_database[enemy_id]
	push_warning("[DataManager] Enemy not found: " + enemy_id)
	return {}


## 获取道具数据
func get_item(item_id: String) -> Dictionary:
	if item_database.has(item_id):
		return item_database[item_id]
	push_warning("[DataManager] Item not found: " + item_id)
	return {}


## 获取楼层数据
func get_floor(floor_id: int) -> Dictionary:
	if floor_database.has(floor_id):
		return floor_database[floor_id]
	push_warning("[DataManager] Floor not found: " + str(floor_id))
	return {}


## 获取所有敌人
func get_all_enemies() -> Array:
	return enemy_database.values()


## 获取所有道具
func get_all_items() -> Array:
	return item_database.values()


## 获取所有楼层
func get_all_floors() -> Array:
	return floor_database.values()


## 验证敌人数据
func validate_enemy(enemy: Dictionary) -> bool:
	if not enemy.has("id"):
		push_error("[DataManager] Enemy missing 'id'")
		return false
	if not enemy.has("name"):
		push_error("[DataManager] Enemy missing 'name'")
		return false
	if not enemy.has("stats"):
		push_error("[DataManager] Enemy missing 'stats'")
		return false
	return true


## 验证道具数据
func validate_item(item: Dictionary) -> bool:
	if not item.has("id"):
		push_error("[DataManager] Item missing 'id'")
		return false
	if not item.has("type"):
		push_error("[DataManager] Item missing 'type'")
		return false
	return true


## 验证楼层数据
func validate_floor(floor: Dictionary) -> bool:
	if not floor.has("id"):
		push_error("[DataManager] Floor missing 'id'")
		return false
	if not floor.has("size"):
		push_error("[DataManager] Floor missing 'size'")
		return false
	return true


## 添加敌人数据 (运行时)
func add_enemy(enemy: Dictionary) -> bool:
	if not validate_enemy(enemy):
		return false
	enemy_database[enemy.id] = enemy
	print("[DataManager] Added enemy: " + enemy.id)
	return true


## 添加道具数据 (运行时)
func add_item(item: Dictionary) -> bool:
	if not validate_item(item):
		return false
	item_database[item.id] = item
	print("[DataManager] Added item: " + item.id)
	return true


## 添加楼层数据 (运行时)
func add_floor(floor: Dictionary) -> bool:
	if not validate_floor(floor):
		return false
	floor_database[floor.id] = floor
	print("[DataManager] Added floor: " + str(floor.id))
	return true


## 导出数据到文件
func export_data(data_type: String, output_path: String) -> bool:
	var data = null
	match data_type:
		"enemies":
			data = enemy_database.values()
		"items":
			data = item_database.values()
		"floors":
			data = floor_database.values()
		_:
			push_error("[DataManager] Unknown data type: " + data_type)
			return false
	
	var json = JSON.new()
	var content = json.stringify(data, "  ")
	
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		print("[DataManager] Exported %s to %s" % [data_type, output_path])
		return true
	else:
		push_error("[DataManager] Failed to export: " + output_path)
		return false


## 获取数据统计
func get_statistics() -> Dictionary:
	return {
		"enemies": enemy_database.size(),
		"items": item_database.size(),
		"floors": floor_database.size(),
		"total": enemy_database.size() + item_database.size() + floor_database.size()
	}
