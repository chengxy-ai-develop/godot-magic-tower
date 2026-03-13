extends CanvasLayer
class_name UIManager

## UI 管理系统 - 处理所有界面显示

# 信号
signal dialog_finished
signal menu_opened
signal menu_closed

# UI 节点引用
@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPBar/HPLabel
@onready var gold_label: Label = $GoldLabel
@onready var attack_label: Label = $AttackLabel
@onready var defense_label: Label = $DefenseLabel
@onready var floor_label: Label = $FloorLabel
@onready var keys_container: HBoxContainer = $KeysContainer

# 对话框
@onready var dialog_panel: Panel = $DialogPanel
@onready var dialog_label: Label = $DialogPanel/DialogLabel

# 菜单
@onready var menu_panel: Panel = $MenuPanel

# 战斗 UI
@onready var battle_panel: Panel = $BattlePanel
@onready var battle_log: TextEdit = $BattlePanel/BattleLog

# 状态
var is_dialog_active: bool = false
var is_menu_open: bool = false
var is_battle_active: bool = false

func _ready() -> void:
	print("[UIManager] UI 系统初始化完成")
	_hide_all_panels()

func _hide_all_panels() -> void:
	"""
	隐藏所有面板
	"""
	if dialog_panel:
		dialog_panel.visible = false
	if menu_panel:
		menu_panel.visible = false
	if battle_panel:
		battle_panel.visible = false

# ============ 状态栏更新 ============

func update_player_stats(player_data: Dictionary) -> void:
	"""
	更新玩家状态显示
	"""
	if hp_bar:
		var hp = player_data.get("hp", 1000)
		var max_hp = player_data.get("max_hp", 1000)
		hp_bar.max_value = max_hp
		hp_bar.value = hp
		hp_label.text = "%d / %d" % [hp, max_hp]
	
	if gold_label:
		gold_label.text = "💰 %d" % player_data.get("gold", 0)
	
	if attack_label:
		attack_label.text = "⚔️ %d" % player_data.get("attack", 10)
	
	if defense_label:
		defense_label.text = "🛡️ %d" % player_data.get("defense", 10)
	
	if floor_label:
		floor_label.text = "第 %d 层" % player_data.get("floor", 1)

func update_keys(keys: Dictionary) -> void:
	"""
	更新钥匙显示
	"""
	if not keys_container:
		return
	
	# 清除现有
	for child in keys_container.get_children():
		child.queue_free()
	
	# 添加钥匙图标
	if keys.get("yellow", 0) > 0:
		_add_key_icon("yellow", keys["yellow"])
	if keys.get("blue", 0) > 0:
		_add_key_icon("blue", keys["blue"])
	if keys.get("red", 0) > 0:
		_add_key_icon("red", keys["red"])

func _add_key_icon(color: String, count: int) -> void:
	"""
	添加钥匙图标
	"""
	var label = Label.new()
	var color_name = {
		"yellow": "🗝️",
		"blue": "🔑",
		"red": "🔐"
	}.get(color, "🗝️")
	label.text = "%s %d" % [color_name, count]
	keys_container.add_child(label)

# ============ 对话框 ============

func show_dialog(text: String, auto_hide: bool = false, duration: float = 3.0) -> void:
	"""
	显示对话框
	"""
	if not dialog_panel:
		return
	
	is_dialog_active = true
	dialog_panel.visible = true
	dialog_label.text = text
	
	if auto_hide:
		await get_tree().create_timer(duration).timeout
		hide_dialog()

func hide_dialog() -> void:
	"""
	隐藏对话框
	"""
	if dialog_panel:
		dialog_panel.visible = false
	is_dialog_active = false
	dialog_finished.emit()

func type_dialog(text: String, speed: float = 0.05) -> void:
	"""
	打字机效果显示对话
	"""
	if not dialog_panel:
		return
	
	is_dialog_active = true
	dialog_panel.visible = true
	dialog_label.text = ""
	
	for char in text:
		dialog_label.text += char
		await get_tree().create_timer(speed).timeout
	
	await get_tree().create_timer(1.0).timeout
	hide_dialog()

# ============ 菜单 ============

func open_menu() -> void:
	"""
	打开菜单
	"""
	if not menu_panel:
		return
	
	is_menu_open = true
	menu_panel.visible = true
	menu_opened.emit()

func close_menu() -> void:
	"""
	关闭菜单
	"""
	if menu_panel:
		menu_panel.visible = false
	is_menu_open = false
	menu_closed.emit()

func toggle_menu() -> void:
	"""
	切换菜单状态
	"""
	if is_menu_open:
		close_menu()
	else:
		open_menu()

# ============ 战斗 UI ============

func start_battle_ui(enemy_name: String, enemy_hp: int, player_hp: int) -> void:
	"""
	开始战斗 UI
	"""
	if not battle_panel:
		return
	
	is_battle_active = true
	battle_panel.visible = true
	
	if battle_log:
		battle_log.text = "⚔️ 遭遇 %s！\n" % enemy_name
		battle_log.text += "敌人 HP: %d | 你的 HP: %d\n" % [enemy_hp, player_hp]

func add_battle_log(text: String) -> void:
	"""
	添加战斗日志
	"""
	if battle_log:
		battle_log.text += text + "\n"
		battle_log.scroll_vertical = battle_log.get_line_count()

func end_battle_ui(result: Dictionary) -> void:
	"""
	结束战斗 UI
	"""
	if battle_log:
		if result.get("won", false):
			battle_log.text += "\n✅ 胜利！\n"
			battle_log.text += "获得：💰%d  💫%d" % [
				result.get("gold", 0),
				result.get("experience", 0)
			]
		else:
			battle_log.text += "\n❌ 失败..."
	
	await get_tree().create_timer(2.0).timeout
	end_battle_ui_clean()

func end_battle_ui_clean() -> void:
	"""
	清理战斗 UI
	"""
	if battle_panel:
		battle_panel.visible = false
	is_battle_active = false

# ============ 消息提示 ============

func show_message(text: String, duration: float = 2.0) -> void:
	"""
	显示简短消息提示
	"""
	# 可以用 Toast 或 Label 实现
	print("[UI] 消息：", text)

func show_damage_popup(damage: int, position: Vector2) -> void:
	"""
	显示伤害弹出
	"""
	# 需要在场景中实例化弹出预制体
	print("[UI] 伤害：", damage, " 位置：", position)

func show_item_pickup(item_name: String) -> void:
	"""
	显示道具拾取提示
	"""
	show_message("📦 获得：%s" % item_name, 1.5)

# ============ 存档界面 ============

func show_save_menu() -> void:
	"""
	显示存档菜单
	"""
	# 显示存档槽选择界面
	print("[UI] 显示存档菜单")

func show_load_menu() -> void:
	"""
	显示读档菜单
	"""
	print("[UI] 显示读档菜单")

# ============ 工具函数 ============

func fade_in(duration: float = 1.0) -> void:
	"""
	淡入效果
	"""
	# 可以用 ColorRect + Tween 实现
	print("[UI] 淡入：", duration)

func fade_out(duration: float = 1.0) -> void:
	"""
	淡出效果
	"""
	print("[UI] 淡出：", duration)

func shake_screen(intensity: float = 10.0, duration: float = 0.5) -> void:
	"""
	屏幕震动
	"""
	print("[UI] 震动：强度=", intensity, " 时长=", duration)
