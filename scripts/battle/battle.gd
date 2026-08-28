extends Node2D

enum State { FIGHTING, WON, LOST }

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const MAX_WAVE := 10
const MAX_WORLD := 3

var state: State = State.FIGHTING
var _upgrade_rows: Dictionary = {}
var _upgrades_built := false
var _wave_drops: Array = []
var _current_drop: Dictionary = {}

@onready var player: Player = $World/Player
@onready var base_building: BaseBuilding = $World/Base
@onready var enemies_container: Node2D = $World/Enemies
@onready var units_container: Node2D = $World/Units
@onready var wave_label: Label = %WaveLabel
@onready var currency_label: Label = %CurrencyLabel
@onready var gold_label: Label = %GoldLabel
@onready var science_label: Label = %ScienceLabel
@onready var mat_label: Label = %MatLabel
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
@onready var bg_rect: ColorRect = $Background
@onready var ground_rect: ColorRect = $GroundStrip
@onready var era_banner: CenterContainer = %EraBanner
@onready var era_banner_title: Label = %EraBannerTitle
@onready var era_banner_name: Label = %EraBannerName

const SPAWN_X := 1160.0
const SPAWN_Y_BASE := 1350.0
const SPAWN_Y_VAR := 40.0
const PLAYER_POS := Vector2(220, 1350)
const BASE_POS := Vector2(140, 1450)
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
	player.critical_hit.connect(_on_player_crit)
	player.died.connect(_end_battle.bind(false))
	base_building.died.connect(_end_battle.bind(false))
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	upgrades_button.pressed.connect(_open_upgrades)
	close_upgrades_button.pressed.connect(func() -> void: upgrades_panel.visible = false)
	item_equip_button.pressed.connect(_on_drop_equipped)
	item_sell_button.pressed.connect(_on_drop_sold)
	player.position = PLAYER_POS
	base_building.position = BASE_POS
	_wave_drops.clear()
	_current_drop = {}
	SignalBus.currency_changed.connect(_refresh_currency)
	SignalBus.era_changed.connect(_on_era_changed)
	_apply_era_visual(GameState.current_era)
	_spawn_allies()
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
	# lateral spawn: from right, random Y around ground
	enemy.position = Vector2(SPAWN_X, SPAWN_Y_BASE + randf_range(-SPAWN_Y_VAR, SPAWN_Y_VAR))
	enemies_container.add_child(enemy)

func _on_enemy_killed(enemy_id: String) -> void:
	GameState.stats["enemies_killed"] = int(GameState.stats.get("enemies_killed", 0)) + 1
	var data := WaveManager.get_enemy_data(enemy_id)
	if data.is_empty():
		return
	if bool(data.get("is_boss", false)):
		GameState.stats["bosses_killed"] = int(GameState.stats.get("bosses_killed", 0)) + 1
	var chance := float(data.get("loot_chance", 0.0)) + BuildingManager.get_bonus("loot_bonus")
	var drop := LootManager.roll_drop(chance, GameState.world, GameState.wave, bool(data.get("is_boss", false)))
	if drop.is_empty():
		return
	if InventoryManager.add_item(drop) == "stored":
		_wave_drops.append(drop)

func is_over() -> bool:
	return state != State.FIGHTING

func did_win() -> bool:
	return state == State.WON

func _advance_progression() -> void:
	if GameState.wave >= MAX_WAVE:
		if GameState.world < MAX_WORLD:
			GameState.world += 1
			GameState.wave = 1
		else:
			GameState.wave = MAX_WAVE
	else:
		GameState.wave += 1

