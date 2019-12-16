#!/bin/sh
set -e

#
# START OF DEFAULT JVM ARGS
#

# This is the reorganized list of "application default JVM args" from Gradle build
# NOTE: The Docker build currently modifies the auditor script to remove these

JR_GC_OPTS="${GC_OPTS:--XX:+UseG1GC -XX:MaxGCPauseMillis=1000 }"
if [ -n "${AUDITOR_GC_OPTS}" ]; then
  JR_GC_OPTS="${AUDITOR_GC_OPTS}"
fi
# Memory profiling
JR_GC_LOGGING_OPTS="${AUDITOR_GC_LOGGING_OPTS:--Xloggc:${HUB_APPLICATION_HOME}/logs/gc-${HUB_APPLICATION_NAME}.log -XX:+UnlockDiagnosticVMOptions -XX:+StartAttachListener -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${HUB_APPLICATION_HOME}/logs}"

AUDITOR_OPTS="$AUDITOR_OPTS -server"
AUDITOR_OPTS="$AUDITOR_OPTS -Xms512m -Xmx${HUB_MAX_MEMORY:-3072m} ${JR_GC_OPTS} ${JR_GC_LOGGING_OPTS} "

# Defaults
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.docker.enabled=true"

# Security overrides
AUDITOR_OPTS="$AUDITOR_OPTS -Djava.security.properties=${HUB_APPLICATION_HOME}/lib/security/java.security"

# Legacy logging configuration
# TODO Is this needed in the Job Runner?
AUDITOR_OPTS="$AUDITOR_OPTS -Dorg.apache.cxf.Logger=org.apache.cxf.common.logging.Log4jLogger"

# HTTP client timeout for large requests
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.rest.client.httpclient.read.timeout=900000"

# Directory configurations
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.homeURL=file:///opt/blackduck/hub/"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.scm.clone.dir=/var/lib/blckdck/hub/clones"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.scm.fetch.dir=/var/lib/blckdck/hub/fetches"
# TODO Who is this guy?
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.scan.csvfiles.location=/opt/blackduck/hub/csvfiles"

# Scan processing
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.scan.match.batchsize=100"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.scan.match.sha1enabled=true"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.scan.directory.blacklist.regex.group=.*nexus.*"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.large.scan.directory.threshold=NUM_BYTES:209715200,NUM_FILES:10000"

# ZooKeeper
AUDITOR_OPTS="$AUDITOR_OPTS -DzkClientTimeout=15000"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.zookeeper.config.root.path=/hub/config"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.zookeeper.config.root.path.solrcloud=/hub/solrcloud"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.zookeeper.shared.config.root.path=/blackduck/hub/shared"

AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.blackduck.system.ssl.store=${HUB_APPLICATION_HOME}/security/blackduck_system.keystore"

#
# END OF DEFAULT JVM ARGS
#

dockerSecretDir=${RUN_SECRETS_DIR:-/run/secrets}

# Set the application name
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.applicationHome=/opt/blackduck/hub/auditor"

# Enable database migrations
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.admin.db.migrate=true"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.admin.db.migrate=true"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.bdio.db.migrate=true"

# HUB_LOGSTASH_HOST/PORT
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.logstash.host=${HUB_LOGSTASH_HOST:-logstash}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.logstash.port=${HUB_LOGSTASH_PORT:-4560}"

# Log4j config location
AUDITOR_OPTS="$AUDITOR_OPTS -Dlog4j.configurationFile=file://$AUDITOR_HOME/conf/log4j2.properties"

# HUB_ZOOKEEPER_HOST/PORT
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.zookeeper.connection.string=${HUB_ZOOKEEPER_HOST:-zookeeper}:${HUB_ZOOKEEPER_PORT:-2181}"
AUDITOR_OPTS="$AUDITOR_OPTS -DzkHost=${HUB_ZOOKEEPER_HOST:-zookeeper}:${HUB_ZOOKEEPER_PORT:-2181}"

# HUB_REGISTRATION_HOST/PORT
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.regupdate.scheme=${HUB_REGISTRATION_SCHEME:-https}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.regupdate.host=${HUB_REGISTRATION_HOST:-registration}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.regupdate.port=${HUB_REGISTRATION_PORT:-8443}"

