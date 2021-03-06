#!/bin/sh
### BEGIN INIT INFO
# Provides:          uwsgi-emperor
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs $remote_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start/stop uWSGI server instance(s)
# Description:       This script manages uWSGI Emperor server instance(s).
### END INIT INFO

# Author: Janos Guljas <janos@debian.org>

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="emperor server"
NAME="uwsgi"
DAEMON="/usr/bin/uwsgi"
PIDFILE=/run/uwsgi-emperor.pid
LOGFILE=/var/log/uwsgi/emperor.log
DAEMON_ARGS="--ini /etc/uwsgi-emperor/emperor.ini --pidfile ${PIDFILE} --daemonize ${LOGFILE}"
SCRIPTNAME="/etc/init.d/uwsgi-emperor"

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Read configuration variable file if it is present
[ -r "/etc/default/uwsgi-emperor" ] && . "/etc/default/uwsgi-emperor"

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start()
{
  # Return
  #   0 if daemon has been started
  #   1 if daemon was already running
  #   2 if daemon could not be started
  if [ "$ENABLED" != yes ]; then
    [ "$VERBOSE" != no ] && log_progress_msg "(disabled; see /etc/default/uwsgi-emperor)"
    return 2
  fi
  start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON --test > /dev/null \
    || return 1
  start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- \
    $DAEMON_ARGS 1> /dev/null 2>&1 \
    || return 2
}

#
# Function that stops the daemon/service
#
do_stop()
{
  # Return
  #   0 if daemon has been stopped
  #   1 if daemon was already stopped
  #   2 if daemon could not be stopped
  #   other if a failure occurred
  start-stop-daemon --stop --quiet --retry=QUIT/30/KILL/5 --pidfile $PIDFILE --name $NAME
  RETVAL="$?"
  [ "$RETVAL" = 2 ] && return 2

  start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
  [ "$?" = 2 ] && return 2

  rm -f $PIDFILE
  return "$RETVAL"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
  start-stop-daemon --stop --signal 1 --quiet --pidfile $PIDFILE --name $NAME
  return 0
}

case "$1" in
  start)
  [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
  do_start
  case "$?" in
    0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
    2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
  esac
  ;;
  stop)
  [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
  do_stop
  case "$?" in
    0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
    2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
  esac
  ;;
  status)
  status_of_proc "$DAEMON" "$NAME" && exit 0 || exit $?
  ;;
  reload|force-reload)
  log_daemon_msg "Reloading $DESC" "$NAME"
  do_reload
  log_end_msg $?
  ;;
  restart)
  log_daemon_msg "Restarting $DESC" "$NAME"
  do_stop
  case "$?" in
    0|1)
    do_start
    case "$?" in
      0) log_end_msg 0 ;;
      1) log_end_msg 1 ;; # Old process is still running
      *) log_end_msg 1 ;; # Failed to start
    esac
    ;;
    *)
    # Failed to stop
    log_end_msg 1
    ;;
  esac
  ;;
  *)
  echo "Usage: $SCRIPTNAME {start|stop|status|restart|reload|force-reload}" >&2
  exit 3
  ;;
esac

:

