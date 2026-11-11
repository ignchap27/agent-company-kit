---
name: backend-craft
description: Reglas para backend sin AI slop. Convenciones del repo, validación en los bordes, errores, datos, seguridad, tests que prueban comportamiento. Úsalo antes de dar por terminado cualquier cambio de backend.
---

# Backend craft

## Antes de escribir

- Busca en el repo cómo se hace lo mismo hoy (rutas, capa de datos, errores, logging, auth) y copia ese patrón. Reutiliza helpers existentes antes de crear otros.
- Usa stdlib o dependencias ya instaladas. Nada de librería nueva ni capa nueva por "limpieza".

## Señales de AI slop: no las produzcas

- Interfaz con una sola implementación, factory para un producto, config para un valor que nunca cambia, capas service/repository/manager que solo reenvían llamadas.
- `try/catch` que se traga el error, `catch (e) { return null }`, log y continuar como si nada.
- Comentarios que repiten el código; docstrings en cada función trivial.
- Código defensivo para casos imposibles dentro del sistema, y ninguna defensa en los bordes reales.
- Tests que verifican que el mock fue llamado, o que reescriben la implementación. Tests que nunca vieron fallar. Asserts sobre datos hardcodeados (`toBe("Ignacio Chaparro")`, nombre del producto) en vez de comportamiento.
- Nombres genéricos (`data`, `handler`, `utils`, `helper`), funciones de 100 líneas, flags booleanos que cambian todo el comportamiento.
- Endpoints, campos o parámetros que el spec no pidió.

## Piso de calidad

1. **Bordes validados:** todo input externo (HTTP, cola, archivo, env) se valida y tipa en un solo punto. Dentro del sistema, se confía en los tipos.
2. **Errores:** distingue error del cliente (4xx, mensaje accionable) de error del servidor (5xx, detalle solo en logs). Nunca filtres stack traces ni SQL al cliente. Propaga con contexto, no ocultes.
3. **Datos:** migraciones reversibles y compatibles hacia atrás (añadir antes de quitar), índices para las consultas nuevas, sin N+1 (revisa el SQL real de la ruta que tocas), transacciones donde hay escrituras múltiples, operaciones repetibles por reintentos (idempotentes).
4. **Seguridad:** autorización comprobada en el servidor para cada recurso (no solo autenticación), consultas parametrizadas, ningún secreto en código ni en logs, nada de datos personales en logs.
5. **Contrato:** respeta al pie de la letra el contrato del spec (rutas, campos, códigos). Cambios incompatibles de API se reportan, no se hacen.
6. **Tests:** uno por AC, escrito antes y visto fallar. Prueban comportamiento observable (entrada → salida o efecto), incluyen el caso de error y el borde (vacío, límite, duplicado, sin permiso). Mock solo en el límite del sistema (red, reloj, terceros). **Comportamiento, no datos:** el valor esperado sale de la entrada o de la fuente de verdad (`expect(getName(user)).toBe(user.name)`, constante importada), nunca de un literal reescrito; si renombrar algo o cambiar config rompe el test sin cambiar comportamiento, está mal. Excepción: el literal es la salida de una transformación (`formatPrice(1234.5) → "$1.234,50"`). QA lo rechaza.
7. **Observabilidad mínima:** un log con contexto en los fallos relevantes, con el formato que ya usa el repo.

Termina el reporte con: AC → test, riesgos de datos o seguridad que viste, qué no pudiste verificar.