if [ -f "${dockerSecretDir}/HUB_POSTGRES_CA" ] ||  [ -f "${dockerSecretDir}/HUB_POSTGRES_CRT" ] ||  [ -f "${dockerSecretDir}/HUB_POSTGRES_KEY" ]; then
    DB_SSL_CA="${dockerSecretDir}/HUB_POSTGRES_CA"
    DB_SSL_CRT="${dockerSecretDir}/HUB_POSTGRES_CRT"
    DB_SSL_KEY="${dockerSecretDir}/HUB_POSTGRES_KEY"

    if [ -f "${dockerSecretDir}/HUB_ADMIN_POSTGRES_CRT" ] ||  [ -f "${dockerSecretDir}/HUB_ADMIN_POSTGRES_KEY" ]; then
        DB_ADMIN_SSL_CRT="${dockerSecretDir}/HUB_ADMIN_POSTGRES_CRT"
        DB_ADMIN_SSL_KEY="${dockerSecretDir}/HUB_ADMIN_POSTGRES_KEY"
    else
        DB_ADMIN_SSL_CRT="${DB_SSL_CRT}"
        DB_ADMIN_SSL_KEY="${DB_SSL_KEY}"
    fi
else
    DB_SSL_CA="${HUB_APPLICATION_HOME}/security/root.crt"
    DB_SSL_CRT="${HUB_APPLICATION_HOME}/security/hub-db-user.crt"
    DB_SSL_KEY="${HUB_APPLICATION_HOME}/security/hub-db-user.key"
    DB_ADMIN_SSL_CRT="${HUB_APPLICATION_HOME}/security/hub-db-admin.crt"
    DB_ADMIN_SSL_KEY="${HUB_APPLICATION_HOME}/security/hub-db-admin.key"
fi

# HUB_POSTGRES_HOST/PORT FOR BDS_HUB
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.db.ssl=${HUB_POSTGRES_ENABLE_SSL:-true}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.db.ssl_cert_auth=${HUB_POSTGRES_ENABLE_SSL_CERT_AUTH:-true}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.db.url=jdbc:postgresql://${HUB_POSTGRES_HOST:-postgres}:${HUB_POSTGRES_PORT:-5432}/bds_hub"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.db.sslkey=${DB_SSL_KEY}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.db.sslcert=${DB_SSL_CRT}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.db.sslrootcert=${DB_SSL_CA}"
if [ -n "${HUB_POSTGRES_CONNECTION_USER}" ]; then
  AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.db.connection.user=${HUB_POSTGRES_CONNECTION_USER}"
fi
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.db.user=${HUB_POSTGRES_USER:-blackduck_user}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.db.passwordFile=${dockerSecretDir}/HUB_POSTGRES_USER_PASSWORD_FILE"

# Reporting user - role on BDS for accessing reporting data, distinct from user assigned to separate reporting database. Used for migration scripts
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.reporting.db.user=${HUB_POSTGRES_REPORTING_USER:-blackduck_reporter}"

# FOR REPORT DB
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.db.ssl=${HUB_POSTGRES_ENABLE_SSL:-true}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.db.ssl_cert_auth=${HUB_POSTGRES_ENABLE_SSL_CERT_AUTH:-true}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.db.url=jdbc:postgresql://${HUB_POSTGRES_HOST:-postgres}:${HUB_POSTGRES_PORT:-5432}/bds_hub_report"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.db.sslkey=${DB_SSL_KEY}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.db.sslcert=${DB_SSL_CRT}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.db.sslrootcert=${DB_SSL_CA}"
if [ -n "${HUB_POSTGRES_CONNECTION_USER}" ]; then
  AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.db.connection.user=${HUB_POSTGRES_CONNECTION_USER}"
fi
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.db.user=${HUB_POSTGRES_USER:-blackduck_user}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.db.passwordFile=${dockerSecretDir}/HUB_POSTGRES_USER_PASSWORD_FILE"

# FOR BDIO
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.bdio.db.ssl=${HUB_POSTGRES_ENABLE_SSL:-true}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.bdio.db.ssl_cert_auth=${HUB_POSTGRES_ENABLE_SSL_CERT_AUTH:-true}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.bdio.db.url=jdbc:postgresql://${HUB_POSTGRES_HOST:-postgres}:${HUB_POSTGRES_PORT:-5432}/bdio"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.bdio.db.sslkey=${DB_SSL_KEY}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.bdio.db.sslcert=${DB_SSL_CRT}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.bdio.db.sslrootcert=${DB_SSL_CA}"
if [ -n "${HUB_POSTGRES_CONNECTION_USER}" ]; then
  AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.bdio.db.connection.user=${HUB_POSTGRES_CONNECTION_USER}"
fi
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.bdio.db.user=${HUB_POSTGRES_USER:-blackduck_user}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.bdio.db.passwordFile=${dockerSecretDir}/HUB_POSTGRES_USER_PASSWORD_FILE"

