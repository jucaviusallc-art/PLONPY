# PLONPY — BLOQUE 02: COSTA DE CHISPA

## Objetivo
Este bloque completa la base física del World Building de Costa de Chispa:

- Suelo con colisión.
- Cuatro límites físicos invisibles.
- Límite lógico de seguridad para el jugador.
- Gravedad.
- Recuperación si el jugador cae.
- Distribución formal de los coleccionables existentes.
- Preparación para ampliar el mapa.

## Archivos

`res://scripts/world/world_manager.gd`
Construye automáticamente los límites de Costa de Chispa al entrar en la escena.

`res://scripts/player/jugador.gd`
Nueva versión del controlador del jugador.

## Integración

1. Copia `world_manager.gd` a:
   `res://scripts/world/world_manager.gd`

2. Copia `jugador.gd` a:
   `res://scripts/player/jugador.gd` y, si tu escena todavía usa
   `res://scenes/jugador.gd`, reemplaza ese archivo con este contenido.

3. En `project.godot`, agrega este Autoload:
   `WorldManager="res://scripts/world/world_manager.gd"`

   Colócalo después de `SaveManager` y antes de iniciar el juego.

4. No elimines ni reemplaces `GameManager`, `MissionManager` o
   `SaveManager` de tu versión actual.

## Importante
El sistema coloca automáticamente, si existen en la escena:

- ChispaPrimigenia
- NucleoZyl01
- EcoDeCosta
- GotaDeLuz
- BurbujaDeEnergia

No es necesario moverlos manualmente.

## Navegación
Todavía NO se crea una NavigationRegion3D porque Costa de Chispa actualmente
no tiene NPCs que necesiten pathfinding. Para el jugador, las colisiones físicas
son la solución correcta. Cuando aparezca el primer NPC, añadiremos la malla
de navegación sobre la geometría definitiva, no antes.

## Prueba
Ejecuta la escena y comprueba:

1. El jugador no atraviesa el suelo.
2. No puede salir por los cuatro lados.
3. Puede recorrer toda la zona.
4. Los coleccionables están separados.
5. G/L continúa funcionando.
6. Al cerrar y abrir, los objetos recogidos siguen desaparecidos.

No se ha probado el runtime de Godot fuera de tu equipo; la integración debe
validarse ejecutando el proyecto en Godot 4.7.2.
