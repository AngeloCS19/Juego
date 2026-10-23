# Sprites: lista de assets y guías de diseño

Estado: lista y guías listas; los sprites básicos viven en `assets/sprites/`. Todavía **no** están conectados a `sala.gd` (que hoy dibuja con `_draw()`); eso se hace en un cambio aparte para no pisar la mecánica.

## Assets necesarios (sacados de `sala.gd`, `main.gd`, `barra_habilidades.gd`)

Todos son SVG de 64×64 (una casilla; en el juego se escalan a 48 px).

| Archivo | Qué es | Dónde se usa |
|---|---|---|
| `piso.svg` | Piso de piedra (casilla `.`) | plano normal |
| `muro.svg` | Muro (`#`) | siempre bloquea |
| `agua.svg` | Agua del río (`~`) | plano normal |
| `vacio.svg` | Vacío (`v`), oscuro | plano normal |
| `puente.svg` | Puente de madera (`=`) | plano normal |
| `salida.svg` | Salida dorada (`E`) | plano normal |
| `piedra.svg` | Piedra redonda empujable | plano normal |
| `piedra_fija.svg` | Bloque cuadrado con raíces | plano normal |
| `jugador.svg` | Personaje visto desde arriba, **apuntando hacia arriba** (el juego lo rota según `mirando`) | ambos planos |
| `anillo_reflejo.svg` | Anillo celeste de una piedra marcada con Reflejo | encima de la piedra |
| `icono_traspasar.svg` | Icono de la habilidad Traspasar | barra de habilidades |
| `icono_reflejo.svg` | Icono de la habilidad Reflejo | barra de habilidades |

**El plano celeste no necesita sprites propios:** se logra en código tiñendo los mismos sprites de celeste y con transparencia (`modulate`), y el piso se reemplaza por la cuadrícula que ya dibuja `transformacion.gd`. Así hay un solo arte por objeto y no se desincroniza con las salas.

## Guías de diseño que se siguieron

1. **Lectura en pantalla pequeña (celular horizontal).** Cada casilla mide 48 px: formas grandes y simples, contorno oscuro grueso, sin detalles finos que se pierdan al reducir. (Principio de silueta: cada objeto debe distinguirse solo por su forma.)
2. **Forma + color, nunca solo color.** Una persona con daltonismo (o un celular con poco brillo) debe poder diferenciar piedra empujable (redonda) de piedra fija (cuadrada con raíces), y agua de vacío (ondas vs. oscuridad plana). Ya lo hace el código actual; los sprites lo conservan.
3. **Contraste de valor.** Piso medio, muro oscuro, personaje y piedra más claros/saturados que el fondo, para que lo interactivo destaque sobre lo estático.
4. **Paleta corta y consistente**, tomada de las constantes de `sala.gd` (piso `#8c8066`, muro `#383330`, agua `#3373b3`, madera `#73523a`, vacío `#0a0a0f`, salida `#d9b34d`, piedra `#73b366`, piedra fija `#336633`, jugador `#f28c33`, celeste `#8cd9ff`). Así el cambio visual es coherente con lo que ya se juega. Angelo dijo que la paleta definitiva viene después: cambiarla es editar colores en los SVG.
5. **Celeste reservado.** El celeste solo significa "plano espiritual / reflejo". Ningún sprite del plano normal lo usa, excepto el anillo de Reflejo, que es justamente el puente entre planos.
6. **Mosaico sin costuras.** Los tiles (piso, agua, muro, vacío, puente) llenan los 64×64 completos y su borde no tiene marcos que formen una rejilla fea al repetirse.
7. **Vista cenital pura.** Sin perspectiva ni sombras proyectadas hacia un lado: la cámara puede girar 90°, así que ningún sprite tiene "arriba" salvo el jugador, cuya orientación se rota por código.
8. **Aprendizaje implícito, sin texto en los sprites.** Nada de números ni letras dibujadas; los iconos de habilidad se entienden por forma (Traspasar: dos planos/círculos que se cruzan; Reflejo: figura y su espejo con eje).
9. **Básico a propósito.** Formas geométricas simples hechas a mano en SVG (vectorial: nítido a cualquier pantalla, pesa pocos KB, se edita con un editor de texto). El arte elaborado queda para después.

Referencias generales de práctica en juegos 2D cenitales: legibilidad y silueta por encima del detalle, paleta limitada, contraste de valor para separar capas jugables, y no depender solo del color (accesibilidad).

## Anillos de marca por transformación

El anillo `anillo_reflejo.svg` lleva un eje punteado con dos triángulos enfrentados (símbolo de espejo). Cada transformación futura tendrá su propio anillo celeste con un símbolo distinto (p. ej. flecha para traslación, flecha curva para rotación).

## Personaje

Queda neutro hasta definir el lore (¿persona o figura?): un disco naranja con una punta dorada que marca hacia dónde mira. El sprite apunta hacia arriba y el juego lo rota según `mirando`.
