# dockvel

A Docker-based local development environment for Laravel 13, featuring PHP 8.4-FPM, Nginx with HTTP/2 and HTTPS, PostgreSQL 18, and Redis 8.

## Stack

| Service   | Image / Version        |
|-----------|------------------------|
| PHP       | 8.4-FPM (custom image) |
| Nginx     | 1.28-alpine            |
| PostgreSQL| 18-alpine              |
| Redis     | 8-alpine               |

PHP extensions included: `pdo_pgsql`, `mbstring`, `exif`, `pcntl`, `bcmath`, `gd`, `zip`, `opcache`, `redis` (Xdebug optional)

## Requirements

- [Docker](https://www.docker.com/) & Docker Compose
- [mkcert](https://github.com/FiloSottile/mkcert) for local TLS certificates

```bash
brew install mkcert
```

## Getting started

```bash
# Clone the repo
git clone <repo-url> dockvel && cd dockvel

# Full setup: generates SSL cert, adds /etc/hosts entry,
# installs Laravel, configures .env, and starts containers
make install
```

After setup the app is available at **https://dockvel.test**.

## Configuration

Copy `.env.example` to `.env` (if present) and adjust the values before running `make install`.

| Variable          | Default        | Description                     |
|-------------------|----------------|---------------------------------|
| `DOMAIN`          | `dockvel.test` | Local domain                    |
| `NGINX_HTTP_PORT` | `80`           | HTTP port                       |
| `NGINX_HTTPS_PORT`| `443`          | HTTPS port                      |
| `DB_DATABASE`     | `laravel`      | PostgreSQL database name        |
| `DB_USERNAME`     | `laravel`      | PostgreSQL user                 |
| `DB_PASSWORD`     | `secret`       | PostgreSQL password             |
| `DB_PORT`         | `5432`         | PostgreSQL host port            |
| `REDIS_PORT`      | `6379`         | Redis host port                 |
| `APP_ENV`         | `local`        | Laravel application environment |
| `INSTALL_XDEBUG`  | `false`        | Install Xdebug in the PHP image |

## Make targets

| Target      | Description                                              |
|-------------|----------------------------------------------------------|
| `install`   | Full first-time setup (SSL, hosts, build, Laravel, env)  |
| `up`        | Start all containers in detached mode                    |
| `down`      | Stop and remove containers                               |
| `build`     | Rebuild images without cache                             |
| `restart`   | Restart all containers                                   |
| `logs`      | Follow container logs                                    |
| `shell`     | Open a bash shell in the app container                   |
| `configure` | Re-run the Laravel `.env` configuration script           |
| `ssl`       | Regenerate local TLS certificate via mkcert              |
| `hosts`     | Add domain entry to `/etc/hosts`                         |
| `migrate`   | Run `php artisan migrate`                                |
| `fresh`     | Run `php artisan migrate:fresh --seed`                   |
| `seed`      | Run `php artisan db:seed`                                |
| `dump`      | Export a timestamped SQL dump to `dumps/`                |
| `restore`   | Import a dump: `make restore FILE=dumps/file.sql`        |
| `init-db`   | Drop and recreate the database (run before `restore`)    |

Pass extra arguments to `artisan` or `composer` via the `CMD` variable:

```bash
make artisan CMD="make:controller UserController"
make composer CMD="require spatie/laravel-permission"
```

## Project structure

```
dockvel/
├── docker/
│   ├── nginx/
│   │   ├── default.conf.template   # Nginx config (HTTP→HTTPS + HTTP/2, PHP-FPM)
│   │   └── ssl/                    # Generated TLS certificate (git-ignored)
│   ├── php/
│   │   ├── php.ini                 # PHP runtime settings
│   │   ├── opcache.ini             # OPcache settings
│   │   └── xdebug.ini             # Xdebug settings (used when INSTALL_XDEBUG=true)
│   └── scripts/
│       └── configure-env.sh        # Patches Laravel .env for Docker
├── dumps/                          # SQL dumps (git-ignored)
├── src/                            # Laravel application (created by make install)
├── docker-compose.yml
├── Dockerfile
└── Makefile
```

## Xdebug

Xdebug is **not installed by default**. To enable it, set `INSTALL_XDEBUG=true` in your `.env` and rebuild:

```bash
make build && make up
```

To activate Xdebug only for a single build without changing `.env`:

```bash
docker compose build --build-arg INSTALL_XDEBUG=true
```

## Database dumps

```bash
make dump                                    # export to dumps/ (timestamped)
make init-db                                 # drop & recreate database
make restore FILE=dumps/dump_20260420.sql    # import dump
```

Dumps are stored in `dumps/` and git-ignored.
