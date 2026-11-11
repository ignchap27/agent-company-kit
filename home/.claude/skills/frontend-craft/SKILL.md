---
name: frontend-craft
description: Checklist de calidad para UI que se siente hecha por una persona. Estados, accesibilidad, copy, responsive y verificación visual con screenshot. Úsalo antes de dar por terminado cualquier cambio de frontend.
---

# Frontend craft

Complementa `frontend-design` (estética). Este skill es el piso de calidad y la verificación.

## Primero, el repo manda

Si el repo ya tiene design system, tokens, componentes o tema: úsalos y no inventes otra identidad visual. Eso fija el vocabulario (color, tipo, espacio, componentes), no la composición: `frontend-design` sigue mandando en jerarquía, protagonista y personalidad de cada pantalla. Tokens correctos sobre un layout por defecto sigue siendo plantilla. Si hay `docs/referencias/<vista>*` del dueño, esa referencia manda sobre todo. Nunca mezcles dos lenguajes visuales en la misma pantalla.

## Señales de AI slop: no las produzcas

- Todo en tarjetas idénticas con el mismo radio y sombra gris; tarjetas dentro de tarjetas.
- Degradados morado/azul, brillos, glassmorphism sin motivo.
- Iconos en círculo de color encima de cada título; emojis como iconos.
- Cada sección con entrada fade-and-slide-up; hover con escala en todo.
- Eyebrows en mayúsculas sobre cada título, numeración 01/02/03 sin secuencia real, palabra suelta acentuada en el titular.
- Copy de relleno: "Potencia tu flujo de trabajo", "Experiencia fluida", Lorem ipsum, "John Doe", "Acme Inc".
- Colores, tamaños y espacios hardcodeados cuando existen tokens.
- Fila de tarjetas KPI idénticas, todas con el mismo peso; nada destaca como lo más importante.
- Gráficos sin contexto (sin comparación, tendencia ni escala) o barras planas de un solo color como única visualización.
- Filtros y formularios como lo primero de la pantalla, por encima de la respuesta que el usuario vino a buscar.
- Todo el mismo tamaño y peso tipográfico; marca usada solo en el botón y el sidebar.

## Piso de calidad (todo cambio de UI)

1. **Estados completos:** loading, vacío (con la acción siguiente), error (qué pasó y cómo arreglarlo), éxito, deshabilitado. No solo el camino feliz.
2. **Datos reales:** nombres largos, textos de 1 y de 200 caracteres, listas de 0, 1 y 500 elementos, fechas y números con el formato del locale.
3. **Accesibilidad:** HTML semántico (`button` no `div onClick`), label en cada input, foco visible, orden de tab lógico, contraste AA, objetivos táctiles ≥ 44px, `alt` útil o vacío si es decorativo, `prefers-reduced-motion` respetado.
4. **Responsive:** funciona a 375px sin scroll horizontal y a 1280px sin líneas de texto > 80 caracteres.
5. **Copy:** verbos concretos ("Guardar cambios", no "Enviar"), la misma palabra para la misma acción en todo el flujo, sentence case, errores sin disculpas ni vaguedad. Reutiliza el tono y las cadenas i18n existentes.
6. **Movimiento:** solo como respuesta a una acción o un único momento de entrada. Sin rebotes ni easing elástico. CSS para lo predeterminado; Motion (`motion/react`) para springs, layout, salidas y gestos. Detalle en `animate` y `emil-design-eng`.
7. **Sin dependencias nuevas** para lo que CSS o el sistema de componentes ya resuelve.
8. **Tests de comportamiento, no de datos:** consulta por rol/label (`getByRole("button", { name: SAVE_LABEL })`) o por la constante/cadena i18n importada, nunca por copy, nombre de producto o dato de fixture reescrito a mano (`getByText("MISW")`, `toBe("Ignacio Chaparro")`). El valor esperado sale del fixture o de la fuente de verdad. Si cambiar un texto o una marca rompe el test sin cambiar comportamiento, está mal. QA lo rechaza.

## Verificación visual (obligatoria si hay dev server o storybook)

Claude no ve su propio resultado: míralo.

1. Levanta la app o el componente (comando de dev del repo).
2. Captura a 375px y 1280px: `npx playwright screenshot --viewport-size=375,800 <url> /tmp/m.png` (y 1280,800). Si el repo no tiene Playwright, usa el que tenga (Storybook, Cypress) o declara en el reporte que no pudiste verificar visualmente.
3. Abre las imágenes con Read y critica: jerarquía, alineación, espaciado, contraste, texto cortado.
4. Corrige y repite una vez. No más de dos rondas.

Termina el reporte con: estados cubiertos, viewports revisados, qué no pudiste verificar.
