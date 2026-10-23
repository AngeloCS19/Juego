# Juego Didáctico

Juego de puzzles con vista cenital donde se aprende matemática sin darse cuenta. El jugador cambia entre el plano normal y un plano espiritual que transforma los objetos sagrados. Cada templo enseña una transformación del plano (programa del MEP, 8.º año). El primero es el **Templo del Río**: reflexión respecto a un eje.

## Cómo abrirlo

1. Instala [Godot 4.4 o más reciente](https://godotengine.org/download) (la versión estándar, no la .NET).
2. En el gestor de proyectos de Godot: **Importar** y elige el archivo `project.godot` de esta carpeta.
3. Presiona **F5** (o el botón ▶ arriba a la derecha) para jugar.

Si tu Godot es más nuevo que 4.4, puede preguntar si quieres convertir el proyecto: acepta.

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

Habilidades: **Traspasar** cambia de plano; **Reflejo** marca la piedra que tienes enfrente.

## Cómo está organizado

```
main.tscn                 Escena principal (los nodos)
scripts/main.gd           Controles, cámara y orden de las salas
scripts/sala.gd           Reglas de una sala y cómo se dibuja
scripts/barra_habilidades.gd  Barra de habilidades (abajo a la izquierda)
scripts/habilidades/
  habilidad.gd            Molde general de cualquier habilidad
  traspasar.gd            Cambiar de plano
  reflejo.gd              Marcar la piedra de enfrente para reflejarla
scripts/transformaciones/
  transformacion.gd       Molde general de cualquier transformación
  reflexion.gd            La reflexión (primer templo)
salas/rio_01.json ...     Cada sala, descrita como datos
tests/test_reflexion.gd   Pruebas automáticas
```

### Los nodos de la escena

Si abres `main.tscn` en Godot verás este árbol:

- **Main** (Node2D) tiene el script `main.gd`. Es el director: carga salas y escucha el teclado.
- **Pivote** (Node2D) es un punto en el centro de la pantalla. La sala se coloca dentro de él, así que girar el pivote gira toda la sala. Así funciona la rotación de cámara.
- **Interfaz** (CanvasLayer) es una capa que no gira ni se mueve con el mundo. Dentro está **Etiqueta** (Label), el texto de arriba.

La sala no aparece en el árbol porque `main.gd` la crea por código (`Sala.new()`) cada vez que empieza una sala nueva.

### Ideas de Godot que usa el código

- **`class_name`**: al poner `class_name Sala` arriba de un script, cualquier otro script puede usar `Sala` como un tipo, sin cargar el archivo a mano.
- **Señales** (`signal completada`): la sala avisa "me resolvieron" sin saber quién escucha. `main.gd` se conecta con `sala.completada.connect(...)` y carga la siguiente. Así la sala no depende de `main`.
- **`_draw()` y `queue_redraw()`**: en vez de usar imágenes, la sala se dibuja con figuras simples (rectángulos y círculos). Cuando algo cambia, `queue_redraw()` le pide a Godot que vuelva a llamar a `_draw()`. Esto es temporal: cuando tengamos arte, cambiaremos solo la parte de dibujo.
- **`_unhandled_input(evento)`**: Godot llama esta función cada vez que se presiona una tecla.
- **`Vector2i`**: un par de números enteros (x, y). Lo usamos para las casillas de la cuadrícula. `y` crece hacia abajo.

### Las reglas de la sala (`sala.gd`)

- En el **plano normal**, las piedras son obstáculos: caminar contra una solo te gira hacia ella. Para empujarla hay que mirarla y sostener la dirección `TIEMPO_EMPUJE` segundos (`_process()` en `main.gd` mide el tiempo y llama a `sala.empujar_enfrente()`). Las redondas verde claro se pueden empujar; los bloques cuadrados con raíces están fijos. Una piedra empujada al agua queda flotando y se puede pisar.
- En el **plano espiritual**, el piso se desvanece y queda la cuadrícula. Las piedras originales se vuelven fantasmas que se pueden atravesar, y el agua se puede cruzar y el vacío solo sobre un reflejo celeste. Los muros siempre bloquean.
- **Cambiar de plano** es una habilidad del jugador (`cambiar_plano()` en `sala.gd`). Si vuelves al plano normal parado sobre el vacío o el agua, caes y la sala se reinicia (señal `caida`). Encima de una piedra no se puede volver.
- **Solo las piedras marcadas con Reflejo** aparecen reflejadas en el plano espiritual. Una piedra marcada lleva un anillo celeste en el plano normal. El jugador tiene un punto negro que indica hacia dónde mira: esa es la casilla que apuntan las habilidades (`mirando` en `sala.gd`).
- La función `imagen_en(c)` es el corazón matemático: pregunta si alguna piedra marcada, al aplicarle la transformación, cae en la casilla `c`.

### La matemática (`reflexion.gd`)

El eje pasa por el centro de una fila o columna de casillas. Con un eje horizontal en la fila `k`, una casilla `(x, y)` se refleja en `(x, 2k − y)`: queda a la misma distancia del eje, del otro lado. También están los ejes vertical y diagonales para salas futuras.

## Crear una sala nueva sin programar

Copia `salas/rio_01.json`, cámbiale el nombre y edítala:

```
#  muro      .  suelo     ~  agua      =  puente
v  vacío     E  salida
```

- `jugador`: casilla inicial `[x, y]` (empezando en 0, desde la esquina de arriba a la izquierda).
- `plano_espiritual`: qué transformación aplica. Por ahora `"tipo": "reflexion"` con `"eje"` (`horizontal`, `vertical`, `diagonal`, `antidiagonal`) y `"valor"`.
- `piedras`: posición de cada piedra; `"fija": true` si no se puede empujar.
- `habilidades` (opcional): qué habilidades tiene el jugador en esa sala, por ejemplo `["traspasar"]`. Si no aparece, tiene todas.
- `solucion`: una secuencia de teclas que la resuelve (U arriba, D abajo, L izquierda, R derecha, P usar Traspasar, F usar Reflejo). Las pruebas la usan para comprobar que la sala tiene solución.

Después agrega la ruta del archivo a la lista `SALAS` en `scripts/main.gd`.

## Controles táctiles (en `main.gd`)

- `_crear_controles_tactiles()` pone en la capa `Interfaz` un `Control` llamado *pantalla* que ocupa toda la ventana. Sus hijos son los botones, colocados en las esquinas con *anclas* (`set_anchors_and_offsets_preset`), así que siguen en su esquina aunque el celular tenga otra proporción.
- La pantalla recibe los toques sobre el mapa en `_on_toque()`: si el dedo se movió más de `UMBRAL_DESLIZAR` píxeles es un deslizamiento; si no, es un toque sobre una casilla.
- En `project.godot`, `stretch/aspect="expand"` aprovecha toda la pantalla del celular y `handheld/orientation` la deja horizontal.
- Los botones tienen `focus_mode = FOCUS_NONE`; si no, Espacio también "presionaría" el último botón tocado.

## Habilidades

El jugador tiene una barra de habilidades y solo una está activa a la vez (con borde dorado). Espacio usa la activa. Mientras una habilidad sigue en curso no se puede elegir otra: por ejemplo, estando en el plano espiritual con Traspasar no puedes cambiar a Reflejo.

- `Habilidad` es el molde: tiene `nombre`, `disponible`, `usar(sala)` y `en_curso(sala)`.
- `Traspasar` es la primera: `usar()` llama a `sala.cambiar_plano()` y `en_curso()` responde si estás en el plano espiritual.
- `BarraHabilidades` es un `HBoxContainer` (una fila de controles de interfaz) que crea por código un `PanelContainer` con un `Label` por cada habilidad. `elegir(i, sala)` aplica la regla de "una a la vez".
- La lista de habilidades está en `_ready()` de `main.gd`. Cada sala decide cuáles están disponibles con la clave `habilidades` de su JSON; las demás aparecen bloqueadas.
- `Reflejo` marca o desmarca la piedra que el jugador tiene enfrente (`sala.marcar_enfrente()`).

Para agregar una habilidad nueva: crea un archivo en `scripts/habilidades/` que extienda `Habilidad`, implementa `usar()` (y `en_curso()` si dura en el tiempo) y agrégala a esa lista.

## Cómo crecerá a otros templos

Para el templo de la rotación basta con crear `scripts/transformaciones/rotacion.gd` que extienda `Transformacion` e implemente `aplicar()` y `dibujar()`, y agregar un caso en `Transformacion.desde_datos()`. Las salas, el dibujo y las pruebas no cambian.

## Pruebas

Desde una terminal, en esta carpeta:

```
godot --headless --script res://tests/test_reflexion.gd
```

Revisa las fórmulas de la reflexión y que cada sala se resuelva con su `solucion`. Debe terminar con `Fallos: 0`.
