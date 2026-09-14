# laravel-docker-starter-ngxMsql

Plantilla de GitHub para levantar un proyecto Laravel dockerizado con **Nginx + PHP-FPM + MySQL 8**, en cualquier máquina, con un solo comando. Es la contraparte "production-like" de [laravel-docker-starter](../laravel-docker-starter) (que usa `php artisan serve` + SQLite, sin servicios extra) — usá este cuando el proyecto necesite algo más cercano a cómo se despliega en serio.

Este repo **no contiene código de Laravel**. Versiona solo el andamiaje (Dockerfiles, config de Nginx, `docker-compose.yml`, Makefile) para que siempre instales la última versión estable de Laravel al momento de crear el proyecto.

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (o Docker Engine + Compose plugin) corriendo.
- [GitHub CLI](https://cli.github.com/) (`gh`) si querés crear proyectos nuevos desde la terminal. Alternativa: botón **"Use this template"** en GitHub.

No hace falta PHP, Composer ni MySQL instalados en tu máquina: todo corre en contenedores.

## Arquitectura

Tres servicios en `docker-compose.yml`:

| Servicio | Imagen | Rol |
|---|---|---|
| `nginx` | `nginx:alpine` | Recibe las requests en `APP_PORT` (default 8000) y las pasa por FastCGI a `app`. Es el único servicio con puerto publicado al host. |
| `app` | build propio, `php:8.4-fpm` | Corre PHP-FPM. No expone puertos al host; solo lo ve `nginx` dentro de la red interna de Docker. |
| `mysql` | `mysql:8` | Base de datos, con volumen persistente `mysql-data` y healthcheck. `app` espera a que MySQL esté *healthy* (no solo iniciado) antes de arrancar. |

`./src` se monta como volumen tanto en `nginx` (para servir estáticos y que `root` apunte a `public/`) como en `app` (para que PHP-FPM ejecute el código).

## Crear un proyecto nuevo desde este template

```bash
gh repo create mi-proyecto --template harikirtandas/laravel-docker-starter-nginx-mysql --private --clone
cd mi-proyecto
make install
```

Al terminar, la app está en **http://localhost:8000**.

### Qué hace `make install` exactamente

Es idempotente: revisa el estado de `src/` y actúa según corresponda, así que podés correrlo más de una vez sin romper nada — útil si una instalación anterior se cortó a mitad de camino (por ejemplo, MySQL tardó en levantar o se cayó internet durante `composer create-project`).

| Estado de `src/` | Acción |
|---|---|
| Vacío o no existe | Corre `composer create-project laravel/laravel` |
| Tiene proyecto pero sin `vendor/` | Corre `composer install` |
| Ya instalado (`vendor/` existe) | No reinstala nada, solo levanta los contenedores |

En los tres casos, al final levanta `docker compose up -d --build` (que espera a que MySQL esté healthy antes de arrancar `app`) y corre `php artisan migrate`.

## Cómo se configura la conexión a MySQL (importante)

Las credenciales de base de datos **no se escriben en `src/.env`**. Se inyectan como variables de entorno del contenedor `app`, definidas en `docker-compose.yml`:

```yaml
environment:
  DB_CONNECTION: mysql
  DB_HOST: mysql
  DB_PORT: 3306
  DB_DATABASE: ${DB_DATABASE:-laravel}
  DB_USERNAME: ${DB_USERNAME:-laravel}
  DB_PASSWORD: ${DB_PASSWORD:-secret}
```

Laravel (vía `phpdotenv`) da prioridad a las variables de entorno reales del proceso por sobre lo que dice el archivo `.env`. Como Docker Compose las setea al crear el contenedor, Laravel las usa directamente — aunque `src/.env` diga `DB_CONNECTION=sqlite` (el default que trae `composer create-project`), no importa: nunca se lee para esto.

**Por qué así y no editando `.env` con `sed`:** evita tener la config de MySQL duplicada en dos lugares (`docker-compose.yml` y `src/.env`) que se pueden desincronizar si después cambiás una contraseña en uno y te olvidás del otro. Con este approach hay una sola fuente de verdad.

Si en algún momento necesitás cambiar el nombre de la base, usuario o contraseña, no edites `src/.env`: copiá `.env.example` (en la raíz de este repo, no en `src/`) a `.env` y modificalo ahí. `docker-compose.yml` lo lee automáticamente.

```bash
cp .env.example .env
# editar .env
make down && make up
```

## Comandos disponibles (Makefile)

| Comando | Qué hace |
|---|---|
| `make install` | Instala (o retoma la instalación de) Laravel, levanta los tres contenedores y migra la base. Correlo una sola vez por proyecto. |
| `make up` | Levanta los contenedores en segundo plano. |
| `make down` | Apaga los contenedores. **No borra datos**: `mysql-data` es un volumen con nombre que sobrevive a `down`. |
| `make shell` | Abre una terminal `bash` dentro del contenedor `app`. Desde ahí corrés `php artisan ...`, `composer require ...`, etc. |
| `make db-shell` | Abre el cliente `mysql` conectado a la base del proyecto, usando las mismas credenciales del contenedor. |
| `make fresh` | Corre `migrate:fresh --seed`: **borra todas las tablas** y las recrea con seeders. Pide confirmación explícita antes de ejecutar. |

Ejemplo de uso día a día:

```bash
make up
make shell
php artisan tinker
exit
make down
```

## Por qué `src/` está gitignoreado

Igual que en el starter con SQLite: este repo versiona la **receta** (cómo levantar Laravel con Nginx + MySQL), no una copia congelada del framework. Cada `make install` en un proyecto nuevo baja la versión estable más reciente de Laravel. Si el proyecto real necesita versionar `src/` completo, esa decisión se toma en el repo que se crea *a partir* de este template, no acá.

## Puertos y datos persistentes

- `APP_PORT` (default `8000`) controla el puerto público de Nginx. Permite correr varios proyectos de este starter en paralelo: `APP_PORT=8001 make up`.
- Los datos de MySQL viven en el volumen con nombre `mysql-data`, no en `src/`. Sobreviven a `make down` y a reinicios de Docker. Para borrarlos de verdad: `docker compose down -v` (fuera del Makefile a propósito, para que no sea un comando de un solo tipeo).

## Compatibilidad Mac/Linux (permisos de archivos)

El servicio `app` corre como usuario no-root (UID/GID configurables por build args, default `1000`). En Mac es indistinto — Docker Desktop traduce el ownership al usuario del host sin importar la UID del contenedor. En Linux nativo (ej. Ubuntu) sí importa: sin esto, `composer create-project` y PHP-FPM escribirían en `src/` como `root`, y no podrías editar/borrar esos archivos con tu usuario normal sin `sudo`.

`make install` pasa tu UID/GID real (`$(id -u)`/`$(id -g)`) tanto a los `docker run` efímeros de Composer como al build de la imagen (`HOST_UID`/`HOST_GID`), así que funciona igual en las dos plataformas sin tocar nada a mano.

## Variante más simple (SQLite)

Si el proyecto no necesita MySQL ni Nginx, usá [laravel-docker-starter](../laravel-docker-starter): un solo contenedor, SQLite, cero configuración de base de datos.
