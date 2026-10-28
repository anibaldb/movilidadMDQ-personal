# Estado del proyecto — Movilidad MDQ

> Última actualización: **2026-08-23**
> Documento vivo: lo vamos actualizando a medida que avanzamos.

---

## 1. Resumen del proyecto

App de movilidad para Mar del Plata (Programación 3 — UTN). Estructura de carpetas:

| Carpeta | Qué es | Estado |
|---|---|---|
| `movilidad-mdq/` | Backend Spring Boot (Java 21, Maven, Docker) | En producción ✅ |
| `frontend1/` | Front actual: React 19 + Vite + TypeScript | En producción ✅ |
| `frontend2/` | Front nuevo (se hace este año: HTML/CSS/JS → Angular) | En construcción 🚧 |

---

## 2. Arquitectura actual

- **Backend:** Spring Boot dockerizado, corriendo en una instancia **EC2 de AWS**.
- **Base de datos:** **MySQL en AWS RDS** (el back se conecta por `SPRING_DATASOURCE_URL`).
- **Dominio del back:** `https://movilidadmdq.ddns.net` (DDNS → IP de la EC2, con HTTPS por reverse proxy).
- **Front1:** desplegado en **Vercel** (cuenta nueva, propia). Le pega al back directo.
- **Google Cloud (Maps + login):** proyecto propio **"My Maps Project"** con billing. Key de Maps y cliente de OAuth propios. ✅
- **Deploy del back:** GitHub Actions (`.github/workflows/deploy.yml`) → push a `main` → SSH a la EC2 → `git pull` + `docker-compose up -d --build` + healthcheck.

### Flujo front → back
El front llama a la API con `VITE_API_URL = https://movilidadmdq.ddns.net` (directo, cross-origin → habilitado por CORS). El login con Google va a `VITE_OAUTH_BASE_URL/oauth2/authorization/google` → el back rebota a Google → vuelve al back (`/login/oauth2/code/google`) → el back manda al front con un token (`/oauth2/redirect?token=`).

---

## 3. Datos clave / referencias

> ⚠️ Los secretos (tokens, passwords, JWT_SECRET, client secret, API keys) **NO** van en este archivo. Viven en el `.env` de la EC2 y en los paneles de GitHub/Vercel/Google. Acá solo dónde están.

| Cosa | Valor |
|---|---|
| Repo backend | `github.com/anibaldb/movilidadmdq` (privado) |
| Repo frontend1 | `github.com/anibaldb/movilidadmdq-frontend1` |
| Repo frontend2 | `github.com/anibaldb/movilidadmdq-frontend2` |
| IP EC2 | `18.218.9.42` (usuario SSH: `ubuntu`) |
| Dominio back | `movilidadmdq.ddns.net` |
| URL front1 (Vercel) | `https://movilidadmdq-frontend1.vercel.app` |
| URL front2 (Vercel) | _(anotar la URL cuando la tengas a mano)_ |
| Base de datos | AWS RDS MySQL (endpoint en el `.env` de la EC2) |
| Key SSH de la EC2 | `movilidad-key.pem` (dentro de `movilidad-mdq/`, ignorada por git) |
| Disco EC2 | 16 GB (se agrandó de 8 GB el 16/08/2026) |
| Proyecto Google Cloud | `My Maps Project` (ID `graphical-reach-505912-v2`) |
| Cuenta de facturación Google | `018B61-A8E3A8-63E986` (prueba gratuita, $300 / 90 días) |
| OAuth callback (Google) | `https://movilidadmdq.ddns.net/login/oauth2/code/google` |

### Variables de entorno del front (en Vercel, proyecto frontend1)
- `VITE_GOOGLE_MAPS_API_KEY` = _(key de Maps del proyecto propio)_
- `VITE_API_URL` = `https://movilidadmdq.ddns.net`
- `VITE_OAUTH_BASE_URL` = `https://movilidadmdq.ddns.net`

---

## 4. Lo que hicimos (2026-08-16)

