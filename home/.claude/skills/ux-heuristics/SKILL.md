---
name: ux-heuristics
description: Catálogo de heurísticas de diseño y usabilidad (Nielsen, Shneiderman, leyes de UX, Gestalt, formularios, entradas numéricas, tablas, navegación, feedback, errores, accesibilidad, móvil, microcopy) para diseñar o evaluar una interfaz. Úsalo al revisar capturas o código de UI, o antes de dar por terminada una pantalla.
---

Cada regla lleva un id. Al reportar un hallazgo, cita el id (p. ej. `F7`) para que el dev sepa qué regla rompe.
Las que dependen de la interacción (teclado, foco, cómo se llena un campo) no se ven en una captura: compruébalas leyendo el código del componente o con un script de Playwright efímero (`node -e` / `npx playwright`) que teclee, tabule y capture.

## N. Nielsen (10 heurísticas)
- N1 Visibilidad del estado: toda acción responde en < 100 ms (cambio visual) y lo largo muestra progreso; el usuario siempre sabe dónde está y qué está pasando.
- N2 Lenguaje del usuario: palabras del dominio del usuario, nunca códigos, ids, enums, JSON, nombres de tabla ni jerga técnica. Orden natural y lógico.
- N3 Control y libertad: deshacer, cancelar, volver y cerrar siempre a mano; salida clara de cualquier estado; Escape cierra.
- N4 Consistencia y estándares: un concepto = una palabra, un estilo y un sitio; mismos componentes para lo mismo; convenciones de la web (logo lleva al inicio, enlaces parecen enlaces).
- N5 Prevención de errores: mejor impedir el error que explicarlo; restricciones en el control (selector, rango, fecha), valores por defecto sensatos, confirmación solo en lo destructivo o irreversible.
- N6 Reconocer antes que recordar: opciones visibles, no memorizar códigos ni datos de una pantalla a otra; contexto presente (qué aspirante, qué filtro está activo).
- N7 Flexibilidad y eficiencia: atajos para expertos sin estorbar al novato (Enter envía, acciones en lote, filtros recordados).
- N8 Estética y minimalismo: cada elemento compite por atención; quita lo que no ayuda a la tarea de esta pantalla.
- N9 Errores reconocibles y recuperables: qué pasó, por qué y cómo arreglarlo, en lenguaje llano, junto al campo; nunca culpar al usuario; nunca perder lo que escribió.
- N10 Ayuda en contexto: ayuda breve donde se necesita (texto de ayuda, tooltip, ejemplo), no un manual aparte.

## S. Shneiderman (las que no repite Nielsen)
- S1 Diálogos con cierre: secuencias con inicio, progreso y final claro ("Listo: invitación enviada a …").
- S2 Locus de control interno: el usuario manda; nada se mueve, salta o cambia solo sin que él lo pida.
- S3 Reducir carga de memoria a corto plazo: pantallas que no exijan recordar más de unas pocas cosas.

## L. Leyes de UX
- L1 Fitts: lo frecuente e importante, grande y cerca; objetivos táctiles ≥ 44×44 px (24 px mínimo absoluto, WCAG 2.5.8); lo destructivo lejos de lo frecuente.
- L2 Hick: menos opciones por decisión; agrupa, oculta lo avanzado (divulgación progresiva), una acción principal por pantalla.
- L3 Miller / chunking: agrupa en bloques de ~5–7; parte números largos (teléfono, cuenta) en grupos.
- L4 Jakob: la gente pasa su tiempo en otras webs; usa los patrones que ya conoce (tabla, buscador arriba, menú lateral, avatar arriba a la derecha).
- L5 Doherty: respuesta < 400 ms o feedback inmediato (optimista, esqueleto, spinner con texto).
- L6 Tesler: la complejidad inevitable la absorbe el sistema, no el usuario (calcular, autocompletar, inferir).
- L7 Von Restorff: lo importante destaca, y solo una cosa por zona.
- L8 Serial position / peak-end: lo clave al principio o al final; termina las tareas con un momento positivo.
- L9 Goal-gradient y efecto Zeigarnik: muestra el progreso en tareas de varios pasos ("Paso 2 de 3").
- L10 Estética-usabilidad: lo bonito se percibe más fácil; pero no tapes problemas de uso con pulido.
- L11 Postel: acepta entradas con formato libre (espacios, guiones, mayúsculas) y normalízalas tú.

