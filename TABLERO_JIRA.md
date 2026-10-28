# Tablero Jira — MovilidadMDQ (frontend2 en Angular)

> Backlog adaptado a las **14 pantallas del diseño** (`MovilidadMDQ-pantallas.excalidraw`) y al **backend real** ya desplegado. Reemplaza al plan genérico de 4 épicas.
> Convención de la app: mobile-first, moneda ARS, contexto Mar del Plata, backend en `https://movilidadmdq.ddns.net`, auth con JWT + Google.

## Épicas

- **EPIC-1** — Configuración y Arquitectura Base
- **EPIC-2** — Autenticación y Cuenta de Usuario
- **EPIC-3** — Búsqueda y Cálculo de Viaje
- **EPIC-4** — Comparador y Resultados
- **EPIC-5** — Mapa / Integración Visual
- **EPIC-6** — Historial y Favoritos
- **EPIC-7** — Estadísticas del Cliente *(nueva)*
- **EPIC-8** — Navegación y Layout *(nueva)*
- **EPIC-9** — Panel de Administración *(nueva)*
- **EPIC-10** — Backend: nuevos endpoints *(nueva — lo que hay que agregar del lado del server)*

> ⚠️ = la pantalla depende de un **endpoint de backend que hoy NO existe**. Todos esos endpoints están detallados en **EPIC-10**.

---

## ⚙️ EPIC-1 — Configuración y Arquitectura Base

- **[Task] Setup inicial Angular** — Proyecto con Angular CLI, RxJS, HttpClient y ruteo.
- **[Task] Librería de UI + estilo global** — Angular Material / Tailwind. Aplicar identidad del diseño: fondo gris claro, cards blancas redondeadas, botones negros en MAYÚSCULAS, wordmark "Movilidad**MDQ**". Soporte **modo claro/oscuro**.
- **[Task] Servicio HTTP (ApiService) + modelos TS** — Interfaces TypeScript y servicios para consumir los endpoints (usuarios, viajes, tarifas).
- **[Task] Sesión JWT** — Interceptor que agrega `Authorization: Bearer`, guardado de sesión y **cierre automático al vencer el token**.
- **[Task] Guards de ruta** — Rutas protegidas (requiere login) y ruta **solo ADMIN** (rol).
- **[Task] Configuración de entornos** — `environment` con URL del back y la API key de Google Maps.

## 🔐 EPIC-2 — Autenticación y Cuenta de Usuario  *(pantallas 1, 2, 3, 9)*

- **[Story] Iniciar sesión** — "Como usuario quiero entrar con mi usuario/email y contraseña." → `POST /usuarios/login`, guarda JWT. AC: validación de campos, error claro si son inválidos.
- **[Story] Login con Google** — Botón "Continuar con Google" → `/oauth2/authorization/google`, maneja el token de retorno.
- **[Story] Crear cuenta** — Nombre, email, contraseña → `POST /usuarios/registro`. AC: validaciones, avisa si el usuario/email ya existe.
- **[Story] Recuperar contraseña** ⚠️ — Pantalla "escribí tu mail → nueva contraseña". **Requiere endpoint nuevo en el back** (hoy no existe recuperación de contraseña).
- **[Story] Ver y editar perfil** — Nombre, email, contraseña → `PUT /usuarios/{id}`.
- **[Story] Eliminar cuenta** — `DELETE /usuarios/{id}` con confirmación.

## 📍 EPIC-3 — Búsqueda y Cálculo de Viaje  *(pantalla 4)*

- **[Story] Formulario de origen y destino** — "Como usuario quiero ingresar origen y destino para calcular el costo." AC: campos con validación (no vacíos), botón "CALCULAR". *(El diseño actual NO incluye el botón de intercambiar A↔B; queda como opcional/futuro.)*
- **[Story] Autocompletado + ubicación actual** — Sugerencias mientras escribe (Google Places, restringido a MDQ) y usar la **ubicación GPS** como origen.
- **[Story] Viaje frecuente** — Mostrar el viaje más repetido y repetirlo con un toque → `GET /usuarios/{id}/viaje-frecuente`.

## 💰 EPIC-4 — Comparador y Resultados  *(pantalla 5)*

- **[Story] Tarjetas comparativas (Taxi / Uber / DiDi)** — "Como usuario quiero ver precio y tiempo de cada servicio para elegir." → `POST /viajes/calcular`. AC: logo/color de cada servicio, precio en ARS, tiempo estimado, acción **"Elegir"** (deep link a la app o web).
- **[Story] Manejo de estados (carga y errores)** — Spinner/skeleton mientras calcula; mensajes de error amigables si falla el back.
- *(Opcional / futuro, NO está en el diseño: indicador de "más económico" / "más rápido" y ordenamiento por barato/rápido.)*

## 🗺️ EPIC-5 — Mapa / Integración Visual  *(pantallas 4 y 5)*

- **[Story] Mapa con ruta** — "Como usuario quiero ver A y B marcados y el trazado de la ruta." → Google Maps + Directions. AC: dibuja la ruta al fijar origen/destino; respeta modo claro/oscuro.

