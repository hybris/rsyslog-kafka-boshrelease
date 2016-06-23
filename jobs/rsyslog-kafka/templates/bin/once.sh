#!/bin/bash

# abort script on any command that exits with a non zero value
set -x

# move config file
cp /var/vcap/jobs/rsyslog-kafka/etc/rsyslog.d/02-ygomkafka.conf /etc/rsyslog.d/02-ygomkafka.conf

# forward vcap logs
if [ -f /etc/rsyslog.d/00-syslog_forwarder.conf ]; then
  sed -i -e 's/^\(:programname, startswith, "vcap." ~\).*$/#\1/g' /etc/rsyslog.d/00-syslog_forwarder.conf
fi;

# Restart rsyslog to apply new changes
service rsyslog restart