extends Node2D

enum State { FIGHTING, WON, LOST }

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const JUICE_BURST_SCRIPT = preload("res://scripts/battle/juice_burst.gd")
const ERA_TRANSITION_SCRIPT = preload("res://scripts/battle/era_transition_overlay.gd")
const ERA_HAZARD_SCRIPT = preload("res://scripts/battle/era_hazard.gd")
const ERA_PROFILE = preload("res://scripts/progression/era_profile.gd")
const ERA_COMBAT_RULES = preload("res://scripts/progression/era_combat_rules.gd")
const PET_SCRIPT = preload("res://scripts/units/pet.gd")
const PREMIUM_STYLE = preload("res://scripts/ui/premium_style.gd")
const BATTLE_ICONS := {
	"inventory": "res://assets/ui/icons/inventory.png",
	"equipment": "res://assets/ui/icons/shield.png",
	"upgrades": "res://assets/ui/icons/gear.png",
	"technology": "res://assets/ui/icons/book.png",
	"power": "res://assets/ui/icons/sword.png",
	"shield": "res://assets/ui/icons/shield.png",
	"fury": "res://assets/ui/icons/fury.png",
}
const MAX_WAVE := 10
const MAX_WORLD := 3

var state: State = State.FIGHTING
var _upgrade_rows: Dictionary = {}
var _upgrades_built := false
var _wave_drops: Array = []
var _current_drop: Dictionary = {}
var _ability_cooldowns: Dictionary = {"power": 0.0, "shield": 0.0, "fury": 0.0}
var _shield_active := false
var _fury_active := false
var _shield_remaining := 0.0
var _fury_remaining := 0.0
var _paused := false
var _combo_count := 0
var _combo_timer := 0.0
var _combo_label: Label
var _era_transition_overlay: Control
var _transition_active := false
var _transition_target := ""
var _player_era := "prehistoric"
var _enemy_era := "prehistoric"
var _pet: Node2D
var _era_rule_state: Dictionary = ERA_COMBAT_RULES.new_state()
var _era_time_scale := 1.0
var _era_time_left := 0.0

@onready var player: Player = $World/Player
@onready var base_building: BaseBuilding = $World/Base
@onready var enemies_container: Node2D = $World/Enemies
@onready var units_container: Node2D = $World/Units
@onready var wave_label: Label = %WaveLabel
@onready var currency_label: Label = %CurrencyLabel
@onready var gold_label: Label = %GoldLabel
@onready var science_label: Label = %ScienceLabel
@onready var mat_label: Label = %MatLabel
@onready var crystals_label: Label = %CrystalsLabel
@onready var power_label: Label = %PowerLabel
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
@onready var inv_button: Button = %InvButton
@onready var equip_button: Button = %EquipButton
@onready var battle_upg_button: Button = %BattleUpgButton
@onready var tech_button: Button = %TechButton
@onready var equip_panel: CenterContainer = %EquipPanel
@onready var equip_list: VBoxContainer = %EquipList
@onready var equip_stats: Label = %EquipStats
@onready var close_equip_button: Button = %CloseEquipButton
@onready var research_quick_panel: CenterContainer = %ResearchQuickPanel
@onready var active_research_label: Label = %ActiveResearchLabel
@onready var research_time_label: Label = %ResearchTimeLabel
@onready var research_list: VBoxContainer = %ResearchList
@onready var close_research_button: Button = %CloseResearchButton
@onready var item_card: VBoxContainer = %ItemCard
@onready var item_title: Label = %ItemTitle
@onready var item_stats: Label = %ItemStats
@onready var item_compare: Label = %ItemCompare
@onready var item_icon_holder: CenterContainer = %ItemIconHolder
@onready var item_equip_button: Button = %ItemEquipButton
@onready var item_sell_button: Button = %ItemSellButton
@onready var bg_rect: ColorRect = $Background
@onready var ground_rect: ColorRect = $GroundStrip
@onready var backdrop: BattleBackdrop = $BattleBackdrop
@onready var era_banner: CenterContainer = %EraBanner
@onready var era_banner_title: Label = %EraBannerTitle
@onready var era_banner_name: Label = %EraBannerName
@onready var power_button: Button = %PowerAbilityButton
@onready var shield_button: Button = %ShieldAbilityButton
@onready var fury_button: Button = %FuryAbilityButton
@onready var speed_button: Button = %SpeedButton
@onready var pause_button: Button = %PauseButton

const SPAWN_X := 1160.0
const GROUND_Y := 1380.0
const SPAWN_Y_BASE := GROUND_Y
const SPAWN_Y_VAR := 40.0
const PLAYER_POS := Vector2(250, GROUND_Y)
const BASE_POS := Vector2(140, 1450)
const DESIGN_WIDTH := 1080.0
var wave_manager := WaveManager.new()

