# PLONPY — Fase 3: UI/UX 0.2

## Qué incorpora
- Menú principal: Nueva partida, Continuar, Opciones y Salir.
- Menú de pausa con ESC.
- HUD definitivo compacto y legible.
- Notificaciones flotantes para misiones, núcleos, descubrimientos y guardado.
- Caja de diálogo narrativa.
- Compatibilidad con el HUD anterior mediante puente.
- Integración con GameManager, MissionManager y SaveManager.

## Integración
1. Copiar `scripts/ui/ui_manager.gd` y `scripts/ui/hud.gd` al proyecto.
2. Reemplazar `scripts/exploration/discovery.gd` por la versión del paquete.
3. Añadir al `[autoload]` de `project.godot`:
   `UIManager="res://scripts/ui/ui_manager.gd"`
4. Ejecutar el proyecto.

## Prueba global
1. F5.
2. Verificar que aparece el menú principal.
3. Nueva partida.
4. Mover al Plonpy y recoger un descubrimiento.
5. Verificar notificación.
6. Pulsar ESC y comprobar pausa.
7. Guardar desde pausa.
8. Volver al menú y comprobar que Continuar queda habilitado.
9. Continuar y comprobar restauración.

## Nota
No se modifica todavía el sistema de audio. La sección de Opciones deja preparado el lugar para el bloque de sonido que corresponde a la Fase 4.
