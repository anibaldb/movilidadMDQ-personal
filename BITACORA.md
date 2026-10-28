# Bitácora personal — MovilidadMDQ (Aníbal)

> Documento propio, **fuera de los repositorios** (no se pushea). Junta la planificación completa, lo que fui haciendo con explicación y por qué, y lo que hicieron mis compañeros (lo que entra en cada `git pull`).
> Se actualiza a medida que avanzamos, hasta terminar el proyecto.

---

## 1. Objetivo y fechas

Rehacer el frontend de MovilidadMDQ en **Angular** (frontend2), con el mismo estilo visual que frontend1 (React) y la distribución del boceto de 14 pantallas (`MovilidadMDQ-pantallas.png`), sumando 4 requisitos nuevos (RF44–RF47).

| Fecha | Hito |
|---|---|
| 06/11 (vie) | **Pre-entrega** (H5): todo terminado salvo RF44–RF47 |
| 14/11 | H6: versión desplegada y probada |
| 16/11 (lun) | **Entrega final** (H7) |
| 17/11 (mar) | Exposición |

## 2. Planificación completa

### 2.1 Sprints

| Sprint | Fechas | Objetivo | Reuniones |
|---|---|---|---|
| Sprint 1 | 27/10 – 01/11 | Base técnica, login y búsqueda | Planificación 27/10 · Revisión 30/10 |
| Sprint 2 | 02/11 – 06/11 | Pre-entrega: todo menos RF44–RF47 | Planificación 02/11 · Revisión 06/11 |
| Sprint 3 | 09/11 – 16/11 | RF44–RF47, despliegue y entrega final | Planificación 09/11 · Revisión 16/11 |

**Por qué así:** sprints semanales (lo dice el dossier); el Sprint 2 cierra justo en la pre-entrega; lo crítico (login, búsqueda, comparación, mapa) va primero.

### 2.2 Reparto (Plan B, 2 personas) — yo soy la **Persona B**

| Sprint | Persona A (compañero) | Persona B (yo) |
|---|---|---|
| 1 | SCRUM-15 Setup · 17 ApiService · 18 Sesión JWT · 19 Guards · 20 Entornos · 21 Iniciar sesión · 23 Crear cuenta | **SCRUM-16 Estilo global · 38 Menú · 39 Ruteo · 27 Formulario · 28 Autocompletado y GPS · 33 Mapa** |
| 2 | SCRUM-30 Tarjetas comparativas · 31 Estados · 41 Tarifa · 42 Gestión de usuarios | **SCRUM-34 Historial · 35 Marcar favorita · 36 Direcciones favoritas · 25 Perfil · 22 Login con Google** |
| 3 | SCRUM-45 a 48 (back RF44–RF47) · 24 Pantalla recuperar contraseña | **SCRUM-37 Estadísticas · 43 Informe usuarios por mes · 44 Informe transporte más elegido** |

Diferidas (backlog, etiqueta `diferido`): SCRUM-26, 29, 32, 40. Faltan crear en Jira: librería de gráficos, despliegue y prueba de carga, documentación/dossier, auditoría (condicionada).

**Por qué este reparto:**
- La base técnica la hace una sola persona primero (bloquea a todos). Objetivo: en `main` el **jueves 29/10**.
- Cada uno es dueño de pantallas completas (pantalla + servicio + ruta) → pocos conflictos.
- Persona A: base técnica, admin y back. Persona B: flujo del cliente.

### 2.3 Mi orden de trabajo en el Sprint 1

1. **SCRUM-16 Estilo global** — no depende de nadie y define el estilo de todas las pantallas.
2. **SCRUM-27 Formulario** y **SCRUM-33 Mapa** — se aprovecha el maquetado existente.
3. **SCRUM-28 Autocompletado y GPS**.
4. **SCRUM-38 Menú** y **SCRUM-39 Ruteo** — cuando la base técnica de la Persona A esté en `main` (el menú necesita saber quién está logueado).

### 2.4 Cómo trabajamos (Git y Jira)

- Una rama por tarjeta: `SCRUM-XX-descripcion`. Commits: `SCRUM-XX qué hice`.
- Nadie pushea a `main`: rama → push → Pull Request → revisión del compañero → merge → borrar rama.
- Antes de empezar una tarjeta: `git checkout main && git pull`, y recién ahí crear la rama.
- Reglas del equipo en `frontend2/CLAUDE.md` (estructura, código, decisiones).

---

## 3. Bitácora (lo que se fue haciendo)

### Antes de empezar a codear

**26/10 — Backend a servidor propio**
- El back salió de AWS y quedó en mi servidor ("covacha"), publicado con Cloudflare Tunnel en `https://api-movilidad.vendlysoft.com`, con MySQL en Docker y deploy automático (GitHub Actions con runner propio).
- **Por qué:** la cuenta de AWS se quedó sin créditos; HTTPS hace falta para el login con Google y para que el navegador permita que el front le pegue al back.
- Datos de RDS migrados al server. Backups diarios (3:30 en el server, 11:00 se copian a la notebook).
- Todo documentado en `INFRAESTRUCTURA.md`.

