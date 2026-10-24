# Dirección de arte y sonido

Decisiones de Angelo (2026-10-23) para la mejora gráfica. `docs/sprites.md` tiene la lista de archivos; aquí está el *porqué* y el plan.

## Lo elegido

| Tema | Decisión |
|---|---|
| Estilo | **Vectorial pulido**: SVG con volumen (degradados suaves), bordes redondeados y contorno café oscuro. Nítido en cualquier pantalla. |
| Ambiente | **Onírico**, como un sueño: colores suaves, el vacío con motas violeta como un cielo nocturno, la salida que brilla. |
| Paleta | **Tierra cálida**. El celeste sigue reservado al plano espiritual. |
| Personaje | El jugador elige: **niño, niña o espíritu** sin sexo aparente. |
| Animaciones | Caminar y empujar; la piedra que viaja al otro lado del eje al reflejarse; Narciso y sus fases; caer al vacío o al agua. |
| Transición entre salas | **Espejo que se cierra en el eje**: dos mitades oscuras se juntan en una línea punteada celeste y se vuelven a abrir. |
| Efecto al Traspasar | **Mancha** que se expande desde el jugador, no un círculo perfecto: borde irregular y distinto cada vez (como tinta en agua), para que se sienta creativo. |
| Tipografía | **Una por personaje, según su personalidad y emoción** (pedido de Angelo, 2026-10-23). Narciso: cursiva fina y elegante, de aire griego (Cormorant Garamond itálica); cuando está furioso, en la huida, sus letras tiemblan rojas. Los nombres van en mayúsculas romanas (Cinzel). Todo personaje nuevo que hable necesita su propia letra y sus retratos. |
| Botones (celular) | **Solo iconos**; el nombre aparece únicamente la primera vez que se ve el botón. |
| Menú inicial | Ilustración fija del templo con el título. |
| Pausa | Pantalla completa oscurecida, más bonita que la actual. |
| Sonido | Elegido por Angelo el 2026-10-24 (ver abajo, «Lo elegido en sonido»). |

## Paleta

| Uso | Color |
|---|---|
| Contorno de todo | `#2b1a14` (café muy oscuro, más suave que el negro) |
| Piso (arenisca) | `#e3c9a0` → `#cfae82`, manchas `#b8966a` |
| Muro (adobe) | `#9a5a3d` → `#7a4330`, junta `#6e3a2a` |
| Agua | `#3a7aa3` → `#4b8fb8`, lisa como el vacío, con brillo sutil `#cfeaf2` en el borde para contar casillas |
| Vacío | `#1b1424` → `#0d0912`, motas `#5a4670` |
| Lava | `#f07a32` → `#cf4a24`, burbujas `#ffd36a` |
| Madera (puente) | `#9a6a44`, `#5c3a24` |
| Salida (oro) | `#fff6cf`, `#e7b94e`, `#a77a1e` |
| Roca que se mueve | gris `#d4d0c8` → `#a39e95` → `#77726a`; forma irregular, tres variantes (`piedra_1..3.svg`) |
| Piedra fija | mármol `#f1ede4` → `#9c9588`; redonda y tallada, como la base de una estatua |
| Pasto | `#9db66a` → `#86a055` |
| Celeste espiritual | `#8cd9ff` (solo plano espiritual y marcas de Reflejo) |

Regla: lo que se puede mover (piedra, jugador) es más claro y saturado que el piso; lo que bloquea (muro, vacío) es más oscuro.

## Orden de trabajo

1. Paleta y sprites nuevos, con los tres personajes. *(hecho)*
2. Animaciones: caminar y empujar, la piedra que se refleja, caer, Narciso. *(hecho; ver README, "Animaciones")*
3. Transiciones y efectos: espejo entre salas (`cortina.gd`), mancha al Traspasar (`_dibujar_mancha()` en `sala.gd`). *(hecho)* Agua y lava que se mueven: *(hecho)* un brillo que ondula en el agua y burbujas en la lava (`_animar_agua`/`_animar_lava` en `sala.gd`).
4. Interfaz: botones con iconos, menú inicial ilustrado y pausa nueva. *(hecho)*
5. Sonido y música (con la dirección de abajo).

