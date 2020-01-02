#!/bin/sh

if [ -z "$JAVA_HOME" ]
then
        export JAVA_HOME=$(readlink -f /etc/alternatives/java | sed  's&/bin/java&&')
fi

hubAuditorDir=/opt/blackduck/hub/auditor
hubAuditorTruststore="$hubAuditorDir/security/$HUB_APPLICATION_NAME.truststore"
dockerSecretDir=${RUN_SECRETS_DIR:-/run/secrets}

manageCertificates() {
  targetCAHost="${HUB_CFSSL_HOST:-cfssl}"
  targetCAPort="${HUB_CFSSL_PORT:-8888}"

  echo "Certificate authority host: $targetCAHost"
  echo "Certificate authority port: $targetCAPort"

  $hubAuditorDir/bin/certmanager.sh db-client-cert \
                  --ca $targetCAHost:$targetCAPort \
                  --rootcert $hubAuditorDir/security/root.crt \
                  --key $hubAuditorDir/security/hub-db-user.key \
                  --cert $hubAuditorDir/security/hub-db-user.crt \
                  --outputDirectory $hubAuditorDir/security \
                  --commonName blackduck_user
  exitCode=$?
  if [ $exitCode -eq 0 ];
  then
    chmod 644 $hubAuditorDir/security/root.crt
    chmod 400 $hubAuditorDir/security/hub-db-user.key
    chmod 644 $hubAuditorDir/security/hub-db-user.crt
  else
    echo "Unable to manage auditor database client certificate for user: blackduck_user (Code: $exitCode)."
    exit $exitCode
  fi

  $hubAuditorDir/bin/certmanager.sh db-client-cert --ca $targetCAHost:$targetCAPort --rootcert $hubAuditorDir/security/root.crt --key $hubAuditorDir/security/hub-db-admin.key --cert $hubAuditorDir/security/hub-db-admin.crt --outputDirectory $hubAuditorDir/security --commonName blackduck
  exitCode=$?
  if [ $exitCode -eq 0 ];
  then
    chmod 644 $hubAuditorDir/security/root.crt
    chmod 400 $hubAuditorDir/security/hub-db-admin.key
    chmod 644 $hubAuditorDir/security/hub-db-admin.crt
  else
    echo "Unable to manage auditor database client certificate for user: blackduck (Code: $exitCode)."
    exit $exitCode
  fi
}

manageBlackduckSystemClientCertificate() {
    echo "Attempting to generate blackduck_system client certificate and key."
    $hubAuditorDir/bin/certmanager.sh client-cert \
        --ca $targetCAHost:$targetCAPort \
        --outputDirectory $hubAuditorDir/security \
        --commonName blackduck_system
    exitCode=$?
    if [ $exitCode -eq 0 ];
    then
        chmod 400 $hubAuditorDir/security/blackduck_system.key
        chmod 644 $hubAuditorDir/security/blackduck_system.crt
    else
        echo "ERROR: Unable to generate blackduck_system certificate and key (Code: $exitCode)."
        exit $exitCode
    fi

    echo "Attempting to generate blackduck_system store."
    $hubAuditorDir/bin/certmanager.sh keystore \
        --outputDirectory $hubAuditorDir/security \
        --outputFile blackduck_system.keystore \
        --password changeit \
        --keyAlias blackduck_system \
        --key $hubAuditorDir/security/blackduck_system.key \
        --cert $hubAuditorDir/security/blackduck_system.crt
    exitCode=$?
    if [ $exitCode -ne 0 ];
    then
        echo "ERROR: Unable to generate blackduck_system store (Code: $exitCode)."
        exit $exitCode
    fi

    echo "Attempting to trust root certificate within the blackduck_system store."
    $hubAuditorDir/bin/certmanager.sh trust-java-cert \
        --store $hubAuditorDir/security/blackduck_system.keystore \
        --password changeit \
        --cert $hubAuditorDir/security/root.crt \
        --certAlias blackduck_root
    exitCode=$?
    if [ $exitCode -ne 0 ];
    then
      echo "ERROR: Unable to trust root certificate within the blackduck_system store (Code: $exitCode)."
      exit $exitCode
    fi
}

