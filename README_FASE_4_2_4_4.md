# PLONPY — Fase 4.2 + 4.4
## Juice visual integrado — energía, partículas, luz y feedback

Este bloque parte de PLONPY 0.3 + Fase 4.1 y deja integrada la siguiente capa visual en Costa de Chispa.

### Incluido
- Chispa Primigenia:
  - pulso de emisión más vivo
  - luz dinámica
  - partículas ascendentes
  - reacción visual al recogerla
- Núcleo ZYL:
  - pulso propio
  - halo de luz violeta
  - partículas
  - remate visual al descubrirlo
- Eco de Costa / Gota de Luz / Burbuja de Energía:
  - flotación continua
  - brillo pulsante
  - luz local
  - partículas ambientales
  - remate visual al descubrirlos
- Fase 4.1 queda integrada mediante `CostaDeChispaFX` como nodo hijo, sin reemplazar `costa_de_chispa.gd`.
- Niebla, glow, partículas ambientales, agua reactiva y cámara dinámica se conservan.
- Guardado/carga y progresión no se sustituyen.

### Archivos principales modificados
- `scenes/chispa_primigenia.gd`
- `scenes/nucleo_zyl_01.gd`
- `scripts/exploration/discovery.gd`
- `scripts/fx/costa_de_chispa_fx.gd`
- `scenes/costa_de_chispa.tscn`

### Instalación recomendada
1. Haz una copia de seguridad de tu proyecto actual.
2. Extrae esta carpeta `PLONPY` completa.
3. Abre el proyecto desde `project.godot` en Godot 4.7.2.
4. Ejecuta F6/F5.

### Prueba visual
1. Acércate a la Chispa Primigenia.
2. Observa el pulso, halo y partículas.
3. Descubre el Núcleo ZYL.
4. Recorre la costa y recoge Eco de Costa, Gota de Luz y Burbuja de Energía.
5. Usa G para guardar y L para cargar y comprueba que los objetos ya descubiertos no reaparecen.

No requiere assets externos ni plugins.