func _ready() -> void:
	AudioManager.play_music("battle")
	_apply_premium_skin()
	_configure_responsive_layout()
	_setup_juice_hud()
	_setup_era_transition_overlay()
	add_child(wave_manager)
	wave_manager.spawn_enemy.connect(_on_spawn_enemy)
	wave_manager.start(GameState.world, GameState.wave)
	SignalBus.wave_started.emit(GameState.world, GameState.wave)
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
	SignalBus.equipment_changed.connect(_on_equipment_changed)
	SignalBus.era_changed.connect(_on_era_changed)
	SignalBus.technology_completed.connect(_on_technology_completed)
	_player_era = String(GameState.current_era)
	_enemy_era = ERA_PROFILE.era_for_wave(GameState.world, GameState.wave)
	_apply_player_era_visual(_player_era)
	_apply_enemy_era_visual(_enemy_era)
	_spawn_pet()
	inv_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/inventory/inventory_screen.tscn"))
	equip_button.pressed.connect(_toggle_equip_panel)
	battle_upg_button.pressed.connect(_open_upgrades)
	tech_button.pressed.connect(_toggle_research_panel)
	power_button.pressed.connect(_use_power_ability)
	shield_button.pressed.connect(_use_shield_ability)
	fury_button.pressed.connect(_use_fury_ability)
	speed_button.pressed.connect(_toggle_speed)
	pause_button.pressed.connect(_toggle_pause)
	close_equip_button.pressed.connect(func() -> void: equip_panel.visible = false)
	close_research_button.pressed.connect(func() -> void: research_quick_panel.visible = false)
	_refresh_currency()
	_refresh_power()
	_refresh_ability_buttons()
	_show_wave_intro()

func _apply_premium_skin() -> void:
	for button in [speed_button, pause_button]:
		PREMIUM_STYLE.style_button(button, "brown")
	for button in [inv_button, equip_button, battle_upg_button, tech_button]:
		PREMIUM_STYLE.style_button(button, "blue")
	for button in [power_button, shield_button, fury_button]:
		PREMIUM_STYLE.style_button(button, "brown")
	for pair in [[inv_button, "inventory"], [equip_button, "equipment"], [battle_upg_button, "upgrades"], [tech_button, "technology"], [power_button, "power"], [shield_button, "shield"], [fury_button, "fury"]]:
		var button: Button = pair[0]
		var icon_size := 56 if button.get_parent().name == "BottomBar" else 64
		button.icon = PREMIUM_STYLE.load_icon(BATTLE_ICONS[String(pair[1])], icon_size)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	for button in [retry_button, menu_button, upgrades_button, close_upgrades_button, close_equip_button, close_research_button]:
		PREMIUM_STYLE.style_button(button, "blue")
	PREMIUM_STYLE.style_button(item_equip_button, "green")
	PREMIUM_STYLE.style_button(item_sell_button, "gold")
	var result_box := result_panel.get_node_or_null("Panel") as PanelContainer
	var upgrades_box := upgrades_panel.get_node_or_null("Panel") as PanelContainer
	var equip_box := equip_panel.get_node_or_null("Panel") as PanelContainer
	var research_box := research_quick_panel.get_node_or_null("Panel") as PanelContainer
	for panel in [result_box, upgrades_box, equip_box, research_box]:
		if panel != null:
			PREMIUM_STYLE.style_panel(panel)

func _configure_responsive_layout() -> void:
	# En escritorio el modo "expand" puede ofrecer más ancho lógico que el diseño
	# vertical. Se centra el campo de batalla y las barras usan anchors para ocupar
	# todo el viewport sin recortar textos ni dejar una franja de color por defecto.
	var visible_rect := get_viewport().get_visible_rect()
	var visible_width := visible_rect.size.x
	var extra_width := maxf(visible_width - DESIGN_WIDTH, 0.0)
	$World.position.x = extra_width * 0.5
	# Los ColorRect son hijos directos de Node2D, por lo que sus anchors no siempre
	# se resuelven contra el viewport expandido. Fijar el rect evita zonas grises.
	bg_rect.position = visible_rect.position
	bg_rect.size = visible_rect.size
	$BattleArt.position = visible_rect.position
	$BattleArt.size = visible_rect.size
	ground_rect.position = Vector2(visible_rect.position.x, GROUND_Y)
	ground_rect.size = Vector2(visible_width, maxf(visible_rect.size.y - GROUND_Y, 0.0))
	$GroundDetail.position = Vector2(visible_rect.position.x, GROUND_Y)
	$GroundDetail.size = Vector2(visible_width, 12.0)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if upgrades_panel.visible:
		upgrades_panel.visible = false
	elif equip_panel.visible:
		equip_panel.visible = false
	elif research_quick_panel.visible:
		research_quick_panel.visible = false
	else:
		get_tree().change_scene_to_file(MENU_SCENE)

