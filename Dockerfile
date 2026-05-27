FROM frappe/erpnext:v16.19.1

# Switch to frappe user to perform bench actions
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
