# AGE LOOP

Prototipo 2D vertical offline-first hecho con Godot 4 y GDScript.

## Ejecutar

Abrir el proyecto con Godot 4.7.x y ejecutar la escena principal. La ventana base es 1080x1920 y el juego está configurado en portrait.

El loop incluye 13 eras encadenadas —de Prehistoria a Era Cuántica—, cada una
con costos, investigación puente, paleta y ambientación visual propia. El
combate tiene feedback de racha, críticos, bosses, loot, recompensas y cambios
de era.

## Validar

Desde la raíz del proyecto:

```text
godot --headless --path . --script res://tools/validate_data.gd
godot --headless --path . --script res://tests/scene_smoke_test.gd
```

Los tests funcionales están en `tests/` y se pueden ejecutar individualmente con `--script`.

La batería completa se ejecuta con:

```text
.\tools\run_tests.ps1 -Godot godot
```

En una build de desarrollo, `F1` abre el menú debug oculto para entregar
recursos, avanzar oleadas/eras, completar investigación, crear un Legendary,
fijar una semilla reproducible y borrar el save. No se muestra en una build
release.

## Exportar Android

El preset `Android` genera `builds/age-loop-debug.apk`.

El preset `Android AAB` requiere tener instalados en Godot la plantilla Android Gradle y en el SDK las plataformas/build-tools compatibles con la versión de la plantilla.

```text
godot --headless --path . --export-debug Android builds/age-loop-debug.apk
godot --headless --path . --export-debug "Android AAB" builds/age-loop-debug.aab
godot --headless --path . --export-release "Android AAB" builds/age-loop-release.aab
```

El AAB debug sirve para QA. El AAB release requiere una keystore de lanzamiento
configurada en Godot; la keystore y sus contraseñas deben permanecer fuera del
repositorio.