## G. Gestalt y layout
- G1 Proximidad: lo relacionado junto, lo distinto separado; el espacio agrupa mejor que las líneas.
- G2 Semejanza: mismo estilo = misma función; no uses el color de un enlace para texto normal.
- G3 Región común: tarjetas o fondos para agrupar; no cajas dentro de cajas dentro de cajas.
- G4 Alineación: una rejilla; bordes izquierdos alineados; números alineados a la derecha en tablas.
- G5 Jerarquía: tamaño, peso y color en ese orden; un solo H1 por vista; escaneo en F/Z; lo principal arriba a la izquierda.
- G6 Espaciado con escala (4/8 px) consistente; aire suficiente; densidad acorde al uso (tablas de admin densas pero legibles).
- G7 Longitud de línea 45–75 caracteres en texto corrido; interlineado 1.4–1.6.

## F. Formularios y entradas
- F1 Etiqueta visible siempre encima del campo; el placeholder nunca sustituye a la etiqueta (desaparece al escribir).
- F2 Una columna; orden lógico; agrupa con títulos; solo los campos imprescindibles.
- F3 Marca lo opcional ("opcional"), no lo obligatorio con asteriscos sin explicar.
- F4 Tipo de control correcto: `type="email"`, `tel`, `url`, `date`, `search`; selector para ≤ 7 opciones visibles como radio, más como select o combobox con búsqueda.
- F5 Teclado móvil correcto: `inputmode="numeric"` / `decimal` / `tel` / `email`; `autocomplete` adecuado (`email`, `name`, `one-time-code`, `current-password`, `new-password`).
- F6 **Entradas numéricas**: los dígitos se llenan de izquierda a derecha como al escribir en papel; el cursor no salta al final ni los dígitos se empujan desde la derecha; nada de `type="number"` para códigos, documentos, teléfonos o cédulas (pierde ceros a la izquierda, rueda del ratón cambia el valor, flechas confusas): usa `type="text" inputmode="numeric" pattern="[0-9]*"`. Las máscaras (miles, fechas, teléfono) no deben mover el cursor ni impedir borrar; permite pegar el valor completo. Códigos tipo OTP: avanza solo al siguiente dígito, retrocede al borrar, acepta pegar todo el código.
- F7 Ancho del campo proporcional al dato esperado (código postal corto, correo largo).
- F8 Validación en línea al salir del campo (blur), no a cada tecla ni solo al enviar; al corregir, el error desaparece al instante; en envío, foco al primer error y resumen arriba.
- F9 Mensajes de error junto al campo, con `aria-describedby`, en lenguaje llano y diciendo cómo arreglarlo ("Escribe un correo como nombre@dominio.com", no "Formato inválido").
- F10 Nunca borres lo escrito tras un error ni al volver atrás; guarda borradores en formularios largos.
- F11 Botón de envío con verbo concreto ("Enviar invitación", no "Aceptar"/"Submit"); deshabilitado solo con explicación visible, mejor habilitado y validar; estado de envío (spinner + texto) y bloqueo de doble envío.
- F12 Contraseñas: mostrar/ocultar, requisitos visibles antes de escribir, sin bloquear pegar.
- F13 Fechas: selector nativo o formato explícito ("dd/mm/aaaa"), zona horaria clara si importa, rangos con inicio ≤ fin validado.
- F14 Valores por defecto inteligentes y recordados; autofocus solo en el primer campo de una pantalla cuyo único propósito es ese formulario.

## A. Acciones, botones y confirmaciones
- A1 Una acción principal por vista (botón primario); secundarias con menos peso; terciarias como enlace.
- A2 Los botones parecen botones (relleno o borde, estados hover/focus/active/disabled distintos); los enlaces navegan, los botones actúan.
- A3 Acciones destructivas: color de peligro, texto explícito ("Eliminar 3 aspirantes"), confirmación que repite el objeto y la consecuencia, o mejor: deshacer durante unos segundos.
- A4 Etiquetas de acción con verbo + objeto; iconos solos solo para convenciones universales (cerrar, buscar, menú) y siempre con `aria-label` y tooltip.
- A5 Acciones cerca de lo que afectan (en la fila, en la tarjeta), no en una barra lejana.

## R. Feedback y estados
- R1 Todo componente con datos tiene estado cargando (esqueleto con la forma final), vacío, error y con datos; y caso de muchos datos.
- R2 Vacío útil: explica por qué está vacío y da el siguiente paso con botón ("Aún no hay aspirantes. Invita al primero").
- R3 Éxito visible y breve (toast o mensaje en línea) que dice qué pasó; no interrumpe con modales.
- R4 Errores de sistema con salida: "Reintentar", qué puede hacer el usuario, nunca un stack trace o un código HTTP.
- R5 Cambios optimistas donde sea seguro; revertir con aviso si falla.
- R6 Progreso determinado cuando se conoce (subidas, procesos por lotes).

