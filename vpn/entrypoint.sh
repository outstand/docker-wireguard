#!/bin/bash

# From: https://gist.github.com/przemoc/571091
## Copyright (C) 2009  Przemyslaw Pawelczyk <przemoc@gmail.com>
## License: GNU General Public License v2, v3
#
# Lockable script boilerplate

### HEADER ###

LOCKFILE="/etc/wireguard/lock/sync.lock"
LOCKFD=99

# PRIVATE
_lock()             { flock -$1 $LOCKFD; }
_no_more_locking()  { _lock u; _lock xn && rm -f $LOCKFILE; }
_prepare_locking()  { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; }

# ON START
# ryansch: moved _prepare_locking to conditional locking below
#_prepare_locking

# PUBLIC
exlock_now()        { _lock xn; }  # obtain an exclusive lock immediately or fail
exlock()            { _lock x; }   # obtain an exclusive lock
shlock()            { _lock s; }   # obtain a shared lock
unlock()            { _lock u; }   # drop a lock

### BEGIN OF SCRIPT ###

if [ "$1" = 'wg' ] || [ "$1" = 'wg-quick' ]; then
  echo 'Checking for config sync...'
  _prepare_locking
  exlock

  until [ -f /etc/wireguard/lock/synced ]; do
    unlock
    sleep 1
    exlock
  done

  unlock

  echo 'Config sync detected.'
fi

install_module () {
  cd /wireguard/src
  echo "Installing the wireguard kernel module..."


  DKMSDIR=/usr/src/wireguard-${WIREGUARD_MODULE_VERSION} make dkms-install
  dkms install wireguard/${WIREGUARD_MODULE_VERSION}
  modprobe wireguard

  echo "Successfully built and installed the wireguard kernel module!"
}

if [[ "$1" = 'bash' ]] || [[ "$1" = 'wg' ]] || [[ "$1" = 'wg-quick' ]]; then
  exec "$@"
fi

lsmod | grep wireguard
test $? -eq 0 || install_module

# Find a Wireguard interface
interfaces=`find /etc/wireguard -maxdepth 1 -type f -name '*.conf'`
if [[ -z $interfaces ]]; then
    echo "$(date): Interface not found in /etc/wireguard" >&2
    exit 1
fi

set -e

for interface in $interfaces; do
    echo "$(date): Starting Wireguard $interface"
    wg-quick up $interface
done

# Add masquerade rule for NAT'ing VPN traffic bound for the Internet

# Handle shutdown behavior
finish () {
    echo "$(date): Shutting down Wireguard"
    for interface in $interfaces; do
        wg-quick down $interface
    done
    exit 0
}

trap finish SIGTERM SIGINT SIGQUIT

sleep infinity &
wait $!
