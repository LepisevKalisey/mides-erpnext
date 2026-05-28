FROM frappe/erpnext:v16.19.1

# Switch to root to install system dependencies
USER root
RUN apt-get update && apt-get install -y \
    supervisor \
    nginx \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Switch back to frappe to install apps and build assets
USER frappe
WORKDIR /home/frappe/frappe-bench

# Set default configuration so that frontend builds can resolve socketio_port
RUN bench set-config -g socketio_port 9000

# Install custom apps
# --- Core business apps ---
RUN bench get-app hrms --branch version-16
RUN bench get-app insights --branch main
RUN bench get-app print_designer --branch main
RUN bench get-app https://github.com/developmentforpeople/dfp_external_storage --branch develop
RUN bench get-app https://github.com/omfsakib/pwa_frappe --branch main
RUN bench get-app eps --branch version-16
RUN bench get-app wiki --branch develop

# --- Marketplace apps (Phase 1: Install + Test) ---
RUN bench get-app https://github.com/clefincode/clefincode_chat --branch develop
RUN bench get-app https://github.com/The-Commit-Company/mint --branch develop
RUN bench get-app https://github.com/vineyrawat/saas_theme --branch version-16
RUN bench get-app https://github.com/bhavesh95863/workboard

# Build assets so they are compiled inside the image
RUN bench build

# Copy configurations and scripts as root to set correct permissions
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