**26/10 — Dossier de Gestión v0.4** (`gestion/`)
- Solicitud de cambio SC-01: RF44–RF47 se agregan para la entrega final (16/11), sin tocar lo planificado hasta el 06/11.
- Estimación PERT (34,2 h), reparto entre integrantes, hitos H5–H7 nuevos, Gantt nuevo, riesgo R06.
- Se corrigió que RF41–RF43 estaban mal ubicados en la tabla de control de versiones.

**26/10 — Jira**
- Etiquetas con el código de requisito en cada tarjeta (trazabilidad dossier ↔ tablero).
- Diferidos con etiqueta `diferido`.

### Sprint 1

**27/10 — Reutilizar el repo frontend2 (no crear uno nuevo)**
- **Por qué:** Vercel, CORS del back y la clave de Maps ya están configurados para esa URL; el maquetado cuenta como trabajo hecho en el dossier.

**27/10 — Guía del equipo (`CLAUDE.md`), boceto y `.gitattributes`** — rama `docs-guia-equipo`
- `CLAUDE.md`: convenciones, estructura, reglas de código y registro de decisiones del equipo.
- `docs/MovilidadMDQ-pantallas.png`: el boceto dentro del repo, para que todos lo tengan.
- `.gitattributes`: normaliza fines de línea (Windows marcaba archivos como modificados sin cambios reales).
- Pasos: rama → commit → push → PR con mi compañero como revisor → merge → borrar rama.

**27/10 — Decisiones de diseño**
- Estilo visual = frontend1; distribución de cada pantalla = boceto.
- **CSS propio y simple**, sin Tailwind ni librería de UI, con pocas variables de color. **Por qué:** el diseño es simple a propósito para no complicar el CSS; el modo oscuro está diferido.

**27/10 — SCRUM-16 Estilo global** (en curso) — rama `SCRUM-16-estilo-global`
- El maquetado usaba un tema azul oscuro con 8 variables de color. Cambiando los valores de esas variables por los de frontend1, todo el maquetado cambia de una vez.
- Alcance: solo apariencia (colores, fuente, botones, tarjetas, inputs). La distribución según el boceto va en SCRUM-27, 33 y 38.
- **Parte 1 (`styles.css` e `index.html`):** se mantienen los nombres de variables del maquetado y se cambian sus valores por los de frontend1; se saca `--color-primary-light` (celeste que frontend1 no tiene) y se agregan `--color-text-faint`, `--color-primary-hover` y `--color-danger`. Cuatro clases comunes: `.card`, `.btn-primary`, `.input`, `.label`. En `index.html`: idioma español, título de frontend1 y fuente Inter. El comentario de Google Maps queda sin tocar (es de SCRUM-20/33).
- Primer `npm install` en mi compu: `node_modules` no se sube a GitHub, cada uno lo genera desde `package.json`.

**27/10 — Actualización de dependencias** — rama `chore-actualizar-dependencias`
- `npm audit` marcaba 17 vulnerabilidades, casi todas en herramientas de desarrollo (CLI, build, servidor de prueba, tests).
- Se hizo en una rama aparte y no dentro de SCRUM-16, porque cambia `package-lock.json` para todo el equipo y el PR de estilos tiene que tener solo estilos.
- `npm audit fix` (sin `--force`, que puede saltar de versión mayor y romper el proyecto): de 17 a 4.
- `npm update`: Angular tiene que actualizarse completo y en la misma versión; `package.json` permite cualquier 22.x, así que subió a la última 22.x sin salto mayor. De 4 a 2.
- Quedan 2 de `vite`: `@angular/build` exige una versión exacta de vite y hasta que Angular publique la corrección no se puede actualizar sin forzarlo. Riesgo bajo: solo el servidor de desarrollo.
- Después del merge, el compañero tiene que correr `npm install`.
- Resultado: `npm run build` sin errores; rama pusheada.

**27/10 — Conflicto con `main`**
- Al hacer `git pull` en `main` entraron 3 commits del 13/09 (hechos desde la web de GitHub): se borró el `index.html` placeholder de la raíz y se activó el script de Google Maps en `src/index.html`.
- La rama de SCRUM-16 había salido de un `main` viejo y también tocaba `src/index.html` → conflicto. Se resuelve con `git merge main` en la rama de SCRUM-16, quedándose con lo mío (idioma, título, Inter) + la línea de Maps de `main`.
- **Por qué merge y no rebase:** merge no reescribe commits ya hechos; es lo más seguro mientras aprendo.
- `angular.json` aparecía modificado solo por fines de línea (lo reescribió el comando de compilación) → `git restore angular.json`.
- **Lección:** antes de crear una rama, siempre `git checkout main && git pull`.

