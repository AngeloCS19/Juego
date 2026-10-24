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
- **Lava** (`^`): no se sobrevuela en el plano espiritual, ni sobre un reflejo; se cruza en el plano normal hundiendo una piedra (queda fija, se tiñe de rojo y se puede marcar). Siempre tiene su eje. Un eje se dibuja con al menos dos casillas de río o lava: con una sola parecería una reflexión respecto a un punto.
- **La lava no toca el agua ni el vacío**: se separan con muros (Angelo: los tres juntos se ven raros). Agua junto a vacío sí es normal.
- Las salas son datos (`salas/*.json`). Cada una lleva `solucion`, y las pruebas la juegan. El orden lo da `SALAS` en `main.gd`, no el número del archivo.
- **Templo del Río**: termina con Narciso (jefe, 3 fases), la huida (3 tramos con punto de control, nada nuevo bajo presión) y el altar afuera. El diseño completo y las decisiones de Angelo están en el README ("El jefe: Narciso").
- **Prendas de Narciso**: opcionales. La salida siempre abre; el altar solo muestra las que el jugador recogió y tiene salida aunque no se complete.
- **Narciso en tiempo real**: en normal y en difícil se mueve solo; la dificultad solo cambia su velocidad (`RITMO_NORMAL`, `RITMO_DIFICIL`). El modo por turnos se descartó porque obligaba a contar acciones. Solo las pruebas juegan por turnos. Las arenas del jefe son simétricas respecto al eje.
- **Perder** siempre muestra la ventana de derrota (Reintentar desde el punto de control o Menú inicial). La dificultad se elige en el menú (Esc o botón Menú).
- **Dirección de arte** (Angelo, 2026-10-23): vectorial pulido, ambiente onírico, paleta tierra cálida. Todo personaje que hable tiene retratos 2D (estilo Hades) y **su propia tipografía**, que muestra su personalidad o emoción (`PERSONAJES` en `dialogo.gd`). Todo está en `docs/arte.md`, también la dirección de sonido y música (que se hará después).
- **Sonido** (Angelo, 2026-10-24): decisiones en `docs/arte.md` («Lo elegido en sonido»). La música sale de `tools/musica/` (`sonido.html` + `render.js`): si cambias un boceto, vuelve a grabar los `.ogg`. Cada pieza tiene versión normal y espiritual del mismo largo, en sincronía.
- El código debe crecer a otras transformaciones (rotación, traslación, homotecia) con nuevas subclases de `Transformacion`, sin tocar las salas.

## Forma de trabajar

- Angelo es principiante en Godot: cada PR explica el cambio de forma didáctica, y el README se actualiza cuando cambia una regla o la estructura.
- Ramas `claude/...`. Títulos de PR con el formato "Categoría: qué cambia" (Controles, Mecánica, Salas, Interfaz, Sprites…).
- Claude puede fusionar sus propios PRs (squash) tras probar. Angelo luego hace Pull en GitHub Desktop.
- Pruebas con Godot 4.5: `godot --headless --import` (en una copia nueva) y luego `godot --headless --script res://tests/test_reflexion.gd`, que debe dar `Fallos: 0`.
- No subas los `assets/sprites/*.svg.import`: Godot los regenera.
- Para diseñar salas usa `tools/solver.py` (BFS con las reglas de `sala.gd`): la solución sale de ahí, y con letras prohibidas comprueba que la sala exija su idea (por ejemplo, que sin `F` no se resuelva). `tools/formatear.py` escribe el JSON con su `solucion`. Si cambias reglas en `sala.gd`, cámbialas también en el solver.
- Si cambias el jefe, regenera su `solucion` con `tools/gen_jefe.gd` (lo juega con el código real).
- Angelo dibuja bocetos en pizarra: S salida, I inicio, negro vacío, azul río, rojo lava, círculo verde piedra.
