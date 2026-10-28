# Backend — Cambios pendientes (MovilidadMDQ)

> Endpoints/cambios que hay que agregar al backend (Spring Boot, `movilidad-mdq/`) para que funcionen las pantallas nuevas del diseño. Corresponden a la **EPIC-10** del tablero de Jira.
>
> **Ya hecho (no cuenta):** `GET /admin/tarifas/taxi` (RF19) — agregado y deployado.
>
> Orden sugerido: 1 → 2 → 3 → 4 (de menos a más trabajo).

---

## 1. Estadísticas del cliente  *(fácil — solo consulta, sin tocar la base)*

- **Endpoint:** `GET /usuarios/{id}/estadisticas?desde&hasta` — autenticado, dueño de la cuenta.
- **Devuelve:** transporte más elegido (conteo por TAXI/UBER/DIDI), total ahorrado y cantidad de viajes.
- **Cómo:** se calcula sobre los `Viaje` del usuario (ya existen `tipoElegido`, `precioTaxi/precioUber/precioDidi`, `fechaHora`).
  - viajesRealizados = cantidad de viajes del usuario en el rango.
  - transporteMasElegido = agrupar/contar por `tipoElegido`.
  - totalAhorrado = por cada viaje, (precio de la opción más cara − precio de la elegida), sumado.
- **Archivos a tocar:** `ViajeRepository` (query por usuario + rango), método en `HistorialViajeService`/`ViajeService`, endpoint en `ViajeController` o `UsuarioController`.
- **Base de datos:** sin cambios.
- **Habilita:** pantalla 8 (Estadísticas del cliente).

## 2. Transporte más elegido — admin  *(fácil — solo consulta, sin tocar la base)*

- **Endpoint:** `GET /admin/estadisticas/transporte-elegido?desde&hasta` — solo ADMIN.
- **Devuelve:** conteo global por tipo de transporte en el rango.
- **Cómo:** query sobre `Viaje` agrupando por `tipoElegido` (mismo campo que ya usa la auditoría).
- **Archivos a tocar:** `ViajeRepository` (query count group by `tipoElegido` con filtro de fecha), endpoint admin (controller nuevo o en `ViajeController`).
- **Seguridad:** `SecurityConfig` ya protege `/admin/**` para ADMIN → no hace falta tocarla.
- **Base de datos:** sin cambios.
- **Habilita:** pantalla 14 (Informe transporte más elegido).

## 3. Usuarios registrados por mes — admin  *(medio — requiere cambio en la base)*

- **Endpoint:** `GET /admin/estadisticas/usuarios-por-mes?anio` — solo ADMIN.
- **Devuelve:** cantidad de altas de usuarios agrupadas por mes.
- **OJO — cambio en la base:** el modelo `Usuario` **no tiene fecha de alta**. Hay que:
  - Agregar un campo `fechaAlta` (LocalDateTime) en `Usuario`, seteado con `@PrePersist` al crear.
  - Eso agrega una **columna nueva** en la tabla `usuarios`. Los usuarios existentes quedan con `fechaAlta` nula → rellenar a mano o asumir.
- **Archivos a tocar:** modelo `Usuario` (+ `@PrePersist`), `UsuarioRepository` (query group by mes/año), endpoint admin.
- **Base de datos:** columna nueva `fecha_alta`.
- **Habilita:** pantalla 13 (Informe usuarios registrados por mes).

## 4. Recuperación de contraseña  *(el más pesado — requiere infraestructura nueva)*

- **Endpoint:** `POST /usuarios/recuperar-password` — público (sin auth), body con el email.
- **Cómo:** buscar usuario por email → generar contraseña/token temporal → guardar con BCrypt (ya está el `PasswordEncoder` en `PasswordConfig`) → **enviar un mail** con la nueva contraseña o un enlace.
- **OJO — infraestructura nueva:** hay que configurar **envío de emails (SMTP)**:
  - Dependencia `spring-boot-starter-mail`.
  - Credenciales SMTP en el `.env` / `application.properties` (ej. Gmail con app password).
  - Un `EmailService`.
- **Archivos a tocar:** `UsuarioController` (endpoint), `UsuarioService`, nuevo `EmailService`, `SecurityConfig` (agregar la ruta a `permitAll`), `UsuarioRepository` (`findByEmail`).
- **Base de datos:** sin cambios (salvo que se opte por guardar un token de reseteo → columna extra).
- **Habilita:** pantalla 3 (Recuperar contraseña).

---

## Resumen de impacto

| # | Cambio | Base de datos | Infra nueva | Esfuerzo |
|---|---|---|---|---|
| 1 | Estadísticas del cliente | No | No | Bajo |
| 2 | Transporte más elegido (admin) | No | No | Bajo |
| 3 | Usuarios por mes (admin) | Sí (columna `fechaAlta`) | No | Medio |
| 4 | Recuperación de contraseña | Opcional | Sí (SMTP) | Alto |

## Notas al implementar

- **Deploy:** cada cambio de backend se ve en prod recién al pushear a `main` de `anibaldb/movilidadmdq` (GitHub Action → EC2). Si la Action no deploya, deploy manual en la EC2: `git pull origin main` + `sudo docker-compose down` + `sudo docker-compose up -d --build`.
- `tipoElegido` (usado en 1 y 2) ya se registra cuando el usuario toca "Elegir".
- Todos los endpoints `/admin/**` quedan protegidos automáticamente para ADMIN por `SecurityConfig`.
