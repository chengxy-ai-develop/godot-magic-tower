extends Node
class_name BattleSystem

## 战斗系统 - 处理战斗逻辑和动画
## 支持：自动战斗、伤害计算、战斗动画、战斗结果

signal battle_started(enemy_data: Dictionary)
signal battle_ended(victory: bool, rewards: Dictionary)
signal damage_dealt(amount: int, is_critical: bool)
signal damage_taken(amount: int)

var is_in_battle: bool = false
var current_enemy: Dictionary = {}
var battle_log: Array = []

func _ready() -> void:
	print("[BattleSystem] 初始化完成")

func start_battle(enemy_data: Dictionary) -> void:
	if is_in_battle:
		return
	
	is_in_battle = true
	current_enemy = enemy_data
	battle_log.clear()
	
	print("[BattleSystem] 战斗开始：", enemy_data.get("name", "敌人"))
	battle_started.emit(enemy_data)
	
	# 执行自动战斗
	await execute_auto_battle(enemy_data)

func execute_auto_battle(enemy_data: Dictionary) -> void:
	var player = get_player()
	var enemy_stats = enemy_data.get("stats", {})
	
	if not player:
		end_battle(false)
		return
	
	var player_stats = player.get_stats()
	
	# 战斗计算
	var player_damage_per_hit = max(0, player_stats["attack"] - enemy_stats.get("defense", 0))
	var enemy_damage_per_hit = max(0, enemy_stats.get("attack", 0) - player_stats["defense"])
	
	if player_damage_per_hit <= 0:
		print("[BattleSystem] 无法对敌人造成伤害！")
		end_battle(false)
		return
	
	var enemy_hp = enemy_stats.get("hp", 100)
	var player_hp = player_stats["hp"]
	
	# 计算战斗回合
	var turns_to_kill = ceil(float(enemy_hp) / player_damage_per_hit)
	var total_player_damage = enemy_damage_per_hit * (turns_to_kill - 1)
	
	# 记录战斗日志
	battle_log.append("战斗开始：vs %s" % enemy_data.get("name", "敌人"))
	battle_log.append("玩家属性：HP=%d, 攻击=%d, 防御=%d" % [
		player_stats["hp"], player_stats["attack"], player_stats["defense"]
	])
	battle_log.append("敌人属性：HP=%d, 攻击=%d, 防御=%d" % [
		enemy_stats.get("hp", 0), enemy_stats.get("attack", 0), enemy_stats.get("defense", 0)
	])
	
	if total_player_damage >= player_hp:
		# 玩家战败
		battle_log.append("结果：战败 (受到 %d 点伤害)" % total_player_damage)
		print("[BattleSystem] 战斗失败")
		end_battle(false)
	else:
		# 玩家胜利
		var gold_reward = enemy_stats.get("gold", 0)
		var exp_reward = enemy_stats.get("experience", 0)
		
		battle_log.append("结果：胜利！")
		battle_log.append("获得：金币=%d, 经验=%d" % [gold_reward, exp_reward])
		
		# 更新玩家状态
		player.take_damage(total_player_damage)
		if gold_reward > 0:
			player.gain_gold(gold_reward)
		if exp_reward > 0:
			player.gain_experience(exp_reward)
		
		print("[BattleSystem] 战斗胜利！获得金币：%d, 经验：%d" % [gold_reward, exp_reward])
		end_battle(true, {"gold": gold_reward, "experience": exp_reward})

func end_battle(victory: bool, rewards: Dictionary = {}) -> void:
	is_in_battle = false
	battle_ended.emit(victory, rewards)
	
	if victory:
		print("[BattleSystem] 战斗胜利奖励：", rewards)
	else:
		print("[BattleSystem] 战斗失败")

func get_battle_log() -> Array:
	return battle_log

func get_player() -> Node:
	return get_node_or_null("../../Player")

func get_game_manager() -> Node:
	return get_node_or_null("../../GameManager")
