# PLONPY 0.3 — Validación integral de persistencia

## Qué cambia

Esta versión refuerza el sistema de guardado sin cambiar el flujo jugable actual.

### Estado persistente incluido

- Región actual.
- Escena actual.
- Posición exacta del jugador.
- Núcleos obtenidos.
- Descubrimientos obtenidos.
- Inventario (`item_id -> cantidad`).
- Plonpy descubiertos y Plonpy actual.
- Misiones completadas.
- Misión activa.
- Progreso de cada misión.
- Nivel.
- XP.
- CHISPA.
- Estado de inicio de partida.

`is_loading_game` sigue siendo transitorio y deliberadamente no se guarda.

## Compatibilidad

`SaveManager` acepta el formato anterior que guardaba el estado del `GameManager` directamente en la raíz del JSON. Al cargarlo, lo convierte internamente al formato nuevo.

## Seguridad del archivo

El guardado se escribe primero en un temporal y conserva un backup durante la operación. Además, antes de guardar y antes de cargar se comprueba que estén presentes los campos esenciales.

## Prueba manual de estrés

1. Ejecuta PLONPY.
2. Presiona `N` para comenzar una partida limpia.
3. Muévete para completar M001.
4. Toca la Chispa Primigenia para completar M002.
5. Obtén algunos descubrimientos de M003.
6. Muévete a una posición fácil de reconocer.
7. Presiona `G`.
8. Cierra completamente el juego/ejecutor de Godot.
9. Vuelve a ejecutar PLONPY.
10. Presiona `L`.
11. Comprueba:
   - misma posición;
   - mismos núcleos;
   - mismos descubrimientos;
   - misma misión y progreso;
   - mismo XP/nivel/CHISPA;
   - mismo inventario si ya existen objetos;
   - objetos recogidos no reaparecen.
12. Repite el ciclo G → cerrar → ejecutar → L varias veces.

## Resultado esperado en la consola

Debe aparecer, entre otros mensajes:

- `PLONPY: Tecla G detectada.`
- `PLONPY: Partida guardada correctamente.`
- `PLONPY: Guardado validado -> ...`
- `PLONPY: Tecla L detectada.`
- `PLONPY: Estado de partida restaurado.`
- `PLONPY: Partida cargada correctamente.`

## Nota de validación

El código fue revisado estáticamente en el entorno de preparación. La prueba real de cerrar/reabrir el ejecutable debe realizarse en Godot 4.7.2 en el equipo donde está instalado el proyecto.
