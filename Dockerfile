FROM frappe/erpnext:v16.19.1

# Switch to frappe user to perform bench actions
USER frappe
WORKDIR /home/frappe/frappe-bench

# Set default configuration so that frontend builds can resolve socketio_port
RUN bench set-config -g socketio_port 9000

# Install custom apps (hrms, insights, print_designer, dfp_external_storage)
RUN bench get-app hrms --branch version-16
RUN bench get-app insights --branch main
RUN bench get-app print_designer --branch main
RUN bench get-app https://github.com/developmentforpeople/dfp_external_storage --branch develop

# Build assets so they are compiled inside the image
RUN bench build