## V. Navegación y arquitectura
- V1 El usuario sabe dónde está: ítem activo marcado en el menú, título de página, migas en niveles profundos.
- V2 Navegación principal persistente y corta (≤ 7 ítems), con nombres del dominio del usuario.
- V3 El botón atrás del navegador funciona; filtros, pestañas y paginación viven en la URL.
- V4 Cada vista de detalle tiene "Volver" al listado conservando filtros y scroll.
- V5 La ruta a la tarea principal es corta (≤ 3 clics desde el inicio).

## T. Tablas y listas
- T1 Encabezados claros y fijos al hacer scroll; columnas con lo que el usuario escanea primero a la izquierda.
- T2 Números alineados a la derecha con cifras tabulares; texto a la izquierda; fechas en formato humano ("hace 2 días", "5 ene 2026").
- T3 Búsqueda y filtros visibles, con el filtro activo indicado y "Quitar filtros".
- T4 Orden por columna indicado; paginación o carga incremental con total visible.
- T5 Estados con badge de color + texto (nunca solo color); acciones de fila consistentes.
- T6 En móvil, la tabla se convierte en tarjetas o tiene scroll horizontal señalado; nunca se rompe.

## C. Contenido y microcopy
- C1 Frases cortas, voz activa, segunda persona, tono amable y consistente (tú o usted, no mezclar).
- C2 Títulos que dicen qué hace la pantalla; botones que dicen qué pasará.
- C3 Números y fechas localizados (separadores, moneda, formato de fecha del país).
- C4 Sin mayúsculas sostenidas en textos largos; sin texto en imágenes.
- C5 Truncar con elipsis y tooltip/expandir, nunca cortar a la mitad sin aviso; nombres largos no rompen el layout.

## X. Accesibilidad (WCAG 2.2 AA)
- X1 Contraste texto ≥ 4.5:1 (≥ 3:1 en texto grande y en bordes de controles e iconos significativos).
- X2 Todo usable con teclado; orden de tabulación lógico; foco visible y bonito (no `outline: none` sin reemplazo); sin trampas de foco salvo en modales (que lo devuelven al cerrar).
- X3 Semántica: landmarks, encabezados en orden, `button`/`a` reales, `label` asociado, `alt` en imágenes con significado.
- X4 Nunca solo color para transmitir información; iconos o texto además.
- X5 Respeta `prefers-reduced-motion`; nada parpadea > 3 veces por segundo.
- X6 Mensajes dinámicos anunciados (`role="status"`/`alert`, `aria-live`).
- X7 Zoom al 200 % sin pérdida ni scroll horizontal; texto en `rem`.

## M. Movimiento e interacción
- M1 La animación tiene propósito (orientar, dar feedback, mostrar relación), dura 150–300 ms en UI y usa ease-out al entrar.
- M2 Nada bloquea al usuario mientras anima; interrumpible.
- M3 Hover no es la única forma de descubrir algo (no existe en táctil).
- M4 Sin saltos de layout al cargar (reserva espacio de imágenes, esqueletos del tamaño final).

## D. Responsive y móvil
- D1 Diseña para 375 px primero; nada desborda; texto ≥ 16 px en inputs (evita el zoom de iOS).
- D2 Acciones principales al alcance del pulgar; menús compactos.
- D3 Sin scroll horizontal de página; tablas y código con su propio scroll.

## E. Confianza y estética
- E1 Identidad de marca consistente (color, logo, tipografía) sin saturar; el color de marca marca acciones y estados, no decora todo.
- E2 Aspecto actual: tipografía moderna, radios y sombras suaves y consistentes, iconografía de una sola familia, sin bordes grises por todas partes ni tablas de los 2000.
- E3 Datos sensibles o acciones de impacto explican qué pasará con ellos.
- E4 Cero texto de relleno, lorem ipsum, "TODO" o datos de prueba visibles.

## Cómo evaluar con este catálogo
1. Por vista: escribe la tarea principal del usuario y recórrela paso a paso (recorrido cognitivo): ¿sabe qué hacer?, ¿ve el control?, ¿entiende el feedback?
2. Pasa las secciones relevantes (formularios → F; listados → T; todo → N, G, R, X, C).
3. Severidad: high si impide o confunde la tarea principal o rompe accesibilidad básica; medium si causa fricción, inconsistencia o aspecto descuidado; low si es pulido.
