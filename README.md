# Juego Didáctico

Juego de puzzles con vista cenital donde se aprende matemática sin darse cuenta. El jugador cambia entre el plano normal y un plano espiritual que transforma los objetos sagrados. Cada templo enseña una transformación del plano (programa del MEP, 8.º año). El primero es el **Templo del Río**: reflexión respecto a un eje.

## Cómo abrirlo

1. Instala [Godot 4.4 o más reciente](https://godotengine.org/download) (la versión estándar, no la .NET).
2. En el gestor de proyectos de Godot: **Importar** y elige el archivo `project.godot` de esta carpeta.
3. Presiona **F5** (o el botón ▶ arriba a la derecha) para jugar.

Si tu Godot es más nuevo que 4.4, puede preguntar si quieres convertir el proyecto: acepta.

## Controles

| Tecla | Acción |
|---|---|
| Flechas o WASD | Moverse una casilla |
| Espacio | Cambiar de plano |
| R | Reiniciar la sala |
| Q / E | Girar la cámara 90° |

## Cómo está organizado

```
main.tscn                 Escena principal (los nodos)
scripts/main.gd           Controles, cámara y orden de las salas
scripts/sala.gd           Reglas de una sala y cómo se dibuja
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

- En el **plano normal**, las piedras son obstáculos. Las redondas verde claro se pueden empujar; los bloques cuadrados con raíces están fijos. Una piedra empujada al agua queda flotando y se puede pisar.
- En el **plano espiritual**, el piso se desvanece y queda la cuadrícula. Las piedras originales se vuelven fantasmas que se pueden atravesar, y el agua se puede cruzar y el vacío solo sobre un reflejo celeste. Los muros siempre bloquean.
- **Cambiar de plano** es una habilidad del jugador (`cambiar_plano()` en `sala.gd`). Si vuelves al plano normal parado sobre el vacío o el agua, caes y la sala se reinicia (señal `caida`). Encima de una piedra no se puede volver.
- La función `imagen_en(c)` es el corazón matemático: pregunta si alguna piedra, al aplicarle la transformación, cae en la casilla `c`.

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
- `solucion`: una secuencia de teclas que la resuelve (U arriba, D abajo, L izquierda, R derecha, P cambiar de plano). Las pruebas la usan para comprobar que la sala tiene solución.

Después agrega la ruta del archivo a la lista `SALAS` en `scripts/main.gd`.

## Cómo crecerá a otros templos

Para el templo de la rotación basta con crear `scripts/transformaciones/rotacion.gd` que extienda `Transformacion` e implemente `aplicar()` y `dibujar()`, y agregar un caso en `Transformacion.desde_datos()`. Las salas, el dibujo y las pruebas no cambian.

## Pruebas

Desde una terminal, en esta carpeta:

```
godot --headless --script res://tests/test_reflexion.gd
```

Revisa las fórmulas de la reflexión y que cada sala se resuelva con su `solucion`. Debe terminar con `Fallos: 0`.
