#!/bin/sh
DATADIR='/var/lib/mysql'
MARIADB_PID=
DATABASE_ALREADY_EXISTS='false'
SOCKET=/var/lib/mysql/mysql.sock

check_env() {
	i=0
	while read var; do
		content=$(eval "echo \${$var}")
		if [ -z "$content" ]; then
			echo "You need to specify $var"
			i=$((i+1))
		fi
	done << EOF
MARIADB_ROOT_PASSWORD
MARIADB_USER
MARIADB_PASSWORD
MARIADB_DATABASE
EOF

	if [ $i -gt 0 ]; then
		exit 1
	fi
}

switch_user() {
	if [ "$(id -u)" = "0" ]; then
		echo "Switching to dedicated user 'mysql'"
		exec su-exec mysql sh $0 $@
	fi
}

prepare_files() {
	if [ "$(id -u)" = "0" ]; then
		echo -e "[client-server] \n\
				socket=$SOCKET \n\
				port=3306 \n\
				[mysqld] \n\
				datadir=/var/lib/mysql \n\
				skip-bind-address \n\
				skip-networking=false" > /etc/my.cnf
		mkdir -p "$DATADIR"
		find "$DATADIR" \! -user mysql -exec chown mysql: '{}' +
	fi
}

init_database() {
	mysql_install_db --user=mysql --datadir="$DATADIR" --rpm --auth-root-authentication-method=normal \
		--skip-test-db \
		--default-time-zone=SYSTEM --enforce-storage-engine= \
		--skip-log-bin \
		--expire-logs-days=0 \
		--loose-innodb_buffer_pool_load_at_startup=0 \
		--loose-innodb_buffer_pool_dump_at_shutdown=0
}

temp_server_start() {
	"$@" --skip-networking --default-time-zone=SYSTEM --socket="${SOCKET}" --wsrep_on=OFF \
		--expire-logs-days=0 \
		--loose-innodb_buffer_pool_load_at_startup=0 &
	MARIADB_PID=$!
	echo "Waiting for temp server startup"
	extraArgs=''
	if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
		extraArgs='--dont-use-mysql-root-password'
	fi
	local i
	for i in {30..0}; do
		if echo 'SELECT 1' | mysql --protocol=socket -uroot -hlocalhost --socket="${SOCKET}" $extraArgs &> /dev/null; then
			break
		fi
		sleep 1
	done
	if [ "$i" = 0 ]; then
		mysql_error "Unable to start temp server."
	fi
}

temp_server_stop() {
	kill "$MARIADB_PID"
	wait "$MARIADB_PID"
}

sql_escape_string_literal() {
	local newline=$'\n'
	local escaped=${1//\\/\\\\}
	escaped="${escaped//$newline/\\n}"
	echo "${escaped//\'/\\\'}"
}

setup_db() {
	echo "Creating database ${MARIADB_DATABASE} with user ${MARIADB_USER} and passwords"

	rootPassEsc=$( sql_escape_string_literal "$MARIADB_ROOT_PASSWORD" )
	userPassEsc=$( sql_escape_string_literal "$MARIADB_PASSWORD" )

	mariadb --protocol=socket -uroot -hlocalhost --socket="${SOCKET}" --binary-mode --database=mysql <<-EOSQL
		SET @orig_sql_log_bin= @@SESSION.SQL_LOG_BIN;
		SET @@SESSION.SQL_LOG_BIN=0;
		SET @@SESSION.SQL_MODE=REPLACE(@@SESSION.SQL_MODE, 'NO_BACKSLASH_ESCAPES', '');

		DROP USER IF EXISTS root@'127.0.0.1', root@'::1', root@'localhost';
		EXECUTE IMMEDIATE CONCAT('DROP USER IF EXISTS root@\'', @@hostname,'\'');

		CREATE USER 'root'@'localhost' IDENTIFIED BY '$rootPassEsc' ;
		GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION ;

		DROP DATABASE IF EXISTS test ;
		SET @@SESSION.SQL_LOG_BIN=@orig_sql_log_bin;

		CREATE DATABASE IF NOT EXISTS $MARIADB_DATABASE;

		CREATE USER '$MARIADB_USER'@'%' IDENTIFIED BY '$userPassEsc';
		GRANT ALL ON ${MARIADB_DATABASE//_/\\_}.* TO '$MARIADB_USER'@'%';
	EOSQL

	echo "Database and user created"
}

main() {
	if [ -d "$DATADIR/mysql" ]; then
		DATABASE_ALREADY_EXISTS='true'
	fi

	if [ "$DATABASE_ALREADY_EXISTS" = 'false' ]; then
		check_env
		echo "Installing MariaDB..."
		prepare_files
		switch_user $@
		init_database

		echo "Starting temporary server"
		temp_server_start "$@"
		echo "Temporary server started."

		setup_db

		echo "Stopping temporary server"
		temp_server_stop
		echo "Temporary server stopped"

		echo -e "\nMariaDB init process done. Ready for start up.\n"
		echo "Starting MariaDB..."
		exec "$@"
	else
		prepare_files
		switch_user $@
		echo "MariaDB is already installed"
		echo "Starting MariaDB..."
		exec "$@"
	fi
}

if [ "$1" = 'mariadbd' ]; then
	main $@
else
	exec "$@"
fi
