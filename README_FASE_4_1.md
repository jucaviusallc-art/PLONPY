# PLONPY — Fase 4.1
## Atmósfera + VFX + cámara + feedback

Este bloque añade el pulido visual de Costa de Chispa sin reemplazar la lógica que ya funciona.

### Archivo principal
`res://scripts/fx/costa_de_chispa_fx.gd`

### Instalación
1. Copia la carpeta `scripts/fx` dentro de tu proyecto PLONPY.
2. Abre `scenes/costa_de_chispa.tscn`.
3. Selecciona el nodo raíz `CostaDeChispa`.
4. Adjunta `costa_de_chispa_fx.gd` al nodo raíz.
5. Guarda la escena.
6. Ejecuta F6/F5.

### Qué hace
- Niebla ambiental suave.
- Glow ambiental.
- Partículas flotantes sin assets externos.
- Agua con material luminoso y pulso suave.
- Cámara con FOV dinámico durante el movimiento.
- Micro-bob de cámara al caminar.
- Flash visual de cámara al recoger un núcleo o registrar un descubrimiento.
- Mantiene las colisiones y objetos existentes.
- No modifica el sistema de guardado.

### Importante
No reemplaces `costa_de_chispa.gd`, `game_manager.gd`, `save_manager.gd` ni `mission_manager.gd`.
Este bloque se suma a ellos.

### Si ya existe un WorldEnvironment
El script reutiliza el `WorldEnvironment` existente y modifica solamente parámetros ambientales.
