# laravel-docker-starter-ngxMsql

- MySQL 8 + Nginx es el stack (contraparte de [laravel-docker-starter](../laravel-docker-starter), que usa SQLite sin Nginx).
- El código de Laravel vive en `src/`, gitignoreado: este repo versiona solo el andamiaje Docker.
- Nginx (`nginx`) expone el puerto público y proxea por FastCGI a PHP-FPM (`app`, puerto 9000 interno). El navegador nunca habla directo con `app`.
- `DB_HOST`/`DB_PORT`/`DB_USERNAME`/`DB_PASSWORD` se inyectan como variables de entorno del servicio `app` en `docker-compose.yml`, no editando `src/.env`. Laravel/phpdotenv respeta las variables de entorno reales por sobre lo que dice `.env` para esas cuatro.
- **`DB_CONNECTION` y `DB_DATABASE` son la excepción deliberada: NUNCA van en `environment:`.** `make install` los escribe en `src/.env` (vía `docker/patch-env-mysql.sh`, idempotente) — mismo patrón que usa Laravel Sail. Motivo: Laravel resuelve `env()` leyendo `$_SERVER` antes que `$_ENV`/`getenv()` (`Illuminate\Support\Env` → `Dotenv\Repository\RepositoryBuilder::DEFAULT_ADAPTERS`), y una variable de entorno real del contenedor puebla `$_SERVER` de una forma que ni `phpunit.xml` ni `.env.testing` pueden pisar después. Manteniendo estas dos solo en `.env`, el `phpunit.xml` default de Laravel (`DB_CONNECTION=sqlite`) aísla los tests sin configuración extra.
- Todo comando de Artisan/Composer corre vía `docker compose exec app ...` (o `make shell`). Para MySQL directo, `make db-shell`. Para tests, `make test` (o directamente `php artisan test`/`vendor/bin/phpunit` — cualquiera es seguro, no depende de un wrapper).
- `make install` es idempotente: detecta si `src/` está vacío, tiene proyecto sin `vendor/`, o ya está instalado. El paso de `.env` (`docker/patch-env-mysql.sh`) también es idempotente.