### Backend / EC2
- **Cambio de repo de origen:** el `origin` de la EC2 apuntaba al repo viejo (`ciroschot-dev/movilidad-mdq`). Se repuntó a `anibaldb/movilidadmdq` (`git remote set-url` + `reset --hard origin/main`).
- **Credenciales de git en la EC2:** repo privado → PAT guardado con `git config credential.helper store` (para que la GitHub Action también pueda hacer `pull`).
- **Ajustes de memoria llevados al repo:** `Dockerfile` y `docker-compose.yml` tenían tuneos hechos a mano solo en el server (imagen JRE en vez de JDK, `-Xms128m -Xmx384m`, `mem_limit: 450m`). Se commitearon al repo. Se mantuvo `restart: unless-stopped`.
- **Disco lleno:** se limpió Docker y se **agrandó el volumen EBS de 8 GB a 16 GB** (`growpart /dev/nvme0n1 1` + `resize2fs /dev/nvme0n1p1`).
- **Redeploy exitoso:** el back corre la versión nueva (contrato con campo `precio`).
- **`.env` actualizado:** `APP_OAUTH2_REDIRECT_URI` → URL nueva del front + `APP_CORS_ALLOWED_ORIGINS` con la URL nueva; y `GOOGLE_OAUTH_CLIENT_ID`/`GOOGLE_OAUTH_CLIENT_SECRET` reemplazados por los propios.
- Recordar tener cargados los secrets `EC2_HOST` y `EC2_SSH_KEY` en el repo nuevo (para el deploy automático).

### Frontends
- Se crearon los repos `movilidadmdq-frontend1` (React/Vite) y `movilidadmdq-frontend2` (scaffold placeholder HTML).
- Cuenta nueva de Vercel propia; los dos repos importados como proyectos separados.
- **Login con Google arreglado:** el botón mandaba al front en vez de al back porque `VITE_OAUTH_BASE_URL`/`VITE_API_URL` quedaban vacíos. Se setearon explícitos a `https://movilidadmdq.ddns.net`. ✅
- El proyecto viejo de Vercel lo maneja un compañero → se deja como está.

### Google Cloud (independencia total) ✅
- **Maps:** el mapa/autocompletado fallaban (`BillingNotEnabledMapError`) porque la key salía de un proyecto sin billing. Se pasó a usar la key del proyecto propio **"My Maps Project"** (que sí tiene billing), con **Maps JavaScript API + Places API + Geocoding API** habilitadas y la key **restringida** por HTTP referrer a la URL de Vercel + `localhost`.
- **Login:** se creó **pantalla de consentimiento OAuth propia** (External, publicada en Production) y un **OAuth 2.0 Client ID propio** (Web app, redirect `https://movilidadmdq.ddns.net/login/oauth2/code/google`). Se reemplazaron las credenciales en el `.env` del EC2. **Ya no depende de las credenciales de los compañeros.** ✅

---

## 5. Pendientes / próximos pasos

### Corto plazo
- [ ] **Activar la cuenta completa de Google Cloud** antes de que se venzan los **90 días de prueba (~14/11/2026)** o se acabe el crédito de $300. Si no, el proyecto se frena y se caen mapa + login. Con el uso bajo del proyecto, al activar igual quedás en el tramo gratis (no te cobran). Conviene también:
  - [ ] Presupuesto con alerta (Billing → Budgets & alerts, ej. US$1).
- [ ] **Acceso admin:** las credenciales del admin no están en el `.env` actual (se sembró en un arranque anterior). Para recuperar acceso, update en la base (RDS):
  - Opción A: resetear la password del usuario `admin` (nuevo hash BCrypt).
  - Opción B (más cómoda): darle rol `ADMIN` a tu propia cuenta de Google.
- [ ] Anotar la URL de Vercel de frontend2 en la tabla de referencias.
- [ ] (Opcional) Borrar backups viejos en la EC2: `rm Dockerfile.bak docker-compose.yml.bak .env.bak .env.bak2`.

### Mediano / largo plazo
- [ ] **frontend2:** aprender HTML, CSS y JS, después Angular, y construir el front nuevo.
- [ ] (Opcional) Pasar el back a un **servidor propio** (ver sección 7).
- [ ] (Opcional) Migrar la base fuera de RDS (a un MySQL propio) con `mysqldump`.
- [ ] (Opcional) Actualizar `docker-compose` v1 (deprecado) al plugin v2 (`docker compose`).

---

## 6. Runbook — comandos útiles

