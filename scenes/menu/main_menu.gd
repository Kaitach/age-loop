extends Control

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const INVENTORY_SCENE := "res://scenes/inventory/inventory_screen.tscn"
const RESEARCH_SCENE := "res://scenes/research/research_screen.tscn"
const BASE_SCENE := "res://scenes/base/base_screen.tscn"
const SETTINGS_SCENE := "res://scenes/settings/settings_screen.tscn"
const EQUIPMENT_SCENE := "res://scenes/equipment/equipment_screen.tscn"
const PREMIUM_STYLE = preload("res://scripts/ui/premium_style.gd")
const MENU_ICONS := {
	"play": "res://assets/ui/icons/play.png",
	"inventory": "res://assets/ui/icons/inventory.png",
	"book": "res://assets/ui/icons/book.png",
	"castle": "res://assets/ui/icons/castle.png",
	"gear": "res://assets/ui/icons/gear.png",
}

@onready var play_button: Button = %PlayButton
@onready var inventory_button: Button = %InventoryButton
@onready var research_button: Button = %ResearchButton
@onready var base_button: Button = %BaseButton
@onready var settings_button: Button = %SettingsButton
@onready var equipment_button: Button = %EquipmentButton
@onready var next_era_label: Label = %NextEraLabel
@onready var offline_panel: CenterContainer = %OfflinePanel
@onready var offline_time_label: Label = %OfflineTimeLabel
@onready var offline_gold_label: Label = %OfflineGoldLabel
@onready var offline_mat_label: Label = %OfflineMatLabel
@onready var offline_science_label: Label = %OfflineScienceLabel
@onready var claim_button: Button = %ClaimButton
@onready var notification_overlay: Control = %NotificationOverlay
@onready var notification_icon: Label = %NotificationIcon
@onready var notification_title: Label = %NotificationTitle
@onready var notification_body: Label = %NotificationBody
@onready var notification_continue: Button = %NotificationContinue

var _pending_offline: Dictionary = {}
var _debug_overlay: Control

func _ready() -> void:
	_configure_menu_layout()
	_apply_premium_skin()
	AudioManager.play_music("main")
	play_button.pressed.connect(_on_play_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)
	research_button.pressed.connect(_on_research_pressed)
	base_button.pressed.connect(_on_base_pressed)
	settings_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(SETTINGS_SCENE))
	equipment_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(EQUIPMENT_SCENE))
	claim_button.pressed.connect(_on_claim_pressed)
	notification_continue.pressed.connect(_on_notification_continue)
	var next_era_id := GameState.future_era_preview
	var next_era: Dictionary = DataLoader.load_json("eras/eras.json").get(next_era_id, {})
	next_era_label.text = "PRÓXIMA ERA: %s\nPróximamente" % String(next_era.get("name", next_era_id)).to_upper()
	_check_offline()
	_show_pending_notifications()
	if OS.is_debug_build():
		var debug_script := load("res://scenes/debug/debug_overlay.gd") as Script
		_debug_overlay = debug_script.new()
		_debug_overlay.name = "DebugOverlay"
		add_child(_debug_overlay)
	call_deferred("_animate_primary_button")

func _configure_menu_layout() -> void:
	var visible_rect := get_viewport().get_visible_rect()
	var content_width := minf(760.0, maxf(visible_rect.size.x - 64.0, 520.0))
	var content_height := minf(1500.0, maxf(visible_rect.size.y - 72.0, 900.0))
	$TitleBlock.position = Vector2(visible_rect.position.x + (visible_rect.size.x - content_width) * 0.5, visible_rect.position.y + 36.0)
	$TitleBlock.size = Vector2(content_width, content_height)
	$TitleBlock.add_theme_constant_override("separation", 14)
	$TitleBlock/Spacer.custom_minimum_size = Vector2(0, 18)

