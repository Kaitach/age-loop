extends Node

signal currency_changed
signal inventory_changed
signal equipment_changed
signal technology_completed(technology_id: String)
signal era_changed(era_id: String)
signal wave_started(world: int, wave: int)
signal wave_completed(world: int, wave: int)
signal player_died
signal save_requested