func _process(delta: float) -> void:
	if _paused or _transition_active:
		_refresh_ability_buttons()
		return
	var gameplay_delta := delta * GameState.battle_speed
	if _era_time_left > 0.0:
		_era_time_left = maxf(_era_time_left - gameplay_delta, 0.0)
		if _era_time_left <= 0.0:
			_era_time_scale = 1.0
	gameplay_delta *= _era_time_scale
	if _combo_timer > 0.0:
		_combo_timer = maxf(_combo_timer - gameplay_delta, 0.0)
		if _combo_timer <= 0.0:
			_combo_count = 0
			if is_instance_valid(_combo_label):
				_combo_label.visible = false
	for ability_id in _ability_cooldowns.keys():
		_ability_cooldowns[ability_id] = maxf(float(_ability_cooldowns[ability_id]) - gameplay_delta, 0.0)
	if _shield_active:
		_shield_remaining = maxf(_shield_remaining - gameplay_delta, 0.0)
		if _shield_remaining <= 0.0:
			_shield_active = false
			player.damage_taken_multiplier = 1.0
	if _fury_active:
		_fury_remaining = maxf(_fury_remaining - gameplay_delta, 0.0)
		if _fury_remaining <= 0.0:
			_fury_active = false
			player.damage_multiplier = 1.0
			player.attack_speed_multiplier = 1.0
	_refresh_ability_buttons()
	if research_quick_panel.visible and ResearchManager.is_researching():
		research_time_label.text = "%ds restantes" % ResearchManager.get_remaining_seconds()
	if state != State.FIGHTING:
		return
	ERA_COMBAT_RULES.tick_battle(self, _enemy_era, _era_rule_state, gameplay_delta)
	_register_new_enemies()
	wave_manager.tick(gameplay_delta)
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
	# La posicion del nodo es el punto de apoyo de los pies, no el centro del sprite.
	enemy.position = Vector2(SPAWN_X, SPAWN_Y_BASE + GameRng.randf_range(-SPAWN_Y_VAR, SPAWN_Y_VAR))
	enemies_container.add_child(enemy)
	enemy.set_era_visual(_enemy_era)
	_register_enemy(enemy)
	ERA_COMBAT_RULES.on_enemy_spawn(enemy, _enemy_era)
	if bool(WaveManager.get_enemy_data(enemy_id).get("is_boss", false)):
		AudioManager.play_sfx("boss")
		_show_combat_banner("¡BOSS!", String(WaveManager.get_enemy_data(enemy_id).get("name", "Enemigo élite")).to_upper(), Color(1.0, 0.36, 0.25), 2.0)
		_spawn_juice_burst_world(enemy.global_position + Vector2(0, -100), "BOSS", "PREPARATE", Color(1.0, 0.32, 0.2), backdrop.accent_color())

func _register_new_enemies() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null:
			_register_enemy(enemy)

func _register_enemy(enemy: Enemy) -> void:
	if enemy.has_meta("battle_registered"):
		return
	enemy.set_meta("battle_registered", true)
	enemy.died.connect(func() -> void:
		_on_enemy_killed(enemy.enemy_id, enemy.global_position, enemy)
	, CONNECT_ONE_SHOT)

func _on_enemy_killed(enemy_id: String, death_position: Vector2, enemy: Enemy = null) -> void:
	GameState.stats["enemies_killed"] = int(GameState.stats.get("enemies_killed", 0)) + 1
	_spawn_juice_burst_world(death_position + Vector2(0, -75), "KO", "", Color(1.0, 0.46, 0.25), backdrop.accent_color())
	_register_combo(death_position)
	var data := WaveManager.get_enemy_data(enemy_id)
	if data.is_empty():
		return
	if enemy != null:
		ERA_COMBAT_RULES.on_enemy_killed(self, enemy, _enemy_era, death_position)
	if bool(data.get("is_boss", false)):
		GameState.stats["bosses_killed"] = int(GameState.stats.get("bosses_killed", 0)) + 1
	var chance := float(data.get("loot_chance", 0.0)) + BuildingManager.get_bonus("loot_bonus") + GameState.get_effect_modifier("loot_bonus")
	chance = clampf(chance, 0.0, 1.0)
	var drop := LootManager.roll_drop(chance, GameState.world, GameState.wave, bool(data.get("is_boss", false)))
	if drop.is_empty():
		return
	var inventory_result := InventoryManager.add_item(drop)
	if inventory_result == "stored":
		_wave_drops.append(drop)
	elif inventory_result == "pending_full":
		_show_tutorial("Inventario lleno: el objeto quedó pendiente en Inventario.")

func _use_power_ability() -> void:
	if state != State.FIGHTING or float(_ability_cooldowns["power"]) > 0.0:
		return
	var target := _nearest_enemy()
	if target == null:
		return
	target.take_damage(maxi(int(round(player.damage * 4.0)), 1))
	_ability_cooldowns["power"] = 15.0
	_show_floating_text(target.global_position + Vector2(0, -90), "GOLPE PODEROSO", Color(1.0, 0.55, 0.25))
	AudioManager.play_sfx("ability")
	AudioManager.vibrate(45)

