extends Node
class_name MapLoader

## 地图加载系统 - 处理魔塔楼层加载和管理

# 信号
signal floor_loaded(floor_id: int)
signal floor_load_failed(floor_id: int, reason: String)
signal tile_changed(tile_x: int, tile_y: int, tile_id: int)

# 楼层数据
var current_floor_id: int = 1
var floor_data: Dictionary = {}
var tile_size: int = 32
var map_width: int = 15
var map_height: int = 15

# 图层
var floor_layer: TileMapLayer
var collision_layer: TileMapLayer
var object_layer: Node2D

# 缓存
var _floor_cache: Dictionary = {}

func _ready() -> void:
	print("[MapLoader] 地图加载系统初始化完成")
	_setup_layers()

func _setup_layers() -> void:
	"""
	设置地图图层
	"""
	# 这里需要引用实际场景中的节点
	# 暂时使用占位实现
	pass

func load_floor(floor_id: int) -> bool:
	"""
	加载指定楼层
	返回：是否成功
	"""
	print("[MapLoader] 加载第 ", floor_id, " 层")
	
	# 检查缓存
	if _floor_cache.has(floor_id):
		print("[MapLoader] 从缓存加载")
		return _apply_floor(_floor_cache[floor_id])
	
	# 加载数据
	var data = _load_floor_data(floor_id)
	if not data:
		floor_load_failed.emit(floor_id, "数据不存在")
		return false
	
	# 缓存
	_floor_cache[floor_id] = data
	
	return _apply_floor(data)

func _load_floor_data(floor_id: int) -> Dictionary:
	"""
	从配置文件加载楼层数据
	"""
	# 这里需要从 data/floors.json 读取
	# 暂时返回示例数据
	return _generate_sample_floor(floor_id)

func _generate_sample_floor(floor_id: int) -> Dictionary:
	"""
	生成示例楼层数据（临时）
	"""
	var data = {
		"floor_id": floor_id,
		"width": map_width,
		"height": map_height,
		"tiles": [],
		"enemies": [],
		"items": [],
		"doors": [],
		"stairs": {"up": null, "down": null}
	}
	
	# 生成简单地图
	for x in range(map_width):
		for y in range(map_height):
			var tile_id = 0  # 0=空地，1=墙壁，2=地板
			
			# 边界是墙
			if x == 0 or x == map_width - 1 or y == 0 or y == map_height - 1:
				tile_id = 1
			else:
				tile_id = 2
			
			data["tiles"].append({"x": x, "y": y, "id": tile_id})
	
	# 添加楼梯
	data["stairs"]["down"] = {"x": 7, "y": 13}
	if floor_id < 50:
		data["stairs"]["up"] = {"x": 7, "y": 1}
	
	return data

func _apply_floor(data: Dictionary) -> bool:
	"""
	应用楼层数据到场景
	"""
	current_floor_id = data["floor_id"]
	
	# 这里需要实际更新 TileMap
	# 暂时只发射信号
	floor_loaded.emit(current_floor_id)
	
	print("[MapLoader] 第 ", current_floor_id, " 层加载完成")
	return true

func get_tile_at(x: int, y: int) -> int:
	"""
	获取指定位置的 Tile ID
	"""
	if not floor_data.has("tiles"):
		return 0
	
	for tile in floor_data["tiles"]:
		if tile["x"] == x and tile["y"] == y:
			return tile["id"]
	
	return 0

func set_tile_at(x: int, y: int, tile_id: int) -> void:
	"""
	设置指定位置的 Tile ID
	"""
	tile_changed.emit(x, y, tile_id)

func is_walkable(x: int, y: int) -> bool:
	"""
	检查位置是否可通行
	"""
	var tile_id = get_tile_at(x, y)
	return tile_id != 1  # 1=墙壁

func get_floor_data() -> Dictionary:
	"""
	获取当前楼层数据
	"""
	return floor_data.duplicate(true)

func get_player_start_position() -> Vector2i:
	"""
	获取玩家起始位置
	"""
	if floor_data.has("stairs") and floor_data["stairs"].has("down"):
		var pos = floor_data["stairs"]["down"]
		return Vector2i(pos["x"], pos["y"])
	return Vector2i(7, 7)

func unload_floor() -> void:
	"""
	卸载当前楼层
	"""
	current_floor_id = 0
	floor_data.clear()
	print("[MapLoader] 楼层已卸载")

func get_floor_info(floor_id: int) -> Dictionary:
	"""
	获取楼层信息
	"""
	return {
		"id": floor_id,
		"name": "第 %d 层" % floor_id,
		"difficulty": _calculate_difficulty(floor_id),
		"enemies_count": _count_enemies(floor_id)
	}

func _calculate_difficulty(floor_id: int) -> String:
	"""
	计算楼层难度
	"""
	if floor_id <= 10:
		return "简单"
	elif floor_id <= 20:
		return "普通"
	elif floor_id <= 30:
		return "困难"
	elif floor_id <= 40:
		return "非常困难"
	else:
		return "地狱"

func _count_enemies(floor_id: int) -> int:
	"""
	统计楼层敌人数量
	"""
	# 从数据中读取
	return randi_range(5, 15)