**27/10 — SCRUM-16 parte 2: componentes existentes**
- Header, botones redondos, inputs, pestañas, tarjetas de opciones, estado vacío y mapa pasan al estilo de frontend1 (solo colores, tamaños y bordes).
- El botón Calcular usa la clase global `.btn-primary` (primer uso de las clases comunes). El texto va en minúscula en el HTML y la clase lo pone en mayúsculas.
- `:focus-within` en el campo de dirección: marca el borde del contenedor cuando el input de adentro tiene foco.
- El CSS de cada componente está encapsulado, pero `styles.css` es global: por eso los componentes pueden usar `.btn-primary`.

**27/10 — Responsive (PC y celular)**
- "App de teléfono" = la misma web en el navegador del celular (app nativa excluida por el dossier; PWA posible más adelante).
- Criterio: **mobile first** con un solo punto de corte, `@media (min-width: 768px)`. **Por qué:** el boceto es mobile y es más fácil agrandar un diseño simple que achicar uno complejo; dos tamaños cubren lo pedido.
- Calcular: una columna en celular (mapa con altura fija de 320 px), dos columnas en PC. El orden del boceto (mapa entre los campos y el botón) se arma en SCRUM-27/33.
- Header: en celular título más chico y sin saludo; el diseño del boceto (saludo abajo + menú hamburguesa) va en SCRUM-38.
- Mapa: se sacó el estilo oscuro de `map.ts` (`DARK_MAP_STYLE`) para usar el mapa claro de Google como frontend1.
- Regla agregada al `CLAUDE.md` para que el compañero siga el mismo criterio.
- Para probar: F12 + Ctrl+Shift+M en Chrome. En la preview de Vercel puede no cargar el mapa (la clave de Maps solo acepta la URL principal y localhost).

**27/10 — PR de SCRUM-16 creado** (#3). Orden de merge: guía → dependencias → SCRUM-16.

**27/10 — SCRUM-27 Formulario de origen y destino** — rama `SCRUM-27-formulario-origen-destino` (sale de SCRUM-16 porque toca los mismos archivos)
- Primera versión: Reactive Forms en componentes separados (`route-form`, `location-input`) con `ControlValueAccessor`. **Descartada:** demasiado compleja para algo que solo se usa en una pantalla.
- **Criterio nuevo de componentes:** componente aparte solo si se usa en 2 o más pantallas o tiene lógica compleja (el mapa). Si no, va directo en la página. Se borran `route-form` y `location-input`.
- **Revisé el modelo de parcial de la cátedra** (`parcialp1/pp3`) y cambiamos al estilo que usan:
  - **Signal Forms** (`signal` con los datos + `form()` con reglas + `[formField]`), en vez de Reactive Forms.
  - `httpResource` para GET; `HttpClient` + `subscribe` + `reload()` para POST/PATCH/DELETE.
  - `@Service()` para servicios; carpetas `services/`, `models/`, `guards/`, `interceptors/` directo en `app/`.
  - Componente reutilizable `mensaje-error` para los errores de formulario (yo muestro solo el primer error para no repetir mensajes).
  - Botón deshabilitado mientras el formulario sea inválido.
  - **Por qué:** es lo que la cátedra espera ver y es menos código.
- Formulario directo en `pages/calcular`: dos campos con ícono, obligatorios y sin solo espacios (`required` + `pattern(/\S/)`); `trim()` al calcular. El pedido real al back queda para SCRUM-30.
- Pendiente: avisarle al compañero el cambio de estilo **antes de que haga SCRUM-17** y actualizar el `CLAUDE.md` (estructura de carpetas y reglas de formularios, HTTP, servicios y componentes).

---

## 4. Lo que hicieron mis compañeros (en cada pull)

| Fecha | Qué entró | Qué hicieron | Me afecta en… |
|---|---|---|---|
| | | | |

## 5. Pendientes y dudas

- [ ] **Hoy:** contarle al compañero el estilo de la cátedra (Signal Forms, httpResource, @Service, carpetas) antes de que haga SCRUM-17, y pasarle el modelo de parcial.
- [ ] Actualizar `CLAUDE.md` en `docs-guia-equipo` con la estructura y reglas nuevas.
- [ ] Definir en SCRUM-33: botón Calcular pegado a los campos (recomendado) o mapa en el medio como el boceto.

- [ ] Agregar a mi compañero como colaborador en los repos de frontend2 y del back.
- [ ] Que mi compañero revise y apruebe el PR de `docs-guia-equipo`.
- [ ] Avisarle a la Persona A que la clave de Maps está escrita en `src/index.html`: en SCRUM-20 conviene pasarla a los archivos de entorno.
- [ ] Revisar más adelante (`npm audit`) las 2 vulnerabilidades de `vite` que quedan: dependen de que Angular publique un `@angular/build` con un vite corregido. Solo afectan al servidor de desarrollo, no a lo que se publica en Vercel.
