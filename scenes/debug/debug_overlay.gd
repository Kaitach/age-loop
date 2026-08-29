extends Control

var _panel: PanelContainer
var _status: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()

func toggle() -> void:
	visible = not visible
	if visible:
		_status.text = "Seed actual: %s" % (str(GameRng.current_seed()) if GameRng.current_seed() != 0 else "aleatoria")
		get_node("Panel/Content/Close").grab_focus()

func close() -> void:
	visible = false

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-430, -600)
	_panel.size = Vector2(860, 1200)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.075, 0.13, 0.99)
	panel_style.border_color = Color(0.9, 0.62, 0.22, 0.9)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(24)
	panel_style.content_margin_left = 34
	panel_style.content_margin_right = 34
	panel_style.content_margin_top = 30
	panel_style.content_margin_bottom = 30
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 14)
	_panel.add_child(content)
	var title := Label.new()
	title.text = "DEBUG MENU"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.76, 0.3))
	content.add_child(title)
	_status = Label.new()
	_status.text = "Seed actual: aleatoria"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 25)
	_status.add_theme_color_override("font_color", Color(0.62, 0.72, 0.86))
	content.add_child(_status)
	for spec in [
		["+1000 ORO", Callable(self, "_grant_gold")],
		["+100 CIENCIA", Callable(self, "_grant_science")],
		["+100 MATERIALES", Callable(self, "_grant_materials")],
		["+10 CRISTALES", Callable(self, "_grant_crystals")],
		["COMPLETAR INVESTIGACION", Callable(self, "_complete_research")],
		["AVANZAR OLEADA", Callable(self, "_advance_wave")],
		["DESBLOQUEAR SIGUIENTE ERA", Callable(self, "_unlock_era")],
		["CREAR ITEM LEGENDARY", Callable(self, "_create_legendary")],
		["FIJAR RNG EN 1337", Callable(self, "_set_debug_seed")],
		["RNG ALEATORIO", Callable(self, "_randomize_rng")],
		["BORRAR SAVE", Callable(self, "_delete_save")],
	]:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(0, 64)
		button.add_theme_font_size_override("font_size", 27)
		_style_button(button, Color(0.1, 0.16, 0.27), Color(0.18, 0.28, 0.44))
		button.pressed.connect(spec[1])
		content.add_child(button)
	var close_button := Button.new()
	close_button.name = "Close"
	close_button.text = "CERRAR (F1)"
	close_button.custom_minimum_size = Vector2(0, 76)
	close_button.add_theme_font_size_override("font_size", 30)
	_style_button(close_button, Color(0.5, 0.16, 0.16), Color(0.72, 0.24, 0.2))
	close_button.pressed.connect(close)
	content.add_child(close_button)

func _style_button(button: Button, normal_color: Color, hover_color: Color) -> void:
	for entry in [["normal", normal_color], ["hover", hover_color], ["pressed", normal_color.darkened(0.15)], ["focus", hover_color]]:
		var style := StyleBoxFlat.new()
		style.bg_color = entry[1]
		style.set_corner_radius_all(12)
		button.add_theme_stylebox_override(entry[0], style)

func _feedback(message: String) -> void:
	_status.text = message

func _grant_gold() -> void:
	Economy.add_gold(1000)
	_feedback("Oro: %d" % GameState.gold)

func _grant_science() -> void:
	Economy.add_science(100)
	_feedback("Ciencia: %d" % GameState.science)

func _grant_materials() -> void:
	Economy.add_materials(100)
	_feedback("Materiales: %d" % GameState.materials)

func _grant_crystals() -> void:
	Economy.add_crystals(10)
	_feedback("Cristales: %d" % GameState.crystals)

func _complete_research() -> void:
	if not ResearchManager.is_researching():
		_feedback("No hay investigación activa")
		return
	GameState.current_research["started_at"] = int(Time.get_unix_time_from_system()) - int(GameState.current_research.get("duration_seconds", 0))
	ResearchManager.check_completion()
	_feedback("Investigación completada")

func _advance_wave() -> void:
	if GameState.wave < 10:
		GameState.wave += 1
	elif GameState.world < 3:
		GameState.world += 1
		GameState.wave = 1
	SaveManager.save_game()
	_feedback("Oleada actual: %d-%d" % [GameState.world, GameState.wave])

func _unlock_era() -> void:
	var eras: Array = DataLoader.load_json("eras/eras.json").values()
	eras.sort_custom(func(a, b): return int(a.get("order", 99)) < int(b.get("order", 99)))
	var current_order := int(DataLoader.load_json("eras/eras.json").get(GameState.current_era, {}).get("order", 1))
	for era in eras:
		if int(era.get("order", 99)) == current_order + 1:
			GameState.current_era = String(era.get("id", GameState.current_era))
			SignalBus.era_changed.emit(GameState.current_era)
			SaveManager.save_game()
			_feedback("Era: %s" % era.get("name", GameState.current_era))
			return
	_feedback("Ya estás en la última era disponible")

func _create_legendary() -> void:
	var item := LootManager.roll_drop(1.0, GameState.world, GameState.wave, true)
	if item.is_empty():
		_feedback("No se pudo crear el item")
		return
	item["rarity"] = "legendary"
	item["name"] = "DEBUG · " + String(item.get("name", "Objeto"))
	item["sell_value"] = maxi(int(item.get("sell_value", 0)), 100)
	InventoryManager.add_item(item)
	_feedback("Item Legendary creado")

func _set_debug_seed() -> void:
	GameRng.set_seed(1337)
	_status.text = "Seed actual: 1337"

func _randomize_rng() -> void:
	GameRng.randomize()
	_status.text = "Seed actual: aleatoria"

func _delete_save() -> void:
	SaveManager.delete_save()
	_feedback("Save borrado; reinicia la app para empezar limpio")
