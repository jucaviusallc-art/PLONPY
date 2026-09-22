# PLONPY 0.1 — Vertical Slice jugable

Esta versión convierte la Costa de Chispa en un primer bloque jugable integrado.

## Qué incluye

- Movimiento del jugador con WASD.
- Gravedad y colisión del suelo.
- M001 — Despertar.
- M002 — La Llamada.
- M003 — Tres luces azules.
- Chispa Primigenia como descubrimiento de historia.
- Núcleo ZYL como núcleo coleccionable.
- Tres descubrimientos de exploración:
  - Eco de Costa
  - Gota de Luz
  - Burbuja de Energía
- XP, niveles y CHISPA.
- HUD dinámico de progreso y misión.
- Mensajes de descubrimiento.
- Guardado con `G` y carga con `L`.
- Estado persistente de núcleos, misiones, descubrimientos, XP, nivel y CHISPA.

## Controles

- `W A S D`: mover al jugador.
- `G`: guardar partida.
- `L`: cargar partida.

## Flujo de prueba

1. Ejecuta el proyecto con F6/F5.
2. Mueve a PLONPY: M001 debe completarse y aparecer M002.
3. Ve hacia la Chispa Primigenia (zona izquierda): se registra el núcleo y M002 se completa.
4. Busca las tres luces azules: al descubrir las tres, M003 se completa.
5. Pulsa `G` para guardar.
6. Pulsa `L` para comprobar que el estado se conserva.

## Nota

La estructura de los nuevos sistemas está separada en `scripts/missions`, `scripts/progression`, `scripts/exploration` y `scripts/ui` para que las siguientes regiones puedan reutilizar estos sistemas sin reconstruirlos.

Esta entrega no pretende cerrar todo PLONPY: es el primer vertical slice funcional sobre el proyecto real existente.