func _apply_premium_skin() -> void:
	PREMIUM_STYLE.style_button(play_button, "green")
	for button in [inventory_button, equipment_button, research_button, base_button, settings_button]:
		PREMIUM_STYLE.style_button(button, "blue")
	for pair in [[play_button, "play"], [inventory_button, "inventory"], [equipment_button, "shield"], [research_button, "book"], [base_button, "castle"], [settings_button, "gear"]]:
		var button: Button = pair[0]
		var icon_id := String(pair[1])
		var icon_path: String = String(MENU_ICONS.get(icon_id, "res://assets/ui/icons/shield.png"))
		button.icon = PREMIUM_STYLE.load_icon(icon_path, 64)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	$TitleBlock/Title.add_theme_constant_override("outline_size", 8)
	$TitleBlock/Title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.46, 1.0))
	$TitleBlock/VersionLabel.add_theme_constant_override("outline_size", 4)
	$TitleBlock/VersionLabel.add_theme_color_override("font_color", Color(0.68, 0.78, 0.88, 1.0))

func _animate_primary_button() -> void:
	if not is_instance_valid(play_button):
		return
	play_button.pivot_offset = play_button.size * 0.5
	var tw := create_tween().set_loops()
	tw.tween_property(play_button, "scale", Vector2(1.025, 1.025), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(play_button, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_debug_overlay.toggle()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		if _debug_overlay != null and _debug_overlay.visible:
			_debug_overlay.close()
			return
		if notification_overlay.visible:
			_on_notification_continue()
			return
		var dialog := ConfirmationDialog.new()
		dialog.title = "Salir"
		dialog.dialog_text = "¿Querés cerrar AGE LOOP?"
		dialog.confirmed.connect(func() -> void: get_tree().quit())
		add_child(dialog)
		dialog.popup_centered()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)

func _on_inventory_pressed() -> void:
	get_tree().change_scene_to_file(INVENTORY_SCENE)

func _on_research_pressed() -> void:
	get_tree().change_scene_to_file(RESEARCH_SCENE)

func _on_base_pressed() -> void:
	get_tree().change_scene_to_file(BASE_SCENE)

func _check_offline() -> void:
	_pending_offline = OfflineManager.get_offline_rewards()
	if int(_pending_offline.get("elapsed", 0)) < 60:
		return
	if int(_pending_offline.get("gold", 0)) == 0 and int(_pending_offline.get("materials", 0)) == 0 and int(_pending_offline.get("science", 0)) == 0:
		return
	offline_time_label.text = "Tiempo fuera: %s" % OfflineManager.format_elapsed(int(_pending_offline["elapsed"]))
	offline_gold_label.text = "ORO +%d" % int(_pending_offline["gold"])
	offline_mat_label.text = "MAT +%d" % int(_pending_offline["materials"])
	offline_science_label.text = "CIENCIA +%d" % int(_pending_offline["science"])
	offline_panel.visible = true

func _on_claim_pressed() -> void:
	OfflineManager.claim(_pending_offline)
	offline_panel.visible = false
	_pending_offline = {}

func _show_pending_notifications() -> void:
	if not is_instance_valid(notification_overlay) or GameState.pending_notifications.is_empty():
		if is_instance_valid(notification_overlay):
			notification_overlay.visible = false
		return
	var notification: Dictionary = GameState.pending_notifications.pop_front()
	if String(notification.get("type", "")) == "era":
		var era_id := String(notification.get("id", ""))
		var era_name := String(DataLoader.load_json("eras/eras.json").get(era_id, {}).get("name", era_id))
		notification_icon.text = "✦"
		notification_icon.add_theme_color_override("font_color", Color(1.0, 0.76, 0.25))
		notification_title.text = "¡NUEVA ERA!"
		notification_body.text = era_name + "\n\nNuevas tecnologías, unidades y objetos disponibles."
	else:
		var technology_id := String(notification.get("id", ""))
		var tech_name := String(DataLoader.load_json("technologies/technologies.json").get(technology_id, {}).get("name", technology_id))
		notification_icon.text = "✓"
		notification_icon.add_theme_color_override("font_color", Color(0.35, 0.92, 0.55))
		notification_title.text = "INVESTIGACIÓN COMPLETADA"
		notification_body.text = tech_name + "\n\nEl nuevo conocimiento ya está activo."
	notification_overlay.visible = true
	notification_continue.grab_focus()
	SignalBus.save_requested.emit()

func _on_notification_continue() -> void:
	notification_overlay.visible = false
	SignalBus.save_requested.emit()
	if not GameState.pending_notifications.is_empty():
		_show_pending_notifications()