## Lo elegido en sonido (Angelo, 2026-10-24)

Bocetos en `tools/musica/sonido.html` (la misma página que Angelo escuchó).

| Tema | Decisión |
|---|---|
| Música del templo | Ocarina y marimba (guiño a las ocarinas precolombinas de Costa Rica), tres motivos que se alternan, río de fondo muy bajo. *(hecha)* |
| Al Traspasar | La misma pieza, filtrada y con eco; se cruza sin cortar. *(hecha)* |
| A lo largo del templo | La pieza se arma por capas: marimba, luego bajo, luego ocarina. *(hecha)* |
| Jefe | El tema del templo, insistente y con tambor, más un pulso al ritmo de los pasos de Narciso. |
| Huida | Las melodías de Angelo (grabadas en flauta dulce: principal y tres variantes, alternándose en ese orden) en ocarina, cada nota atacada y la anacrusa ligada, sobre arpegios y tambor bajos (re menor, la menor, un compás cada uno). *(hecha)* |
| Altar | Solo la lira, muy despacio, con el motivo de Narciso. |
| Reflejo | Una sola nota cristalina. |
| Traspasar / volver | Campana al revés que crece y se corta; volver es el mismo sonido invertido. |
| Empujar | Puerta de piedra que se arrastra y un golpe al quedar en su lugar (0,3 s, lo que dura el empujón). |
| Pasos | Según la superficie: arenisca, madera, pasto. Cada templo nuevo agrega las suyas. |
| Voz de Narciso | Sílabas con su timbre (como Undertale): cada personaje que hable tiene su voz, como su tipografía. |
| Volumen | Música y efectos por separado en el menú. |
| De dónde salen | Música por código; efectos físicos (piedra, pasos, agua, lava) de bibliotecas libres CC0; efectos musicales por código. |

## Sonido y música (la dirección original)

La idea general: el sonido acompaña el sueño, nunca regaña. Nada de bocinas de error ni campanitas de "¡correcto!": el mundo responde, y el jugador entiende por la consecuencia.

**Música**
- Ambiente suave y lento, instrumentos acústicos con eco: arpa o lira (guiño griego a Narciso), flauta, cuerdas tenues, pads de sintetizador cálido. Poca melodía, mucha atmósfera, para no cansar durante un puzzle largo.
- **Dos capas de la misma pieza**: plano normal (cálido, con más graves) y plano espiritual (la misma melodía pero filtrada, con reverberación y un toque cristalino). Al Traspasar se cruza de una a otra sin cortar, así el cambio de plano se *oye*.
- Cada templo con su instrumento propio: el del Río con agua y arpa; el de la rotación podría usar algo que gire (arpegios circulares).
- Narciso: la misma melodía del templo, pero insistente y con percusión, que sube un escalón por fase. La huida: más rápida, sin melodía nueva.
- El altar: la pieza completa por primera vez, en calma.

**Efectos**
- Pasos: suaves sobre arenisca; distintos en puente (madera) y pasto.
- Empujar: roce grave de piedra que dura lo que dura el movimiento. Girar hacia una piedra sin empujar: casi nada, un leve roce.
- Reflejo (marcar): nota cristalina corta; el reflejo que aparece en el otro lado repite la nota *invertida* (la misma nota, más aguda o al revés), un eco sonoro de la simetría.
- Traspasar: un "respiro" con eco que crece mientras se expande la mancha.
- Hundir piedra en lava: siseo y burbujeo grave.
- Caer: un descenso de tono que se apaga, sin golpe fuerte; la sala vuelve con un acorde suave.
- Prenda encontrada: un motivo corto de la melodía de Narciso.
- Salida: acorde que se abre al llegar; se encadena con la transición de espejo.
- Interfaz: toques muy cortos y suaves (madera o piedra pequeña), siempre más bajos que el juego.

**Celular**: todo debe entenderse con el sonido apagado (muchos juegan en silencio en clase). El sonido refuerza, nunca es la única pista.