## 🕑 EPIC-6 — Historial y Favoritos  *(pantallas 6, 7)*

- **[Story] Historial de viajes** — Lista con fecha, distancia, precios y botones **Repetir** / **Borrar** → `GET /usuarios/{id}/historial`, `DELETE /usuarios/{id}/historial/{viajeId}`.
- **[Story] Marcar búsqueda favorita** — Estrella para marcar/desmarcar un viaje → `PUT /viajes/{id}/favorito`.
- **[Story] Direcciones favoritas** — Listar, **renombrar** (alias tipo casa/trabajo) y **eliminar** → `GET/PUT/DELETE /viajes/direcciones-favoritas`.

## 📊 EPIC-7 — Estadísticas del Cliente  *(pantalla 8 — nueva)*

- **[Story] Estadísticas del usuario** ⚠️ — Torta "transporte más elegido", **total ahorrado** vs la opción más cara, **viajes realizados**, filtro por rango de fechas. **Requiere endpoint(s) nuevos** en el back (hoy no expone estas métricas al cliente).

## 🧭 EPIC-8 — Navegación y Layout  *(pantalla 10 — nueva)*

- **[Story] Menú desplegable** — Header "Hola, [usuario]" + menú hamburguesa: Mi perfil, Mi historial, Mis direcciones favoritas, Mis estadísticas. *(El diseño nuevo reemplaza las tabs por menú desplegable.)*
- **[Task] Ruteo entre vistas** — Item **Admin** visible solo con rol ADMIN.
- **[Task] Toggle modo claro/oscuro**.

## 🛠️ EPIC-9 — Panel de Administración  *(pantallas 11, 12, 13, 14 — nueva)*

- **[Story] Configuración de tarifa** — Bajada de bandera y ficha (día/noche) y metros por ficha, **mostrando los valores actuales** → `GET` + `PUT /admin/tarifas/taxi`.
- **[Story] Gestión de usuarios** — Buscar por username/email, ver info y eliminar → `GET /usuarios/buscar`, `DELETE /usuarios/{id}`.
- **[Story] Informe: usuarios registrados por mes** ⚠️ — Gráfico de línea, filtro por año. **Requiere endpoint nuevo** en el back.
- **[Story] Informe: transporte más elegido** ⚠️ — Torta, filtro por fechas. Requiere endpoint nuevo (o derivarlo de la auditoría existente).
- **[Story] Auditoría global de búsquedas** *(a confirmar)* — Filtros por usuario/origen/destino/fecha/favorito → `GET /viajes/admin/auditoria`. Existe en la app pero no está dibujada en el diseño nuevo; confirmar si se mantiene.

> **Sacado** respecto del plan/app anterior: la pantalla admin de **"Destinos populares / más solicitados"** ya no va.

## 🧩 EPIC-10 — Backend: nuevos endpoints  *(lo que hay que agregar al server)*

> El backend actual (Spring Boot en la EC2) ya cubre login, registro, perfil, cálculo de viaje, historial, favoritos, viaje frecuente, tarifa (GET/PUT) y gestión de usuarios. Lo que sigue es lo que **falta crear** para que las pantallas nuevas funcionen. Cada tarea es la contraparte de una ⚠️ del front.

- **[Task][Backend] Recuperación de contraseña** — Endpoint para solicitar una nueva contraseña por mail (ej. `POST /usuarios/recuperar-password` con el email). Incluye: generar contraseña/token temporal, **configurar envío de email (SMTP)** y guardar el hash nuevo. → habilita EPIC-2 "Recuperar contraseña" (pantalla 3).
- **[Task][Backend] Estadísticas del cliente** — Endpoint que devuelva, para el usuario logueado y un rango de fechas, el **conteo de transporte más elegido** (Taxi/Uber/Didi), el **total ahorrado** vs la opción más cara y la **cantidad de viajes realizados** (ej. `GET /usuarios/{id}/estadisticas?desde&hasta`). Se puede calcular sobre los viajes ya guardados. → habilita EPIC-7 (pantalla 8).
- **[Task][Backend] Informe: usuarios registrados por mes** — Endpoint admin que devuelva la cantidad de usuarios creados agrupados por mes, filtrable por año (ej. `GET /admin/estadisticas/usuarios-por-mes?anio=`). Requiere tener/usar la fecha de alta del usuario. → habilita EPIC-9 informe de línea (pantalla 13).
- **[Task][Backend] Informe: transporte más elegido (admin)** — Endpoint admin con el conteo global por tipo de transporte en un rango de fechas (ej. `GET /admin/estadisticas/transporte-elegido?desde&hasta`). Se puede **derivar del campo `tipoElegido` de la auditoría** que ya existe. → habilita EPIC-9 torta (pantalla 14).

> Notas técnicas:
> - Para "usuarios registrados por mes" hay que asegurarse de que la entidad `Usuario` guarde **fecha de alta** (si no la tiene, agregar el campo).
> - "Transporte más elegido" (cliente y admin) se apoya en `tipoElegido`, que ya se registra al tocar "Elegir".
> - Recuperación de contraseña es la única que suma **infraestructura nueva** (envío de emails), el resto son consultas sobre datos que ya se guardan.
