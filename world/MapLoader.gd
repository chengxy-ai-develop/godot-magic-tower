extends Node
class_name MapLoader

## 地图加载器
## 负责加载和生成楼层地图

# ==================== 信号 ====================
signal floor_load_started(floor_id: int)
signal floor_load_completed(floor_id: int)
signal floor_load_failed(floor_id: int, error: String)
signal tile_placed(x: int, y: int, tile_type: String)
signal entity_spawned(entity_type: String, entity_id: String, x: int, y: int)

# ==================== 当前楼层 ====================
var current_floor_id: int = 0
var current_floor_data: Dictionary = {}
var floor_tilemap: TileMapLayer = null
var floor_collision: CollisionShape2D = null

# ==================== 地图配置 ====================
var default_tile_size: int = 32
var map_offset: Vector2 = Vector2.ZERO

# ==================== 地块类型 ====================
const TILE_FLOOR: String = "floor"
const TILE_WALL: String = "wall"
const TILE_DOOR: String = "door"
const TILE_STAIRS_UP: String = "stairs_up"
const TILE_STAIRS_DOWN: String = "stairs_down"
const TILE_SPIKES: String = "spikes"
const TILE_WATER: String = "water"
const TILE_LAVA: String = "lava"
const TILE_ICE: String = "ice"
const TILE Conveyor: String = "conveyor"

# ==================== 实体类型 ====================
const ENTITY_PLAYER: String = "player"
const ENTITY_ENEMY: String = "enemy"
const ENTITY_ITEM: String = "item"
const ENTITY_NPC: String = "npc"
const ENTITY_DOOR: String = "door"
const ENTITY_TELEPORTER: String = "teleporter"


func _ready():
	# 连接到事件总线
	if EventBus:
		EventBus.floor_entered.connect(_on_floor_entered)


## 加载楼层
func load_floor(floor_id: int):
	print("[MapLoader] Loading floor %d..." % floor_id)
	emit_signal("floor_load_started", floor_id)
	
	current_floor_id = floor_id
	
	# 从 DataManager 获取楼层数据
	var floor_data = DataManager.get_floor(floor_id)
	if floor_data.is_empty():
		emit_signal("floor_load_failed", floor_id, "Floor data not found")
		push_error("[MapLoader] Floor data not found: %d" % floor_id)
		return
	
	current_floor_data = floor_data
	
	# 清理旧地图
	_clear_floor()
	
	# 创建地图节点
	_create_floor_nodes()
	
	# 放置地块
	_place_tiles(floor_data)
	
	# 放置实体
	_place_entities(floor_data)
	
	# 设置楼层属性
	_setup_floor_settings(floor_data)
	
	emit_signal("floor_load_completed", floor_id)
	EventBus.emit_signal("floor_loaded", floor_id)
	print("[MapLoader] Floor %d loaded successfully" % floor_id)


## 清理旧楼层
func _clear_floor():
	# 清理地块
	if floor_tilemap:
		floor_tilemap.clear()
	
	# 清理实体
	var entities = get_tree().get_nodes_in_group("floor_entities")
	for entity in entities:
		entity.queue_free()


## 创建楼层节点
func _create_floor_nodes():
	# 获取游戏场景
	var game_scene = get_tree().current_scene
	if not game_scene:
		push_error("[MapLoader] Game scene not found")
		return
	
	# 创建 TileMapLayer
	if not floor_tilemap or floor_tilemap.get_parent() == null:
		floor_tilemap = TileMapLayer.new()
		floor_tilemap.name = "FloorTilemap"
		game_scene.add_child(floor_tilemap)
		
		# 加载 tileset
		var tileset = load("res://assets/tiles/dungeon_tileset.tres")
		if tileset:
			floor_tilemap.tile_set = tileset
			print("[MapLoader] TileSet loaded")
		else:
			push_warning("[MapLoader] TileSet not found, using default")


## 放置地块
func _place_tiles(floor_data: Dictionary):
	if not floor_tilemap:
		push_error("[MapLoader] TileMap not initialized")
		return
	
	var tiles = floor_data.get("tiles", [])
	var size = floor_data.get("size", {"width": 17, "height": 17})
	
	var width = size.get("width", 17)
	var height = size.get("height", 17)
	
	# 设置地图大小
	floor_tilemap.size = Vector2i(width, height)
	
	# 放置每个地块
	for tile in tiles:
		var x = tile.get("x", 0)
		var y = tile.get("y", 0)
		var tile_type = tile.get("type", "floor")
		
		_place_tile(x, y, tile_type)
	
	print("[MapLoader] Placed %d tiles" % tiles.size())


## 放置单个地块
func _place_tile(x: int, y: int, tile_type: String):
	if not floor_tilemap:
		return
	
	# 根据类型获取 tile 索引
	var tile_index = _get_tile_index(tile_type)
	
	# 设置地块
	floor_tilemap.set_cell(Vector2i(x, y), 0, Vector2i(tile_index, 0))
	
	emit_signal("tile_placed", x, y, tile_type)


## 获取地块索引
func _get_tile_index(tile_type: String) -> int:
	# 简化版本，实际应该从 tileset 获取
	match tile_type:
		TILE_FLOOR: return 0
		TILE_WALL: return 1
		TILE_DOOR: return 2
		TILE_STAIRS_UP: return 3
		TILE_STAIRS_DOWN: return 4
		TILE_SPIKES: return 5
		TILE_WATER: return 6
		TILE_LAVA: return 7
		TILE_ICE: return 8
		TILE_Conveyor: return 9
		_: return 0


