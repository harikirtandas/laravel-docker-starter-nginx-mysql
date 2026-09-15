.PHONY: install up down shell db-shell fresh test

install:
	@mkdir -p src
	@if [ ! -f src/artisan ]; then \
		echo "==> src/ vacio: creando proyecto Laravel..."; \
		docker run --rm --user "$$(id -u):$$(id -g)" -v "$(PWD)/src":/app -w /app composer:latest \
			create-project laravel/laravel . ; \
	elif [ ! -d src/vendor ]; then \
		echo "==> Proyecto existente sin vendor/: instalando dependencias..."; \
		docker run --rm --user "$$(id -u):$$(id -g)" -v "$(PWD)/src":/app -w /app composer:latest install; \
		[ -f src/.env ] || cp src/.env.example src/.env; \
	else \
		echo "==> Proyecto ya instalado, solo levantando."; \
	fi
	HOST_UID=$$(id -u) HOST_GID=$$(id -g) docker compose up -d --build
	@echo "==> Configurando .env para MySQL (DB_CONNECTION/DB_DATABASE NO se inyectan por environment: a proposito, ver README seccion 'Tests')..."
	@DB_NAME=$$(docker compose exec -T mysql sh -c 'echo $$MYSQL_DATABASE'); \
	docker compose cp docker/patch-env-mysql.sh app:/tmp/patch-env-mysql.sh; \
	docker compose exec app sh /tmp/patch-env-mysql.sh "$$DB_NAME"
	docker compose exec app php artisan migrate
	@echo "Listo -> http://localhost:$${APP_PORT:-8000}"

up:
	docker compose up -d

down:
	docker compose down

shell:
	docker compose exec app bash

db-shell:
	docker compose exec mysql sh -c 'mysql -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" "$$MYSQL_DATABASE"'

fresh:
	@read -p "Esto borra TODOS los datos con migrate:fresh. Escribi 'yes' para continuar: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		docker compose exec app php artisan migrate:fresh --seed; \
	else \
		echo "Cancelado."; \
	fi

test:
	docker compose exec app php artisan test
