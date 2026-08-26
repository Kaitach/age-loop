extends Node2D

enum State { FIGHTING, WON, LOST }

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const MAX_WAVE := 10

var state: State = State.FIGHTING
var _upgrade_rows: Dictionary = {}
var _upgrades_built := false
var _wave_drops: Array = []
var _current_drop: Dictionary = {}

@onready var player: Player = $World/Player
@onready var base_building: BaseBuilding = $World/Base
@onready var enemies_container: Node2D = $World/Enemies
@onready var wave_label: Label = %WaveLabel
@onready var currency_label: Label = %CurrencyLabel
@onready var player_bar: ProgressBar = %PlayerBar
@onready var base_bar: ProgressBar = %BaseBar
@onready var result_panel: CenterContainer = %ResultPanel
@onready var result_title: Label = %ResultTitle
@onready var result_sub: Label = %ResultSub
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton
@onready var upgrades_button: Button = %UpgradesButton
@onready var upgrades_panel: CenterContainer = %UpgradesPanel
@onready var upgrades_list: VBoxContainer = %UpgradesList
@onready var close_upgrades_button: Button = %CloseUpgradesButton
@onready var item_card: VBoxContainer = %ItemCard
@onready var item_title: Label = %ItemTitle
@onready var item_stats: Label = %ItemStats
@onready var item_compare: Label = %ItemCompare
@onready var item_equip_button: Button = %ItemEquipButton
@onready var item_sell_button: Button = %ItemSellButton

var wave_manager := WaveManager.new()

func _ready() -> void:
	add_child(wave_manager)
	wave_manager.spawn_enemy.connect(_on_spawn_enemy)
	wave_manager.start(GameState.world, GameState.wave)
	wave_label.text = "OLEADA %d-%d" % [GameState.world, GameState.wave]
	player_bar.max_value = player.max_health
	player_bar.value = player.health
	base_bar.max_value = base_building.max_health
	base_bar.value = base_building.health
	player.damaged.connect(func(_amount: int) -> void: player_bar.value = player.health)
	base_building.damaged.connect(func(_amount: int) -> void: base_bar.value = base_building.health)
	player.died.connect(_end_battle.bind(false))
	base_building.died.connect(_end_battle.bind(false))
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	upgrades_button.pressed.connect(_open_upgrades)
	close_upgrades_button.pressed.connect(func() -> void: upgrades_panel.visible = false)
	item_equip_button.pressed.connect(_on_drop_equipped)
	item_sell_button.pressed.connect(_on_drop_sold)
	_wave_drops.clear()
	_current_drop = {}
	SignalBus.currency_changed.connect(_refresh_currency)
	_refresh_currency()

func _process(delta: float) -> void:
	if state != State.FIGHTING:
		return
	wave_manager.tick(delta)
	if wave_manager.finished_spawning() and get_tree().get_nodes_in_group("enemies").is_empty():
		_victory()

func _on_spawn_enemy(enemy_id: String, position_p: Vector2) -> void:
	var enemy := Enemy.new()
	enemy.setup_from_data(
		enemy_id,
		WaveManager.get_enemy_data(enemy_id),
		WaveManager.hp_scale_for(GameState.world, GameState.wave),
		WaveManager.dmg_scale_for(GameState.world, GameState.wave)
	)
	enemy.position = position_p
	enemy.died.connect(_on_enemy_killed.bind(enemy_id))
	enemies_container.add_child(enemy)

func _on_enemy_killed(enemy_id: String) -> void:
	GameState.stats["enemies_killed"] = int(GameState.stats.get("enemies_killed", 0)) + 1
	var data := WaveManager.get_enemy_data(enemy_id)
	if data.is_empty():
		return
	if bool(data.get("is_boss", false)):
		GameState.stats["bosses_killed"] = int(GameState.stats.get("bosses_killed", 0)) + 1
	var drop := LootManager.roll_drop(float(data.get("loot_chance", 0.0)), GameState.world, GameState.wave, bool(data.get("is_boss", false)))
	if drop.is_empty():
		return
	if InventoryManager.add_item(drop) == "stored":
		_wave_drops.append(drop)

func is_over() -> bool:
	return state != State.FIGHTING

func did_win() -> bool:
	return state == State.WON

func _victory() -> void:
	var rewards := WaveManager.calculate_rewards(GameState.world, GameState.wave)
	Economy.add_gold(int(rewards["gold"]))
	Economy.add_science(int(rewards["science"]))
	Economy.add_materials(int(rewards["materials"]))
	result_sub.text = "+%d oro   +%d ciencia   +%d materiales" % [rewards["gold"], rewards["science"], rewards["materials"]]
	if GameState.wave >= MAX_WAVE:
		GameState.wave = MAX_WAVE
	else:
		GameState.wave += 1
	GameState.stats["waves_completed"] = int(GameState.stats.get("waves_completed", 0)) + 1
	SignalBus.save_requested.emit()
	_show_drop_card()
	_end_battle(true)

