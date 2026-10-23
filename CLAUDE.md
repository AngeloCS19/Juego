# Guía para agentes

Lee primero `README.md` (reglas, estructura, salas) y `docs/sprites.md` (arte). Todo en español.

## Qué es

Juego de puzzles cenital (tipo Zelda/Portal) para secundaria en Costa Rica (MEP, 8.º año: transformaciones del plano). La matemática se aprende jugando: es la mecánica, no una capa de puntos o preguntas. Si una idea se puede quitar sin que el puzzle cambie, no sirve.

## Decisiones de diseño vigentes

- **Celular es obligatorio**: todo debe poder jugarse cómodo con el dedo (botones grandes, deslizar, tocar casillas vecinas) además de teclado.
- **Una mecánica nueva por sala**, sin texto de tutorial. Nada de plataformas visuales que regalen la respuesta.
- **Habilidades**: una sola activa a la vez. Traspasar (cambiar de plano) es una habilidad; mientras se está en el plano espiritual no se puede elegir otra.
- **Reflejo** marca la piedra que el jugador mira. Solo las piedras marcadas aparecen reflejadas en el plano espiritual.
- **Plano espiritual**: se atraviesan objetos y agua. El vacío solo se cruza sobre un reflejo. Los muros siempre bloquean. Volver al plano normal sobre agua o vacío es caer, y la sala se reinicia. Sobre una piedra no se puede volver.
- **Movimiento**: caminar contra una piedra solo gira al jugador. Para empujar hay que mirarla y sostener la dirección (`TIEMPO_EMPUJE`).
- Las salas son datos (`salas/*.json`). Cada una lleva `solucion`, y las pruebas la juegan.
- El código debe crecer a otras transformaciones (rotación, traslación, homotecia) con nuevas subclases de `Transformacion`, sin tocar las salas.

## Forma de trabajar

- Angelo es principiante en Godot: cada PR explica el cambio de forma didáctica, y el README se actualiza cuando cambia una regla o la estructura.
- Ramas `claude/...`. Títulos de PR con el formato "Categoría: qué cambia" (Controles, Mecánica, Salas, Interfaz, Sprites…).
- Claude puede fusionar sus propios PRs (squash) tras probar. Angelo luego hace Pull en GitHub Desktop.
- Pruebas con Godot 4.5: `godot --headless --import` (en una copia nueva) y luego `godot --headless --script res://tests/test_reflexion.gd`, que debe dar `Fallos: 0`.
- No subas los `assets/sprites/*.svg.import`: Godot los regenera.