# ADMIN FOR EACH BDS_HUB AND BDS_HUB_REPORT
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.admin.db.ssl=${HUB_POSTGRES_ENABLE_SSL:-true}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.admin.db.ssl_cert_auth=${HUB_POSTGRES_ENABLE_SSL_CERT_AUTH:-true}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.admin.db.url=jdbc:postgresql://${HUB_POSTGRES_HOST:-postgres}:${HUB_POSTGRES_PORT:-5432}/bds_hub"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.admin.db.sslkey=${DB_ADMIN_SSL_KEY}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.admin.db.sslcert=${DB_ADMIN_SSL_CRT}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.admin.db.sslrootcert=${DB_SSL_CA}"
if [ -n "${HUB_POSTGRES_CONNECTION_ADMIN}" ]; then
  AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.admin.db.connection.user=${HUB_POSTGRES_CONNECTION_ADMIN}"
fi
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.admin.db.user=${HUB_POSTGRES_ADMIN:-blackduck}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.admin.db.passwordFile=${dockerSecretDir}/HUB_POSTGRES_ADMIN_PASSWORD_FILE"

AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.admin.db.ssl=${HUB_POSTGRES_ENABLE_SSL:-true}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.admin.db.ssl_cert_auth=${HUB_POSTGRES_ENABLE_SSL_CERT_AUTH:-true}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.admin.db.url=jdbc:postgresql://${HUB_POSTGRES_HOST:-postgres}:${HUB_POSTGRES_PORT:-5432}/bds_hub_report"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.admin.db.sslkey=${DB_ADMIN_SSL_KEY}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.admin.db.sslcert=${DB_ADMIN_SSL_CRT}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.admin.db.sslrootcert=${DB_SSL_CA}"
if [ -n "${HUB_POSTGRES_CONNECTION_ADMIN}" ]; then
  AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.admin.db.connection.user=${HUB_POSTGRES_CONNECTION_ADMIN}"
fi
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.admin.db.user=${HUB_POSTGRES_ADMIN:-blackduck}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.report.admin.db.passwordFile=${dockerSecretDir}/HUB_POSTGRES_ADMIN_PASSWORD_FILE"

# Metrics Support (Export - pulled by Prometheus)
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.metrics.httpexporter.enabled=${HUB_METRICS_HTTPEXPORTER_ENABLED:-false}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.metrics.httpexporter.port=${HUB_METRICS_HTTPEXPORTER_PORT:-7070}"

# Metrics Support (Report - to Graphite, Log4j)
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.metrics.reporters=${HUB_METRICS_REPORTERS}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.metrics.reporter.period=${HUB_METRICS_REPORTER_PERIOD}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.metrics.reporter.time.unit=${HUB_METRICS_REPORTER_TIME_UNIT}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.metrics.reporter.graphite.host=${HUB_METRICS_REPORTER_GRAPHITE_HOST}"
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.metrics.reporter.graphite.port=${HUB_METRICS_REPORTER_GRAPHITE_PORT}"

if [ -n "$HUB_VERSION" ]; then
    AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.product.version=${HUB_VERSION}"
fi

# Scan settings
AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.scan.map.component.kb.allowPartial=${HUB_SCAN_ALLOW_PARTIAL:false}"

# HUB_KB_HOST (port is not currently configurable, always 443)
if [ -n "$HUB_KB_HOST" ]; then
	AUDITOR_OPTS="$AUDITOR_OPTS -DBLACKDUCK_JSONWEBTOKEN_HOST=${HUB_KB_HOST}"
	AUDITOR_OPTS="$AUDITOR_OPTS -DBLACKDUCK_KB_HOST=${HUB_KB_HOST}"
	AUDITOR_OPTS="$AUDITOR_OPTS -DBLACKDUCK_KBCLOUD_HOST=${HUB_KB_HOST}"
	AUDITOR_OPTS="$AUDITOR_OPTS -DBLACKDUCK_KBDETAIL_HOST=${HUB_KB_HOST}"
	AUDITOR_OPTS="$AUDITOR_OPTS -DBLACKDUCK_KBFEEDBACK_HOST=${HUB_KB_HOST}"
	AUDITOR_OPTS="$AUDITOR_OPTS -DBLACKDUCK_KBMATCH_HOST=${HUB_KB_HOST}"
	AUDITOR_OPTS="$AUDITOR_OPTS -DBLACKDUCK_KBSEARCH_HOST=${HUB_KB_HOST}"
	AUDITOR_OPTS="$AUDITOR_OPTS -DBLACKDUCK_KBSEARCH_VULN_HOST=${HUB_KB_HOST}"
fi

# Allow the time between reporting database transfer jobs to be configured
if [ -n "$BLACKDUCK_REPORTING_DELAY_MINUTES" ]; then
	AUDITOR_OPTS="$AUDITOR_OPTS -DBLACKDUCK_REPORTING_DELAY_MINUTES=${BLACKDUCK_REPORTING_DELAY_MINUTES}"
fi

