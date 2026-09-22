# PLONPY 0.1.1 — Bloque de jugabilidad inicial

Esta entrega corrige y consolida el primer bloque jugable de PLONPY sobre el proyecto real.

## Flujo jugable

1. Al iniciar aparece **M001 — Despertar**.
2. Al mover a PLONPY, M001 se completa: **+50 XP / +25 CHISPA**.
3. Se activa **M002 — La Llamada**.
4. Al tocar la Chispa Primigenia, se registra el núcleo y M002 se completa: **+100 XP / +50 CHISPA**.
5. Se activa **M003 — Tres luces azules**.
6. Los descubrimientos son:
   - Eco de Costa
   - Gota de Luz
   - Burbuja de Energía
7. El HUD muestra el progreso 1/3, 2/3 y 3/3.
8. Al completar M003: **+150 XP / +75 CHISPA**.

## Guardado

- `G` guarda la partida.
- `L` carga la partida.
- El guardado conserva posición, núcleos, descubrimientos, misiones, XP, nivel y CHISPA.

## Estructura funcional añadida

- `scripts/missions/mission_manager.gd`
- `scripts/progression/progression_manager.gd`
- `scripts/exploration/exploration_manager.gd`
- `scripts/exploration/discovery.gd`
- `scripts/ui/hud.gd`

## Correcciones de esta versión

- El HUD obtiene la misión directamente del estado persistente del GameManager.
- La misión actual ya no depende únicamente de una variable temporal del MissionManager.
- Se guarda el estado de la misión y su progreso.
- Se evita que una recarga de escena pierda la misión activa.
- Los descubrimientos se guardan automáticamente.
- Se mejoró la separación visual entre estadísticas, misión y controles.
- El suelo de Costa de Chispa conserva colisión física.

## Prueba recomendada

Ejecuta con `F6` o `F5` y comprueba el flujo completo sin modificar scripts.