func _victory() -> void:
	var rewards := WaveManager.calculate_rewards(GameState.world, GameState.wave)
	Economy.add_gold(int(rewards["gold"]))
	Economy.add_science(int(rewards["science"]))
	Economy.add_materials(int(rewards["materials"]))
	result_sub.text = "+%d oro   +%d ciencia   +%d materiales" % [rewards["gold"], rewards["science"], rewards["materials"]]
	_advance_progression()
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
	item_card.scale = Vector2(0.85, 0.85)
	item_card.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(item_card, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(item_card, "modulate:a", 1.0, 0.2)
	if TutorialManager.should_show("first_drop"):
		TutorialManager.mark_seen("first_drop")
		_show_tutorial("¡Conseguiste un objeto! Equipalo para ser más fuerte.")
	AudioManager.play_sfx("drop")

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
	if InventoryManager.equip_item(String(_current_drop["id"])):
		result_sub.text += "   [Equipado]"
		_show_tutorial("¡Objeto equipado!")
	_hide_drop_card()

func _on_drop_sold() -> void:
	if _current_drop.is_empty():
		return
	var val := int(_current_drop.get("sell_value", 0))
	InventoryManager.sell_item(String(_current_drop["id"]))
	result_sub.text += "   [+%d oro]" % val
	_show_tutorial("Vendido por %d oro" % val)
	_hide_drop_card()

func _hide_drop_card() -> void:
	_current_drop = {}
	item_card.visible = false

func _spawn_allies() -> void:
	var count := clampi(1 + BuildingManager.get_level("housing"), 1, 3)
	var types := ["archer", "heavy", "crossbow"]
	for i in range(count):
		var u := AllyUnit.new()
		u.setup(types[i % types.size()])
		u.position = Vector2(280 + i * 110, SPAWN_Y_BASE + randf_range(-12, 12))
		units_container.add_child(u)

func _end_battle(victory: bool) -> void:
	if state == State.WON or state == State.LOST:
		return
	state = State.WON if victory else State.LOST
	for node in get_tree().get_nodes_in_group("enemies"):
		node.set_process(false)
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.set_process(false)
	for node in get_tree().get_nodes_in_group("allies"):
		node.set_process(false)
	player.set_process(false)
	base_building.set_process(false)
	result_title.text = "VICTORIA" if victory else "DERROTA"
	if not victory:
		result_sub.text = "La base ha caido. Vuelves a la oleada anterior para farmear."
		retry_button.text = "REINTENTAR"
		if GameState.wave > 1:
			GameState.wave -= 1
		elif GameState.world > 1:
			GameState.world -= 1
			GameState.wave = MAX_WAVE
		SignalBus.save_requested.emit()
		get_tree().create_timer(2.5).timeout.connect(func() -> void:
			if state == State.LOST and is_inside_tree():
				get_tree().reload_current_scene()
		, CONNECT_ONE_SHOT)
	else:
		retry_button.text = "SIGUIENTE"
		if TutorialManager.should_show("first_victory"):
			TutorialManager.mark_seen("first_victory")
			_show_tutorial("¡Victoria! Ganaste recursos. Usa MEJORAS para fortalecerte.")
		AudioManager.play_sfx("victory")
		_shake(6.0)
		get_tree().create_timer(2.8).timeout.connect(func() -> void:
			if state == State.WON and is_inside_tree():
				get_tree().reload_current_scene()
		, CONNECT_ONE_SHOT)
	result_panel.visible = true
	result_panel.scale = Vector2(0.9, 0.9)
	var tw := create_tween()
	tw.tween_property(result_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _refresh_currency() -> void:
	currency_label.text = "ORO %d    CIENCIA %d    MAT %d" % [GameState.gold, GameState.science, GameState.materials]
	if is_instance_valid(gold_label):
		gold_label.text = str(GameState.gold)
		science_label.text = str(GameState.science)
		mat_label.text = str(GameState.materials)

func _apply_era_visual(era_id: String) -> void:
	match era_id:
		"prehistoric":
			bg_rect.color = Color(0.051, 0.071, 0.122)
			ground_rect.color = Color(0.086, 0.11, 0.165)
		"bronze":
			bg_rect.color = Color(0.14, 0.12, 0.09)
			ground_rect.color = Color(0.22, 0.18, 0.14)
		"iron":
			bg_rect.color = Color(0.1, 0.12, 0.13)
			ground_rect.color = Color(0.16, 0.17, 0.18)
		_:
			bg_rect.color = Color(0.08, 0.09, 0.12)
			ground_rect.color = Color(0.12, 0.13, 0.15)
	wave_label.text = "OLEADA %d-%d · %s" % [GameState.world, GameState.wave, String(DataLoader.load_json("eras/eras.json").get(era_id, {}).get("name", era_id)).to_upper()]

func _on_era_changed(era_id: String) -> void:
	_apply_era_visual(era_id)
	var era_name: String = String(DataLoader.load_json("eras/eras.json").get(era_id, {}).get("name", era_id))
	era_banner_name.text = era_name.to_upper()
	era_banner.visible = true
	era_banner.modulate.a = 0.0
	era_banner.scale = Vector2(0.7, 0.7)
	var tw := create_tween()
	tw.tween_property(era_banner, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property(era_banner, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.0)
	tw.tween_property(era_banner, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: era_banner.visible = false)

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

func _on_player_crit(target: Combatant, dmg: int) -> void:
	if not is_instance_valid(target):
		return
	_show_floating_text(target.global_position + Vector2(0, -70), "¡CRÍTICO! %d" % dmg, Color(1, 0.85, 0.2))
	_shake(3.0)

func _show_floating_text(pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 44)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = pos + Vector2(-120, -20)
	label.z_index = 10
	$World.add_child(label)
	var tw := create_tween()
	tw.tween_property(label, "position:y", label.position.y - 60.0, 0.7).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tw.tween_callback(label.queue_free)

func _show_tutorial(text: String) -> void:
	var toast := PanelContainer.new()
	toast.position = Vector2(60, 220)
	toast.size = Vector2(960, 0)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(1, 0.92, 0.5))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.add_child(lbl)
	$UI.add_child(toast)
	var tw := create_tween()
	toast.modulate.a = 0.0
	tw.tween_property(toast, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.0)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)
	tw.tween_callback(toast.queue_free)

func _shake(intensity: float) -> void:
	var orig: Vector2 = $World.position
	var tw := create_tween()
	tw.tween_property($World, "position", orig + Vector2(intensity, -intensity), 0.04)
	tw.tween_property($World, "position", orig + Vector2(-intensity, intensity), 0.04)
	tw.tween_property($World, "position", orig, 0.04)

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
