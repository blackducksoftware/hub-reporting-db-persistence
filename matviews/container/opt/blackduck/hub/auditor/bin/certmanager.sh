#!/bin/bash

COMMAND=""
CERTIFICATE=""
CERTIFICATE_ALIAS=""
CERTIFICATE_AUTHORITY=""
CERTIFICATE_AUTHORITY_CERTIFICATE=""
JVM_CERT_DIR=""
COMMON_NAME=""
HOST_NAME=""
KEY=""
KEY_ALIAS=""
OUTPUT_DIRECTORY=""
OUTPUT_FILE=""
PASSWORD=""
PROFILE=""
ROOT_CERTIFICATE=""
SUBJECT_ALTERNATIVE_NAMES=""
STORE=""
TARGET=""
AUTOCOPY="true"


displayUsage() {
  echo "Cert manager - SSL/TLS key and certificate management."
  echo "Usage: $0 [command] [options]"
  echo ""
  echo "Commands:"
  echo "root                     Get the root certificate."
  echo "client-cert              Create a new client-based private key and certificate."
  echo "check-blackduck-issued   Check if certificate is issued by Blackduck Software Inc."
  echo "db-client-cert           Create a new database client-based private key and certificate."
  echo "db-server-cert           Create a new database server-based private key and certificate."
  echo "keystore                 Create a new keystore."
  echo "server-cert              Create a new server-based private key and certificate."
  echo "trust-java-cert          Trust a certificate by importing it into a Java truststore."
  echo "truststore               Create a truststore and copy cacerts from the default path."
  echo "verify-cert-chain        Verify certificate and certificate authority certificate match."
  echo "verify-hostname          Verify hostname matches with certificate."
  echo "verify-key-and-cert      Verify private key and certificate match."
  echo ""
  echo "Options:"
  echo "--ca                	 The certificate authority host and port."
  echo "--cacert            	 The certificate authority certificate."
  echo "--cert              	 The certificate."
  echo "--certAlias              The certificate alias."
  echo "--commonName        	 The certificate subject's common name."
  echo "--hostName          	 The host name of webserver."
  echo "--key               	 The key."
  echo "--keyAlias               The key alias."
  echo "--outputDirectory   	 The output directory."
  echo "--outputFile             The output file."
  echo "--password               The password."
  echo "--profile           	 The profile."
  echo "--rootcert          	 The root certificate."
  echo "--san               	 The certificate's subject alternative name."
  echo "--store                  The store."
  echo "--target            	 The local or remote target flag."
  echo "--autocopy            	 [true/false], controls if db-client-cert automatically moves and removes files."
}

displayUsageAndExit() {
  displayUsage
  exit 1
}

displayMessageUsageAndExit() {
  echo "ERROR: $1"
  displayUsageAndExit
}

validateNotBlank() {
  if [ -z "$1" ];
  then
    displayMessageUsageAndExit "$2"
  fi
}

validateFile() {
  if [ ! -f "$1" ];
  then
    displayMessageUsageAndExit "$2 ('$1')"
  fi
}

validateDirectory() {
  if [ ! -d "$1" ];
  then
    displayMessageUsageAndExit "$2 ('$1')"
  fi
}

executeCommand() {
  echo "Attempting to execute command: $1"

  $1
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    echo "ERROR: $2 (Code: $exitCode)"
    exit 1
  fi

  echo "Successfully executed command: $1"
}

executeCommandQuietly() {
  $1 &> /dev/null
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    echo "ERROR: $2 (Code: $exitCode)"
    exit 1
  fi
}

