# PLONPY 0.2 — Bloque jugable integrado

Esta versión consolida el avance actual de Costa de Chispa y corrige la progresión de las tres primeras misiones.

## Flujo jugable

1. Al comenzar se activa **M001 — Despertar**.
2. El primer movimiento del jugador completa M001: **+50 XP / +25 CHISPA**.
3. Se activa **M002 — La Llamada**.
4. Al tocar la Chispa Primigenia se registra el núcleo y se completa M002: **+100 XP / +50 CHISPA**.
5. Se activa **M003 — Tres luces azules**.
6. Al descubrir Eco de Costa, Gota de Luz y Burbuja de Energía se completa M003: **+150 XP / +75 CHISPA**.
7. El HUD muestra núcleo, nivel, XP, CHISPA, misión y progreso.
8. **G** guarda y **L** carga.
9. **N** inicia una nueva partida y elimina el guardado anterior.

## Guardado

Ahora también se guardan:
- misión activa;
- progreso de cada misión;
- descubrimientos;
- núcleos;
- XP, nivel y CHISPA;
- posición del jugador;
- escena actual.

## Importante

Abrir el proyecto con **Godot 4.7.x** y ejecutar la escena principal.

Esta versión fue revisada estáticamente; el entorno de preparación no dispone del ejecutable de Godot para hacer una ejecución local automatizada.
