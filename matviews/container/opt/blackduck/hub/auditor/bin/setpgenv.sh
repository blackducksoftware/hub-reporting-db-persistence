#!/bin/bash
#

if [ -f $RUN_SECRETS_DIR/HUB_POSTGRES_ADMIN_PASSWORD_FILE ] 
then
	export PGPASSWORD=$(cat $RUN_SECRETS_DIR/HUB_POSTGRES_ADMIN_PASSWORD_FILE)
fi
export PGHOST=${HUB_POSTGRES_HOST:-postgres}
export PGPORT=${HUB_POSTGRES_PORT:-5432}
export PGUSER=${HUB_POSTGRES_ADMIN:-blackduck}


cp /opt/blackduck/hub/auditor/security/hub-db-admin.pem /tmp/key.pem
chmod 600 /tmp/key.pem

export PGSSLKEY=/tmp/key.pem
export PGSSLCERT=/opt/blackduck/hub/auditor/security/hub-db-admin.crt


