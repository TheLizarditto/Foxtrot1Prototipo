El idle del caballero tiene dos fotogramas a 3 FPS, igual que el Dragon.
Los ocho `reposo_*` reutilizan `caballero_espalda.png`: el segundo fotograma
reduce la altura visible del torso en dos pixeles de origen con filtrado nearest,
manteniendo el apoyo de las botas. No se redibuja ni cambia la paleta del personaje.

`Scripts/ritmo_idle.gd` mantiene una fase compartida para ambos personajes.
El reloj respeta la pausa y la velocidad del juego, corrige la fase cada frame
y vuelve a aplicarla al regresar de movimiento, ataque, defensa o herida.
Las animaciones de accion conservan su propio ritmo y el impacto de espada.