func _use_shield_ability() -> void:
	if state != State.FIGHTING or float(_ability_cooldowns["shield"]) > 0.0 or _shield_active:
		return
	_shield_active = true
	_shield_remaining = 5.0
	player.damage_taken_multiplier = 0.35
	_ability_cooldowns["shield"] = 25.0
	_show_tutorial("ESCUDO activo: daño reducido durante 5 segundos.")
	AudioManager.play_sfx("ability")
	AudioManager.vibrate(35)

func _use_fury_ability() -> void:
	if state != State.FIGHTING or float(_ability_cooldowns["fury"]) > 0.0 or _fury_active:
		return
	_fury_active = true
	_fury_remaining = 8.0
	player.damage_multiplier = 1.6
	player.attack_speed_multiplier = 1.5
	_ability_cooldowns["fury"] = 30.0
	_show_tutorial("FURIA activa: daño y velocidad aumentados durante 8 segundos.")
	AudioManager.play_sfx("ability")
	AudioManager.vibrate(35)

func _nearest_enemy() -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and enemy.is_alive():
			var distance: float = player.global_position.distance_squared_to(enemy.global_position)
			if distance < best_distance:
				best_distance = distance
				best = enemy
	return best

func _refresh_ability_buttons() -> void:
	if not is_instance_valid(power_button):
		return
	_update_ability_button(power_button, "GOLPE", "power")
	_update_ability_button(shield_button, "ESCUDO", "shield")
	_update_ability_button(fury_button, "FURIA", "fury")

func _update_ability_button(button: Button, title: String, ability_id: String) -> void:
	var remaining := float(_ability_cooldowns[ability_id])
	button.disabled = _paused or state != State.FIGHTING or remaining > 0.0
	button.text = "%s\n%.0fs" % [title, remaining] if remaining > 0.0 else title

func _toggle_speed() -> void:
	GameState.battle_speed = 2.0 if is_equal_approx(GameState.battle_speed, 1.0) else 1.0
	speed_button.text = "VELOCIDAD x%.0f" % GameState.battle_speed
	_show_tutorial("Velocidad de batalla: x%.0f" % GameState.battle_speed)

func _toggle_pause() -> void:
	_paused = not _paused
	pause_button.text = "CONTINUAR" if _paused else "PAUSAR"
	var should_process := not _paused and not _transition_active
	for node in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("allies") + get_tree().get_nodes_in_group("pets") + get_tree().get_nodes_in_group("projectiles"):
		node.set_process(should_process)
	player.set_process(should_process)
	base_building.set_process(should_process)
	backdrop.set_process(should_process)
	wave_manager.set_process(should_process)