processCommandLineArguments() {
    if [ "$1" == "root" ] || [ "$1" == "check-blackduck-issued" ] || [ "$1" == "client-cert" ] || [ "$1" == "truststore" ] || [ "$1" == "db-client-cert" ] || [ "$1" == "db-server-cert" ] || [ "$1" == "keystore" ] || [ "$1" == "server-cert" ] || [ "$1" == "trust-java-cert" ] || [ "$1" == "verify-cert-chain" ] || [ "$1" == "verify-hostname" ] || [ "$1" == "verify-key-and-cert" ] ;
  then
    COMMAND="$1"
  else
    if [ -z "$1" ];
    then
      displayMessageUsageAndExit "The command is required."
    else
      displayMessageUsageAndExit "The command, '$1', is not supported."
    fi
  fi

  shift

  while [ $# -gt 0 ];
  do
    if [ "$1" == "--ca" ];
    then
      shift
      CERTIFICATE_AUTHORITY="$1"
    elif [ "$1" == "--cacert" ];
    then
      shift
      CERTIFICATE_AUTHORITY_CERTIFICATE="$1"
    elif [ "$1" == "--cert" ];
    then
      shift
      CERTIFICATE="$1"
    elif [ "$1" == "--certAlias" ];
    then
      shift
      CERTIFICATE_ALIAS="$1"
    elif [ "$1" == "--commonName" ];
    then
      shift
      COMMON_NAME="$1"
    elif [ "$1" == "--hostName" ];
    then
      shift
      HOST_NAME="$1"
    elif [ "$1" == "--key" ];
    then
      shift
      KEY="$1"
    elif [ "$1" == "--keyAlias" ];
    then
      shift
      KEY_ALIAS="$1"
    elif [ "$1" == "--outputDirectory" ];
    then
      shift
      OUTPUT_DIRECTORY="$1"
    elif [ "$1" == "--outputFile" ];
    then
      shift
      OUTPUT_FILE="$1"
    elif [ "$1" == "--password" ];
    then
      shift
      PASSWORD="$1"
    elif [ "$1" == "--profile" ];
    then
      shift
      PROFILE="$1"
    elif [ "$1" == "--rootcert" ];
    then
      shift
      ROOT_CERTIFICATE="$1"
    elif [ "$1" == "--san" ];
    then
      shift
      if [ -n "$SUBJECT_ALTERNATIVE_NAMES" ];
      then
        # Change from upper to lowercase, sorting and removing duplicate SANs
        SUBJECT_ALTERNATIVE_NAMES=$(echo "$SUBJECT_ALTERNATIVE_NAMES $1" | tr '[:upper:]' '[:lower:]' | xargs -n1 | sort -u -f | xargs)
      else
        SUBJECT_ALTERNATIVE_NAMES="$1"
      fi
    elif [ "$1" == "--store" ];
    then
      shift
      STORE="$1"
    elif [ "$1" == "--target" ];
    then
      shift
      TARGET="$1"
    elif [ "$1" == "--autocopy" ];
    then
      shift
      AUTOCOPY="$1"
    else
      displayMessageUsageAndExit "The option, '$1', is not supported."
    fi

    shift
  done
}


calculateCertDirectory() { 
    if [ -f "$JAVA_HOME/lib/security/cacerts" ] ; then 
       JVM_CERTS_DIR="$JAVA_HOME/lib/security/cacerts"
    else
       JVM_CERTS_DIR="$JAVA_HOME/jre/lib/security/cacerts"
    fi
}


validateCommandLineArguments() {

  calculateCertDirectory

  if [ "$COMMAND" == "root" ];
  then
    validateNotBlank "$CERTIFICATE_AUTHORITY" "The certificate authority host and port are required."
    validateNotBlank "$OUTPUT_DIRECTORY" "The output directory is required."
    validateDirectory "$OUTPUT_DIRECTORY" "The output directory does not exist or is not a directory."
    validateNotBlank "$PROFILE" "The profile is required."
  elif [ "$COMMAND" == "check-blackduck-issued" ];
  then
    validateNotBlank "$CERTIFICATE_AUTHORITY" "The certificate authority host and port are required."
    validateNotBlank "$ROOT_CERTIFICATE" "The root certificate is required."
    validateNotBlank "$CERTIFICATE" "The certificate is required."
    validateFile "$CERTIFICATE" "The certificate does not exist or is not a file."
  elif [ "$COMMAND" == "client-cert" ];
  then
    validateNotBlank "$CERTIFICATE_AUTHORITY" "The certificate authority host and port are required."
    validateNotBlank "$OUTPUT_DIRECTORY" "The output directory is required."
    validateDirectory "$OUTPUT_DIRECTORY" "The output directory does not exist or is not a directory."
    validateNotBlank "$COMMON_NAME" "The certificate subject's common name is required."
  elif [ "$COMMAND" == "truststore" ];
  then
    validateDirectory "$JAVA_HOME" "The JAVA_HOME environment variable does not exist or is not a directory."
    validateFile "$JVM_CERTS_DIR" "The Java cacerts file does not exist or is not a file."
    validateNotBlank "$OUTPUT_DIRECTORY" "The output directory is required."
    validateDirectory "$OUTPUT_DIRECTORY" "The output directory does not exist or is not a directory."
    validateNotBlank "$OUTPUT_FILE" "The output file is required."
  elif [ "$COMMAND" == "db-client-cert" ];
  then
    validateNotBlank "$CERTIFICATE_AUTHORITY" "The certificate authority host and port are required."
    validateNotBlank "$ROOT_CERTIFICATE" "The root certificate is required."
    validateNotBlank "$KEY" "The key is required."
    validateNotBlank "$CERTIFICATE" "The certificate is required."
    validateNotBlank "$OUTPUT_DIRECTORY" "The output directory is required."
    validateDirectory "$OUTPUT_DIRECTORY" "The output directory does not exist or is not a directory."
    validateNotBlank "$COMMON_NAME" "The certificate subject's common name is required."
  elif [ "$COMMAND" == "db-server-cert" ];
  then
    validateNotBlank "$CERTIFICATE_AUTHORITY" "The certificate authority host and port are required."
    validateNotBlank "$ROOT_CERTIFICATE" "The root certificate is required."
    validateNotBlank "$KEY" "The key is required."
    validateNotBlank "$CERTIFICATE" "The certificate is required."
    validateNotBlank "$OUTPUT_DIRECTORY" "The output directory is required."
    validateDirectory "$OUTPUT_DIRECTORY" "The output directory does not exist or is not a directory."
    validateNotBlank "$COMMON_NAME" "The certificate subject's common name is required."
    validateNotBlank "$SUBJECT_ALTERNATIVE_NAMES" "The certificate's subject alternative name is required."
  elif [ "$COMMAND" == "keystore" ];
  then
    validateNotBlank "$OUTPUT_DIRECTORY" "The output directory is required."
    validateDirectory "$OUTPUT_DIRECTORY" "The output directory does not exist or is not a directory."
    validateNotBlank "$OUTPUT_FILE" "The output file is required."
    validateNotBlank "$PASSWORD" "The password is required."
    validateNotBlank "$KEY_ALIAS" "The key alias is required."
    validateNotBlank "$KEY" "The key is required."
    validateFile "$KEY" "The key does not exist or is not a file."
    validateNotBlank "$CERTIFICATE" "The certificate is required."
    validateFile "$CERTIFICATE" "The certificate does not exist or is not a file."
  elif [ "$COMMAND" == "server-cert" ];
  then
    validateNotBlank "$CERTIFICATE_AUTHORITY" "The certificate authority host and port are required."
    validateNotBlank "$ROOT_CERTIFICATE" "The root certificate is required."
    validateNotBlank "$KEY" "The key is required."
    validateNotBlank "$CERTIFICATE" "The certificate is required."
    validateNotBlank "$OUTPUT_DIRECTORY" "The output directory is required."
    validateDirectory "$OUTPUT_DIRECTORY" "The output directory does not exist or is not a directory."
    validateNotBlank "$COMMON_NAME" "The certificate subject's common name is required."
    validateNotBlank "$SUBJECT_ALTERNATIVE_NAMES" "The certificate's subject alternative name is required."
    validateNotBlank "$HOST_NAME" "Host name is required."
  elif [ "$COMMAND" == "trust-java-cert" ];
  then
    validateNotBlank "$STORE" "The truststore is required."
    validateFile "$STORE" "The truststore does not exist or is not a file."
    validateNotBlank "$PASSWORD" "The password is required."
    validateNotBlank "$CERTIFICATE" "The certificate is required."
    # Missing certificates are skipped.
    validateNotBlank "$CERTIFICATE_ALIAS" "The certificate alias is required."
  elif [ "$COMMAND" == "verify-cert-chain" ];
  then
    validateNotBlank "$TARGET" "The target is required."
    if [ "$TARGET" == "local" ];
    then
      validateNotBlank "$CERTIFICATE" "The certificate is required."
      validateFile "$CERTIFICATE" "The certificate does not exist or is not a file."
      validateNotBlank "$CERTIFICATE_AUTHORITY_CERTIFICATE" "The certificate authority certificate is required."
      validateFile "$CERTIFICATE_AUTHORITY_CERTIFICATE" "The certificate authority certificate does not exist or is not a file."
    elif [ "$TARGET" == "remote" ];
    then
      validateNotBlank "$CERTIFICATE_AUTHORITY" "The certificate authority host and port are required."
      validateNotBlank "$CERTIFICATE" "The certificate is required."
      validateFile "$CERTIFICATE" "The certificate does not exist or is not a file."
      validateNotBlank "$OUTPUT_DIRECTORY" "The output directory is required."
      validateDirectory "$OUTPUT_DIRECTORY" "The output directory does not exist or is not a directory."
      validateNotBlank "$PROFILE" "The profile is required."
    else
      displayMessageUsageAndExit "The target option must be either 'local' or 'remote'."
    fi
  elif [ "$COMMAND" == "verify-key-and-cert" ];
  then
    validateNotBlank "$CERTIFICATE" "The certificate is required."
    validateFile "$CERTIFICATE" "The certificate does not exist or is not a file."
    validateNotBlank "$KEY" "The key is required."
    validateFile "$KEY" "The key does not exist or is not a file."
  elif [ "$COMMAND" == "verify-hostname" ];
  then
    validateNotBlank "$ROOT_CERTIFICATE" "The root certificate is required."
    validateNotBlank "$CERTIFICATE" "The certificate is required."
    validateFile "$CERTIFICATE" "The certificate does not exist or is not a file."
    validateNotBlank "$HOST_NAME" "Host name is required."
  else
    displayMessageUsageAndExit "The command, '$COMMAND', is not supported."
  fi
}

manageOperation() {
  if [ "$COMMAND" == "root" ];
  then
    manageRootOperation
  elif [ "$COMMAND" == "check-blackduck-issued" ];
  then
    manageCheckBlackduckSoftwareCertificate
  elif [ "$COMMAND" == "client-cert" ];
  then
    manageClientCertOperation
  elif [ "$COMMAND" == "truststore" ];
  then
    manageCopyJavaCacertsOperation
  elif [ "$COMMAND" == "db-client-cert" ];
  then
    manageDBClientCertOperation
  elif [ "$COMMAND" == "db-server-cert" ];
  then
    manageDBServerCertOperation
  elif [ "$COMMAND" == "keystore" ];
  then
    manageKeystoreOperation
  elif [ "$COMMAND" == "server-cert" ];
  then
    manageServerCertOperation
  elif [ "$COMMAND" == "trust-java-cert" ];
  then
    manageTrustJavaCertOperation
  elif [ "$COMMAND" == "verify-cert-chain" ];
  then
    if [ "$TARGET" == "local" ];
    then
      manageVerifyLocalCertChainOperation
    elif [ "$TARGET" == "remote" ];
    then
      manageVerifyRemoteCertChainOperation
    else
      displayMessageAndExit "The target option, '$TARGET', is not supported."
    fi
  elif [ "$COMMAND" == "verify-key-and-cert" ];
  then
    manageVerifyKeyAndCertOperation
  elif [ "$COMMAND" == "verify-hostname" ];
  then
    manageVerifyHostnameOperation
  else
    displayMessageUsageAndExit "The command, '$COMMAND', is not supported."
  fi
}

manageRootOperation() {
  executeCommandQuietly "curl --version" "curl is not present.  curl is not available within the environment path or is not installed."
  executeCommandQuietly "jq --version" "jq is not present.  jq is not available within the environment path or is not installed."

  getRootCertificate "$CERTIFICATE_AUTHORITY" "root" "$PROFILE" "$OUTPUT_DIRECTORY"
}

manageClientCertOperation() {
  executeCommandQuietly "curl --version" "curl is not present.  curl is not available within the environment path or is not installed."
  executeCommandQuietly "jq --version" "jq is not present.  jq is not available within the environment path or is not installed."

  if [ -f "$OUTPUT_DIRECTORY/$COMMON_NAME.key" ];
  then
    executeCommandQuietly "rm -f $OUTPUT_DIRECTORY/$COMMON_NAME.key" "Unable to remove old client private key."
  fi

  if [ -f "$OUTPUT_DIRECTORY/$COMMON_NAME.crt" ];
  then
    executeCommandQuietly "rm -f $OUTPUT_DIRECTORY/$COMMON_NAME.crt" "Unable to remove old client certificate."
  fi

  getClientCertificate "$CERTIFICATE_AUTHORITY" "$COMMON_NAME" "$OUTPUT_DIRECTORY" "$COMMON_NAME"
}

manageCopyJavaCacertsOperation() {
  copyJavaCacerts "$OUTPUT_DIRECTORY" "$OUTPUT_FILE"
}

manageDBClientCertOperation() {
  executeCommandQuietly "curl --version" "curl is not present.  curl is not available within the environment path or is not installed."
  executeCommandQuietly "jq --version" "jq is not present.  jq is not available within the environment path or is not installed."
  executeCommandQuietly "openssl version" "OpenSSL is not present.  OpenSSL is not available within the environment path or is not installed."

  if [ -f "$KEY" ] && [ -f "$CERTIFICATE" ];
  then
    echo "Database client key and certificate are present and will be validated."

    getRootCertificate "$CERTIFICATE_AUTHORITY" "root" "peer" "/tmp"
    isCertificateChainValid "/tmp/root.crt" "$CERTIFICATE"
    returnValue=$?
    if [ $returnValue -eq 0 ];
    then
      if [ -f "$ROOT_CERTIFICATE" ];
      then
        isHostnameValid "$COMMON_NAME" "$ROOT_CERTIFICATE" "$CERTIFICATE"
        returnValue=$?
    	if [ $returnValue -ne 0 ];
    	then    		
    		echo "Common name mismatches. Regenerating server certificate"
    		getServerCertificate "$CERTIFICATE_AUTHORITY" "$COMMON_NAME" "$SUBJECT_ALTERNATIVE_NAMES" "$OUTPUT_DIRECTORY" "$COMMON_NAME"
    	fi
      else
        getRootCertificate "$CERTIFICATE_AUTHORITY" "root" "peer" "$OUTPUT_DIRECTORY"
      fi
    else
      echo "Database client certificate is invalid and will be re-created."

      getRootCertificate "$CERTIFICATE_AUTHORITY" "root" "peer" "$OUTPUT_DIRECTORY"
      getClientCertificate "$CERTIFICATE_AUTHORITY" "$COMMON_NAME" "$OUTPUT_DIRECTORY" "$COMMON_NAME"
      convertPEMKeyToPKCS8DERKey "$OUTPUT_DIRECTORY/$COMMON_NAME.key" "$OUTPUT_DIRECTORY/$COMMON_NAME.key.pkcs8"
      
      if [ "$AUTOCOPY" == "true" ];
      then
      	executeCommandQuietly "mv -f $OUTPUT_DIRECTORY/$COMMON_NAME.key.pkcs8 $KEY" "Unable to move client private key."
      	executeCommandQuietly "mv -f $OUTPUT_DIRECTORY/$COMMON_NAME.crt $CERTIFICATE" "Unable to move client certificate."
      	#executeCommandQuietly "rm -f $OUTPUT_DIRECTORY/$COMMON_NAME.key" "Unable to remove old client private key."
      	executeCommandQuietly "mv -f $OUTPUT_DIRECTORY/$COMMON_NAME.key ${KEY/key/pem}" "Unable to remove old client private key."
      fi
    fi
  else
    echo "Database client key and/or certificate are not present and will be re-created."

    getRootCertificate "$CERTIFICATE_AUTHORITY" "root" "peer" "$OUTPUT_DIRECTORY"
    getClientCertificate "$CERTIFICATE_AUTHORITY" "$COMMON_NAME" "$OUTPUT_DIRECTORY" "$COMMON_NAME"
    convertPEMKeyToPKCS8DERKey "$OUTPUT_DIRECTORY/$COMMON_NAME.key" "$OUTPUT_DIRECTORY/$COMMON_NAME.key.pkcs8"
    
    if [ "$AUTOCOPY" == "true" ];
    then
    	executeCommandQuietly "mv -f $OUTPUT_DIRECTORY/$COMMON_NAME.key.pkcs8 $KEY" "Unable to move client private key."
    	executeCommandQuietly "mv -f $OUTPUT_DIRECTORY/$COMMON_NAME.crt $CERTIFICATE" "Unable to move client certificate."
    	#executeCommandQuietly "rm -f $OUTPUT_DIRECTORY/$COMMON_NAME.key" "Unable to remove old client private key."
    	executeCommandQuietly "mv -f $OUTPUT_DIRECTORY/$COMMON_NAME.key ${KEY/key/pem}" "Unable to remove old client private key."
    fi
  fi
}

manageDBServerCertOperation() {
  executeCommandQuietly "curl --version" "curl is not present.  curl is not available within the environment path or is not installed."
  executeCommandQuietly "jq --version" "jq is not present.  jq is not available within the environment path or is not installed."
  executeCommandQuietly "openssl version" "OpenSSL is not present.  OpenSSL is not available within the environment path or is not installed."

  if [ -f "$KEY" ] && [ -f "$CERTIFICATE" ];
  then
    echo "Database server key and certificate are present and will be validated."
    getRootCertificate "$CERTIFICATE_AUTHORITY" "root" "peer" "/tmp"
    isCertificateChainValid "/tmp/root.crt" "$CERTIFICATE"
    returnValue=$?
    if [ $returnValue -eq 0 ];
    then
      if [! -f "$ROOT_CERTIFICATE" ];
      then       
        echo "Root certificate is not present and will be retrieved."
        getRootCertificate "$CERTIFICATE_AUTHORITY" "root" "peer" "$OUTPUT_DIRECTORY"
      fi
    else
      echo "Database server certificate is invalid and will be re-created."
      getRootCertificate "$CERTIFICATE_AUTHORITY" "root" "peer" "$OUTPUT_DIRECTORY"
      getServerCertificate "$CERTIFICATE_AUTHORITY" "$COMMON_NAME" "$SUBJECT_ALTERNATIVE_NAMES" "$OUTPUT_DIRECTORY" "$COMMON_NAME"
    fi
  else
    echo "Database server key and/or certificate are not present and will be re-created."
    getRootCertificate "$CERTIFICATE_AUTHORITY" "root" "peer" "$OUTPUT_DIRECTORY"
    getServerCertificate "$CERTIFICATE_AUTHORITY" "$COMMON_NAME" "$SUBJECT_ALTERNATIVE_NAMES" "$OUTPUT_DIRECTORY" "$COMMON_NAME"
  fi
}

manageServerCertOperation() {
  executeCommandQuietly "curl --version" "curl is not present.  curl is not available within the environment path or is not installed."
  executeCommandQuietly "jq --version" "jq is not present.  jq is not available within the environment path or is not installed."

  if [ -f "$KEY" ] && [ -f "$CERTIFICATE" ];
  then
    echo "Server key and certificate are present and will be validated."
    getRootCertificate "$CERTIFICATE_AUTHORITY" "root" "peer" "/tmp"
    isCertificateChainValid "/tmp/root.crt" "$CERTIFICATE"
    returnValue=$?
    if [ $returnValue -eq 0 ];
    then
      if [ -f "$ROOT_CERTIFICATE" ];
      then
    	isHostnameValid "$HOST_NAME" "$ROOT_CERTIFICATE" "$CERTIFICATE"
		returnValue=$?
    	if [ $returnValue -ne 0 ]; then
    		echo "Host name mismatch. Re-generating the self-signed certificate with right host name"
    		getServerCertificate "$CERTIFICATE_AUTHORITY" "$COMMON_NAME" "$SUBJECT_ALTERNATIVE_NAMES" "$OUTPUT_DIRECTORY" "$COMMON_NAME"
    	fi
      else
        echo "Root certificate is not present and will be retrieved."
        getRootCertificate "$CERTIFICATE_AUTHORITY" "root" "peer" "$OUTPUT_DIRECTORY"
      fi
    else
      echo "Server certificate is invalid and will be re-created."
      getRootCertificate "$CERTIFICATE_AUTHORITY" "root" "peer" "$OUTPUT_DIRECTORY"
      getServerCertificate "$CERTIFICATE_AUTHORITY" "$COMMON_NAME" "$SUBJECT_ALTERNATIVE_NAMES" "$OUTPUT_DIRECTORY" "$COMMON_NAME"
    fi

  else
    echo "Server key and/or certificate are not present and will be re-created."
    getRootCertificate "$CERTIFICATE_AUTHORITY" "root" "peer" "$OUTPUT_DIRECTORY"
    getServerCertificate "$CERTIFICATE_AUTHORITY" "$COMMON_NAME" "$SUBJECT_ALTERNATIVE_NAMES" "$OUTPUT_DIRECTORY" "$COMMON_NAME"
  fi
}

manageVerifyKeyAndCertOperation() {
  executeCommandQuietly "openssl version" "OpenSSL is not present.  OpenSSL is not available within the environment path or is not installed."

  privateKeyModulus=`openssl rsa -noout -modulus -in $KEY`
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    displayMessageUsageAndExit "Unable to determine private key modulus [$exitCode]"
  fi

  certificateModulus=`openssl x509 -noout -modulus -in $CERTIFICATE`
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    displayMessageUsageAndExit "Unable to determine certificate modulus [$exitCode]"
  fi

  if [ "$privateKeyModulus" != "$certificateModulus" ];
  then
    echo "The private key and certificate do not match."
    exit 2
  fi
}

manageTrustJavaCertOperation() {
  executeCommandQuietly "keytool" "Keytool is not present.  Keytool is not available within the environment path or is not installed."

  trustJavaCertificate "$STORE" "$PASSWORD" "$CERTIFICATE" "$CERTIFICATE_ALIAS"
}

manageKeystoreOperation() {
  executeCommandQuietly "openssl version" "OpenSSL is not present.  OpenSSL is not available within the environment path or is not installed."

  createKeystore "$OUTPUT_DIRECTORY" "$OUTPUT_FILE" "$PASSWORD" "$KEY_ALIAS" "$KEY" "$CERTIFICATE"
}

manageVerifyLocalCertChainOperation() {
  executeCommandQuietly "openssl version" "OpenSSL is not present.  OpenSSL is not available within the environment path or is not installed."

  isCertificateChainValid "$CERTIFICATE_AUTHORITY_CERTIFICATE" "$CERTIFICATE"
  returnValue=$?
  if [ $returnValue -ne 0 ];
  then
    # Local CA certificate and local certificate do not match.  Exit with non-zero.
    echo "The local certificate does not verify with the given local certificate authority certificate."
    exit 2
  fi
}

manageVerifyRemoteCertChainOperation() {
  executeCommandQuietly "curl --version" "curl is not present.  curl is not available within the environment path or is not installed."
  executeCommandQuietly "jq --version" "jq is not present.  jq is not available within the environment path or is not installed."
  executeCommandQuietly "openssl version" "OpenSSL is not present.  OpenSSL is not available within the environment path or is not installed."

  label="currentRoot"
  getRootCertificate "$CERTIFICATE_AUTHORITY" "$label" "$PROFILE" "$OUTPUT_DIRECTORY"

  isCertificateChainValid "$OUTPUT_DIRECTORY/$label.crt" "$CERTIFICATE"
  returnValue=$?

  # Cleanup
  rm -f $OUTPUT_DIRECTORY/$label.json
  rm -f $OUTPUT_DIRECTORY/$label.crt

  if [ $returnValue -ne 0 ];
  then    
    # Remote CA certificate and local certificate do not match.  Exit with non-zero.
    echo "The local certificate does not verify with the remote certificate authority certificate."
    exit 2
  fi
}

getRootCertificate() {
  certificateAuthority="$1"
  label="$2"
  profile="$3"
  outputDirectory="$4"

  url="http://$certificateAuthority/api/v1/cfssl/info"
  body="{ \"label\": \"root\", \"profile\": \"$profile\" }"

  echo "Attempting to get root certificate."

  # Get the root certificate.
  curl -s -X POST -H "Content-Type: application/json" -d "$body" -o $outputDirectory/$label.json --connect-timeout 15 --max-time 30 --retry 20 --retry-delay 10 --retry-max-time 180 --retry-connrefused $url
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    echo "URL: $url"
    echo "Body: $body"
    displayMessageUsageAndExit "Unable to create root certificate request [$exitCode]"
  fi

  rm -f $outputDirectory/$label.crt

  # Parse the root certificate from the JSON response.
  cat $outputDirectory/$label.json | jq '.result.certificate' | tr -d '"' | sed 's/\\n/\
/g' > $outputDirectory/$label.crt
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    displayMessageUsageAndExit "Unable to parse root certificate [$exitCode]"
  fi

  rm -f $outputDirectory/$label.json
}

getClientCertificate() {
  certificateAuthority="$1"
  commonName="$2"
  outputDirectory="$3"
  fileName="$4"

  url="http://$certificateAuthority/api/v1/cfssl/newcert"
  body="{ \"request\": { \"profile\": \"client\", \"key\": { \"algo\": \"rsa\", \"size\": 2048 }, \"names\": [ { \"C\": \"US\", \"ST\": \"Massachusetts\", \"L\": \"Burlington\", \"O\": \"Black Duck Software, Inc.\", \"OU\": \"Engineering\" } ], \"CN\": \"$commonName\" } }"

  echo "Attempting to create client-based private key and certificate."

  # Create the client-based private key and certificate.
  curl -s -X POST -H "Content-Type: application/json" -d "$body" -o $outputDirectory/$fileName.json --connect-timeout 15 --max-time 30 --retry 20 --retry-delay 10 --retry-max-time 180 --retry-connrefused $url
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    echo "URL: $url"
    echo "Body: $body"
    displayMessageUsageAndExit "Unable to create client-based private key and certificate request [$exitCode]"
  fi

  # Parse the client-based private key and certificate from the JSON response
  cat $outputDirectory/$fileName.json | jq '.result.private_key' | tr -d '"' | sed 's/\\n/\
/g' > $outputDirectory/$fileName.key
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    displayMessageUsageAndExit "Unable to parse client-based private key [$exitCode]"
  fi

  cat $outputDirectory/$fileName.json | jq '.result.certificate' | tr -d '"' | sed 's/\\n/\
/g' > $outputDirectory/$fileName.crt
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    displayMessageUsageAndExit "Unable to parse client-based certificate [$exitCode]"
  fi

  rm -f $outputDirectory/$fileName.json

  echo "Client-based private key: $fileName.key"
  echo "Client-based certificate: $fileName.crt"
}

copyStore() {
  storePath="$1"

  executeCommandQuietly "cp $JVM_CERTS_DIR $storePath" "Unable to copy default Java cacerts."
  chmod 644 $storePath
}

createStoreMD5() {
  storePath="$1"
  storeMD5Path="$storePath.md5"
  storeMD5FileName=$(basename "$storeMD5Path")
   
  md5sum $storePath > $storeMD5Path
  exitCode=$?
  if [ $exitCode -eq 0 ];
  then
    chmod 644 $storeMD5Path
    echo "Successfully created store MD5 file: $storeMD5FileName"
  else
    echo "Unable to create store MD5 file (Code: $exitCode)."
    exit $exitCode
  fi
}

copyJavaCacerts() {
  outputDirectory="$1"
  outputFile="$2"
  storePath="$outputDirectory/$outputFile"

  # Determine if target store is present or absent.
  if [ -f "$storePath" ]; then
     # Compare the present store against the current Java cacerts.
     cmp -s $storePath $JVM_CERTS_DIR
     exitCode=$?
     if [ $exitCode -eq 0 ]; then
       chmod 644 $storePath
       createStoreMD5 "$storePath"
     else
       if [ -f "$storePath.md5" ]; then
         md5sum -s -c $storePath.md5
         exitCode=$?
         if [ $exitCode -eq 0 ]; then
           # The store is not equal to Java cacerts, but is equal via the store md5 file.
           # This implies the current store is from a different Java version from the currently installed version.
           echo "Store has not been modified and will be updated with new, default Java cacerts."
           copyStore "$storePath"
           createStoreMD5 "$storePath"
         else
           # The store is not equal to Java cacerts and is not equal via the store md5 file.
           # This implies the current store has been modified by an end-user and no action should be taken.
           echo "Store has been modified so no changes will be made."
         fi
       else
         echo "WARN: Store md5 file is not present so no changes will be made."
       fi
     fi
   else
     echo "Store is absent.  Copying to create a new store."
     copyStore "$storePath"
     createStoreMD5 "$storePath"
   fi
}

createKeystore() {
  outputDirectory="$1"
  outputFile="$2"
  keystorePassword="$3"
  keyAlias="$4"
  key="$5"
  certificate="$6"
  keystore="$outputDirectory/$outputFile"

  if [ -f "$keystore" ];
  then
    executeCommandQuietly "rm -f $keystore" "Unable to remove old Java keystore."
  fi

  openssl pkcs12 -export -name $keyAlias -in $certificate -inkey $key -out $keystore -password pass:$keystorePassword
  exitCode=$?
  if [ $exitCode -eq 0 ];
  then
    chmod 644 $keystore
    echo "Keystore has been created: $outputFile"
  else
    echo "Unable to create keystore (Code: $exitCode)."
    exit $exitCode
  fi
}

trustJavaCertificate() {
  truststore="$1"
  truststorePassword="$2"
  certificate="$3"
  certificateAlias="$4"
  
  if [ ! -f "$certificate" ]; then
    echo "WARNING: Certificate is not present. Import of certificate into Java truststore will be skipped."
  else
    echo "Attempting to trust $(basename "$certificate") into store $(basename "$truststore")"
    if keytool -list -keystore "$truststore" -storepass "$truststorePassword" -alias "$certificateAlias"
    then
      keytool -delete -alias "$certificateAlias" -keystore "$truststore" -storepass "$truststorePassword"
    fi

    if keytool -import -trustcacerts -file "$certificate" -alias "$certificateAlias" -keystore "$truststore" -storepass "$truststorePassword" -noprompt
    then
   	  :
    else 
      echo "Unable to import certificate into Java truststore.  Manually import the certificate."
      exit 1
    fi
  fi
}

getServerCertificate() {
  certificateAuthority="$1"
  commonName="$2"
  subjectAlternativeNames="$3"
  outputDirectory="$4"
  fileName="$5"

  url="http://$certificateAuthority/api/v1/cfssl/newcert"
  hosts=$(echo "$subjectAlternativeNames" | sed 's/ /", "/g')
  body="{ \"request\": { \"profile\": \"server\", \"key\": { \"algo\": \"rsa\", \"size\": 2048 }, \"hosts\": [ \"$hosts\" ], \"names\": [ { \"C\": \"US\", \"ST\": \"Massachusetts\", \"L\": \"Burlington\", \"O\": \"Black Duck Software, Inc.\", \"OU\": \"Engineering\" } ], \"CN\": \"$commonName\" } }"

  echo "Attempting to create server-based private key and certificate."

  # Create the server-based private key and certificate.
  curl -s -X POST -H "Content-Type: application/json" -d "$body" -o $outputDirectory/$fileName.json --connect-timeout 15 --max-time 30 --retry 20 --retry-delay 10 --retry-max-time 180 --retry-connrefused $url
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    echo "URL: $url"
    echo "Body: $body"
    displayMessageUsageAndExit "Unable to create server-based private key and certificate request [$exitCode]"
  fi

  rm -f $outputDirectory/$fileName.key

  # Parse the server-baed private key and certificate from the JSON response.
  cat $outputDirectory/$fileName.json | jq '.result.private_key' | tr -d '"' | sed 's/\\n/\
/g' > $outputDirectory/$fileName.key
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    displayMessageUsageAndExit "Unable to parse server-based private key [$exitCode]"
  fi

  rm -f $outputDirectory/$fileName.crt

  cat $outputDirectory/$fileName.json | jq '.result.certificate' | tr -d '"' | sed 's/\\n/\
/g' > $outputDirectory/$fileName.crt
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    displayMessageUsageAndExit "Unable to parse server-based certificate [$exitCode]"
  fi

  rm -f $outputDirectory/$fileName.json

  echo "Server-based private key: $fileName.key"
  echo "Server-based certificate: $fileName.crt"
}

isCertificateChainValid() {
  certificateAuthorityFile="$1"
  certificate="$2"

  returnValue=0

  echo "Attempting to verify certificates."

  openssl verify -verbose -x509_strict -CAfile $certificateAuthorityFile -CApath nosuchdir $certificate
  exitCode=$?
  if [ $exitCode -eq 0 ];
  then
    returnValue=0
  else
    returnValue=1
  fi

  return "$returnValue"
}

convertPEMKeyToPKCS8DERKey() {
  inputKey="$1"
  outputKey="$2"  

  echo "Attempting to convert PEM key to PKCS#8 DER key."

  openssl pkcs8 -topk8 -inform PEM -outform DER -in $inputKey -out $outputKey -nocrypt
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    displayMessageUsageAndExit "Unable to convert PEM key to PKCS#8 DER key $outputKey [$exitCode]"
  fi

  
}

isHostnameValid() {
  executeCommandQuietly "openssl version" "OpenSSL is not present.  OpenSSL is not available within the environment path or is not installed."

  hostName="$1"
  rootcert="$2"
  certificate="$3"

  echo "Atttempting to verify certificate hostname match."
  openssl verify -verify_hostname $hostName -CAfile $rootcert $certificate
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
  	returnValue=1
  else
    returnValue=0
  fi

  return "$returnValue"
}

manageVerifyHostnameOperation() {
  executeCommandQuietly "openssl version" "OpenSSL is not present.  OpenSSL is not available within the environment path or is not installed."

  isHostnameValid $HOST_NAME $ROOT_CERTIFICATE $CERTIFICATE
  returnValue=$?
  if [ $returnValue -ne 0 ];
  then
    echo "Host name validation failed. (returnValue: $returnValue)"
    exit 1
  fi
}

isBlackduckSoftwareCertificate() {
  certificate="$1"
  issuer=$(openssl x509 -in $certificate -noout -issuer)
  blackduckIssuer="issuer= /C=US/ST=Massachusetts/L=Burlington/O=Black Duck Software, Inc./OU=Engineering/CN=blackducksoftware"
  if [ "$issuer" == "$blackduckIssuer" ];
  then
    returnValue=0
  else
    returnValue=1
  fi
  return "$returnValue"
}

manageCheckBlackduckSoftwareCertificate() {
  isBlackduckSoftwareCertificate $CERTIFICATE
  returnValue=$?
  if [ $returnValue -ne 0 ]; then
    echo "Certificate was not issued by BlackDuck Software, Inc."
    exit 1
  fi
}
processCommandLineArguments "$@"
validateCommandLineArguments
manageOperation

