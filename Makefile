DC   = docker compose
EXEC = $(DC) exec app

-include .env
export
DOMAIN      ?= dockvel.test
DB_USERNAME ?= laravel
DB_DATABASE ?= laravel

ssl:
	@which mkcert > /dev/null 2>&1 || (echo "mkcert nicht gefunden. Installieren: brew install mkcert" && exit 1)
	@mkdir -p docker/nginx/ssl
	mkcert -install
	mkcert -cert-file docker/nginx/ssl/cert.pem -key-file docker/nginx/ssl/key.pem $(DOMAIN) 127.0.0.1 ::1
	@echo "Zertifikat erstellt für: $(DOMAIN)"

hosts:
	@grep -q "$(DOMAIN)" /etc/hosts \
		&& echo "$(DOMAIN) is already in /etc/hosts" \
		|| (echo "127.0.0.1 $(DOMAIN)" | sudo tee -a /etc/hosts && echo "Added: 127.0.0.1 $(DOMAIN)")

install: ssl hosts
	@mkdir -p src
	$(DC) build
	@if [ ! -f src/artisan ]; then \
		echo "Starting interactive Laravel installation – choose your starter kit:"; \
		$(DC) run --rm -it app bash -c "laravel new /tmp/laravel-app && cp -a /tmp/laravel-app/. /var/www/ && rm -rf /tmp/laravel-app"; \
	else \
		echo "src/ already contains a Laravel installation – skipping."; \
	fi
	@chmod +x docker/scripts/configure-env.sh
	@bash docker/scripts/configure-env.sh
	$(DC) up -d
	$(EXEC) php artisan key:generate --force
	$(EXEC) php artisan migrate --force

configure:
	@chmod +x docker/scripts/configure-env.sh
	@bash docker/scripts/configure-env.sh

up:
	$(DC) up -d

down:
	$(DC) down

build:
	$(DC) build --no-cache

restart:
	$(DC) restart

logs:
	$(DC) logs -f

shell:
	$(EXEC) bash

artisan:
	$(EXEC) php artisan $(CMD)

composer:
	$(EXEC) composer $(CMD)

migrate:
	$(EXEC) php artisan migrate

fresh:
	$(EXEC) php artisan migrate:fresh --seed

seed:
	$(EXEC) php artisan db:seed

dump:
	@mkdir -p dumps
	$(DC) exec -T postgres pg_dump -U $(DB_USERNAME) $(DB_DATABASE) > dumps/dump_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "Dump saved in dumps/"

restore:
	@test -n "$(FILE)" || (echo "Usage: make restore FILE=dumps/file.sql" && exit 1)
	$(DC) exec -T postgres psql -U $(DB_USERNAME) $(DB_DATABASE) < $(FILE)
	@echo "Dump restored: $(FILE)"

init-db:
	$(DC) exec -T postgres psql -U $(DB_USERNAME) -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$(DB_DATABASE)' AND pid <> pg_backend_pid();"
	$(DC) exec -T postgres psql -U $(DB_USERNAME) -d postgres -c "DROP DATABASE IF EXISTS $(DB_DATABASE);"
	$(DC) exec -T postgres psql -U $(DB_USERNAME) -d postgres -c "CREATE DATABASE $(DB_DATABASE);"
	@echo "Datenbank zurückgesetzt: $(DB_DATABASE)"
