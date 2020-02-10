#!/bin/sh

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
_prepare_locking

# PUBLIC
exlock_now()        { _lock xn; }  # obtain an exclusive lock immediately or fail
exlock()            { _lock x; }   # obtain an exclusive lock
shlock()            { _lock s; }   # obtain a shared lock
unlock()            { _lock u; }   # drop a lock

### BEGIN OF SCRIPT ###

exlock
rm -f /etc/wireguard/lock/synced
unlock

# Sync
echo 'Syncing from S3...'
aws s3 sync s3://${S3_BUCKET}/ /etc/wireguard --exclude 'lock/*'
echo 'Done.'

exlock
touch /etc/wireguard/lock/synced
unlock