func _set_combat_processing(enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("allies") + get_tree().get_nodes_in_group("pets") + get_tree().get_nodes_in_group("projectiles"):
		node.set_process(enabled)
	player.set_process(enabled)
	base_building.set_process(enabled)
	backdrop.set_process(enabled)
	wave_manager.set_process(enabled)

func _exit_tree() -> void:
	GameState.battle_speed = 1.0
	_era_time_scale = 1.0
	_era_time_left = 0.0

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
	var completed_world := GameState.world
	var completed_wave := GameState.wave
	var rewards := WaveManager.calculate_rewards(GameState.world, GameState.wave)
	_restore_between_waves()
	Economy.add_gold(int(rewards["gold"]))
	Economy.add_science(int(rewards["science"]))
	Economy.add_materials(int(rewards["materials"]))
	result_sub.text = "+%d oro   +%d ciencia   +%d materiales" % [rewards["gold"], rewards["science"], rewards["materials"]]
	_spawn_juice_burst_ui(Vector2(540, 870), "¡RECOMPENSA!", "+%d ORO" % int(rewards["gold"]), Color(1.0, 0.82, 0.3), backdrop.accent_color())
	AudioManager.play_sfx("coin")
	_advance_progression()
	GameState.stats["waves_completed"] = int(GameState.stats.get("waves_completed", 0)) + 1
	SignalBus.wave_completed.emit(completed_world, completed_wave)
	SignalBus.save_requested.emit()
	_show_drop_card()
	_end_battle(true)

func _restore_between_waves() -> void:
	var regen_ratio := clampf(GameState.get_effect_modifier("regen_between_waves"), 0.0, 1.0)
	if regen_ratio <= 0.0:
		return
	var player_restored := player.restore_health(maxi(1, int(round(float(player.max_health) * regen_ratio))))
	var base_restored := base_building.restore_health(maxi(1, int(round(float(base_building.max_health) * regen_ratio))))
	player_bar.value = player.health
	base_bar.value = base_building.health
	if player_restored > 0 or base_restored > 0:
		_show_tutorial("La Fogata restauró vida entre oleadas.")

func _show_drop_card() -> void:
	if _wave_drops.is_empty():
		item_card.visible = false
		return
	var best: Dictionary = _wave_drops[0]
	for drop in _wave_drops:
		if LootManager.item_power(drop) > LootManager.item_power(best):
			best = drop
	_current_drop = best
	for child in item_icon_holder.get_children():
		child.queue_free()
	var drop_icon := ItemIcon.new()
	drop_icon.custom_minimum_size = Vector2(116, 116)
	drop_icon.set_item(best)
	item_icon_holder.add_child(drop_icon)
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
	_spawn_juice_burst_ui(Vector2(540, 1070), "¡LOOT!", String(best.get("name", "Objeto nuevo")).to_upper(), LootManager.get_rarity_color(String(best.get("rarity", ""))), backdrop.accent_color())
	if String(best.get("rarity", "")) == "legendary":
		AudioManager.vibrate(100)

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
		_spawn_juice_burst_ui(Vector2(540, 1070), "EQUIPADO", "PODER AUMENTADO", Color(0.35, 0.9, 0.55), backdrop.accent_color())
	_hide_drop_card()

func _on_drop_sold() -> void:
	if _current_drop.is_empty():
		return
	var val := int(_current_drop.get("sell_value", 0))
	InventoryManager.sell_item(String(_current_drop["id"]))
	result_sub.text += "   [+%d oro]" % val
	_show_tutorial("Vendido por %d oro" % val)
	_spawn_juice_burst_ui(Vector2(540, 1070), "+%d ORO" % val, "VENTA COMPLETADA", Color(1.0, 0.82, 0.3), backdrop.accent_color())
	_hide_drop_card()

func _hide_drop_card() -> void:
	_current_drop = {}
	item_card.visible = false

func _spawn_pet() -> void:
	var pet_id := String(GameState.active_pet_id)
	var pet_data := DataLoader.get_pet_data(pet_id)
	if pet_data.is_empty():
		pet_id = "wolf"
		pet_data = DataLoader.get_pet_data(pet_id)
	var level := maxi(int(GameState.pet_levels.get(pet_id, 1)), WaveManager.global_wave_number(GameState.world, GameState.wave))
	GameState.active_pet_id = pet_id
	GameState.pet_levels[pet_id] = level
	_pet = PET_SCRIPT.new()
	_pet.call("setup_from_data", pet_id, pet_data, level, ERA_PROFILE.era_for_level(level))
	_pet.position = Vector2(390, SPAWN_Y_BASE + 8.0)
	units_container.add_child(_pet)
	_refresh_pet_label()

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
	for node in get_tree().get_nodes_in_group("pets"):
		node.set_process(false)
	player.set_process(false)
	base_building.set_process(false)
	result_title.text = "VICTORIA" if victory else "DERROTA"
	if not victory:
		SignalBus.player_died.emit()
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
		crystals_label.text = "◆ %d" % GameState.crystals

func _refresh_power() -> void:
	if not is_instance_valid(power_label):
		return
	var stats := StatsCalculator.player_final_stats(player)
	power_label.text = "PODER %d   ·   RECOMENDADO %d" % [StatsCalculator.combat_power(stats), WaveManager.recommended_power(GameState.world, GameState.wave)]

func _refresh_pet_label() -> void:
	var label := get_node_or_null("UI/EraStatusLabel") as Label
	if label == null:
		return
	if _pet != null:
		label.text = "JUGADOR: %s   ·   MASCOTA: LOBO Nv.%d" % [ERA_PROFILE.era_name(_player_era).to_upper(), int(_pet.get("level"))]
		label.visible = true
	else:
		label.visible = false

func _on_equipment_changed() -> void:
	if is_instance_valid(player) and state == State.FIGHTING:
		player.refresh_combat_stats()
		player_bar.max_value = player.max_health
		player_bar.value = player.health
		_refresh_power()

func _on_technology_completed(technology_id: String) -> void:
	if not is_inside_tree():
		return
	_refresh_research_quick()
	if is_instance_valid(player) and state == State.FIGHTING:
		player.refresh_combat_stats()
		player_bar.max_value = player.max_health
		player_bar.value = player.health
		_refresh_power()
	var tech: Dictionary = DataLoader.load_json("technologies/technologies.json").get(technology_id, {})
	_show_combat_banner("¡TECNOLOGÍA!", String(tech.get("name", technology_id)).to_upper(), Color(0.35, 0.85, 1.0), 1.8)

func _apply_enemy_era_visual(era_id: String) -> void:
	_enemy_era = era_id
	backdrop.set_era(era_id)
	bg_rect.color = backdrop.background_color()
	ground_rect.color = backdrop.ground_color()
	$GroundDetail.color = Color(backdrop.detail_color(), 0.48)
	var background_texture := load(ERA_PROFILE.get_asset(era_id, "background")) as Texture2D
	if background_texture != null:
		$BattleArt.texture = background_texture
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null:
			enemy.set_era_visual(era_id)
			ERA_COMBAT_RULES.on_enemy_spawn(enemy, era_id)
	_era_rule_state = ERA_COMBAT_RULES.new_state()
	_update_wave_label()

func _apply_player_era_visual(era_id: String) -> void:
	_player_era = era_id
	if is_instance_valid(player):
		player.set_era_visual(era_id)
	if is_instance_valid(base_building):
		base_building.set_era_visual(era_id)
	_update_wave_label()

func _update_wave_label() -> void:
	wave_label.text = "OLEADA %d-%d · ENEMIGOS: %s" % [GameState.world, GameState.wave, ERA_PROFILE.era_name(_enemy_era).to_upper()]
	_refresh_pet_label()

func _on_era_changed(era_id: String) -> void:
	if era_id == _player_era:
		return
	_transition_target = era_id
	if _transition_active:
		return
	_transition_active = true
	_set_combat_processing(false)
	var era_name: String = String(DataLoader.load_json("eras/eras.json").get(era_id, {}).get("name", era_id))
	var old_name: String = ERA_PROFILE.era_name(_player_era)
	_era_transition_overlay.play(old_name, era_name, ERA_PROFILE.get_transition_color(era_id), float(ERA_PROFILE.get_profile(era_id).get("transition_duration", 2.6)))
	AudioManager.play_sfx("era")
	_shake(9.0)
	AudioManager.vibrate(100)

func _on_era_transition_midpoint() -> void:
	if _transition_target.is_empty():
		return
	_apply_player_era_visual(_transition_target)
	era_banner_name.text = String(DataLoader.load_json("eras/eras.json").get(_transition_target, {}).get("name", _transition_target)).to_upper()
	era_banner.visible = true
	era_banner.modulate.a = 1.0
	era_banner.scale = Vector2.ONE
	_spawn_juice_burst_ui(Vector2(540, 560), "¡NUEVA ERA!", era_banner_name.text, backdrop.accent_color(), Color.WHITE)

func _on_era_transition_finished() -> void:
	_transition_active = false
	_set_combat_processing(not _paused)
	var era_name := ERA_PROFILE.era_name(_player_era)
	_show_combat_banner("ERA DEL JUGADOR ACTIVA", era_name.to_upper(), ERA_PROFILE.get_transition_color(_player_era), 1.6)
	var tw := create_tween()
	tw.tween_property(era_banner, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func() -> void: era_banner.visible = false)

func _setup_era_transition_overlay() -> void:
	_era_transition_overlay = ERA_TRANSITION_SCRIPT.new()
	_era_transition_overlay.name = "EraTransitionOverlay"
	_era_transition_overlay.z_index = 80
	_era_transition_overlay.midpoint_reached.connect(_on_era_transition_midpoint)
	_era_transition_overlay.transition_finished.connect(_on_era_transition_finished)
	$UI.add_child(_era_transition_overlay)

func _show_era_event(title: String, subtitle: String, color: Color) -> void:
	_show_combat_banner(title, subtitle, color, 1.4)
	AudioManager.play_sfx("ability")

func _start_era_hazard(kind: String, target_position: Vector2, delay: float, damage: int) -> void:
	var target: Combatant = base_building if kind == "siege" else player
	var hazard: Node2D = ERA_HAZARD_SCRIPT.new()
	hazard.setup_strike(kind, target, delay, damage, backdrop.accent_color())
	$World.add_child(hazard)
	hazard.global_position = target_position
	_show_era_event("¡PELIGRO!", "Impacto en %.1fs" % delay, backdrop.accent_color())

func _start_era_zone(zone_position: Vector2, duration: float, damage_per_second: float) -> void:
	var hazard: Node2D = ERA_HAZARD_SCRIPT.new()
	hazard.setup_zone(duration, damage_per_second, backdrop.accent_color())
	$World.add_child(hazard)
	hazard.global_position = zone_position
	_show_era_event("RADIACIÓN", "Aléjate de la zona", backdrop.accent_color())

func _start_time_fracture(duration: float, time_scale: float) -> void:
	_era_time_scale = clampf(time_scale, 0.15, 1.0)
	_era_time_left = maxf(duration, 0.5)
	for node in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("allies") + get_tree().get_nodes_in_group("pets"):
		var combatant := node as Combatant
		if combatant != null:
			combatant.apply_status("slow", duration, _era_time_scale)
	_show_era_event("FRACTURA TEMPORAL", "El tiempo se dobla", backdrop.accent_color())

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

func _toggle_equip_panel() -> void:
	if equip_panel.visible:
		equip_panel.visible = false
		return
	_refresh_equip_panel()
	equip_panel.visible = true
	research_quick_panel.visible = false
	upgrades_panel.visible = false

func _refresh_equip_panel() -> void:
	for c in equip_list.get_children():
		c.queue_free()
	var slots := ["weapon", "helmet", "armor", "gloves", "boots", "amulet"]
	for slot in slots:
		var inst = GameState.equipped_items.get(slot, null)
		var row_panel := PanelContainer.new()
		row_panel.custom_minimum_size = Vector2(780, 112)
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(0.06, 0.08, 0.13, 0.98)
		row_style.border_color = Color(0.24, 0.34, 0.52, 0.8)
		row_style.set_border_width_all(2)
		row_style.set_corner_radius_all(14)
		row_panel.add_theme_stylebox_override("panel", row_style)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row_panel.add_child(row)
		var icon := ItemIcon.new()
		icon.custom_minimum_size = Vector2(96, 96)
		if inst != null and inst is Dictionary:
			icon.set_item(inst)
		else:
			icon.set_item({"slot": slot, "rarity": "common", "name": slot})
		row.add_child(icon)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		row.add_child(info)
		var name_lbl := Label.new()
		name_lbl.add_theme_font_size_override("font_size", 29)
		if inst == null or not (inst is Dictionary):
			name_lbl.text = "%s\nVacío" % _slot_label(slot)
			name_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
		else:
			name_lbl.text = "%s  ·  %s Nv.%d" % [_slot_label(slot), inst.get("name", "?"), int(inst.get("level", 1))]
			name_lbl.add_theme_color_override("font_color", LootManager.get_rarity_color(str(inst.get("rarity", ""))))
		info.add_child(name_lbl)
		var detail_lbl := Label.new()
		detail_lbl.add_theme_font_size_override("font_size", 23)
		detail_lbl.add_theme_color_override("font_color", Color(0.62, 0.7, 0.83))
		if inst == null or not (inst is Dictionary):
			detail_lbl.text = "Encontrá un objeto en batalla"
		else:
			var detail_parts: PackedStringArray = []
			for stat_key in StatsCalculator.item_total_stats(inst).keys():
				if stat_key == "attack_range" and float(StatsCalculator.item_total_stats(inst)[stat_key]) <= 0.0:
					continue
				detail_parts.append(StatsCalculator.format_stat_line(stat_key, float(StatsCalculator.item_total_stats(inst)[stat_key])))
			detail_lbl.text = "  ·  ".join(detail_parts.slice(0, 3)) if not detail_parts.is_empty() else "Sin bonificadores"
		info.add_child(detail_lbl)
		if inst != null and inst is Dictionary:
			var btn := Button.new()
			btn.text = "QUITAR"
			btn.custom_minimum_size = Vector2(142, 78)
			btn.add_theme_font_size_override("font_size", 25)
			var sid := str(slot)
			btn.pressed.connect(func() -> void:
				InventoryManager.unequip_item(sid)
				_refresh_equip_panel()
			)
			row.add_child(btn)
		equip_list.add_child(row_panel)
	var dummy := Player.new()
	dummy.base_damage = 14
	dummy.base_max_health = 100
	dummy.attack_speed = 1.2
	var stats := StatsCalculator.player_final_stats(dummy)
	dummy.free()
	equip_stats.text = "DAÑO %d   ·   VIDA %d   ·   CRÍTICO %.1f%%\n%s · ALCANCE %d" % [int(stats["damage"]), int(stats["max_health"]), float(stats["critical_chance"]) * 100.0, "A DISTANCIA" if String(stats.get("attack_type", "melee")) == "ranged" else "CUERPO A CUERPO", int(round(float(stats.get("attack_range", 0.0))))]

func _slot_label(slot: String) -> String:
	return {"weapon": "ARMA", "helmet": "CASCO", "armor": "ARMADURA", "gloves": "GUANTES", "boots": "BOTAS", "amulet": "AMULETO"}.get(slot, slot.to_upper())

func _toggle_research_panel() -> void:
	if research_quick_panel.visible:
		research_quick_panel.visible = false
		return
	_refresh_research_quick()
	research_quick_panel.visible = true
	equip_panel.visible = false
	upgrades_panel.visible = false

func _refresh_research_quick() -> void:
	if ResearchManager.is_researching():
		var cur: Dictionary = GameState.current_research
		var tid := str(cur.get("technology_id", ""))
		var tech: Dictionary = DataLoader.load_json("technologies/technologies.json").get(tid, {})
		active_research_label.text = "Investigando: %s" % tech.get("name", tid)
		research_time_label.text = "%ds restantes" % ResearchManager.get_remaining_seconds()
	else:
		active_research_label.text = "Sin investigación (OFFLINE)"
		research_time_label.text = ""
	for c in research_list.get_children():
		c.queue_free()
	var techs: Dictionary = DataLoader.load_json("technologies/technologies.json")
	var eras: Dictionary = DataLoader.load_json("eras/eras.json")
	var ordered: Array = eras.values()
	ordered.sort_custom(func(a, b): return int(a.get("order", 99)) < int(b.get("order", 99)))
	for era in ordered:
		var eid := str(era.get("id", ""))
		var header := Label.new()
		header.text = str(era.get("name", "")).to_upper()
		header.add_theme_font_size_override("font_size", 36)
		header.add_theme_color_override("font_color", Color(0.9, 0.78, 0.4))
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		research_list.add_child(header)
		for tid in techs.keys():
			var tech2: Dictionary = techs[tid]
			if str(tech2.get("era", "")) != eid:
				continue
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var lbl := Label.new()
			lbl.custom_minimum_size = Vector2(480, 36)
			lbl.add_theme_font_size_override("font_size", 28)
			lbl.text = str(tech2.get("name", tid))
			if ResearchManager.is_completed(str(tid)):
				lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 0.35))
				lbl.text = "✓ " + lbl.text
			elif not bool(ResearchManager.can_start(str(tid))["ok"]):
				lbl.add_theme_color_override("font_color", Color(0.55, 0.57, 0.62))
			else:
				lbl.add_theme_color_override("font_color", Color(0.6, 0.82, 1.0))
			row.add_child(lbl)
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(180, 64)
			btn.add_theme_font_size_override("font_size", 26)
			var check: Dictionary = ResearchManager.can_start(str(tid))
			if ResearchManager.is_completed(str(tid)):
				btn.text = "HECHO"
				btn.disabled = true
			elif bool(check["ok"]):
				btn.text = "INVESTIGAR"
				var id_copy := str(tid)
				btn.pressed.connect(func() -> void:
					if ResearchManager.start_research(id_copy):
						_refresh_research_quick()
						_refresh_currency()
				)
			else:
				btn.text = "BLOQ"
				btn.disabled = true
			row.add_child(btn)
			research_list.add_child(row)

