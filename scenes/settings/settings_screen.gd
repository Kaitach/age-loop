extends Control

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const PREMIUM_STYLE = preload("res://scripts/ui/premium_style.gd")

@onready var music_check: CheckButton = %MusicCheck
@onready var sfx_check: CheckButton = %SfxCheck
@onready var vibration_check: CheckButton = %VibrationCheck
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var back_button: Button = %BackButton
@onready var reset_button: Button = %ResetButton

func _ready() -> void:
	_configure_responsive_layout()
	_apply_premium_skin()
	music_check.button_pressed = bool(GameState.settings.get("music_enabled", true))
	sfx_check.button_pressed = bool(GameState.settings.get("sfx_enabled", true))
	vibration_check.button_pressed = bool(GameState.settings.get("vibration_enabled", true))
	music_slider.value = float(GameState.settings.get("music_volume", 1.0)) * 100.0
	sfx_slider.value = float(GameState.settings.get("sfx_volume", 1.0)) * 100.0
	music_check.toggled.connect(func(value: bool) -> void:
		AudioManager.set_music_enabled(value)
		_save_settings()
	)
	sfx_check.toggled.connect(func(value: bool) -> void:
		AudioManager.set_sfx_enabled(value)
		_save_settings()
	)
	vibration_check.toggled.connect(func(value: bool) -> void:
		GameState.settings["vibration_enabled"] = value
		_save_settings()
	)
	music_slider.value_changed.connect(func(value: float) -> void:
		AudioManager.set_music_volume(value / 100.0)
		_save_settings()
	)
	sfx_slider.value_changed.connect(func(value: float) -> void:
		AudioManager.set_sfx_volume(value / 100.0)
		_save_settings()
	)
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	reset_button.pressed.connect(_confirm_reset)

func _configure_responsive_layout() -> void:
	var visible_rect := get_viewport().get_visible_rect()
	var content_width := minf(920.0, maxf(visible_rect.size.x - 80.0, 640.0))
	var main_vbox := $MainVBox as Control
	main_vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main_vbox.position = Vector2(visible_rect.position.x + (visible_rect.size.x - content_width) * 0.5, visible_rect.position.y + 80.0)
	main_vbox.size = Vector2(content_width, maxf(visible_rect.size.y - 160.0, 1200.0))

func _apply_premium_skin() -> void:
	PREMIUM_STYLE.style_button(back_button, "blue")
	PREMIUM_STYLE.style_button(reset_button, "gold")
	PREMIUM_STYLE.style_title($MainVBox/Title, 64)
	for check in [music_check, sfx_check, vibration_check]:
		check.add_theme_color_override("font_color", Color(0.93, 0.95, 1.0, 1.0))
		check.add_theme_color_override("font_hover_color", Color.WHITE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MENU_SCENE)

func _save_settings() -> void:
	SignalBus.save_requested.emit()

func _confirm_reset() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Borrar partida"
	dialog.dialog_text = "¿Querés borrar la partida local? Esta acción no se puede deshacer."
	dialog.ok_button_text = "CONTINUAR"
	dialog.cancel_button_text = "CANCELAR"
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		var final_dialog := ConfirmationDialog.new()
		final_dialog.title = "Confirmación final"
		final_dialog.dialog_text = "Última confirmación: se perderán recursos, oleadas, objetos, equipo, edificios y tecnologías."
		final_dialog.ok_button_text = "BORRAR TODO"
		final_dialog.cancel_button_text = "CONSERVAR"
		add_child(final_dialog)
		final_dialog.confirmed.connect(_reset_save)
		final_dialog.popup_centered()
	)
	dialog.popup_centered()

func _reset_save() -> void:
	SaveManager.delete_save()
	GameState.gold = 0
	GameState.science = 0
	GameState.materials = 0
	GameState.crystals = 0
	GameState.world = 1
	GameState.wave = 1
	GameState.current_era = "prehistoric"
	GameState.future_era_preview = "medieval"
	GameState.inventory = []
	GameState.pending_items = []
	GameState.equipped_items = {}
	GameState.buildings = {}
	GameState.technologies = {}
	GameState.upgrades = {}
	GameState.effect_modifiers = {}
	GameState.effect_additions = {}
	GameState.unlocked_items = {}
	GameState.unlocked_buildings = {}
	GameState.unlocked_units = {}
	GameState.current_research = null
	GameState.pending_notifications = []
	GameState.stats = {"enemies_killed": 0, "bosses_killed": 0, "waves_completed": 0}
	GameState.tutorial_flags = {}
	GameState.last_played_at = int(Time.get_unix_time_from_system())
	SignalBus.save_requested.emit()
	get_tree().change_scene_to_file(MENU_SCENE)