createTruststore() {
    echo "Attempting to copy Java cacerts to create truststore."
    $hubAuditorDir/bin/certmanager.sh truststore --outputDirectory $hubAuditorDir/security --outputFile $HUB_APPLICATION_NAME.truststore
    exitCode=$?
    if [ ! $exitCode -eq 0 ]; then
        echo "Unable to create truststore (Code: $exitCode)."
        exit $exitCode
    fi
}

trustRootCertificate() {
    $hubAuditorDir/bin/certmanager.sh trust-java-cert \
                        --store $hubAuditorTruststore \
                        --password changeit \
                        --cert $hubAuditorDir/security/root.crt \
                        --certAlias hub-root

    exitCode=$?
    if [ $exitCode -ne 0 ]; then
        echo "Unable to import Black Duck root certificate into Java truststore (Code: $exitCode)."
        exit $exitCode
    fi
}

trustProxyCertificate(){
    proxyCertificate="$dockerSecretDir/HUB_PROXY_CERT_FILE"

    if [ -f "$dockerSecretDir/HUB_PROXY_CERT_FILE" ]; then
        $hubAuditorDir/bin/certmanager.sh trust-java-cert \
                                --store $hubAuditorTruststore \
                                --password changeit \
                                --cert $proxyCertificate \
                                --certAlias proxycert
        exitCode=$?
        if [ $exitCode -ne 0 ]; then
            echo "Unable to import proxy certificate into Java truststore (Code: $exitCode)."
            exit $exitCode
        fi
    fi
}

manageMutualTLS() {
    echo "Creating Java Identity keystore"
    rm -f $hubAuditorDir/security/blackduck_system.keycert.pem || true
    rm -f $hubAuditorDir/security/blackduck_system.keycert.p12 || true
    rm -f $hubAuditorDir/security/blackduck_system.jks || true

    cat  $hubAuditorDir/security/blackduck_system.crt $hubAuditorDir/security/blackduck_system.key > $hubAuditorDir/security/blackduck_system.keycert.pem

    openssl pkcs12 -export \
        -in $hubAuditorDir/security/blackduck_system.keycert.pem \
        -out $hubAuditorDir/security/blackduck_system.keycert.p12 \
        -password pass:changeit \
        -name blackduck_system -noiter -nomaciter

    keytool -importkeystore -srckeystore $hubAuditorDir/security/blackduck_system.keycert.p12 \
        -srcstoretype pkcs12 -srcalias blackduck_system -srcstorepass changeit \
        -destkeystore $hubAuditorDir/security/blackduck_system.jks -deststoretype pkcs12 \
        -deststorepass changeit -destalias blackduck_system
}

manageCertificates
manageBlackduckSystemClientCertificate
createTruststore
trustRootCertificate
trustProxyCertificate
manageMutualTLS

set -e

if [ -f "$hubAuditorTruststore" ]; then
    JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=$hubAuditorTruststore"
    export JAVA_OPTS
fi

#SET FILEBEAT#
echo "Attempting to start "$(.$BLACKDUCK_HOME/filebeat/filebeat --version)
.$BLACKDUCK_HOME/filebeat/filebeat -c $BLACKDUCK_HOME/filebeat/filebeat.yml start &

echo "Attempting to start auditor."

# Allow for environment overrides similar to the Tomcat based containers
if [ -r "$AUDITOR_HOME/bin/setenv.sh" ]; then
    . "$AUDITOR_HOME/bin/setenv.sh"
fi

# Enable debugging, use same environment variables for configuration as the Tomcat based containers
if [ "$DEBUG" = true ]; then
	export JAVA_OPTS="$JAVA_OPTS -agentlib:jdwp=transport=${JPDA_TRANSPORT:-dt_socket},address=${JPDA_ADDRESS:-localhost:8000},server=y,suspend=${JPDA_SUSPEND:-n}"
	export JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.port=${JMX_REMOTE_PORT:-17545} -Dcom.sun.management.jmxremote.rmi.port=${JMX_REMOTE_PORT:-17545} -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djava.rmi.server.hostname=localhost "
fi

#SET AS NON-ROOT USER#
# Check if we are trying to run 'auditor' as 'root'
if  [ "$1" = 'auditor' ] && [ "$(id -u)" = '0' ]; then
    chown auditor:root $hubAuditorDir/security/*
    set -- su-exec auditor:root "$@"
fi

env | sed 's/= /=/' > /tmp/environment

#exec "$@" "auditor_$HOSTNAME"
exec "$@" cron -f -L 8
