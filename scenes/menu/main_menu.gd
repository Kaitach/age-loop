extends Control

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const INVENTORY_SCENE := "res://scenes/inventory/inventory_screen.tscn"
const RESEARCH_SCENE := "res://scenes/research/research_screen.tscn"
const BASE_SCENE := "res://scenes/base/base_screen.tscn"

@onready var play_button: Button = %PlayButton
@onready var inventory_button: Button = %InventoryButton
@onready var research_button: Button = %ResearchButton
@onready var base_button: Button = %BaseButton
@onready var offline_panel: CenterContainer = %OfflinePanel
@onready var offline_time_label: Label = %OfflineTimeLabel
@onready var offline_gold_label: Label = %OfflineGoldLabel
@onready var offline_mat_label: Label = %OfflineMatLabel
@onready var claim_button: Button = %ClaimButton

var _pending_offline: Dictionary = {}

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)
	research_button.pressed.connect(_on_research_pressed)
	base_button.pressed.connect(_on_base_pressed)
	claim_button.pressed.connect(_on_claim_pressed)
	_check_offline()

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
	if int(_pending_offline.get("gold", 0)) == 0 and int(_pending_offline.get("materials", 0)) == 0:
		return
	offline_time_label.text = "Tiempo fuera: %s" % OfflineManager.format_elapsed(int(_pending_offline["elapsed"]))
	offline_gold_label.text = "ORO +%d" % int(_pending_offline["gold"])
	offline_mat_label.text = "MAT +%d" % int(_pending_offline["materials"])
	offline_panel.visible = true

func _on_claim_pressed() -> void:
	OfflineManager.claim(_pending_offline)
	offline_panel.visible = false
	_pending_offline = {}
