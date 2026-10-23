# Sprites: lista de assets y guías de diseño

Estado: los sprites básicos viven en `assets/sprites/` y `sala.gd` ya los dibuja (`_draw()`). Los iconos de habilidad aún no se usan: la barra sigue con botones de texto.

## Assets necesarios (sacados de `sala.gd`, `main.gd`, `barra_habilidades.gd`)

Todos son SVG de 64×64 (una casilla; en el juego se escalan a 48 px).

| Archivo | Qué es | Dónde se usa |
|---|---|---|
| `piso.svg` | Piso de piedra (casilla `.`) | plano normal |
| `muro.svg` | Muro (`#`) | siempre bloquea |
| `agua.svg` | Agua del río (`~`) | plano normal |
| `vacio.svg` | Vacío (`v`), oscuro | plano normal |
| `lava.svg` | Río de lava (`^`), rojo con burbujas | plano normal |
| `prenda_sandalias.svg`, `prenda_cinto.svg`, `prenda_tunica.svg`, `prenda_corona.svg` | Prendas de Narciso, a todo color | plano espiritual |
| `narciso.svg` | Narciso visto desde arriba, a color: rizos oscuros, quitón blanco con broche dorado y una cola de espíritu que se desvanece. El código le pone un aura del color de su ánimo (celeste a naranja según la fase, rojo lava en la huida) y destella en blanco al recibir un golpe; su corona son los pétalos que dibuja el código | plano espiritual (en el normal, translúcido) |
| `pasto.svg` | Pasto, el piso de las salas al aire libre (`"exterior": true`) | plano normal |
| `estatua.svg` | Estatua de piedra de Narciso, con una mano en alto | plano normal (en el espiritual, su reflejo de cabeza) |
| `flor_narciso.svg` | Flor de narciso que crece cuando Narciso descansa | al completar el altar |
| `puente.svg` | Puente de madera (`=`) | plano normal |
| `salida.svg` | Salida: el espejo de Narciso, un estanque redondo y sencillo de mármol con agua dorada (fondo transparente: se dibuja sobre el piso o el pasto) | plano normal |
| `piedra_1.svg`, `piedra_2.svg`, `piedra_3.svg` | Roca gris irregular que se empuja; cada piedra de la sala toma una variante según su orden en el JSON (`"variante"`) | plano normal |
| `piedra_fija.svg` | Piedra fija: redonda y tallada, como la base de una estatua | plano normal |
| `jugador_nino.svg`, `jugador_nina.svg`, `jugador_espiritu.svg` | Los tres personajes que se eligen en el menú inicial, vistos desde arriba y **apuntando hacia arriba** (el juego los rota según `mirando`) | ambos planos |
| `anillo_reflejo.svg` | Anillo celeste de una piedra marcada con Reflejo | encima de la piedra |
| `icono_traspasar.svg` | Icono de la habilidad Traspasar | barra de habilidades |
| `icono_reflejo.svg` | Icono de la habilidad Reflejo | barra de habilidades |

**El plano celeste no necesita sprites propios:** se logra en código con una silueta blanca de cada sprite, teñida de celeste y con transparencia (`_silueta()` en `sala.gd`; teñir con `modulate` no sirve porque multiplica y una piedra verde no se vería celeste), y el piso se reemplaza por la cuadrícula que ya dibuja `transformacion.gd`. Así hay un solo arte por objeto y no se desincroniza con las salas.

## Guías de diseño que se siguieron

1. **Lectura en pantalla pequeña (celular horizontal).** Cada casilla mide 48 px: formas grandes y simples, contorno oscuro grueso, sin detalles finos que se pierdan al reducir. (Principio de silueta: cada objeto debe distinguirse solo por su forma.)
2. **Forma + color, nunca solo color.** Una persona con daltonismo (o un celular con poco brillo) debe poder diferenciar piedra empujable (roca irregular) de piedra fija (círculo tallado, regular), y agua de vacío (azul con brillo en el borde vs. oscuridad con motas).
3. **Contraste de valor.** Piso medio, muro oscuro, personaje y piedra más claros/saturados que el fondo, para que lo interactivo destaque sobre lo estático.
4. **Paleta corta y consistente**: tierra cálida, ver `docs/arte.md`. Cambiarla es editar colores en los SVG.
5. **Celeste reservado.** El celeste solo significa "plano espiritual / reflejo". Ningún sprite del plano normal lo usa, excepto el anillo de Reflejo, que es justamente el puente entre planos.
6. **Mosaico sin costuras.** Los tiles (piso, agua, muro, vacío, puente) llenan los 64×64 completos y su borde no tiene marcos que formen una rejilla fea al repetirse.
7. **Vista cenital pura.** Sin perspectiva ni sombras proyectadas hacia un lado: la cámara puede girar 90°, así que ningún sprite tiene "arriba" salvo el jugador, cuya orientación se rota por código.
8. **Aprendizaje implícito, sin texto en los sprites.** Nada de números ni letras dibujadas; los iconos de habilidad se entienden por forma (Traspasar: dos planos/círculos que se cruzan; Reflejo: figura y su espejo con eje).
9. **Vectorial pulido.** SVG con degradados suaves y contorno café oscuro (`#2b1a14`), sin sombras hacia un lado (la cámara gira). Detalles en `docs/arte.md`.

Referencias generales de práctica en juegos 2D cenitales: legibilidad y silueta por encima del detalle, paleta limitada, contraste de valor para separar capas jugables, y no depender solo del color (accesibilidad).

## Anillos de marca por transformación

El anillo `anillo_reflejo.svg` lleva un eje punteado con dos triángulos enfrentados (símbolo de espejo). Cada transformación futura tendrá su propio anillo celeste con un símbolo distinto (p. ej. flecha para traslación, flecha curva para rotación).

## Personaje

Se elige en el menú inicial: niño, niña o espíritu sin sexo aparente (`Sala.personaje`, un índice en `TEX_PERSONAJES`). Vistos desde arriba: el pelo (o la capucha) cubre la nuca y la cara asoma hacia adelante, así se sabe hacia dónde miran sin flecha. La niña lleva una trenza que cuelga hacia atrás.

## Retratos para diálogos (`assets/retratos/`)

Arte 2D grande (600×900) que aparece a la izquierda en los diálogos, al estilo de Hades. Un SVG por ánimo del personaje:

| Archivo | Qué es |
|---|---|
| `narciso_retrato.svg` | Narciso sereno: ojos entrecerrados, una lágrima celeste, corona completa, halo celeste |
| `narciso_retrato_enojado.svg` | Narciso enojado: cejas fruncidas, ojos naranjas, corona con flores marchitas, halo naranja |

Mismo estilo que los sprites: contorno café grueso (`#2b1a14`), colores planos con una sombra, sin texto. Todo personaje que hable necesita sus retratos; se registran en `PERSONAJES` de `scripts/dialogo.gd`.