func _on_player_crit(target: Combatant, dmg: int) -> void:
	if not is_instance_valid(target):
		return
	_show_floating_text(target.global_position + Vector2(0, -70), "¡CRÍTICO! %d" % dmg, Color(1, 0.85, 0.2))
	_spawn_juice_burst_world(target.global_position + Vector2(0, -80), "CRÍTICO", "%d DAÑO" % dmg, Color(1.0, 0.82, 0.2), backdrop.accent_color())
	_shake(3.0)

func _setup_juice_hud() -> void:
	var juice_hud := Control.new()
	juice_hud.name = "JuiceHud"
	juice_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	juice_hud.grow_horizontal = Control.GROW_DIRECTION_BOTH
	juice_hud.grow_vertical = Control.GROW_DIRECTION_BOTH
	juice_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	juice_hud.z_index = 22
	$UI.add_child(juice_hud)
	_combo_label = Label.new()
	_combo_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_combo_label.offset_left = -225.0
	_combo_label.offset_top = 505.0
	_combo_label.offset_right = 225.0
	_combo_label.offset_bottom = 591.0
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combo_label.add_theme_font_size_override("font_size", 54)
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.28))
	_combo_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.08, 0.9))
	_combo_label.add_theme_constant_override("shadow_offset_x", 4)
	_combo_label.add_theme_constant_override("shadow_offset_y", 5)
	_combo_label.add_theme_constant_override("outline_size", 8)
	_combo_label.visible = false
	juice_hud.add_child(_combo_label)

