#!/bin/sh

executeCommandQuietly() {
  $1 > /dev/null
  exitCode=$?
  if [ $exitCode -ne 0 ];
  then
    echo "ERROR: $2 (Code: $exitCode)"
    exit 1
  fi
}

# jq is required.
executeCommandQuietly "jq --version" "jq is not present.  jq is not available within the environment path or is not installed."

healthcheckFile="${JOBRUNNER_HOME}/temp/healthcheck.json"
if [ -f "$healthcheckFile" ];
then
  # Healthcheck file exists and is a file.
  secondsElapsed="$(($(date +%s) - $(date +%s -r $healthcheckFile)))"
  healthy="$(cat $healthcheckFile | jq '.healthy')"
  if [ $secondsElapsed -le 60 ] && [ "$healthy" == "true" ];
  then
    # Healthcheck file has been updated within the last 60 seconds.
    # Healthcheck file reports healthy status.
    exit 0
  fi

  # Container healthcheck file present, but unhealthy or out of date.
  # Display thread dump in jobrunner logs.
  kill -3 1
fi

# Healthcheck file does not exist or is not a file.
exit 1


