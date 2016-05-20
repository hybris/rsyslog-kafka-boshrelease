#!/bin/bash

# abort script on any command that exits with a non zero value
set -e -x

chown syslog:syslog /var/vcap/packages/gomkafka/var/vcap/bin/gomkafka
chmod 0755 /var/vcap/packages/gomkafka/var/vcap/bin/gomkafka



# move config file
# Check for [dynamic_availability_zone] placeholder
AZ=""
res=$(nc -z -w 3 169.254.169.254 80)
if [ $? -eq 0 ];
then
  AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
fi;

cat /var/vcap/jobs/rsyslog-kafka/etc/rsyslog.d/02-ygomkafka.conf | sed -e "s/\[dynamic_availability_zone\]/$AZ/g" > /etc/rsyslog.d/02-ygomkafka.conf

# forward vcap logs
if [ -f /etc/rsyslog.d/00-syslog_forwarder.conf ]; then
  sed -i -e 's/^\(:programname, startswith, "vcap." ~\).*$/#\1/g' /etc/rsyslog.d/00-syslog_forwarder.conf
fi;

# restart rsyslog
# service rsyslog restart

# Create a cron to run the file generation
(crontab -l | sed /generateCatchAll/d; echo "* * * * * /var/vcap/jobs/rsyslog-kafka/bin/generateCatchAll.sh") | sed /^$/d | crontab

# Run it once now
/var/vcap/jobs/rsyslog-kafka/bin/generateCatchAll.sh