### Conectarse a la EC2
```bash
ssh -i "ruta/movilidad-key.pem" ubuntu@18.218.9.42
```

### Ver estado del back
```bash
cd ~/movilidad-mdq
sudo docker-compose ps
sudo docker-compose logs --tail=80 app
```

### Redeploy manual del back (si hiciera falta)
```bash
cd ~/movilidad-mdq
git pull origin main
sudo docker-compose down
sudo docker-compose up -d --build
```
> Nota: usar `down` + `up`, **no** `up --force-recreate` (el docker-compose v1 tira un bug de `ContainerConfig`).

### Aplicar cambios del `.env` (sin recompilar)
```bash
cd ~/movilidad-mdq
sudo docker-compose down
sudo docker-compose up -d
```

### Ver espacio en disco
```bash
df -h /
sudo docker system df
```

### Deploy automático
Cualquier `push` a `main` del repo `anibaldb/movilidadmdq` dispara la GitHub Action que deploya sola (requiere los secrets `EC2_HOST` y `EC2_SSH_KEY`).

---

## 7. Cómo pasar el back a un servidor propio (pasos por arriba)

1. Conseguir el servidor (VPS o máquina propia con Linux; IP pública o DDNS + port forwarding si es casera).
2. Preparar: usuario + SSH por key, instalar Docker + docker-compose.
3. Decidir la base: **dejar la RDS** (simple) o migrar la DB también (`mysqldump` + restore).
4. Clonar `anibaldb/movilidadmdq` y recrear el `.env` (no está en git).
5. `docker-compose up -d --build`.
6. Reverse proxy con HTTPS delante del `:8080` (**Caddy** es lo más fácil; Nginx la alternativa).
7. **Repuntar el mismo dominio** `movilidadmdq.ddns.net` a la IP nueva → así el front y Google OAuth no cambian.
8. Firewall: abrir 80/443, dejar 8080 interno.
9. Ajustar el `deploy.yml` (host nuevo).
10. Apagar la EC2 cuando esté todo verificado.

> El truco que ahorra más trabajo: **mantener el mismo dominio** y **dejar la RDS**.

---

## 8. Gotchas aprendidos (para no volver a tropezar)

- El `.env` de la EC2 **no está en git** — vive solo en el server. Si armás un server nuevo, hay que recrearlo a mano.
- Al **cambiar el repo de origen**: repuntar el `origin` en la EC2, cargar PAT y recargar los secrets de la Action.
- Los ajustes de memoria (JRE + `-Xmx384m` + `mem_limit`) viven en el repo — no editar a mano en el server.
- El front necesita `VITE_API_URL` y `VITE_OAUTH_BASE_URL` **explícitos** apuntando al back; si quedan vacíos, el login rompe.
- Google Maps exige **billing habilitado** en el proyecto de la key (`BillingNotEnabledMapError` = proyecto sin facturación). La prueba gratuita ya cuenta como billing.
- La **API key** tiene que tener la URL de Vercel en sus HTTP referrers, o falla desde el front.
- El **OAuth callback** en Google Cloud tiene que ser exacto: `https://movilidadmdq.ddns.net/login/oauth2/code/google` (si no, `redirect_uri_mismatch`).
- `docker-compose` v1: nunca `--force-recreate` (bug); usar `down` + `up`.
- **frontend2 (Angular) en Vercel — no sirve el `index.html` de la raíz, hay que COMPILAR** (nos pasó 13/09/2026). El repo `movilidadmdq-frontend2` tenía la app de Angular (`FrontendMovilidadMDP`, Angular 22) pero también un `index.html` placeholder en la raíz; Vercel lo servía como sitio estático y mostraba siempre "en construcción". Solución en Vercel → Settings → Build & Development: **Framework = Angular**, **Build Command = `ng build`**, **Output Directory = `dist/FrontendMovilidadMDP/browser`**, **Install = `npm install`**, y Redeploy. Conviene además borrar el `index.html` de la raíz (Angular usa `src/index.html`). Angular 22 necesita **Node 20+** en Vercel.

---

## 9. Análisis de requisitos vs app real (actualizado 2026-09-13)

> Comparación de los **Requisitos Funcionales** contra lo que realmente hace la app
> (`https://movilidadmdq-frontend1.vercel.app`), recorrida como usuario y como admin
> y cruzada con el código de `frontend1/` y `movilidad-mdq/`.