# Hub proxy support
if [ -n "$HUB_PROXY_HOST" ]; then

    # HTTP is the common default proxy type, since https has complex semantics when proxying.
    PROTOCOL=$(echo "${HUB_PROXY_SCHEME:-http}" | tr [:upper:] [:lower:])
    echo "Using proxy : $HUB_PROXY_SCHEME over $HUB_PROXY_HOST."

    AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.proxyHandling=1"

    AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.proxy.scheme=$PROTOCOL"
    AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.proxy.transport=$PROTOCOL"

    AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.proxy.host=$HUB_PROXY_HOST"
    AUDITOR_OPTS="$AUDITOR_OPTS -D${PROTOCOL}.proxyHost=$HUB_PROXY_HOST"

    if [ -n "$HUB_PROXY_PORT" ]; then
        AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.proxy.port=$HUB_PROXY_PORT"
        # NOTE: Setting only the 'https' port may cause problems (?)
        AUDITOR_OPTS="$AUDITOR_OPTS -Dhttp.proxyPort=$HUB_PROXY_PORT"
        AUDITOR_OPTS="$AUDITOR_OPTS -Dhttps.proxyPort=$HUB_PROXY_PORT"
    fi

    if [ -n "$HUB_PROXY_USER" ]; then
        AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.proxy.user=$HUB_PROXY_USER"
        AUDITOR_OPTS="$AUDITOR_OPTS -D${PROTOCOL}.proxyUser=$HUB_PROXY_USER"
    fi

    if [ -n "$HUB_PROXY_NON_PROXY_HOSTS" ]; then
        AUDITOR_OPTS="$AUDITOR_OPTS -D${PROTOCOL}.nonProxyHosts=$HUB_PROXY_NON_PROXY_HOSTS"
    fi

    # NTLM proxy authentication support
    if [ -n "$HUB_PROXY_WORKSTATION" ]; then
        AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.proxy.workstation=$HUB_PROXY_WORKSTATION"
    fi

    if [ -n "$HUB_PROXY_DOMAIN" ]; then
        AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.proxy.domain=$HUB_PROXY_DOMAIN"
    fi

	if [ -f "$dockerSecretDir/HUB_PROXY_PASSWORD_FILE" ]; then
        PROXY_PASSWORD_METHOD="Password: FILE/SECRET"
  		AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.proxy.passwordFile='$dockerSecretDir/HUB_PROXY_PASSWORD_FILE'"
  		# NOTE: Technically this isn't supported, the legacy code may still look for it
  		AUDITOR_OPTS="$AUDITOR_OPTS -D${PROTOCOL}.proxyPassword='$(cat "$dockerSecretDir/HUB_PROXY_PASSWORD_FILE")'"
    elif [ -n "$HUB_PROXY_PASSWORD" ]; then
        PROXY_PASSWORD_METHOD="Password: ENVIRONMENT"
  		AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.proxy.password=$HUB_PROXY_PASSWORD"
  		# NOTE: Technically this isn't supported, the legacy code may still look for it
  		AUDITOR_OPTS="$AUDITOR_OPTS -D${PROTOCOL}.proxyPassword=$HUB_PROXY_PASSWORD"
  	else
        PROXY_PASSWORD_METHOD="NONE"
	fi

	echo "Proxy is configured successfully: Proxy Host: $HUB_PROXY_HOST | Proxy Port: $HUB_PROXY_PORT | Proxy Scheme: $HUB_PROXY_SCHEME | Proxy User: $HUB_PROXY_USER | Proxy WorkStation: $HUB_PROXY_WORKSTATION | Proxy Domain: $HUB_PROXY_DOMAIN | Proxy Password Method: $PROXY_PASSWORD_METHOD"
else
  echo "No proxy host provided."
fi

# Default usages
if [ -n "$BLACKDUCK_HUB_FILE_USAGE_DEFAULT" ]; then
    AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.file.usage.default=${BLACKDUCK_HUB_FILE_USAGE_DEFAULT}"
fi

if [ -n "$BLACKDUCK_HUB_DEPENDENCY_USAGE_DEFAULT" ]; then
	AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.dependency.usage.default=${BLACKDUCK_HUB_DEPENDENCY_USAGE_DEFAULT}"
fi

if [ -n "$BLACKDUCK_HUB_SOURCE_USAGE_DEFAULT" ]; then
	AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.source.usage.default=${BLACKDUCK_HUB_SOURCE_USAGE_DEFAULT}"
fi

if [ -n "$BLACKDUCK_HUB_MANUAL_USAGE_DEFAULT" ]; then
	AUDITOR_OPTS="$AUDITOR_OPTS -Dblackduck.hub.manual.usage.default=${BLACKDUCK_HUB_MANUAL_USAGE_DEFAULT}"
fi

AUDITOR_OPTS="$AUDITOR_OPTS -Djavax.net.ssl.trustStore=/opt/blackduck/hub/auditor/security/auditor.truststore"

export AUDITOR_OPTS
