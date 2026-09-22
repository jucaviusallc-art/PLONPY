# PLONPY 0.2 — BOSQUE DE VETAS

Bloque grande de continuación de Costa de Chispa.

## Qué añade

- Portal automático desde Costa de Chispa al completar M003.
- Nueva escena `res://scenes/regions/bosque_de_vetas.tscn`.
- Suelo con colisión física incorporada.
- Atmósfera nocturna/bioluminiscente.
- 5 Núcleos coleccionables:
  - Veta Luminosa — común.
  - Semilla de Cristal — común.
  - Eco de Ilin — común.
  - Ojo de Cristal — raro.
  - Susurro de VYRA — raro.
- 3 señales ambientales:
  - Semilla Voladora.
  - Corazón de Vetas.
  - Hongo de Luz.
- `nucleo_coleccionable.gd` reutilizable para futuras regiones.
- WorldManager 0.5 conserva el blindaje de Costa y añade la transición.
- HUD contextual del Bosque de Vetas.
- Persistencia al entrar al bosque y con G/L.

## Relación con el Documento Maestro

El Bosque de Vetas está definido como la subregión de vegetación bioluminiscente y primeros Núcleos Raros. El Documento Maestro identifica allí, entre otros, Ojo de Cristal y Susurro de VYRA, y mantiene M004 — Bajo el lago para Lago Espejo. Por eso PLONPY 0.2 no inventa una M004 para el bosque: deja esta subregión jugable y prepara el siguiente bloque narrativo.

## Instalación en el proyecto actual

1. Copiar `scenes/regions/bosque_de_vetas.tscn`.
2. Copiar `scripts/world/bosque_de_vetas.gd`.
3. Copiar `scripts/exploration/nucleo_coleccionable.gd`.
4. Copiar `scripts/exploration/bosque_sign.gd`.
5. Reemplazar `scripts/world/world_manager.gd` por el incluido en este bloque.
6. Reemplazar `scripts/ui/hud.gd` por el incluido en este bloque.
7. No reemplazar `discovery.gd` ni `jugador.gd`: se conservan las versiones actuales que ya funcionan.
8. No modificar manualmente `costa_de_chispa.tscn`: el portal aparece desde WorldManager.

## Prueba

Con una partida donde M003 esté completada, vuelve a Costa de Chispa y camina hacia el borde derecho. Debe aparecer el portal verde. Al tocarlo se abre el Bosque de Vetas.

En el bosque, recoge los dos Núcleos Raros y prueba G/L.

El entorno de preparación no tiene el ejecutable de Godot 4.7.2, así que la validación final de ejecución se hace en el Godot del proyecto.
