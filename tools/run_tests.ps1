param(
    [string]$Godot = "godot"
)

# Asegura que los PNG nuevos de cada era estén importados antes de ejecutar
# pruebas que instancian sprites dinámicos por ruta.
& $Godot --headless --editor --path (Get-Location).Path --import --quit | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Falló la importación de assets con código $LASTEXITCODE"
}

$scripts = @(
    "res://tools/validate_data.gd",
    "res://tests/scene_smoke_test.gd",
    "res://tests/era_transition_test.gd",
    "res://tests/ui_polish_test.gd",
    "res://tests/combat_behavior_test.gd",
    "res://tests/gameplay_e2e_test.gd",
    "res://tests/smoke_test.gd",
    "res://tests/wave_test.gd",
    "res://tests/economy_test.gd",
    "res://tests/save_test.gd",
    "res://tests/research_test.gd",
    "res://tests/era_progression_test.gd",
    "res://tests/offline_test.gd",
    "res://tests/loot_test.gd",
    "res://tests/building_test.gd"
)

foreach ($script in $scripts) {
    & $Godot --headless --path (Get-Location).Path --script $script
    if ($LASTEXITCODE -ne 0) {
        throw "Falló $script con código $LASTEXITCODE"
    }
}

Write-Output "Todos los tests terminaron correctamente."
