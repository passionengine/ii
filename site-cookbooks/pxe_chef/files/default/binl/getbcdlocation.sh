#!/bin/sh

IPADDR=$1
MACADDR=$2

LOGFILE=/var/log/syslog

tail -1000 $LOGFILE | \
  grep dnsmasq-tftp | \
  grep sent | \
  grep pxeboot.0 | \
  grep "to $IPADDR" | \
  tail -1 | \
  awk -F\/ '{print $4 }'
#FS=\/
