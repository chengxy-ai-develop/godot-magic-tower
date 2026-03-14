extends Node
class_name EventBus

## 全局事件总线
## 用于解耦各系统之间的通信

# ==================== 游戏事件 ====================
signal game_started()
signal game_paused()
signal game_resumed()
signal game_ended(victory: bool)
signal game_quit()

# ==================== 场景事件 ====================
signal scene_changed(scene_name: String)
signal scene_loaded(scene_name: String)
signal scene_load_failed(scene_name: String)

# ==================== 玩家事件 ====================
signal player_moved(x: int, y: int)
signal player_stats_changed()
signal player_hp_changed(new_hp: int, max_hp: int)
signal player_attack_changed(new_attack: int)
signal player_defense_changed(new_defense: int)
signal player_gold_changed(new_gold: int)
signal player_level_up(new_level: int)
signal player_item_used(item_id: String)
signal player_item_obtained(item_id: String)
signal player_key_used(key_id: String)
signal player_door_opened(door_id: String)

# ==================== 战斗事件 ====================
signal battle_started(enemy_id: String)
signal battle_ended(victory: bool, rewards: Dictionary)
signal battle_turn_changed(current_turn: int)
signal battle_damage_dealt(damage: int, is_critical: bool)
signal battle_damage_received(damage: int)
signal battle_skill_used(skill_id: String)

# ==================== 楼层事件 ====================
signal floor_entered(floor_id: int)
signal floor_cleared(floor_id: int)
signal floor_loaded(floor_id: int)
signal floor_load_failed(floor_id: int)
signal floor_event_triggered(event_id: String)

# ==================== 实体事件 ====================
signal enemy_defeated(enemy_id: String, rewards: Dictionary)
signal npc_interacted(npc_id: String, dialogue_id: String)
signal item_picked_up(item_id: String)
signal door_opened(door_id: String)
signal teleporter_used(teleporter_id: String, target_floor: int)

# ==================== MOD 事件 ====================
signal mod_installed(mod_id: String)
signal mod_uninstalled(mod_id: String)
signal mod_enabled(mod_id: String)
signal mod_disabled(mod_id: String)
signal mod_loaded(mod_id: String)
signal mod_load_failed(mod_id: String, error: String)

# ==================== 插件事件 ====================
signal plugin_installed(plugin_id: String)
signal plugin_uninstalled(plugin_id: String)
signal plugin_enabled(plugin_id: String)
signal plugin_disabled(plugin_id: String)
signal plugin_loaded(plugin_id: String)
signal plugin_load_failed(plugin_id: String, error: String)

# ==================== 编辑器事件 ====================
signal editor_opened()
signal editor_closed()
signal floor_saved(floor_id: int)
signal floor_loaded_in_editor(floor_id: int)
signal entity_placed_in_editor(entity_type: String, entity_id: String)
signal tile_painted_in_editor(tile_type: String, x: int, y: int)

# ==================== 存档事件 ====================
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal game_save_failed(slot: int, error: String)
signal game_load_failed(slot: int, error: String)

# ==================== UI 事件 ====================
signal ui_opened(ui_name: String)
signal ui_closed(ui_name: String)
signal notification_shown(message: String, type: String)
signal dialog_shown(dialogue_id: String)
signal dialog_closed()

# ==================== 音频事件 ====================
signal music_changed(track_id: String)
signal sfx_played(sfx_id: String)
signal audio_muted(is_muted: bool)
signal audio_volume_changed(volume: float)

# ==================== 系统事件 ====================
signal settings_changed(setting_name: String, value: Variant)
signal language_changed(language: String)
signal resolution_changed(width: int, height: int)
signal fullscreen_changed(is_fullscreen: bool)


## 发送通知事件
func notify(message: String, type: String = "info"):
	emit_signal("notification_shown", message, type)


## 发送玩家属性变化事件
func notify_player_stats_changed():
	emit_signal("player_stats_changed")
	emit_signal("player_hp_changed", GameManager.player_hp, GameManager.player_max_hp)
	emit_signal("player_attack_changed", GameManager.player_attack)
	emit_signal("player_defense_changed", GameManager.player_defense)
	emit_signal("player_gold_changed", GameManager.player_gold)


## 连接所有事件到调试输出 (用于开发)
func connect_debug_output():
	var signals = get_signal_list()
	for s in signals:
		var signal_name = s.name
		if connect(signal_name, _on_any_event.bind(signal_name)):
			push_warning("Failed to connect debug output for signal: " + signal_name)


func _on_any_event(event_name: String, *args):
	var args_str = ", ".join(args.map(func(a): return str(a)))
	print("[EventBus] %s(%s)" % [event_name, args_str])
