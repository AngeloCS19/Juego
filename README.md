# Juego Didáctico

Juego de puzzles con vista cenital donde se aprende matemática sin darse cuenta. El jugador cambia entre el plano normal y un plano espiritual que transforma los objetos sagrados. Cada templo enseña una transformación del plano (programa del MEP, 8.º año). El juego se llama **Espejismo**. El primero es el **Templo del Río**: reflexión respecto a un eje.

## Cómo abrirlo

1. Instala [Godot 4.5 o más reciente](https://godotengine.org/download) (la versión estándar, no la .NET).
2. En el gestor de proyectos de Godot: **Importar** y elige el archivo `project.godot` de esta carpeta.
3. Presiona **F5** (o el botón ▶ arriba a la derecha) para jugar.

Si tu Godot es más nuevo que 4.5, puede preguntar si quieres convertir el proyecto: acepta.

## Controles

El juego se diseña para PC y para celular, así que todo se puede hacer con teclado o con el dedo (en la PC, el mouse funciona como dedo).

| Acción | Teclado | Pantalla táctil o mouse |
|---|---|---|
| Moverse una casilla (contra una piedra, solo girar hacia ella) | Flechas o WASD | Deslizar en esa dirección, o tocar una casilla vecina |
| Empujar la piedra que miras | Mantener presionada esa dirección | Mantener el dedo después de deslizar, o sobre la piedra |
| Elegir habilidad | 1 a 9 | Tocar su botón (abajo a la izquierda) |
| Usar la habilidad activa | Espacio | Botón **Usar**, o tocar al personaje |
| Reiniciar la sala | R | Botón **Reiniciar** |
| Girar la cámara 90° | Q / E | Botones **Girar** |
| Abrir el menú (pausa y dificultad) | Esc | Botón **Menú** |

### Menús (`menu.gd`)

Una sola ventana, `Menu`, sirve para tres cosas: el **menú inicial** (Jugar o Continuar, Empezar de nuevo, Dificultad, Música, y tres retratos para elegir el personaje: niño, niña o espíritu; el elegido lleva borde dorado y se cambia tocándolo, con el mouse o con izquierda/derecha), la **pausa** (Esc o el botón Menú) y la **derrota**. Perder (caer al vacío o al agua, o que Narciso te venza) siempre muestra la ventana de derrota, con **Reintentar** (la sala, la fase o el tramo ya volvió a empezar: ese es el punto de control) y **Menú inicial**. El título va en Cinzel (mayúsculas romanas), y los textos y botones en un recuadro oscuro con borde dorado. El **menú inicial** muestra detrás una ilustración fija del templo (`assets/ilustracion_templo.svg`): el frontón sobre columnas, el río cruzando al frente y la luna reflejada en el agua, igual que Narciso se refleja. La pausa y la derrota solo oscurecen la sala.

Mientras el menú está abierto el juego se pausa con `get_tree().paused = true`. Para que los botones sigan funcionando, `Main` usa `process_mode = ALWAYS`, y `Pivote`, que contiene la sala, usa `PAUSABLE`: así la sala y su reloj se detienen.

Habilidades: **Traspasar** cambia de plano; **Reflejo** marca la piedra que tienes enfrente.

### Modo debug (solo para el desarrollador)

Al jugar desde el editor (F5) aparece arriba a la derecha un botón rojo **Debug**. Abre un menú para saltar a cualquier sala y para activar **Todas las habilidades** (vale para todas las salas hasta que lo desactives; la sala se reinicia al cambiarlo). El botón solo existe si `OS.is_debug_build()` es verdadero: en el editor sí, y en una exportación para jugadores, con "Export With Debug" desactivado, no. El código está en `_crear_menu_debug()` de `main.gd`.

## Cómo está organizado

```
main.tscn                 Escena principal (los nodos)
scripts/main.gd           Controles (teclado y táctiles), cámara y orden de las salas
scripts/sala.gd           Reglas de una sala y cómo se dibuja
scripts/sala_jefe.gd      Narciso, el jefe (extiende Sala)
scripts/sala_huida.gd     Los tramos de la huida (extiende Sala)
scripts/sala_altar.gd     El altar de Narciso, afuera del templo (extiende Sala)
scripts/menu.gd           Ventana de menú inicial, pausa y derrota
scripts/musica.gd         Música del templo: capas, cruce al Traspasar y volumen
scripts/barra_jefe.gd     Vida de Narciso (su cabeza con una flor por pétalo) y corazones del jugador, solo en la sala del jefe
shaders/                  Efectos que corren en la tarjeta de video: desenfoque.gdshader (fondo del anuncio) y aparecer.gdshader (la cabeza de Narciso aparece de abajo hacia arriba al terminar su primer diálogo)
scripts/dialogo.gd        Ventana de diálogo con retrato (estilo Hades)
scripts/barra_habilidades.gd  Hotbar de habilidades (abajo al centro, siempre visible)
scripts/habilidades/
  habilidad.gd            Molde general de cualquier habilidad
  traspasar.gd            Cambiar de plano
  reflejo.gd              Marcar la piedra de enfrente para reflejarla
scripts/transformaciones/
  transformacion.gd       Molde general de cualquier transformación
  reflexion.gd            La reflexión (primer templo)
salas/rio_00.json ...     Cada sala, descrita como datos
assets/sprites/           Dibujos SVG (ver docs/sprites.md y docs/arte.md)
assets/retratos/          Retratos grandes para los diálogos
assets/musica/            Música grabada (.ogg), sale de tools/musica/
tests/test_reflexion.gd   Pruebas automáticas
tools/solver.py           Buscador de soluciones para diseñar salas (Python)
tools/formatear.py        Escribe una sala con su "solucion"
tools/gen_jefe.gd         Genera la "solucion" del jefe
tools/musica/             Bocetos de sonido (sonido.html) y el script que graba la música (render.js)
```

### Los nodos de la escena

Si abres `main.tscn` en Godot verás este árbol:

- **Main** (Node2D) tiene el script `main.gd`. Es el director: carga salas y escucha el teclado.
- **Pivote** (Node2D) es un punto en el centro de la pantalla. La sala se coloca dentro de él, así que girar el pivote gira toda la sala. Así funciona la rotación de cámara.
- **Interfaz** (CanvasLayer) es una capa que no gira ni se mueve con el mundo. Dentro van los botones, el menú y los diálogos; ya no hay texto fijo arriba.

La sala no aparece en el árbol porque `main.gd` la crea por código (`Sala.desde_archivo()`) cada vez que empieza una sala nueva. El menú (`Menu`) también se crea por código, dentro de **Interfaz**.

### Ideas de Godot que usa el código

- **`class_name`**: al poner `class_name Sala` arriba de un script, cualquier otro script puede usar `Sala` como un tipo, sin cargar el archivo a mano.
- **Señales** (`signal completada`): la sala avisa "me resolvieron" sin saber quién escucha. `main.gd` se conecta con `sala.completada.connect(...)` y carga la siguiente. Así la sala no depende de `main`.
- **`_draw()` y `queue_redraw()`**: la sala se dibuja a sí misma en `_draw()`, pintando los sprites SVG de `assets/sprites/` con `draw_texture_rect()`. Cuando algo cambia, `queue_redraw()` le pide a Godot que vuelva a llamar a `_draw()`. En el plano espiritual se usa una silueta blanca de cada sprite teñida de celeste (`_silueta()` en `sala.gd`).
- **Tween**: anima una propiedad en el tiempo. El giro de cámara usa uno sobre `pivote.rotation`; antes de empezar otro se detiene el anterior (`kill()`) y el destino se calcula desde `giro`, para que girar rápido nunca deje el mapa torcido.
- **`_unhandled_input(evento)`**: Godot llama esta función cada vez que se presiona una tecla.
- **`_process(delta)`**: Godot la llama en cada cuadro. Ahí se mide cuánto tiempo se sostiene una dirección para empujar.
- **`Vector2i`**: un par de números enteros (x, y). Lo usamos para las casillas de la cuadrícula. `y` crece hacia abajo.

### Las reglas de la sala (`sala.gd`)

- En el **plano normal**, las piedras son obstáculos: caminar contra una solo te gira hacia ella. Para empujarla hay que mirarla y sostener la dirección `TIEMPO_EMPUJE` segundos (`_process()` en `main.gd` mide el tiempo y llama a `sala.empujar_enfrente()`). Las redondas verde claro se pueden empujar; los bloques cuadrados con raíces están fijos. Una piedra empujada al agua queda flotando y se puede pisar.
- En el **plano espiritual**, el piso se desvanece y queda la cuadrícula. Las piedras originales se vuelven fantasmas que se pueden atravesar, el agua se puede cruzar y el vacío solo sobre un reflejo celeste. La lava nunca se cruza en este plano. Los muros siempre bloquean.
- La **lava** es lo opuesto del río: no se sobrevuela en el plano espiritual (ni sobre un reflejo). Solo se cruza en el plano normal, empujando una piedra a la lava: queda flotando, fija para siempre, y se pisa como un puente. Siempre tiene su eje de reflexión, como el río. La piedra hundida se tiñe de rojo, se puede marcar con Reflejo y, como está sobre el eje de la lava, su reflejo en ese eje cae en el mismo lugar (un punto invariante).
- **Prendas de Narciso:** cuatro salas guardan una prenda (`prenda` en el JSON). Es de un espíritu: solo existe en el plano espiritual. Son **opcionales**: la salida siempre está abierta. `main.gd` cuenta las prendas que el jugador se llevó al salir de cada sala (`prendas`), y en el altar del final solo aparecen esas.
- Una sala puede tener varios ejes (`transformaciones` en `sala.gd`): cada piedra marcada aparece reflejada respecto a cada uno.
- **Cambiar de plano** es una habilidad del jugador (`cambiar_plano()` en `sala.gd`). Si vuelves al plano normal parado sobre el vacío o el agua, caes y la sala se reinicia (señal `caida`). Encima de una piedra no se puede volver.
- **Solo las piedras marcadas con Reflejo** aparecen reflejadas en el plano espiritual. Una piedra marcada lleva un anillo celeste en el plano normal. El sprite del jugador gira hacia donde mira: esa es la casilla que apuntan las habilidades (`mirando` en `sala.gd`).
- La función `imagen_en(c)` es el corazón matemático: pregunta si alguna piedra marcada, al aplicarle la transformación, cae en la casilla `c`.

### Diálogos (`dialogo.gd`)

Narciso habla entre fases, al empezar la huida y al descansar en el altar. Las líneas viven en los JSON de las salas, no en el código:

```json
"dialogo": [
	{"quien": "narciso", "animo": "sereno", "texto": "Vete. Nadie me separa de mi reflejo."}
]
```

- `"dialogo"` se muestra al entrar a la sala. En el jefe, cada fase lleva el suyo y se muestra al empezar esa fase (señal `fase_nueva`).
- `"dialogo_final"` del altar se muestra cuando Narciso descansa.
- `quien` elige el personaje y `animo` su retrato (ver `PERSONAJES` en `dialogo.gd`). Narciso tiene `sereno`, `enojado` y `furioso` (en la huida: las letras tiemblan con el efecto `[shake]` de `RichTextLabel`).
- Cada personaje tiene su tipografía, que muestra cómo es: Narciso habla en cursiva fina y elegante (Cormorant Garamond), y los nombres van en mayúsculas romanas (Cinzel). Las fuentes están en `assets/fuentes/` con su licencia OFL, que permite usarlas gratis en el juego.

La ventana pausa el juego (como el menú). El texto aparece letra por letra con un `Tween` sobre `visible_ratio`; tocar la pantalla, Espacio o Enter muestra todo el texto, y otra vez pasa a la siguiente línea. Las líneas no explican la mecánica: son historia, no tutorial. El jugador no habla (como Link en Zelda), así sirve cualquiera de los tres personajes.

### Transiciones y efectos

- **Entre salas** (`cortina.gd`): un espejo que se cierra. Dos mitades oscuras avanzan hasta juntarse en el eje de la sala que termina (una línea punteada celeste); con la pantalla tapada se carga la sala siguiente y el espejo se abre. Si el eje es vertical (o la cámara está girada), se cierra de lado. Usa un `Tween` con pasos en fila: cerrar, `tween_callback` (cargar la sala), esperar, abrir.
- **Al Traspasar** (`_dibujar_mancha()` en `sala.gd`): una mancha de tinta del color del plano nuevo se expande desde el jugador hasta el borde de la pantalla, y se va desvaneciendo mientras llega, así casi no la tapa. El borde es un círculo deformado por una suma de ondas (`sin`) con amplitudes y desfases al azar, así que nunca sale igual. Se dibuja con `draw_colored_polygon`.
- **Al Reiniciar** (`rebobinar()` en `cortina.gd`, botón Reiniciar o tecla R): la misma cortina que entre salas, pero en lugar del eje aparece en el centro una flecha circular celeste que da una vuelta hacia atrás, como rebobinando. La sala se reinicia con la pantalla tapada. Un segundo `Tween`, en paralelo, lleva la variable `flecha` de 0 a 1, y `_dibujar_flecha()` calcula el giro a partir de ese número.

### Animaciones (`sala.gd`)

Las reglas cambian al instante; las animaciones solo cambian el **dibujo**. Así las pruebas no tienen que esperar nada. Cada cuadro, `_process(delta)` acerca la posición *dibujada* (`_vis`, y `"vis"` en cada piedra) a la posición *real* a velocidad fija (`DURACION_PASO`, 0,12 s por casilla; un empujón es más lento, `DURACION_EMPUJE`, 0,3 s, lo que dura el sonido de la piedra que se arrastra). Si la diferencia es grande (la sala se reinició), salta de una vez.

- **Caminar y empujar:** el personaje y la piedra se deslizan; el personaje crece un poco a mitad del paso, como un saltito.
- **Reflejo:** al marcar, el anillo aparece grande y se asienta. Al entrar al plano espiritual, cada reflejo viaja (`DURACION_REFLEJO`, 0,6 s) en línea recta desde su piedra hasta su lugar al otro lado del eje, cruzándolo en ángulo recto: sale rápido y frena al llegar. Empieza cuando la mancha de Traspasar ya casi pasó, para que no la tape: es lo más importante de ver.
- **Caer:** el personaje gira y se achica donde cayó. `main.gd` espera `DURACION_CAIDA` antes de abrir la ventana de derrota, y mientras tanto no se puede actuar (`cayendo()`).
- **Narciso:** flota (sube y baja), se desliza entre casillas, su corona gira (más rápido cuanto más enojado) y al recibir un golpe destella en blanco y tiembla.
- **Entrar al espejo:** al llegar a la salida el personaje se desliza al centro del espejo, se achica y se desvanece con un brillo (`DURACION_SALIDA`, 0,6 s). `completada` se emite igual y al instante; `main.gd` espera esa duración antes de la cortina, y mientras tanto `cayendo()` (que cubre la caída y la entrada) bloquea al jugador.
- **Prenda:** al recogerla, su sprite aparece sobre la cabeza, sube, crece, brilla y se desvanece (`DURACION_PRENDA`, 1 s), sin texto (`_dibujar_prenda()`).
- **Agua y lava:** siguen siendo sprites lisos, pero encima se dibuja un movimiento suave. El agua tiene dos brillos tenues que ondulan despacio (`_animar_agua()`). La lava es espesa (`_animar_lava()`): cada casilla tiene dos puestos de burbuja con un ciclo de 2 a 4 s; la burbuja crece despacio en un punto de la casilla, revienta con un anillo y en el ciclo siguiente aparece en otro punto (`_azar()` saca ese punto de la casilla, el puesto y el número de ciclo). Cada casilla usa su posición como fase, así el río no parpadea todo a la vez. Se dibujan solo en el plano normal, cada cuadro, porque `_process` ya llama a `queue_redraw()`.

### Música (`musica.gd`)

La música del Templo del Río es de ocarina y marimba, con tres motivos que se alternan (unos 65 s antes de repetirse). Las decisiones de Angelo están en `docs/arte.md`.

- **Capas.** La pieza viene separada en marimba, bajo y ocarina, y se arma a lo largo del templo: al inicio solo suena la marimba, el bajo entra en la sala 7 y la ocarina en la 13 (`Musica.DESDE`, índices de `SALAS`). Una capa nueva entra despacio (`ENTRADA`, 3 s).
- **Los dos planos.** Cada capa está grabada dos veces, con el mismo largo: plano normal y plano espiritual (filtrada, con más eco y un brillo cristalino). Los seis `AudioStreamPlayer` empiezan juntos y suenan siempre en sincronía; `musica.gd` solo cambia cuáles se oyen. Al Traspasar se cruza de una versión a la otra en `CRUCE` (0,6 s), así la música no se corta. El cruce mueve el volumen lineal, no los dB, para que a mitad de camino no baje.
- **Bus de audio.** La música va por su propio bus, `Musica` (en Godot, un bus es un canal de la mezcla con su propio volumen). El botón **Música** del menú lo pasa por Alta, Media y Apagada sin tocar el resto del sonido.
- **El jefe, la huida y el altar** todavía no tienen su música: ahí no suena nada.
- **De dónde salen los archivos.** `tools/musica/sonido.html` es la página de bocetos (se puede abrir en el navegador). `node tools/musica/render.js` toca esos mismos bocetos sin sonar, en un navegador sin ventana, y graba los seis `.ogg` en `assets/musica/`. Lo que suena después del final (el eco) se suma al inicio, así el bucle empalma sin salto. Necesita Playwright y ffmpeg.

### La matemática (`reflexion.gd`)

El eje pasa por el centro de una fila o columna de casillas. Con un eje horizontal en la fila `k`, una casilla `(x, y)` se refleja en `(x, 2k − y)`: queda a la misma distancia del eje, del otro lado. También están los ejes vertical y diagonales para salas futuras.

## Diseño de las salas

Regla de diseño: **una mecánica nueva por sala**, presentada sin texto de tutorial; las salas siguientes la combinan. Nada de "plataformas" visuales que regalen la respuesta: el jugador debe razonar dónde cae el reflejo.

La tabla sigue el orden del juego, que lo decide la lista `SALAS` de `main.gd` y no el número del archivo.

| Sala | Archivo | Qué enseña |
|---|---|---|
| Cruzar el río | `rio_00.json` | Solo Traspasar: en el plano espiritual el agua se cruza. |
| El paso celeste | `rio_01.json` | El vacío solo se cruza sobre un reflejo: marcar una piedra fija con Reflejo. |
| Dos piedras | `rio_02.json` | Reflejar más de una piedra para armar el camino. |
| Empujar la piedra | `rio_03.json` | Mover la piedra para que su reflejo caiga donde hace falta. |
| Lo que toca el agua | `rio_04.json` | Piedras que flotan en el agua. **Pendiente de rediseño**: perdió su lección cuando el agua se volvió cruzable en el plano espiritual. |
| Lejos del eje | `rio_05.json` | La distancia al eje se conserva: hay que alejar la piedra del río para que su reflejo se aleje igual y caiga sobre el vacío. |
| El río que baja | `rio_06.json` | Eje vertical: el reflejo queda a la izquierda o a la derecha, en la misma fila. |
| El río torcido | `rio_07.json` | Eje diagonal: reflejar intercambia la columna y la fila de la piedra, `(x, y)` → `(y, x)`. Se combina con empujar. |
| La otra orilla | `rio_08.json` | La piedra está del otro lado del río: hay que cruzar, acomodarla allá y su reflejo vuelve a tu lado. (Boceto de Angelo.) |
| El eje escondido | `rio_12.json` | Sala en C: el río queda en un brazo y la piedra en otro, pero su reflejo aparece del otro lado del muro. El eje sigue existiendo aunque no se vea el río. (Boceto de Angelo.) |
| El rincón | `rio_09.json` | Sala en L con río antidiagonal: `(x, y)` → `(10 − y, 10 − x)`. Empujar en dos direcciones. (Boceto de Angelo.) |
| Dos ríos | `rio_10.json` | Dos ejes: cada piedra marcada tiene un reflejo por cada río. (Boceto de Angelo.) |
| La lava | `rio_11.json` | Sin plano espiritual: la lava solo se cruza empujando una piedra para hacer un puente. (Boceto de Angelo.) |
| Elige el paso | `rio_13.json` | Tres pasos de lava y una sola piedra: solo uno lleva a la salida. Mirar la sala completa antes de gastar la piedra. |
| La isla | `rio_14.json` | Dos franjas de lava con una isla. Para empujar la segunda piedra hay que pararse sobre la primera, así que hay que hundirla justo debajo. |
| Cuerpo y espíritu | `rio_15.json` | Río y lava juntos: el agua se cruza con el espíritu y la lava con el cuerpo. |
| El reflejo no es piedra | `rio_16.json` | El reflejo de una piedra cruza el vacío, pero la lava solo se cruza con una piedra de verdad. |
| ¿Puente o reflejo? | `rio_17.json` | Dos piedras: una es el puente sobre la lava y la otra ya está bien puesta para que su reflejo tape el vacío. La trampa es hundir la que no es. |
| Una piedra, dos trabajos | `rio_18.json` | Un río vertical y una lava horizontal. La misma piedra es puente en la lava y, con su reflejo en el río, tapa el vacío. Hay que elegir bien la columna. |
| Narciso (jefe) | `rio_jefe.json` | El jefe del templo: hay que hacer que el reflejo de sus propias piedras caiga donde él está. Tres fases: alinear la columna, ajustar la distancia al eje y un eje vertical. |
| Huida: el río, el vacío, la lava | `rio_huida_1.json` a `rio_huida_3.json` | Fase 4 del jefe: el templo se derrumba y Narciso persigue al jugador dejando lava. Tres tramos cortos con mecánicas ya conocidas (cruzar agua, cruzar el vacío sobre un reflejo, hundir una piedra en la lava). Cada tramo es un punto de control. |
| El altar de Narciso | `rio_altar.json` | Afuera, junto a un estanque. El reflejo de la estatua aparece vestido; hay que empujar cada prenda y marcarla para que su reflejo caiga donde el reflejo vestido la muestra. Lo de arriba queda abajo en el reflejo: la corona va arriba de la estatua aunque en el estanque se vea abajo. |

El Templo del Río está completo, de "Cruzar el río" al altar. Siguiente paso: el segundo templo, "el espíritu que gira" (rotación; ver "Cómo crecerá a otros templos"). Pendientes: rediseñar `rio_04` y probar en un celular el jefe y la huida en tiempo real (sus ritmos, `RITMO_NORMAL` y `CADA_ROMPER`, se ajustan jugando). "Elegir qué marcar" todavía no funciona como puzzle en las salas normales: marcar una piedra de más nunca estorba (en el jefe sí, porque solo se marcan dos). Ideas aplazadas: elegir el eje con estacas y limitar los cambios de plano por sala.

### Cómo se diseña una sala

1. Angelo suele mandar un boceto de pizarra (S salida, I inicio, negro vacío, azul río, rojo lava, círculo verde piedra).
2. Se pasa a JSON y se resuelve con `python3 tools/solver.py sala.json`. Con letras prohibidas (`... sala.json F`) se comprueba que sin esa acción **no** haya solución: si la hay, la sala tiene un atajo y no enseña su idea.
3. `python3 tools/formatear.py boceto.json salas/rio_nn.json` la escribe con su `solucion`, y se agrega a `SALAS`.
4. Reglas de forma: la lava separada del agua y del vacío por muros; cada eje con al menos dos casillas de río o lava, para que se lea como una recta.

## El jefe: Narciso (`sala_jefe.gd`)

Narciso flota en el plano espiritual, del otro lado del río, y lanza piedras a la mitad del jugador (una sombra avisa dónde caen; si caen encima, quitan un corazón). Para golpearlo hay que marcar una de esas piedras y **traspasar** cuando su reflejo cae justo donde está él: se ve a sí mismo, se paraliza y pierde pétalos de su corona. El diseño completo está en el [documento del jefe](https://claude.ai/artifact/3weD4Fmp1SKHYEJssgtUGg).

- `SalaJefe` **extiende** `Sala`: hereda las reglas (moverse, empujar, marcar, traspasar) y solo agrega lo del jefe. `Sala.desde_archivo()` elige la clase según `"tipo": "jefe"` en el JSON.
- **Turnos.** En el juego, Narciso se mueve solo: `usar_tiempo_real()` crea un `Timer` (un nodo de Godot que avisa cada cierto tiempo) que llama a `_turno()` cada `RITMO_NORMAL` (1 s) o `RITMO_DIFICIL` (0,6 s) segundos. En cada turno avanza por su `camino`, lanza piedras y las sombras se acercan.
- **Dificultad.** Solo cambia la velocidad de Narciso (y lo que tardan en caer sus piedras); las salas de puzzle son iguales. Se elige en el menú; tras 5 derrotas seguidas en difícil, la ventana de derrota sugiere normal.
- **Pruebas.** Sin reloj, cada acción del jugador corre un turno (`_accion()`). Las pruebas juegan así, para que la `solucion` dé siempre el mismo resultado.
- **Arena simétrica.** El lado del jugador es el espejo exacto del de Narciso: si Narciso está en su fila del fondo, la piedra va en tu última fila.
- **Romper piedras.** Cuando ya hay `MAX_PIEDRAS` (4) piedras en la arena empieza una cuenta: tras `CADA_ROMPER` turnos Narciso rompe las piedras sin marcar y las vuelve a lanzar, así que quedarse quieto no sirve.
- **Fases.** El JSON trae una lista `fases`; cada una tiene su mapa, eje, `camino`, `cada` (turnos por paso), `lanzamientos`, `cada_lanzamiento` y `golpes`. Reiniciar repite solo la fase actual.
- Solo puede haber **dos piedras marcadas** a la vez en el jefe, para que no baste con marcar todas y traspasar al azar.

### La huida (`sala_huida.gd`)

Al perder su corona, Narciso enfurece. Cada tramo es una sala corta (`"tipo": "huida"`) con algo que el jugador ya sabe hacer: nada nuevo bajo presión.

- Narciso recorre su `camino` (casillas en orden), empieza después de `espera` turnos y avanza una casilla cada `cada` turnos. Usa el mismo reloj que el jefe, así que la dificultad funciona igual: más lento en normal, más rápido en difícil.
- Cada casilla de piso que deja atrás se vuelve lava: el código cambia la letra en `mapa`, una copia del mapa del JSON. Por eso al reiniciar la lava desaparece.
- Si alcanza al jugador, emite `derrota` (la misma señal que usa el jefe) y solo se repite ese tramo.

### El altar (`sala_altar.gd`)

Después de la huida el jugador sale del templo (`"exterior": true` dibuja el piso como pasto). La estatua de Narciso mira un estanque.

- En el plano espiritual se ve el **reflejo vestido**: la estatua de cabeza en el estanque y, en celeste tenue, dónde va cada prenda (`reflejo_vestido`).
- Las prendas son piedras con `"prenda"`: se empujan como piedras, pero no al agua. La estatua (`estatua`) es una piedra fija.
- Solo aparecen las prendas que el jugador recogió (`usar_prendas()`, que llama `main.gd`). El reflejo vestido siempre muestra las cuatro, para que se note cuáles faltan.
- Cuando las cuatro prendas están **marcadas** con Reflejo, el jugador usa **Traspasar** y sus reflejos terminan de viajar y calzan con las sombras, el alma de Narciso descansa y crece un narciso donde estaba la estatua (señal `descanso`). Marcarlas no basta: hay que mirar el reflejo.
- La salida está detrás de un charco de agua suelto (no es parte del eje del estanque): hay que Traspasar para llegar, así el jugador ve las sombras de las prendas. Se llega a `E` sin volver al plano normal, así que no hay caída. Las prendas son opcionales: se sale aunque el altar quede incompleto.

## Crear una sala nueva sin programar

Copia `salas/rio_01.json`, cámbiale el nombre y edítala:

```
#  muro      .  suelo     ~  agua      =  puente
v  vacío     E  salida    ^  lava
```

- `jugador`: casilla inicial `[x, y]` (empezando en 0, desde la esquina de arriba a la izquierda).
- `plano_espiritual`: qué transformación aplica. Por ahora `"tipo": "reflexion"` con `"eje"` (`horizontal`, `vertical`, `diagonal`, `antidiagonal`) y `"valor"`. Si la sala tiene dos ejes, va una lista con una transformación por eje (mira `rio_10.json`).
- `piedras`: posición de cada piedra; `"fija": true` si no se puede empujar.
- `habilidades` (opcional): qué habilidades tiene el jugador en esa sala, por ejemplo `["traspasar"]`. Si no aparece, tiene todas.
- `prenda` (opcional): una prenda de Narciso, `{ "nombre": "sandalias", "pos": [x, y] }`. Solo se ve y se recoge en el plano espiritual. Es opcional: la salida está abierta aunque no se recoja. Nombres: `sandalias`, `cinto`, `tunica`, `corona`.
- `tipo` (opcional): `"jefe"`, `"huida"` o `"altar"` para las salas de Narciso; cada una tiene sus propias claves (ver arriba). Sin `tipo` es una sala de puzzle.
- `exterior` (opcional): `true` dibuja el piso como pasto, para las salas al aire libre.
- `solucion`: una secuencia de teclas que la resuelve (U arriba, D abajo, L izquierda, R derecha, P usar Traspasar, F usar Reflejo). Las pruebas la usan para comprobar que la sala tiene solución.

Después agrega la ruta del archivo a la lista `SALAS` en `scripts/main.gd`.

## Controles táctiles (en `main.gd`)

- `_crear_controles_tactiles()` pone en la capa `Interfaz` un `Control` llamado *pantalla* que ocupa toda la ventana. Sus hijos son los botones, colocados en las esquinas con *anclas* (`set_anchors_and_offsets_preset`), así que siguen en su esquina aunque el celular tenga otra proporción.
- La pantalla recibe los toques sobre el mapa en `_on_toque()`: si el dedo se movió más de `UMBRAL_DESLIZAR` píxeles es un deslizamiento; si no, es un toque sobre una casilla.
- En `project.godot`, `stretch/aspect="expand"` aprovecha toda la pantalla del celular y `handheld/orientation` la deja horizontal.
- Los botones tienen `focus_mode = FOCUS_NONE`; si no, Espacio también "presionaría" el último botón tocado.
- Los botones son **solo iconos** (`assets/sprites/icono_*.svg`). El nombre aparece al lado hasta que el jugador toca ese botón por primera vez; después queda solo como ayuda al pasar el mouse (`tooltip_text`). Lo maneja `crear_boton()` en `barra_habilidades.gd` con un diccionario `static` de botones ya conocidos. El botón **Usar** muestra el icono de la habilidad activa. El icono de cada habilidad se busca por su nombre: `icono_traspasar.svg`, `icono_reflejo.svg`.
- Los botones (menos la hotbar) **solo se ven con pantalla táctil** (`DisplayServer.is_touchscreen_available()` o Android/iOS). En la PC se juega con teclado: el **clic izquierdo** usa la habilidad (como Espacio) y el cursor se oculta mientras se juega (`_ocultar_cursor()`); solo se ve con un menú abierto. En el editor, el menú Debug tiene "Botones táctiles" para probarlos (y el cursor se ve cerca de ese botón).
- Casi no hay texto en pantalla. La **hotbar** (`BarraHabilidades`) está abajo al centro, en PC y en celular: una casilla cuadrada por habilidad desbloqueada, con su icono y el número de su tecla (1, 2…) en la esquina inferior izquierda. La activa tiene borde dorado grueso y brillo; las demás se ven más oscuras. En el celular las casillas se tocan para elegir.
- La primera vez que se consigue una habilidad (señal `nueva` de la barra), `_anunciar()` muestra su nombre grande en medio (Cinzel, dorado, con el icono), y el icono vuela hasta su casilla, que aparece al llegar (`revelar()`). Espera a que se cierre el menú, el diálogo o la cortina, y varios anuncios van de uno en uno. Mientras tanto, la sala se ve borrosa: un `ColorRect` con el shader `shaders/desenfoque.gdshader`, que promedia los píxeles de alrededor de lo que ya está dibujado detrás (`hint_screen_texture`).
- **Tutorial visual** (sin texto): la sala puede traer `"tutorial": {"habilidad": "traspasar"}` o `{"habilidad": "reflejo", "piedra": [x, y]}`. Esa casilla de la hotbar brilla dilatándose (`barra.pulsar()`) y, si hay `piedra`, la sala dibuja un pulso alrededor de ella (`tutorial_piedra`). Deja de brillar cuando el jugador usa Traspasar o marca esa piedra (`_vigilar_tutorial()` en `main.gd`). Con `"aviso_usar": true` (solo la sala 1), en la PC se ve además, encima de la hotbar, "[clic izquierdo] / [Espacio] para usar la habilidad" hasta que se cumple el tutorial; con pantalla táctil no, porque ahí está el botón Usar.
- En el plano espiritual las casillas de las demás habilidades se ven oscuras (`barra.bloquear()`), sin mensaje.

## Habilidades

El jugador tiene una hotbar de habilidades y solo una está activa a la vez (con borde dorado). Espacio usa la activa. Mientras una habilidad sigue en curso no se puede elegir otra: por ejemplo, estando en el plano espiritual con Traspasar no puedes cambiar a Reflejo (su casilla se ve oscura).

- `Habilidad` es el molde: tiene `nombre`, `disponible`, `usar(sala)` y `en_curso(sala)`.
- `Traspasar` es la primera: `usar()` llama a `sala.cambiar_plano()` y `en_curso()` responde si estás en el plano espiritual.
- `BarraHabilidades` es un `HBoxContainer` (una fila de controles de interfaz) que crea por código un `Button` por cada habilidad, grande para el dedo. `elegir(i, sala)` aplica la regla de "una a la vez".
- La lista de habilidades está en `_ready()` de `main.gd`. Cada sala decide cuáles están disponibles con la clave `habilidades` de su JSON; las demás aparecen bloqueadas.
- `Reflejo` marca o desmarca la piedra que el jugador tiene enfrente (`sala.marcar_enfrente()`).

Para agregar una habilidad nueva: crea un archivo en `scripts/habilidades/` que extienda `Habilidad`, implementa `usar()` (y `en_curso()` si dura en el tiempo) y agrégala a esa lista.

## Cómo crecerá a otros templos

Para el templo de la rotación basta con crear `scripts/transformaciones/rotacion.gd` que extienda `Transformacion` e implemente `aplicar()` y `dibujar()`, y agregar un caso en `Transformacion.desde_datos()`. Las salas, el dibujo y las pruebas no cambian.

## Pruebas

Desde una terminal, en esta carpeta:

```
godot --headless --import          # solo la primera vez en una copia nueva
godot --headless --script res://tests/test_reflexion.gd
```

Revisa las fórmulas de la reflexión, que cada sala se resuelva con su `solucion` y las reglas de movimiento, empuje, caída y habilidades. Debe terminar con `Fallos: 0`.