func _show_drop_card() -> void:
	if _wave_drops.is_empty():
		item_card.visible = false
		return
	var best: Dictionary = _wave_drops[0]
	for drop in _wave_drops:
		if LootManager.item_power(drop) > LootManager.item_power(best):
			best = drop
	_current_drop = best
	item_title.text = "%s — %s Nv.%d" % [best.get("name", "?"), LootManager.get_rarity_name(String(best.get("rarity", ""))), int(best.get("level", 1))]
	item_title.add_theme_color_override("font_color", LootManager.get_rarity_color(String(best.get("rarity", ""))))
	var lines: PackedStringArray = []
	for stat_key in StatsCalculator.item_total_stats(best).keys():
		lines.append(StatsCalculator.format_stat_line(stat_key, float(StatsCalculator.item_total_stats(best)[stat_key])))
	item_stats.text = "\n".join(lines)
	item_compare.text = _build_compare_text(String(best.get("slot", "")))
	item_card.visible = true

func _build_compare_text(slot: String) -> String:
	var current = GameState.equipped_items.get(slot, null)
	if current == null or not (current is Dictionary):
		return "(Slot vacio)"
	var old_totals := StatsCalculator.item_total_stats(current)
	var new_totals := StatsCalculator.item_total_stats(_current_drop)
	var lines: PackedStringArray = []
	for stat_key in new_totals.keys():
		var diff := float(new_totals[stat_key]) - float(old_totals.get(stat_key, 0.0))
		if absf(diff) < 0.0005:
			continue
		if stat_key == "attack_speed" or stat_key == "critical_chance":
			lines.append("%+.1f%% %s" % [diff * 100.0, StatsCalculator.format_stat_line(stat_key, 0.0).split(" ")[0]])
		elif stat_key == "damage":
			lines.append("%+d Daño" % int(round(diff)))
		elif stat_key == "max_health":
			lines.append("%+d Vida" % int(round(diff)))
		else:
			lines.append("%+.0f%% %s" % [diff * 100.0, "Daño critico" if stat_key == "critical_damage" else stat_key])
	if lines.is_empty():
		return "(Sin cambios respecto al actual)"
	return "vs equipado:  " + "   ".join(lines)

func _on_drop_equipped() -> void:
	if _current_drop.is_empty():
		return
	InventoryManager.equip_item(String(_current_drop["id"]))
	result_sub.text += "   [Equipado]"
	_hide_drop_card()

func _on_drop_sold() -> void:
	if _current_drop.is_empty():
		return
	InventoryManager.sell_item(String(_current_drop["id"]))
	result_sub.text += "   [+%d oro]" % int(_current_drop.get("sell_value", 0))
	_hide_drop_card()

func _hide_drop_card() -> void:
	_current_drop = {}
	item_card.visible = false

func _end_battle(victory: bool) -> void:
	if state == State.WON or state == State.LOST:
		return
	state = State.WON if victory else State.LOST
	for node in get_tree().get_nodes_in_group("enemies"):
		node.set_process(false)
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.set_process(false)
	player.set_process(false)
	base_building.set_process(false)
	result_title.text = "VICTORIA" if victory else "DERROTA"
	if not victory:
		result_sub.text = "La base ha caido."
	result_panel.visible = true

func _refresh_currency() -> void:
	currency_label.text = "ORO %d    CIENCIA %d    MAT %d" % [GameState.gold, GameState.science, GameState.materials]

func _open_upgrades() -> void:
	if not _upgrades_built:
		_build_upgrade_rows()
		_upgrades_built = true
	_refresh_upgrade_rows()
	upgrades_panel.visible = true

func _build_upgrade_rows() -> void:
	for upgrade_id in Upgrades.defs().keys():
		var def: Dictionary = Upgrades.defs()[upgrade_id]
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var name_label := Label.new()
		name_label.add_theme_font_size_override("font_size", 40)
		name_label.text = String(def.get("name", upgrade_id))
		row.add_child(name_label)
		var buy_button := Button.new()
		buy_button.custom_minimum_size = Vector2(760, 104)
		buy_button.add_theme_font_size_override("font_size", 36)
		buy_button.pressed.connect(_on_upgrade_pressed.bind(String(upgrade_id)))
		row.add_child(buy_button)
		upgrades_list.add_child(row)
		_upgrade_rows[upgrade_id] = { "name": name_label, "button": buy_button }

func _on_upgrade_pressed(upgrade_id: String) -> void:
	if Upgrades.try_buy(upgrade_id):
		_refresh_currency()
		_refresh_upgrade_rows()
		SignalBus.save_requested.emit()

func _refresh_upgrade_rows() -> void:
	for upgrade_id in _upgrade_rows.keys():
		var row: Dictionary = _upgrade_rows[upgrade_id]
		var level := Upgrades.get_level(upgrade_id)
		var def: Dictionary = Upgrades.defs()[upgrade_id]
		if Upgrades.is_maxed(upgrade_id):
			row["name"].text = "%s  Nv.MAX (%s)" % [def.get("name", upgrade_id), def.get("desc", "")]
			row["button"].text = "MAXIMO"
			row["button"].disabled = true
		else:
			row["name"].text = "%s  Nv.%d  (%s)" % [def.get("name", upgrade_id), level, def.get("desc", "")]
			row["button"].text = "MEJORAR — %d ORO" % Upgrades.cost_for(upgrade_id)
			row["button"].disabled = not Economy.can_afford({ "gold": Upgrades.cost_for(upgrade_id) })

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
