#!/bin/bash
set -e

echo "[entrypoint] Starting monolithic entrypoint as $(whoami)..."

# 1. Wait for MariaDB and Redis using python3
echo "[entrypoint] Waiting for MariaDB at $DB_HOST:3306..."
python3 -c "
import socket, time, sys
host = '$DB_HOST'
port = 3306
for _ in range(120):
    try:
        with socket.create_connection((host, port), timeout=2):
            sys.exit(0)
    except OSError:
        time.sleep(2)
sys.exit(1)
"

echo "[entrypoint] Waiting for Redis at $REDIS_HOST:6379..."
python3 -c "
import socket, time, sys
host = '$REDIS_HOST'
port = 6379
for _ in range(120):
    try:
        with socket.create_connection((host, port), timeout=2):
            sys.exit(0)
    except OSError:
        time.sleep(2)
sys.exit(1)
"

# 2. Configure bench common settings
echo "[entrypoint] Configuring bench..."
bench set-config -g db_host "$DB_HOST"
bench set-config -gp db_port "$DB_PORT"
bench set-config -g redis_cache "redis://$REDIS_HOST:6379/0"
bench set-config -g redis_queue "redis://$REDIS_HOST:6379/1"
bench set-config -g redis_socketio "redis://$REDIS_HOST:6379/1"
bench set-config -gp socketio_port 9000
# Gunicorn listens on 8000 internally (proxied by Nginx)
bench set-config -g webserver_port 8000
bench set-config -g dns_multitenancy 0
bench set-config -g default_site "$SITE_NAME"

# Ensure site symlink for Host routing (if dns_multitenancy is active or for fallback)
echo "[entrypoint] Ensuring site symlinks..."
if [ -d "sites/frontend" ] && [ ! -e "sites/devcloud.mides.kz" ]; then
    ln -sf frontend sites/devcloud.mides.kz
fi

# Ensure apps.txt exists and matches the image
echo "[entrypoint] Restoring apps.txt..."
cp -f /home/frappe/frappe-bench/apps.txt sites/apps.txt

# Ensure assets symlink
echo "[entrypoint] Ensuring assets symlink..."
rm -rf sites/assets 2>/dev/null
ln -sf /home/frappe/frappe-bench/assets sites/assets

# 3. Check if site and database exist
SITE_NAME="frontend"
SITE_CONFIG="sites/$SITE_NAME/site_config.json"
SHOULD_CREATE=0

if [ ! -f "$SITE_CONFIG" ]; then
    echo "[entrypoint] site_config.json not found for site '$SITE_NAME' — will create."
    SHOULD_CREATE=1
else
    echo "[entrypoint] site_config.json found — checking if database exists in MariaDB..."
    DB_NAME=$(python3 -c "import json; print(json.load(open('$SITE_CONFIG')).get('db_name', ''))" 2>/dev/null || echo "")
    if [ -z "$DB_NAME" ]; then
        echo "[entrypoint] Could not read db_name from site_config.json — recreating site."
        SHOULD_CREATE=1
    else
        DB_EXISTS=$(mariadb -h "$DB_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES LIKE '$DB_NAME';" 2>/dev/null | grep "$DB_NAME" || echo "")
        if [ -z "$DB_EXISTS" ]; then
            echo "[entrypoint] Database '$DB_NAME' does not exist in MariaDB — recreating site."
            SHOULD_CREATE=1
        else
            echo "[entrypoint] Database '$DB_NAME' exists."
        fi
    fi
fi

if [ "$SHOULD_CREATE" -eq 1 ]; then
    echo "[entrypoint] Creating site '$SITE_NAME'..."
    bench new-site "$SITE_NAME" --db-root-password "$MYSQL_ROOT_PASSWORD" --admin-password admin --install-app erpnext --force
    echo "[entrypoint] Site created."
else
    echo "[entrypoint] Site and database exist — skipping creation."
fi

# 4. Ensure DB grants for all container IPs
echo "[entrypoint] Ensuring database user grants..."
DB_USER=$(python3 -c "import json; print(json.load(open('$SITE_CONFIG'))['db_user'])")
DB_PASS=$(python3 -c "import json; print(json.load(open('$SITE_CONFIG'))['db_password'])")
DB_NAME=$(python3 -c "import json; print(json.load(open('$SITE_CONFIG'))['db_name'])")
mariadb -h "$DB_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS'; FLUSH PRIVILEGES;" && echo "[entrypoint] GRANT OK" || echo "[entrypoint] GRANT failed (non-fatal)"

# 5. Run bench migrate
echo "[entrypoint] Running bench migrate..."
bench --site "$SITE_NAME" migrate

# 6. Install apps
echo "[entrypoint] Installing apps..."
for app in hrms print_designer insights dfp_external_storage pwa_frappe eps wiki clefincode_chat mint saas_theme workboard; do
    echo "[entrypoint] Ensuring app '$app' is installed..."
    bench --site "$SITE_NAME" install-app "$app" || true
done

# 7. Start Supervisord (Supervisord will run Gunicorn on 8000 and Nginx on 8080)
echo "[entrypoint] Starting Supervisord..."
exec supervisord -c /home/frappe/frappe-bench/supervisord.conf
