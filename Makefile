.PHONY: install up down shell db-shell fresh

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
