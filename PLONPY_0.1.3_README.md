# PLONPY 0.1.3

Corrección de compatibilidad con Godot 4.7.

## Qué se corrigió
Los nuevos managers dejaron de usar nombres de Autoload directamente durante el parseo de scripts.
Ahora se obtienen mediante `/root/...`, evitando el efecto dominó de errores de parser cuando Godot está recargando `project.godot`.

## Prueba
1. Cierra Godot.
2. Sustituye el proyecto por esta versión.
3. Abre `project.godot`.
4. Espera la importación.
5. Ejecuta F6/F5.

En el editor, los Globales deberían incluir:
- GameManager
- SaveManager
- ProgressionManager
- ExplorationManager
- MissionManager

La primera ejecución debe mostrar M001 — Despertar.
