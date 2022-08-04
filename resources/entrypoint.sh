#!/bin/bash

set -x

sed -i '/addons_path/c\ ;This line is removed by the admin.' ${ODOO_RC}
# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:='odoo'}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:='odoo'}}

# set all variables

if [ ! -f ${ODOO_RC} ]; then
    echo "
[options]
admin_passwd = ${ADMIN_PASSWORD}
data_dir = ${ODOO_DATA_DIR}
db_host = ${DB_PORT_5432_TCP_ADDR}
db_maxconn = ${DB_MAXCONN}
db_password = ${DB_ENV_POSTGRES_PASSWORD}
db_port = ${DB_PORT_5432_TCP_PORT}
db_sslmode = ${DB_SSLMODE}
db_template = ${DB_TEMPLATE}
db_user = ${DB_ENV_POSTGRES_USER}
dbfilter = ${DBFILTER}
http_interface = ${HTTP_INTERFACE}
http_port = ${HTTP_PORT}
limit_memory_hard = ${LIMIT_MEMORY_HARD}
limit_memory_soft = ${LIMIT_MEMORY_SOFT}
limit_time_cpu = ${LIMIT_TIME_CPU}
limit_time_real = ${LIMIT_TIME_REAL}
limit_time_real_cron = ${LIMIT_TIME_REAL_CRON}
list_db = ${LIST_DB}
log_db = ${LOG_DB}
log_db_level = ${LOG_DB_LEVEL}
logfile = ${logfile}
log_handler = ${LOG_HANDLER}
log_level = ${LOG_LEVEL}
max_cron_threads = ${MAX_CRON_THREADS}
proxy_mode = ${PROXY_MODE}
server_wide_modules = ${SERVER_WIDE_MODULES}
smtp_password = ${SMTP_PASSWORD}
smtp_port = ${SMTP_PORT}
smtp_server = ${SMTP_SERVER}
smtp_ssl = ${SMTP_SSL}
smtp_user = ${SMTP_USER}
test_enable = ${TEST_ENABLE}
unaccent = ${UNACCENT}
without_demo = ${WITHOUT_DEMO}
workers = ${WORKERS}
    " > $ODOO_RC
fi

function getAddons() {
    echo "Repos pointed"
    EXTRA_ADDONS_PATHS=$(python3 getaddons.py ${ODOO_EXTRA_ADDONS} ${ODOO_OCA_ADDONS} 2>&1)
    
    if [ "$ENTERPRISE" == "false" ]; then
        echo "Enterprise modules not pointed."
    else
        echo "Enterprise modules pointed."
    fi
}

getAddons

if [ -z "$EXTRA_ADDONS_PATHS" ]; then
    echo "The variable \$EXTRA_ADDONS_PATHS is empty, using default addons_path"
    echo "addons_path = ${ODOO_ADDONS_BASEPATH}, ${ODOO_NON_ENT_ADDONS}" >> $ODOO_RC
else
    echo "addons_path = ${ODOO_ADDONS_BASEPATH}, $EXTRA_ADDONS_PATHS, ${ODOO_NON_ENT_ADDONS}" >> $ODOO_RC
fi

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if ! grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        DB_ARGS+=("--${param}")
        DB_ARGS+=("${value}")
   fi;
}

check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

echo "Value: $1"
case "$1" in
    -- | odoo | ${ODOO_CMD})
        shift
        if [[ "$1" == "scaffold" ]] ; then
            echo "Odoo scaffold"
            echo "$@"
            exec odoo "$@"
        elif [[ "$RUN_TESTS" -eq "1" ]] ; then
            if [ -z "$EXTRA_MODULES" ]; then
                EXTRA_MODULES=$(python3 -c "from getaddons import get_modules; print(','.join(get_modules('${ODOO_EXTRA_ADDONS}', depth=3)))")
            fi
            exec odoo "$@" "--test-enable" "--stop-after-init" "-i" "${EXTRA_MODULES}" "--test-tags" "${EXTRA_MODULES}" "-d" "${TEST_DB:-test}" "${DB_ARGS[@]}"
        else
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        echo "Run Odoo"
        echo "$@"
        echo "${DB_ARGS[@]}"
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        echo "Run Odoo"
        echo "$@"
        exec "$@"
esac

exit 1
