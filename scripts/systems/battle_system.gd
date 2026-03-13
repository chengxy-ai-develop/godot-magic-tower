extends Node
class_name BattleSystem

## 战斗系统 - 处理魔塔经典固定数值战斗

# 信号
signal battle_started(player_data: Dictionary, enemy_data: Dictionary)
signal battle_round(round: int, player_hp: int, enemy_hp: int)
signal battle_finished(result: Dictionary)

# 战斗配置
@export var auto_battle: bool = false  # 是否自动战斗

# 战斗状态
var _is_battling: bool = false
var _current_round: int = 0
var _player_data: Dictionary = {}
var _enemy_data: Dictionary = {}

func _ready() -> void:
	print("[BattleSystem] 战斗系统初始化完成")

func start_battle(player_data: Dictionary, enemy_data: Dictionary) -> Dictionary:
	"""
	开始战斗
	返回：战斗结果
	"""
	_is_battling = true
	_current_round = 0
	_player_data = player_data.duplicate(true)
	_enemy_data = enemy_data.duplicate(true)
	
	battle_started.emit(_player_data, _enemy_data)
	print("[BattleSystem] 战斗开始 - 敌人：", enemy_data.get("name", "未知"))
	
	if auto_battle:
		return simulate_battle(_player_data, _enemy_data)
	else:
		# 手动战斗模式（待实现 UI 交互）
		return simulate_battle(_player_data, _enemy_data)

func simulate_battle(player: Dictionary, enemy: Dictionary) -> Dictionary:
	"""
	模拟战斗（固定数值计算）
	魔塔经典战斗公式：
	- 玩家伤害 = max(0, 玩家攻击 - 敌人防御)
	- 敌人伤害 = max(0, 敌人攻击 - 玩家防御)
	- 回合数 = ceil(敌人 HP / 玩家伤害)
	- 玩家损失 = (回合数 - 1) * 敌人伤害
	"""
	var player_attack = player.get("attack", 0)
	var player_defense = player.get("defense", 0)
	var player_hp = player.get("hp", 0)
	
	var enemy_attack = enemy.get("attack", 0)
	var enemy_defense = enemy.get("defense", 0)
	var enemy_hp = enemy.get("hp", 0)
	
	# 计算伤害
	var player_damage = max(0, player_attack - enemy_defense)
	var enemy_damage = max(0, enemy_attack - player_defense)
	
	# 特殊情况处理
	if player_damage == 0:
		# 无法破防，必败
		return {
			"won": false,
			"reason": "无法破防",
			"player_hp_remaining": 0,
			"gold": 0,
			"experience": 0
		}
	
	if enemy_damage == 0:
		# 敌人无法破防，必胜且无伤
		var rounds = ceil(float(enemy_hp) / player_damage)
		return {
			"won": true,
			"rounds": rounds,
			"player_hp_remaining": player_hp,
			"player_hp_loss": 0,
			"gold": enemy.get("gold", 0),
			"experience": enemy.get("experience", 0)
		}
	
	# 计算战斗回合数
	var rounds_to_kill_enemy = ceil(float(enemy_hp) / player_damage)
	var player_hp_loss = (rounds_to_kill_enemy - 1) * enemy_damage
	
	# 判断胜负
	var won = player_hp > player_hp_loss
	var remaining_hp = player_hp - player_hp_loss if won else 0
	
	var result = {
		"won": won,
		"rounds": rounds_to_kill_enemy,
		"player_hp_remaining": remaining_hp,
		"player_hp_loss": player_hp_loss,
		"gold": enemy.get("gold", 0) if won else 0,
		"experience": enemy.get("experience", 0) if won else 0
	}
	
	print("[BattleSystem] 战斗结果 - 胜利：", won, ", 剩余 HP: ", remaining_hp, ", 损失：", player_hp_loss)
	
	battle_finished.emit(result)
	_is_battling = false
	
	return result

func calculate_battle(player: Dictionary, enemy: Dictionary) -> Dictionary:
	"""
	计算战斗结果（不实际执行，用于策略规划）
	"""
	return simulate_battle(player, enemy)

func can_defeat_enemy(player: Dictionary, enemy: Dictionary) -> bool:
	"""
	判断玩家是否能击败敌人
	"""
	var result = simulate_battle(player, enemy)
	return result["won"]

func get_battle_preview(player: Dictionary, enemy: Dictionary) -> Dictionary:
	"""
	获取战斗预览信息
	"""
	var player_damage = max(0, player.get("attack", 0) - enemy.get("defense", 0))
	var enemy_damage = max(0, enemy.get("attack", 0) - player.get("defense", 0))
	var rounds = ceil(float(enemy.get("hp", 1)) / player_damage) if player_damage > 0 else 999
	var hp_loss = (rounds - 1) * enemy_damage
	
	return {
		"player_damage": player_damage,
		"enemy_damage": enemy_damage,
		"rounds": rounds,
		"hp_loss": hp_loss,
		"can_win": player.get("hp", 0) > hp_loss
	}

func is_battling() -> bool:
	"""
	是否正在战斗中
	"""
	return _is_battling
