#!/usr/bin/env bash
# Sets up the Laravel .env file with database and app configuration based on the stack's .env settings.
set -euo pipefail

ENV_FILE="src/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: $ENV_FILE not found. Run 'make install' first." >&2
    exit 1
fi

update_env() {
    local key="$1"
    local value="$2"
    if grep -q "^${key}=" "$ENV_FILE"; then
        perl -pi -e "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    else
        echo "${key}=${value}" >> "$ENV_FILE"
    fi
}

# Read values from stack .env
STACK_DOMAIN="$(grep -E '^DOMAIN=' .env 2>/dev/null | cut -d= -f2 || echo 'dockvel.test')"
STACK_DB_DATABASE="$(grep -E '^DB_DATABASE=' .env 2>/dev/null | cut -d= -f2 || echo 'laravel')"
STACK_DB_USERNAME="$(grep -E '^DB_USERNAME=' .env 2>/dev/null | cut -d= -f2 || echo 'laravel')"
STACK_DB_PASSWORD="$(grep -E '^DB_PASSWORD=' .env 2>/dev/null | cut -d= -f2 || echo 'secret')"
STACK_DB_PORT="$(grep -E '^DB_PORT=' .env 2>/dev/null | cut -d= -f2 || echo '5432')"
STACK_REDIS_PORT="$(grep -E '^REDIS_PORT=' .env 2>/dev/null | cut -d= -f2 || echo '6379')"

update_env "APP_URL"        "https://${STACK_DOMAIN}"
update_env "DB_CONNECTION"  "pgsql"
update_env "DB_HOST"        "postgres"
update_env "DB_PORT"        "${STACK_DB_PORT}"
update_env "DB_DATABASE"    "${STACK_DB_DATABASE}"
update_env "DB_USERNAME"    "${STACK_DB_USERNAME}"
update_env "DB_PASSWORD"    "${STACK_DB_PASSWORD}"
update_env "REDIS_HOST"     "redis"
update_env "REDIS_PORT"     "${STACK_REDIS_PORT}"
update_env "REDIS_CLIENT"   "phpredis"

# Remove SQLite default value to avoid conflicts
perl -pi -e 's|^DB_CONNECTION=sqlite.*\n||' "$ENV_FILE" 2>/dev/null || true

echo "Laravel .env successfully configured."
