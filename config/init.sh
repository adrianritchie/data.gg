#!/bin/sh

# File: /etc/init.d/unicorn

### BEGIN INIT INFO
# Provides:          unicorn
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the unicorn web server
# Description:       starts unicorn
### END INIT INFO

set -e
# Example init script, this can be used with nginx, too,
# since nginx and unicorn accept the same signals

# Feel free to change any of the following variables for your app:
TIMEOUT=${TIMEOUT-60}
APP_ROOT=/srv/data/current
PID=/srv/data/shared/pids/unicorn.pid
CMD="/srv/data/shared/bundle/ruby/2.2.0/bin/unicorn -D -c $APP_ROOT/config/unicorn.rb -E production"
INIT_CONF=$APP_ROOT/config/init.conf
action="$1"
set -u

test -f "$INIT_CONF" && . $INIT_CONF

old_pid="$PID.oldbin"

cd $APP_ROOT || exit 1

sig () {
  test -s "$PID" && kill -$1 `cat $PID`
}

oldsig () {
  test -s $old_pid && kill -$1 `cat $old_pid`
}

case $action in
start)
  sig 0 && echo >&2 "Already running" && exit 0
  su - admin -c "/srv/data/shared/bundle/ruby/2.2.0/bin/unicorn -D -c $APP_ROOT/config/unicorn.rb -E production"
 ;;
stop)
  sig QUIT && exit 0
  echo >&2 "Not running"
  ;;
force-stop)
  sig TERM && exit 0
  echo >&2 "Not running"
  ;;
restart|reload)
  sig HUP && echo reloaded OK && exit 0
  echo >&2 "Couldn't reload, starting '$CMD' instead"
  su - admin -c "/srv/data/shared/bundle/ruby/2.2.0/bin/unicorn -D -c $APP_ROOT/config/unicorn.rb -E production"
  ;;
upgrade)
  if sig USR2 && sleep 2 && sig 0 && oldsig QUIT
  then
    n=$TIMEOUT
    while test -s $old_pid && test $n -ge 0
    do
      printf '.' && sleep 1 && n=$(( $n - 1 ))
    done
    echo

    if test $n -lt 0 && test -s $old_pid
    then
      echo >&2 "$old_pid still exists after $TIMEOUT seconds"
      exit 1
    fi
    exit 0
  fi
  echo >&2 "Couldn't upgrade, starting '$CMD' instead"
  su - admin -c "/srv/data/shared/bundle/ruby/2.2.0/bin/unicorn -D -c $APP_ROOT/config/unicorn.rb -E production"
  ;;
reopen-logs)
  sig USR1
  ;;
*)
  echo >&2 "Usage: $0 <start|stop|restart|upgrade|force-stop|reopen-logs>"
  exit 1
  ;;
esac
