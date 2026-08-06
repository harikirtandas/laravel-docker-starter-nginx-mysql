# laravel-docker-starter-ngxMsql

- MySQL 8 + Nginx es el stack (contraparte de [laravel-docker-starter](../laravel-docker-starter), que usa SQLite sin Nginx).
- El código de Laravel vive en `src/`, gitignoreado: este repo versiona solo el andamiaje Docker.
- Nginx (`nginx`) expone el puerto público y proxea por FastCGI a PHP-FPM (`app`, puerto 9000 interno). El navegador nunca habla directo con `app`.
- Las credenciales de DB se inyectan como variables de entorno en el servicio `app` de `docker-compose.yml`, no editando `src/.env`. Laravel/phpdotenv respeta las variables de entorno reales por sobre lo que dice `.env`, así que `src/.env` puede seguir diciendo `DB_CONNECTION=sqlite` sin que afecte nada — ignorarlo.
- Todo comando de Artisan/Composer corre vía `docker compose exec app ...` (o `make shell`). Para MySQL directo, `make db-shell`.
- `make install` es idempotente: detecta si `src/` está vacío, tiene proyecto sin `vendor/`, o ya está instalado.
