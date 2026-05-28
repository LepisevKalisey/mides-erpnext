FROM frappe/erpnext:v16.19.1

# 1. Switch to root to install system dependencies (rarely changes)
USER root
RUN apt-get update && apt-get install -y \
    supervisor \
    nginx \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# 2. Switch back to frappe to install apps and build assets (slow, changes only when apps list or branches change)
USER frappe
WORKDIR /home/frappe/frappe-bench

# Set default configuration so that frontend builds can resolve socketio_port
RUN bench set-config -g socketio_port 9000

# Install custom apps
# --- Core business apps ---
RUN --mount=type=cache,target=/home/frappe/.cache,uid=1000,gid=1000 \
    bench get-app hrms --branch version-16 && \
    bench get-app insights --branch main && \
    bench get-app print_designer --branch main && \
    bench get-app https://github.com/developmentforpeople/dfp_external_storage --branch develop && \
    bench get-app https://github.com/omfsakib/pwa_frappe --branch main && \
    bench get-app eps --branch version-16 && \
    bench get-app wiki --branch develop

# --- Marketplace apps (Phase 1: Install + Test) ---
RUN --mount=type=cache,target=/home/frappe/.cache,uid=1000,gid=1000 \
    bench get-app https://github.com/clefincode/clefincode_chat --branch develop && \
    bench get-app https://github.com/The-Commit-Company/mint --branch develop && \
    bench get-app https://github.com/vineyrawat/saas_theme --branch version-16 && \
    bench get-app https://github.com/bhavesh95863/workboard

# Build assets so they are compiled inside the image
RUN --mount=type=cache,target=/home/frappe/.cache,uid=1000,gid=1000 \
    bench build && \
    cp -R /home/frappe/frappe-bench/sites/assets /home/frappe/frappe-bench/assets && \
    cp /home/frappe/frappe-bench/sites/apps.txt /home/frappe/frappe-bench/apps.txt

# 3. Copy configurations and scripts (changes frequently during deployment debugging)
# We do this at the very end to maximize Docker layer cache utilization!
USER root

# Copy Nginx config
COPY nginx.conf /etc/nginx/nginx.conf
RUN sed -i 's/\r$//' /etc/nginx/nginx.conf && \
    chown frappe:frappe /etc/nginx/nginx.conf

# Copy supervisord config
COPY supervisord.conf /home/frappe/frappe-bench/supervisord.conf
RUN sed -i 's/\r$//' /home/frappe/frappe-bench/supervisord.conf && \
    chown frappe:frappe /home/frappe/frappe-bench/supervisord.conf

# Copy entrypoint script
COPY entrypoint.sh /home/frappe/frappe-bench/entrypoint.sh
RUN sed -i 's/\r$//' /home/frappe/frappe-bench/entrypoint.sh && \
    chmod +x /home/frappe/frappe-bench/entrypoint.sh && \
    chown frappe:frappe /home/frappe/frappe-bench/entrypoint.sh

# Adjust permissions for directories so frappe user can run nginx and supervisord without root
RUN chown -R frappe:frappe /var/log/nginx /var/lib/nginx /run /etc/nginx

# Switch back to frappe for running the container
USER frappe

ENTRYPOINT ["/home/frappe/frappe-bench/entrypoint.sh"]
