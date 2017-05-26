#!/bin/bash

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

# Setup env vars and folders for the webapp_ctl script
source /var/vcap/jobs/nexus/helpers/ctl_setup.sh 'nexus'

export PORT=${PORT:-5000}
export LANG=en_US.UTF-8
export NEXUS_PACKAGE_DIR=/var/vcap/jobs/nexus/packages/nexus

case $1 in

  start)
    cp /var/vcap/jobs/nexus/bin/nexus.rc $NEXUS_PACKAGE_DIR/bin/
    cp /var/vcap/jobs/nexus/bin/nexus.vmoptions $NEXUS_PACKAGE_DIR/bin/
    cp /var/vcap/jobs/nexus/etc/karaf/custom.properties $NEXUS_PACKAGE_DIR/etc/karaf/custom.properties
    cp /var/vcap/jobs/nexus/etc/logback/logback-access.xml $NEXUS_PACKAGE_DIR/etc/logback/logback-access.xml
    cp /var/vcap/jobs/nexus/etc/logback/logback.xml $NEXUS_PACKAGE_DIR/etc/logback/logback.xml

    if [ -f "/var/vcap/jobs/nexus/bin/cert.pem" ]; then
      openssl pkcs12 -export -in /var/vcap/jobs/nexus/bin/cert.crt -inkey /var/vcap/jobs/nexus/bin/cert.pem -out /tmp/cert.pfx -certfile /var/vcap/jobs/nexus/bin/cert.crt -passout pass:changeit -passin pass:Ba%MBQkEs*R9fxFAKe2i
      /var/vcap/packages/java/bin/keytool -importkeystore -srckeystore /tmp/cert.pfx -srcstorepass changeit -deststoretype jks -destkeystore /var/vcap/packages/nexus/etc/ssl/keystore.jks -deststorepass changeit
      rm /var/vcap/jobs/nexus/bin/cert.pem
      rm /tmp/cert.pfx
    fi
    # openssl pkcs12 -export -in /var/vcap/jobs/nexus/bin/cert.crt -inkey /var/vcap/jobs/nexus/bin/cert.pem -out /var/vcap/jobs/nexus/bin/cert.pfx -certfile /var/vcap/jobs/nexus/bin/cert.crt

    pid_guard $PIDFILE $JOB_NAME

    # store pid in $PIDFILE
    echo $$ > $PIDFILE

    exec chpst -u vcap:vcap nexus run \
         >>$LOG_DIR/$JOB_NAME.log 2>&1

    ;;

  stop)
    kill_and_wait $PIDFILE

    ;;
  *)
    echo "Usage: nexus_ctl {start|stop}"

    ;;

esac
exit 0
