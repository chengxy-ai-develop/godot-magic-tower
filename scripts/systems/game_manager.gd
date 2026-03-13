extends Node
class_name GameManager

## 游戏管理器

signal game_started
signal game_over
signal game_won
signal battle_started(enemy_data: Dictionary)
signal battle_won(rewards: Dictionary)

enum GameState { MENU, PLAYING, BATTLE, DIALOG, GAME_OVER, VICTORY }
var current_state: GameState = GameState.MENU

var player: Node
var ui_manager: Node
var map_loader: Node

var game_data: Dictionary = {
	"start_time": 0,
	"play_time": 0,
	"deaths": 0,
	"monsters_defeated": 0
}

func _ready() -> void:
	print("[GameManager] 初始化完成")
	_find_references()

func _find_references() -> void:
	player = get_node_or_null("../Player")
	ui_manager = get_node_or_null("../UILayer/UIManager")
	map_loader = get_node_or_null("../MapLoader")

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		game_data["play_time"] += delta

func start_game() -> void:
	print("[GameManager] 开始新游戏")
	if player:
		player.current_hp = player.max_hp
		player.attack = 10
		player.defense = 10
		player.gold = 0
		player.current_floor = 1
	
	if map_loader:
		map_loader.load_floor(1)
	
	set_state(GameState.PLAYING)
	game_started.emit()

func set_state(new_state: GameState) -> void:
	current_state = new_state

func start_battle(enemy_data: Dictionary) -> void:
	set_state(GameState.BATTLE)
	battle_started.emit(enemy_data)
	print("[GameManager] 战斗开始：", enemy_data.get("name", "敌人"))
	_resolve_battle(enemy_data)

func _resolve_battle(enemy_data: Dictionary) -> void:
	var enemy_stats = enemy_data.get("stats", {})
	var player_stats = player.get_stats() if player else {}
	
	var player_hp = player_stats.get("hp", 1000)
	var player_atk = player_stats.get("attack", 10)
	var player_def = player_stats.get("defense", 10)
	
	var enemy_hp = enemy_stats.get("hp", 100)
	var enemy_atk = enemy_stats.get("attack", 20)
	var enemy_def = enemy_stats.get("defense", 5)
	
	var player_damage = max(0, player_atk - enemy_def)
	var enemy_damage = max(0, enemy_atk - player_def)
	
	if player_damage <= 0:
		_battle_lost()
		return
	
	var turns = ceil(float(enemy_hp) / player_damage)
	var total_damage = enemy_damage * (turns - 1)
	
	if total_damage >= player_hp:
		_battle_lost()
	else:
		_battle_won(enemy_data, total_damage)

func _battle_won(enemy_data: Dictionary, damage_taken: int) -> void:
	if player:
		player.take_damage(damage_taken)
	
	var rewards = {
		"gold": enemy_data.get("stats", {}).get("gold", 0),
		"experience": enemy_data.get("stats", {}).get("experience", 0)
	}
	
	if player:
		player.gain_gold(rewards.gold)
	
	game_data["monsters_defeated"] += 1
	print("[GameManager] 战斗胜利！获得金币：", rewards.gold)
	
	battle_won.emit(rewards)
	set_state(GameState.PLAYING)

func _battle_lost() -> void:
	print("[GameManager] 战斗失败")
	if player:
		player._die()

func save_game(slot: int) -> bool:
	print("[GameManager] 保存游戏到槽位：", slot)
	return true

func load_game(slot: int) -> bool:
	print("[GameManager] 从槽位加载：", slot)
	return true

func game_over() -> void:
	set_state(GameState.GAME_OVER)
	game_over.emit()

func quit_game() -> void:
	get_tree().quit()
