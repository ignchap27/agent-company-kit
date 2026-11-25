# Estilo de diseño del dueño

Destilado de `notes.md` y de `<repo>/design/refs/notes.md`. Si hay conflicto, manda el repo. Es el punto de partida del `designer` para escribir `DESIGN.md`, `tokens.json` y `rubric.md`.

## Principios (se repiten en casi todas las refs)
1. **Simple pero bien ejecutado.** Pocas piezas, mucho aire, jerarquía clara. Parece hecho por un desarrollador de Apple.
2. **Una sola idea de color.** Base neutra (blanco, casi blanco u oscuro) + UN acento fuerte (coral, azul, índigo, lima, turquesa). Un segundo acento solo para estados.
3. **Titular grande, sans bold, con UNA palabra distinta**: de otro color, o en serif cursiva. Es la firma del estilo. Máx. una por pantalla.
4. **La imagen manda.** En portafolio, la foto de la persona, recortada e integrada (círculo, resplandor o degradado, nunca pegada con caja). En producto, foto a pantalla completa. En SaaS, maqueta real del producto como imagen del hero.
5. **Navbar integrado.** Mismo fondo que el hero, sin borde duro ni sombra pesada. Transparente sobre foto o blanco sobre claro. Pequeño CTA a la derecha (pastilla o contorno). Es el punto donde la IA suele fallar: es criterio de rechazo.
6. **Números grandes como prueba**: 120+, 95 %, 18k+. Número grande + etiqueta pequeña, en fila de 3.
7. **Prueba social discreta**: fila de logos grises o fila de skills en texto tenue.
8. **Tarjetas** con radio generoso (16–24 px), sombra suave o ninguna, fondo apenas distinto del de la página.
9. **Detalles lúdicos con medida**: máx. 1 o 2 (subrayado a mano, destello, sello). Nunca decoración en todos los bloques.
10. **Responsive real**: la versión móvil está pensada (apila, mantiene la foto), no solo reducida.

## Tipos de página y qué tomar
| Tipo | Refs | Receta |
|---|---|---|
| Portafolio personal | portfolio/design/refs 01–05 | Fondo oscuro o claro, acento coral, foto recortada con círculo/resplandor, skills en fila tenue, "Sobre mí" con 3 stats. |
| Landing tech / startup | 02, 03, 07 | Hero centrado, titular con palabra de acento, ilustración sutil o resplandor, stats, logos. |
| Landing de producto | 04 | Foto a pantalla completa, nav transparente, un acento fuerte, tarjeta flotante con dato. |
| Sistema de gestión / SaaS | 01, 05, 06 | Sidebar con iconos, tarjetas de métricas arriba, tabla/gráfica abajo, un acento, filtros visibles. |

## Tipografía
- Sans geométrica o grotesca moderna (Inter, Plus Jakarta, Manrope, Montserrat) para todo.
- Serif cursiva (Instrument Serif, Playfair Italic) SOLO para una palabra del titular.
- Titular 56–96 px en escritorio, peso 600–800, interlineado apretado (1.0–1.1). Cuerpo 16–18 px, color atenuado.

## Movimiento
Máx. 3–4 efectos por página: aparición de texto al entrar, parallax suave de la foto, marquee de skills o logos, contadores. Respetar `prefers-reduced-motion`. Solo `transform` y `opacity`.

## Lista negra
Degradados morados genéricos de "IA", emojis como iconos, tarjetas con sombra dura, 5 colores de acento, texto centrado en párrafos largos, navbar con caja o borde que no se integra, imágenes de stock sin recorte ni tratamiento, mockups inclinados en 3D como diseño.
