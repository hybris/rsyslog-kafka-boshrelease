#!/bin/bash

# abort script on any command that exits with a non zero value
set -e -x

apt-get update
apt-get install librdkafka-dev -y --no-install-recommends

# check rsyslog version
rsyslogd -v | head -1 | awk '{print $2}' | grep -o -e '[0-9.]\+' > /tmp/rsyslog.version

# install omkafka module
wget -q -O - https://github.com/hybris/rsyslog-modules/releases/download/v`cat /tmp/rsyslog.version`/omkafka.so > /usr/lib/rsyslog/omkafka.so

# move config file
cp /var/vcap/jobs/rsyslog-kafka/etc/rsyslog.d/01-kafka_forwarder.conf /etc/rsyslog.d/01-kafka_forwarder.conf

# forward vcap logs
if [ -f /etc/rsyslog.d/00-syslog_forwarder.conf ]; then
  sed -i -e 's/^\(:programname, startswith, "vcap." ~\).*$/#\1/g' /etc/rsyslog.d/00-syslog_forwarder.conf
fi;

# restart rsyslog
service rsyslog restart
