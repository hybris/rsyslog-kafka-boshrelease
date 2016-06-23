#!/bin/bash

# abort script on any command that exits with a non zero value
set -x

# Check for [dynamic_availability_zone] placeholder
AZ=""
res=$(nc -z -w 3 169.254.169.254 80)
if [ $? -eq 0 ];
then
  AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
fi;

# move config file
cat /var/vcap/jobs/rsyslog-kafka/etc/rsyslog.d/02-ygomkafka.conf | sed -e "s/\[dynamic_availability_zone\]/$AZ/g" > /etc/rsyslog.d/02-ygomkafka.conf

# forward vcap logs
if [ -f /etc/rsyslog.d/00-syslog_forwarder.conf ]; then
  sed -i -e 's/^\(:programname, startswith, "vcap." ~\).*$/#\1/g' /etc/rsyslog.d/00-syslog_forwarder.conf
fi;

# Restart rsyslog to apply new changes
service rsyslog restart