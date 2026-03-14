extends Node
class_name MapLoader

## 地图加载器 - 从文件加载楼层地图 (Godot 4 兼容)

const MAP_DIR := "res://data/maps/"

var floor_layer: TileMap
var collision_layer: TileMap
var _map_parent: Node


func _ready() -> void:
	print("[MapLoader] 初始化完成 (Godot 4)")


func load_floor(floor_id: int, map_parent: Node) -> void:
	_map_parent = map_parent
	_clear_existing_layers()
	_setup_layers()
	
	var map_data = _load_map_data(floor_id)
	if map_data.is_empty():
		print("[MapLoader] 警告：楼层 ", floor_id, " 地图数据为空")
		return
	
	_render_map(map_data)
	print("[MapLoader] 楼层 ", floor_id, " 加载完成")


func _clear_existing_layers() -> void:
	for child in _map_parent.get_children():
		if child is TileMap:
			child.queue_free()


func _setup_layers() -> void:
	floor_layer = TileMap.new()
	floor_layer.name = "FloorLayer"
	_map_parent.add_child(floor_layer)
	
	collision_layer = TileMap.new()
	collision_layer.name = "CollisionLayer"
	_map_parent.add_child(collision_layer)


func _load_map_data(floor_id: int) -> Dictionary:
	var file_path = MAP_DIR + "floor_" + str(floor_id) + ".json"
	
	if not FileAccess.file_exists(file_path):
		print("[MapLoader] 地图文件不存在：", file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}
	
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(text)
	if error != OK:
		print("[MapLoader] JSON 解析错误：", json.get_error_message())
		return {}
	
	var data = json.get_data()
	if not data is Dictionary:
		return {}
	
	return data


func _render_map(map_data: Dictionary) -> void:
	var tiles = map_data.get("tiles", [])
	
	for tile in tiles:
		var x = int(tile.get("x", 0))
		var y = int(tile.get("y", 0))
		var tile_id = int(tile.get("tile_id", 0))
		var tile_type = tile.get("type", "floor")
		
		if tile_type == "floor":
			floor_layer.set_cell(0, Vector2i(x, y), 0, Vector2i(tile_id, 0))
		elif tile_type == "wall":
			collision_layer.set_cell(0, Vector2i(x, y), 0, Vector2i(tile_id, 0))


func is_cell_walkable(x: int, y: int) -> bool:
	if not collision_layer:
		return true
	var cell = collision_layer.get_cell_atlas_coords(Vector2i(x, y))
	return cell == Vector2i(-1, -1)
