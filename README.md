# The Last Knight

Juego 2D por turnos desarrollado en Godot con GDScript. El jugador usa cartas para mover a un personaje sobre un tablero, administrando su mano y sus puntos de acción (PA).

## Ejecutar el proyecto

1. Abrí `project.godot` desde Godot. El proyecto está configurado para Godot 4.7 y el renderizador Forward Plus.
2. Esperá a que el editor importe los recursos.
3. Presioná **F5** para ejecutar la escena principal, `Scenes/main.tscn`.

## Cómo jugar

Al iniciar, se genera y mezcla una baraja de 20 cartas. Las cartas se cargan en el mazo de robo y se reparten hasta completar una mano de 7 cartas. El personaje comienza en el centro de un tablero de 5 × 5 casillas.

- Pasá el mouse sobre una carta para levantarla y leerla.
- Hacé clic izquierdo en una carta para agregarla al final de la cola, visible en un marco oscuro con bordes dorados a la derecha del tablero. Tiene espacio para dos cartas en vertical; al agregar más, se superponen dejando visible la parte superior de cada una. Si tenés PA suficientes, su costo queda reservado; sus movimientos se ejecutan al finalizar el turno.
- Hacé clic en una carta de la cola para devolverla al extremo izquierdo de la mano y recuperar sus PA.
- Presioná el botón de turno para elegir qué cartas descartar. Hacé clic para seleccionar o deseleccionar y luego confirmá; también podés confirmar sin descartar ninguna.
- Después de confirmar, primero se descartan las cartas elegidas de la mano. Luego se ejecutan las cartas de la cola de arriba hacia abajo y cada una viaja al descarte con la animación habitual. Finalmente, la mano se repone hasta 7 cartas y comienza el siguiente turno con los PA recargados.

Si el mazo de robo se queda sin cartas al reponer la mano, el descarte se mezcla y se transfiere al mazo de robo. Si ambos mazos están vacíos, la reposición termina aunque la mano no esté completa.

## Funcionalidades implementadas

- Tablero generado a partir de una cantidad configurable de filas y columnas.
- Caminata animada del personaje en ocho direcciones, incluidas las diagonales, con desplazamiento suave entre celdas. Los pasos que saldrían del tablero no se aplican.
- El caballero conserva siempre su vista de espaldas y su diseño original, también al caminar en diagonal, atacar con espada y defender con escudo. Las cartas esperan cada animación antes de continuar.
- Generación aleatoria de cartas con movimientos, ataque, defensa y costo de PA.
- Mano en abanico con animaciones de robo, giro, reacomodo, selección y descarte.
- Contadores visibles para los mazos de robo y descarte y para los PA disponibles.
- Cola ordenada de cartas con reserva y devolución de PA, ejecución al finalizar el turno y recarga automática al avanzar.
- Pantalla de selección de descartes con confirmación y distribución adaptable al ancho de la ventana.
- Bloqueo de la interacción con la mano y el botón de turno mientras se resuelven las acciones correspondientes.

Ataque y defensa ya forman parte de los datos de las cartas y se muestran cuando su valor es mayor que cero. Las cartas ejecutan primero sus movimientos y luego las animaciones de ataque y defensa cuando sus valores son mayores que cero. Todavía no hay resolución de daño, enemigos ni condiciones de victoria o derrota.

## Valores actuales

Estos valores se pueden ajustar desde las propiedades exportadas de los scripts en el Inspector:

| Parámetro | Valor por defecto | Script |
| --- | --- | --- |
| Tablero | 5 columnas × 5 filas | `Scripts/tablero.gd` |
| Baraja inicial | 20 cartas | `Scripts/baraja.gd` |
| Capacidad de la mano | 7 cartas | `Scripts/mano.gd` |
| PA por turno | 10 | `Scripts/puntos_accion.gd` |
| Costo de cada carta | Entre 1 y 5 PA | `Scripts/baraja.gd` |
| Movimientos por carta | Entre 2 y 4 | `Scripts/baraja.gd` |
| Pasos por movimiento | Entre 1 y 2 | `Scripts/baraja.gd` |
| Ataque y defensa | Entre 0 y 3 cada uno | `Scripts/baraja.gd` |
| Pausa con el escudo levantado | 0,65 segundos, con destello sobre el escudo | `Scripts/personaje.gd` |
| Duración de cada paso animado | 0,32 segundos | `Scripts/personaje.gd` |
| Pausa entre pasos de una carta | 0,5 segundos | `Scripts/carta.gd` |

Cada movimiento se guarda como un `Vector2i`: su dirección indica hacia dónde avanzar y su magnitud indica la cantidad de pasos. Las cartas muestran flechas y cantidades; los movimientos consecutivos en la misma dirección se agrupan visualmente.

El marco de la cola usa `Assets/Carta/marco_cola.svg`. Para reemplazarlo, asigná otra textura a `sprite_cola` en el Inspector de `Mano`; se adapta al tamaño del recuadro. El interior mide 96 × 256 px (dos cartas de 96 × 128 px), con 4 px de margen por lado. La cola se reacomoda al agregar, devolver o ejecutar cartas.

Las animaciones del caballero se editan en `Assets/Personaje/caballero_animaciones.tres` (SpriteFrames). La hoja PNG conserva la armadura, el casco, la capa roja, la espada y el escudo del personaje de referencia. Las ocho direcciones de desplazamiento comparten poses de espaldas. El reposo utiliza directamente `caballero_espalda.png`, sin redibujar el sprite original.

## Estructura del proyecto

| Ruta | Contenido |
| --- | --- |
| `project.godot` | Configuración del proyecto y escena de inicio. |
| `Scenes/main.tscn` | Integra tablero, personaje, turnos, baraja, mano, mazos y PA. |
| `Scenes/` | Escenas reutilizables de los componentes del juego. |
| `Scripts/turnos.gd` | Preparación de la partida, cambio de turno, reposición de la mano y recarga de PA. |
| `Scripts/baraja.gd` | Generación, normalización y mezcla de la baraja inicial. |
| `Scripts/carta.gd` | Datos, representación visual y ejecución de los movimientos de cada carta. |
| `Scripts/mano.gd` | Distribución de cartas, interacción, pago de PA y animaciones. |
| `Scripts/mazo_robo.gd` | Robo de cartas y recarga desde el descarte. |
| `Scripts/mazo_descarte.gd` | Almacenamiento, mezcla y entrega de cartas descartadas. |
| `Scripts/seleccion_descarte.gd` | Interfaz para seleccionar y confirmar descartes. |
| `Scripts/puntos_accion.gd` | Disponibilidad, gasto, recarga y contador de PA. |
| `Scripts/tablero.gd` | Generación de casillas y validación de posiciones. |
| `Scripts/personaje.gd` | Posición del personaje, caminata en ocho direcciones y animaciones de ataque y defensa. |
| `Assets/` | Recursos gráficos de cartas, tablero, personaje, turnos y PA. |
