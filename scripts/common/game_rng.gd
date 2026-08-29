class_name GameRng
extends RefCounted

## RNG centralizado. Producción usa una secuencia aleatoria; debug puede fijar
## una semilla para reproducir drops, críticos y spawns.
static var _rng := RandomNumberGenerator.new()
static var _initialized := false
static var _debug_seed: int = 0

static func _ensure_initialized() -> void:
	if _initialized:
		return
	_rng.randomize()
	_initialized = true

static func set_seed(seed_value: int) -> void:
	_debug_seed = seed_value
	_rng.seed = seed_value
	_initialized = true

static func randomize() -> void:
	_debug_seed = 0
	_rng.randomize()
	_initialized = true

static func current_seed() -> int:
	return _debug_seed

static func randf() -> float:
	_ensure_initialized()
	return _rng.randf()

static func randi() -> int:
	_ensure_initialized()
	return _rng.randi()

static func randi_range(from: int, to: int) -> int:
	_ensure_initialized()
	return _rng.randi_range(from, to)

static func randf_range(from: float, to: float) -> float:
	_ensure_initialized()
	return _rng.randf_range(from, to)

static func pick(values: Array) -> Variant:
	if values.is_empty():
		return null
	return values[randi_range(0, values.size() - 1)]
