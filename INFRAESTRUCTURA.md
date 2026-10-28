# MovilidadMDQ — Infraestructura y backups

> Estado al **26/10/2026**. Este archivo no tiene claves ni contraseñas: esas viven solo en el server (`/opt/movilidad-mdq/.env`).

---

## 1. Restaurar un backup (lo importante)

### La línea

```bash
gunzip -c movilidadmdq_FECHA.sql.gz | sudo -u deploy docker exec -i movilidad-mdq-db sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" movilidadmdq'
```

Toma el backup comprimido, lo descomprime al vuelo y lo ejecuta dentro del contenedor de MySQL. El backup trae `DROP TABLE` + `CREATE TABLE` + `INSERT`, así que **reemplaza por completo** los datos actuales por los del backup.

### Paso a paso

**1. Elegir el backup.** Hay dos lugares:

| Dónde | Ruta | Cuántos |
|---|---|---|
| Server | `/var/backups/movilidad-mdq/` | últimos 7 días |
| Notebook | `movilidadMDQ\backup-db\dumps\` (también en OneDrive) | últimos 30 días |

Nombre: `movilidadmdq_AAAA-MM-DD_HHMM.sql.gz`. Si el server está sano, usá el de ahí. Si el server murió, usá el de la notebook.

Ver los del server:
```bash
ls -lh /var/backups/movilidad-mdq/
```

**2. (Solo si el backup está en la notebook) Subirlo al server.** En PowerShell:
```powershell
scp "C:\Users\Paola\OneDrive\Escritorio\UTN\progra3\movilidadMDQ\backup-db\dumps\movilidadmdq_FECHA.sql.gz" anibal@covacha:/tmp/
```

**3. Hacer un backup del estado actual** (por si te equivocás de archivo, poder volver):
```bash
sudo /usr/local/bin/backup-movilidad.sh
```

**4. Frenar la app** (que nadie escriba en la base mientras se restaura). MySQL sigue andando:
```bash
sudo -u deploy docker stop movilidad-mdq-app
```

**5. Restaurar** (parado en la carpeta donde está el archivo, ej. `cd /var/backups/movilidad-mdq` o `cd /tmp`):
```bash
gunzip -c movilidadmdq_FECHA.sql.gz | sudo -u deploy docker exec -i movilidad-mdq-db sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" movilidadmdq'
```
Si no imprime nada (salvo el warning de password), salió bien.

**6. Volver a levantar la app:**
```bash
sudo -u deploy docker start movilidad-mdq-app
```

**7. Verificar** (esperar ~40 segundos a que arranque Spring):
```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/api-docs     # tiene que dar 200
sudo -u deploy docker exec movilidad-mdq-db sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" movilidadmdq -e "SELECT COUNT(*) FROM usuarios;"'
```
Y entrar a la app y loguearse.

### Probar un backup sin pisar nada

Para chequear que un backup sirve, sin tocar la base real (lo restaura en una base aparte `movilidadmdq_prueba`):
```bash
sudo -u deploy docker exec movilidad-mdq-db sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE movilidadmdq_prueba;"'
gunzip -c movilidadmdq_FECHA.sql.gz | sudo -u deploy docker exec -i movilidad-mdq-db sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" movilidadmdq_prueba'
sudo -u deploy docker exec movilidad-mdq-db sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" movilidadmdq_prueba -e "SHOW TABLES; SELECT COUNT(*) FROM usuarios;"'
# al terminar, borrarla:
sudo -u deploy docker exec movilidad-mdq-db sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE movilidadmdq_prueba;"'
```

### Si el server murió del todo (server nuevo)

1. Instalar Docker, `cloudflared` (con el mismo túnel) y el runner de GitHub (ver sección 4).
2. Recrear `/opt/movilidad-mdq/.env` (las claves están en Google Cloud / Vercel / se regeneran).
3. Correr el workflow de deploy (GitHub → Actions → *Deploy Backend* → *Run workflow*): crea MySQL vacío y levanta la app.
4. Restaurar el último backup de la notebook con los pasos de arriba.

---

## 2. Cómo funcionan los backups

| Qué | Dónde | Cuándo |
|---|---|---|
| Script de backup | `/usr/local/bin/backup-movilidad.sh` (server) | — |
| Programación | `/etc/cron.d/backup-movilidad` | todos los días **03:30** |
| Log | `/var/log/backup-movilidad.log` | — |
| Copia a notebook | `movilidadMDQ\backup-db\traer-backups.ps1` | Tarea programada de Windows **"Backup MovilidadMDQ"**, **11:00** (si la notebook estaba apagada, corre al prenderla) |
| Log notebook | `movilidadMDQ\backup-db\log.txt` | — |

- El server hace `mysqldump` dentro del contenedor, lo comprime con gzip y borra los de más de 7 días.
- La notebook se conecta por **Tailscale + SSH con llave** (`anibal@covacha`), copia los `.sql.gz` y borra los locales de más de 30 días.
- Hacer un backup a mano: `sudo /usr/local/bin/backup-movilidad.sh`
- Correr la copia a mano en la notebook: `powershell -NoProfile -ExecutionPolicy Bypass -File "...\movilidadMDQ\backup-db\traer-backups.ps1"`

**Chequeo rápido de que todo anda:** mirar `backup-db\log.txt` en la notebook; la última línea tiene que ser de hoy y decir `OK`.

---

## 3. Arquitectura actual

```
Usuario ──https──► movilidadmdq-frontend1.vercel.app  (React, Vercel)
                         │  /api/*  (rewrite de vercel.json)
                         ▼
               https://api-movilidad.vendlysoft.com   (Cloudflare: HTTPS + DNS)
                         │  Cloudflare Tunnel "server-local" (sin abrir puertos)
                         ▼
   Server "covacha" (Debian, en el local) ── cloudflared ──► 127.0.0.1:8080
                         │
             ┌───────────┴────────────┐
             │ movilidad-mdq-app      │  Spring Boot 3.4 / Java 21
             │ movilidad-mdq-db       │  MySQL 8.4 (volumen movilidad-mdq_db_data)
             └────────────────────────┘
                         │
                         ├──► Google Maps (Distance Matrix)  — clave GOOGLE_MAPS_KEY
                         ├──► OpenWeather
                         └──► Google OAuth (login)
```

AWS (EC2 + RDS) **ya no se usa**. El 26/10/2026 se migraron los datos de RDS al MySQL del server (dump de RDS guardado en `movilidadMDQ\backup-db\dump_rds_2026-10-26.sql`, 4 tablas: `usuarios`, `viajes`, `direcciones_favoritas`, `tarifas`). El admin es el que ya existía en RDS.

### Piezas y dónde se configuran

| Pieza | Detalle |
|---|---|
| **Dominio** | `vendlysoft.com`, DNS en Cloudflare. Se puede reusar para otros proyectos (un subdominio por proyecto, **un solo nivel**: `algo.vendlysoft.com`, no `a.b.vendlysoft.com`) |
| **Túnel** | Cloudflare Zero Trust (plan Free) → Redes → Túneles → `server-local`. Corre como servicio `cloudflared` en el server. Ruta: `api-movilidad.vendlysoft.com` → `http://localhost:8080` |
| **Backend repo** | `github.com/anibaldb/movilidadmdq` (privado) |
| **Deploy** | `.github/workflows/deploy.yml`: push a `main` → runner self-hosted `covacha` (label `movilidad`, usuario `deploy`) → `docker compose up --build` → healthcheck a `/api-docs` |
| **Secretos del back** | Solo en `/opt/movilidad-mdq/.env` (dueño `deploy`, permisos 600). El workflow lo copia en cada deploy. Plantilla: `.env.example` del repo |
| **Frontend1** | `github.com/anibaldb/movilidadmdq-frontend1` → Vercel `movilidadmdq-frontend1.vercel.app`. `vercel.json` reenvía `/api/*` al back. Variable Vercel: `VITE_OAUTH_BASE_URL=https://api-movilidad.vendlysoft.com` (tipo Config) |
| **Google Cloud** | Proyecto "My Maps Project". Cliente OAuth **movilidad-mdq back** (`165803055561-...`), redirect `https://api-movilidad.vendlysoft.com/login/oauth2/code/google`. Clave "Maps Platform API Key" restringida a sitios web (es la del front) |
| **CORS permitido** | `localhost:5173`, `localhost:4200`, `movilidadmdq-frontend1.vercel.app`, `movilidadmdq-frontend2.vercel.app` |
| **Redirect post-login** | `https://movilidadmdq-frontend1.vercel.app/oauth2/redirect` (uno solo; ver pendientes) |
| **Swagger** | `https://api-movilidad.vendlysoft.com/swagger-ui/index.html` |

### Otros servicios en el server (no tocar sin revisar)

- `presupuestador-mysql` (otro proyecto) expuesto en `0.0.0.0:3306`.
- Al limpiar Docker **no usar** `docker system prune -a`: borraría imágenes de otros stacks.

---

## 4. Comandos útiles (server)

```bash
# Estado de los contenedores
sudo -u deploy docker ps

# Logs del back (en vivo)
sudo -u deploy docker logs -f movilidad-mdq-app

# Reiniciar el back
sudo -u deploy docker restart movilidad-mdq-app

# Aplicar un cambio en el .env sin hacer deploy
sudo -u deploy nano /opt/movilidad-mdq/.env
sudo -u deploy cp /opt/movilidad-mdq/.env /home/deploy/actions-runner/_work/movilidadmdq/movilidadmdq/.env
cd /tmp && sudo -u deploy docker compose -p movilidad-mdq --project-directory /home/deploy/actions-runner/_work/movilidadmdq/movilidadmdq up -d app

# Túnel de Cloudflare
systemctl status cloudflared
sudo systemctl restart cloudflared

# Runner de GitHub
sudo bash -c 'cd /home/deploy/actions-runner && ./svc.sh status'
sudo bash -c 'cd /home/deploy/actions-runner && ./svc.sh start'

# Entrar a MySQL
sudo -u deploy docker exec -it movilidad-mdq-db sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" movilidadmdq'
```

Probar el back desde el server sin pasar por Cloudflare:
```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/api-docs
```

---

## 5. Problemas que ya aparecieron (y la solución)

| Síntoma | Causa | Solución |
|---|---|---|
| 502 en `api-movilidad...` | El back no está corriendo | `docker ps`, ver logs |
| 401 en `/swagger-ui.html` | Esa ruta no está liberada en `SecurityConfig` | Usar `/swagger-ui/index.html` |
| Deploy rojo: `APP_ADMIN_PASSWORD está vacía` | Base sin admin + password vacía | Poner `APP_ADMIN_PASSWORD` en el `.env` |
| `redirect_uri_mismatch` en el login | `.env` con un cliente OAuth de otro proyecto | Usar el cliente `165803055561-...` |
| Runner *Offline* | Servicio no instalado/iniciado | `svc.sh install deploy` + `svc.sh start` (con `sudo bash -c 'cd ... && ...'`) |
| `permission denied ... docker.sock` | Usuario fuera del grupo `docker` | `sudo usermod -aG docker <usuario>` y reloguear |
| `Host key verification failed` (notebook) | Primer SSH con ese nombre | `ssh anibal@covacha` una vez y responder `yes` |

---

## 6. Pendientes

- [ ] Borrar `movilidadMDQ\.env.servidor` de la notebook (tiene todas las claves).
- [ ] Actualizar `GOOGLE_OAUTH_CLIENT_ID/SECRET` del `.env` local con el cliente `165803055561-...`.
- [ ] Apagar/borrar EC2 y RDS en AWS (región Ohio, us-east-2) para que no cobre más.
- [ ] Borrar `/tmp/dump_rds.sql` del server.
- [ ] Vaciar `APP_ADMIN_PASSWORD` del `.env` del server (ya no se usa: el admin vino de RDS).
- [ ] Opcional: borrar la URI vieja de `movilidadmdq.ddns.net` en Google OAuth y los secrets `EC2_HOST` / `EC2_SSH_KEY` en GitHub.
- [ ] Frontend2 (Angular): definir cómo vuelve el login de Google al front correcto (hoy hay un solo `APP_OAUTH2_REDIRECT_URI`).
- [ ] `presupuestador-mysql` escucha en `0.0.0.0:3306` (accesible desde la red del local). Lo usan 4 dispositivos por Tailscale: limitarlo a la IP de Tailscale del server (`100.x.x.x:3306:3306`) y hacer que Docker espere a `tailscaled` al arrancar.
