#!/bin/sh

echo "The application will start in ${START_SLEEP}s..." && sleep ${START_SLEEP}
exec java ${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom -jar "${HOME}/mscontactmedia.jar" "$@"
