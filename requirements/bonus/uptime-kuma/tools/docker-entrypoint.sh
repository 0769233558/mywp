DATAFILE=/uptime-kuma/data/kuma.db
DATABASE_ALREADY_EXISTS='false'

main() {
	if [ -f "$DATAFILE" ]; then
		DATABASE_ALREADY_EXISTS='true'
	fi

	# Wait for nginx being ready
	while ! ping -c 1 nginx > /dev/null 2>&1; do
		sleep 1
	done

	# Set hosts
	nginxIP=$(getent hosts nginx | awk '{ print $1 }')
	echo "nginx IP: $nginxIP"
	echo "$nginxIP $DOMAIN_NAME" >> /etc/hosts

	if [ "$DATABASE_ALREADY_EXISTS" = 'false' ]; then
		echo "Starting Uptime Kuma temporarily..."
		/usr/bin/node /uptime-kuma/server/server.js &
		serverPID=$!
		echo "Uptime Kuma started with PID $serverPID"
		sleep 10
		echo "Configuring Uptime Kuma..."
		python3 /configure-uptime-kuma.py
		echo "Uptime Kuma configured."
		echo "Stopping Uptime Kuma temp server..."
		kill $serverPID
	fi

	echo "Starting Uptime Kuma..."
	exec "$@"
}

if [ "$1" = 'node' ]; then
	main $@
else
	exec "$@"
fi