### 9.1. Qué se hizo

- **RF09** reformulado: pasó de "visualizar búsquedas favoritas" a "visualizar **direcciones favoritas**" (que es lo que hace la pestaña Favoritos).
- **RF19** resuelto con código + reformulado: se agregó el endpoint **`GET /admin/tarifas/taxi`** en el backend (`TarifaController`) y el panel admin (`AdminDashboard.tsx`) ahora muestra la **tarifa vigente en el placeholder**. El requisito quedó como "visualizar la tarifa actual del taxi".
- **Renumeración completa RF01–RF27** para que no se mezclen usuario y admin: todo lo de Cliente primero (RF01–RF16), todo lo de Admin después (RF17–RF27). Fuente de verdad: `Requisitos_Funcionales_MovMdQ_V.2.docx`.
- Con los reemplazos, **los 27 requisitos quedan cumplidos por lo que la app ya hace** (no hay que programar nada más).

### 9.2. Reemplazos aplicados (requisito viejo que no se cumplía → nuevo, real)

| Viejo | Nuevo (real) |
|---|---|
| Filtrar búsquedas favoritas | Cliente: **renombrar** una dirección favorita (RF12) |
| Favorito método de transporte | Cliente: **eliminar** una dirección favorita (RF13) |
| Filtrar historial de precios | Cliente: **iniciar sesión con Google** (RF03) |
| Historial de destinos | Cliente: **viaje frecuente** (RF09) |
| Visualizar medios de transporte | Admin: **buscar un usuario** por username/email (RF21) |
| Filtrar medios de transporte | Admin: **ver la información** de un usuario (RF22) |
| Ver info del medio de transporte | Admin: ver en la **auditoría** el transporte elegido (RF20) |
| Historial de precios de tarifas | Admin: **recargo nocturno automático** 22–06 (RF26) |

### 9.3. Requisitos que faltaría AGREGAR (features reales que la app ya hace, todavía sin RF)

> Si se quiere mostrar más alcance, estos se pueden sumar como RF nuevos (RF32+). Todos ya están implementados y funcionando.

**Cliente**
- Autocompletado de direcciones mientras se escribe (Google Places, limitado a Mar del Plata).
- Usar la ubicación actual (GPS) como origen automáticamente al abrir la app.
- Ver un mapa con el recorrido trazado entre origen y destino.
- Repetir un viaje desde el historial.
- Borrar un viaje puntual del historial.

**Admin**
- Manejar tarifa diferenciada día/noche (bajada de bandera y ficha).

**Transversal (ambos roles)**
- Cambiar entre modo claro y oscuro.
- Sesión persistente y cierre automático al vencer el token (más bien RNF de seguridad).

### 9.4. Notas técnicas (para no volver a investigar)

- **No hay historial de precios de tarifas en la base**: la tabla `tarifas` solo guarda `ultimaActualizacion` (última modificación), no versiones anteriores. Por eso se descartaron los RF21/RF22 originales en vez de construir una tabla nueva.
- **Endpoint nuevo `GET /admin/tarifas/taxi`** (solo ADMIN): devuelve la tarifa vigente. `SecurityConfig` ya protege `/admin/**` para ADMIN, no hizo falta tocar seguridad. Reusa `TarifaService.obtenerTarifaTaxi()` que ya existía.
- **Para ver los cambios en prod hay que deployar**: backend = push a `main` de `anibaldb/movilidadmdq` → GitHub Action → EC2; frontend = push a `frontend1` → Vercel.
- **Gotcha de deploy (nos pasó el 13/09/2026)**: la EC2 no pulleaba porque le faltaba el PAT de GitHub (GitHub no acepta password por HTTPS). Se regeneró el token `ec2-movilidad-deploy` (fine-grained, Contents: Read sobre `movilidadmdq`) y se guardó con `git config --global credential.helper store`. Para que la Action deploye sola además tienen que estar los secrets `EC2_HOST` y `EC2_SSH_KEY` en el repo.
- **Deploy manual de emergencia** en la EC2: `git pull origin main` + `sudo docker-compose down` + `sudo docker-compose up -d --build` (nunca `--force-recreate`).