## 放置实体
func _place_entities(floor_data: Dictionary):
	var entities = floor_data.get("entities", [])
	
	for entity_data in entities:
		var entity_type = entity_data.get("type", "")
		var entity_id = entity_data.get("entity_id" if entity_type == ENTITY_ENEMY else "item_id", "")
		var x = entity_data.get("x", 0)
		var y = entity_data.get("y", 0)
		
		match entity_type:
			ENTITY_ENEMY:
				_spawn_enemy(entity_id, x, y)
			ENTITY_ITEM:
				_spawn_item(entity_id, x, y)
			ENTITY_NPC:
				_spawn_npc(entity_id, x, y)
			ENTITY_DOOR:
				_spawn_door(entity_id, x, y)
			ENTITY_TELEPORTER:
				_spawn_teleporter(entity_id, x, y)
	
	print("[MapLoader] Placed %d entities" % entities.size())


## 生成敌人
func _spawn_enemy(enemy_id: String, x: int, y: int):
	var enemy_data = DataManager.get_enemy(enemy_id)
	if enemy_data.is_empty():
		push_warning("[MapLoader] Enemy not found: " + enemy_id)
		return
	
	# 创建敌人实例
	# 实际应该从场景文件加载
	var enemy = Node2D.new()
	enemy.name = "Enemy_" + enemy_id
	enemy.set_position(Vector2(x * default_tile_size, y * default_tile_size))
	enemy.add_to_group("floor_entities")
	enemy.add_to_group("enemies")
	
	if floor_tilemap:
		floor_tilemap.add_child(enemy)
	
	emit_signal("entity_spawned", ENTITY_ENEMY, enemy_id, x, y)
	print("[MapLoader] Spawned enemy: %s at (%d, %d)" % [enemy_id, x, y])


## 生成道具
func _spawn_item(item_id: String, x: int, y: int):
	var item_data = DataManager.get_item(item_id)
	if item_data.is_empty():
		push_warning("[MapLoader] Item not found: " + item_id)
		return
	
	var item = Node2D.new()
	item.name = "Item_" + item_id
	item.set_position(Vector2(x * default_tile_size, y * default_tile_size))
	item.add_to_group("floor_entities")
	item.add_to_group("items")
	
	if floor_tilemap:
		floor_tilemap.add_child(item)
	
	emit_signal("entity_spawned", ENTITY_ITEM, item_id, x, y)
	print("[MapLoader] Spawned item: %s at (%d, %d)" % [item_id, x, y])


## 生成 NPC
func _spawn_npc(npc_id: String, x: int, y: int):
	var npc = Node2D.new()
	npc.name = "NPC_" + npc_id
	npc.set_position(Vector2(x * default_tile_size, y * default_tile_size))
	npc.add_to_group("floor_entities")
	npc.add_to_group("npcs")
	
	if floor_tilemap:
		floor_tilemap.add_child(npc)
	
	emit_signal("entity_spawned", ENTITY_NPC, npc_id, x, y)


## 生成门
func _spawn_door(door_id: String, x: int, y: int):
	var door = Node2D.new()
	door.name = "Door_" + door_id
	door.set_position(Vector2(x * default_tile_size, y * default_tile_size))
	door.add_to_group("floor_entities")
	door.add_to_group("doors")
	
	if floor_tilemap:
		floor_tilemap.add_child(door)
	
	emit_signal("entity_spawned", ENTITY_DOOR, door_id, x, y)


## 生成传送器
func _spawn_teleporter(teleporter_id: String, x: int, y: int):
	var teleporter = Node2D.new()
	teleporter.name = "Teleporter_" + teleporter_id
	teleporter.set_position(Vector2(x * default_tile_size, y * default_tile_size))
	teleporter.add_to_group("floor_entities")
	teleporter.add_to_group("teleporters")
	
	if floor_tilemap:
		floor_tilemap.add_child(teleporter)
	
	emit_signal("entity_spawned", ENTITY_TELEPORTER, teleporter_id, x, y)


## 设置楼层属性
func _setup_floor_settings(floor_data: Dictionary):
	var settings = floor_data.get("settings", {})
	
	# 设置背景音乐
	var music = settings.get("music", "")
	if not music.is_empty():
		EventBus.emit_signal("music_changed", music)
	
	# 设置背景
	var background = settings.get("background", "")
	if not background.is_empty():
		# 设置背景纹理
		pass


## 获取当前楼层 ID
func get_current_floor_id() -> int:
	return current_floor_id


## 获取当前楼层数据
func get_current_floor_data() -> Dictionary:
	return current_floor_data


## 检查位置是否可通行
func is_walkable(x: int, y: int) -> bool:
	if not floor_tilemap:
		return false
	
	# 获取地块类型
	var tile_data = floor_tilemap.get_cell_tile_data(Vector2i(x, y))
	if tile_data == null:
		return true  # 空地块可通行
	
	# 检查是否是墙壁等不可通行地块
	# 简化版本
	return true


## 获取楼层统计
func get_statistics() -> Dictionary:
	var entities = get_tree().get_nodes_in_group("floor_entities")
	return {
		"current_floor": current_floor_id,
		"total_entities": entities.size(),
		"enemies": get_tree().get_node_count_in_group("enemies"),
		"items": get_tree().get_node_count_in_group("items"),
		"npcs": get_tree().get_node_count_in_group("npcs")
	}


# ==================== 事件回调 ====================
func _on_floor_entered(floor_id: int):
	load_floor(floor_id)
