#!/bin/bash
set -e

# check machine configuration
echo -e "Checking system requirements"

cpus=$(nproc)
memory=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
CPUS=$(expr $(nproc) - 1)
GLOBAL_CONFIG_URL=${GLOBAL_CONFIG_URL:-https://ton.org/testnet-global.config.json}

echo "This machine has ${cpus} CPUs and ${memory}KB of Memory"
if [ "$IGNORE_MINIMAL_REQS" != true ] && ([ "${cpus}" -lt 16 ] || [ "${memory}" -lt 64000000 ]); then
	echo "Insufficient resources. Requires a minimum of 16 processors and 64Gb RAM."
	exit 1
fi

echo "Setting global config..."
wget ${GLOBAL_CONFIG_URL} -O /usr/bin/ton/global.config.json

URL="https://dump.ton.org"
if [ ! -f /var/ton-work/db/dump_done ]; then
  if [ "$DUMP" == true ] ; then
    if [[ "$GLOBAL_CONFIG_URL" == *"testnet"* ]]; then
       DUMP_NAME="latest_testnet"
    else
       DUMP_NAME="latest"
    fi
    echo "Start DownloadDump $DUMP_NAME"
    DUMPSIZE=$(curl --silent ${URL}/dumps/${DUMP_NAME}.tar.size.archive.txt)
    DISKSPACE=$(df -B1 --output=avail /var/ton-work | tail -n1)
    NEEDSPACE=$(expr 3 '*' "$DUMPSIZE")
    if [ "$DISKSPACE" -gt "$NEEDSPACE" ]; then
      (curl --silent ${URL}/dumps/${DUMP_NAME}.tar.lz | pv --force | plzip -d -n${CPUS} | tar -xC /var/ton-work/db) 2>&1 | stdbuf -o0 tr '\r' '\n'
      mkdir -p /var/ton-work/db/static /var/ton-work/db/import
      chown -R validator:validator /var/ton-work/db
      touch /var/ton-work/db/dump_done
    echo "Done DownloadDump $DUMP_NAME"
    else
      echo "A minimum of $NEEDSPACE bytes of free disk space is required"
      exit 1
    fi
  fi
fi

echo "Setting processor cores"
sed -i -e "s/--threads\s[[:digit:]]\+/--threads ${CPUS}/g" /etc/systemd/system/validator.service

echo "Starting validator"
systemctl start validator
echo "Starting mytoncore"
systemctl start mytoncore

echo "Service started!"
exec /usr/bin/systemctl