func _show_wave_intro() -> void:
	_show_combat_banner("OLEADA %d-%d" % [GameState.world, GameState.wave], "ENEMIGOS: " + ERA_PROFILE.era_name(_enemy_era).to_upper(), backdrop.accent_color(), 1.8)

func _register_combo(death_position: Vector2) -> void:
	_combo_count += 1
	_combo_timer = 2.4
	if not is_instance_valid(_combo_label):
		return
	_combo_label.text = "RACHA x%d" % _combo_count
	_combo_label.visible = true
	_combo_label.modulate.a = 1.0
	_combo_label.scale = Vector2(0.76, 0.76)
	var tw := create_tween()
	tw.tween_property(_combo_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _combo_count > 1:
		AudioManager.play_sfx("combo")
	if _combo_count % 5 == 0:
		_spawn_juice_burst_world(death_position + Vector2(0, -80), "RACHA x%d" % _combo_count, "¡IMPARABLE!", Color(1.0, 0.62, 0.2), backdrop.accent_color())
		_shake(4.0)

func _spawn_juice_burst_world(pos: Vector2, title: String, subtitle: String, color: Color, accent: Color) -> void:
	var burst: Node2D = JUICE_BURST_SCRIPT.new()
	burst.call("setup", title, subtitle, color, accent)
	$World.add_child(burst)
	burst.global_position = pos

func _spawn_juice_burst_ui(pos: Vector2, title: String, subtitle: String, color: Color, accent: Color) -> void:
	var burst: Node2D = JUICE_BURST_SCRIPT.new()
	burst.call("setup", title, subtitle, color, accent)
	burst.position = pos
	$UI.add_child(burst)

func _show_combat_banner(title: String, subtitle: String, color: Color, duration: float) -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.grow_horizontal = Control.GROW_DIRECTION_BOTH
	holder.grow_vertical = Control.GROW_DIRECTION_BOTH
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.z_index = 24
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 184)
	panel.pivot_offset = Vector2(450, 92)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.035, 0.08, 0.88)
	style.border_color = Color(color, 0.78)
	style.set_border_width_all(3)
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 16
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 30)
	subtitle_label.add_theme_color_override("font_color", color)
	box.add_child(title_label)
	box.add_child(subtitle_label)
	panel.add_child(box)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.78, 0.78)
	holder.add_child(panel)
	$UI.add_child(holder)
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(duration)
	tw.tween_property(panel, "modulate:a", 0.0, 0.32)
	tw.tween_callback(holder.queue_free)

func _show_floating_text(pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 44)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08, 0.9))
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
