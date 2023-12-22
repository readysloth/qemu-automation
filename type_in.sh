export QEMU_MONITOR_IP=
export QEMU_MONITOR_PORT=
export QEMU_SEND_CMD='"nc -q0 $QEMU_MONITOR_IP $QEMU_MONITOR_PORT"'
export SEND_NEWLINE=true

QSEND=

set_qemu_monitor_ip() {
  QEMU_MONITOR_IP="$1"
  QSEND=$(eval echo "$QEMU_SEND_CMD")
}


set_qemu_monitor_port() {
  QEMU_MONITOR_PORT="$1"
  QSEND=$(eval echo "$QEMU_SEND_CMD")
}


set_qemu_monitor() {
  set_qemu_monitor_ip "$(echo "$1" | cut -d: -f1)"
  set_qemu_monitor_port "$(echo "$1" | cut -d: -f2)"
  QSEND=$(eval echo "$QEMU_SEND_CMD")
}


exit_if_no_monitor_setup() {
  if [ -z "$QEMU_MONITOR_IP" ] || [ -z "$QEMU_MONITOR_PORT" ]
  then
    echo "You must set both QEMU_MONITOR_IP ($QEMU_MONITOR_IP) and QEMU_MONITOR_PORT ($QEMU_MONITOR_PORT)" >&2
    echo "Use set_qemu_monitor_ip, set_qemu_monitor_port or set_qemu_monitor functions for that" >&2
    exit 1
  fi
}


type_in() {
  exit_if_no_monitor_setup

  do_inline=false
  for ch in $(echo "$@" | sed 's/./& /g' | sed 's/*/\\*/g' )
  do
    if [ "$ch" = '`' ]
    then
      if [ "$do_inline" = 'true' ]
      then
        do_inline=false
        echo $c | $QSEND
        sleep 0.1
        continue
      fi
      do_inline=true
      c=
      continue
    fi

    if [ "$do_inline" = "true" ]
    then
      [ "$ch" = '%' ] && c="$c " || c="$c$ch"
    else
      c="$ch"
      case "$ch" in
        '%') c=spc ;;
        '-') c=minus ;;
        '/') c=slash ;;
        '\') c=backslash ;;
        '.') c=dot ;;
        '>') c=shift-dot ;;
        '<') c=shift-comma ;;
        '=') c=equal ;;
        "'") c=apostrophe ;;
        '"') c=shift-apostrophe ;;
        '\*') c=asterisk ;;
        ':') c=shift-semicolon ;;
        '_') echo "sendkey shift-minus" | $QSEND && continue ;;
        '~') DO_UPPERCASE=yes && continue ;;
      esac

      [ "$DO_UPPERCASE" == yes ] && DO_UPPERCASE= && c="shift-$c"
      echo "sendkey $c" | $QSEND
      sleep 0.1

      [ -n "$TYPE_IN_LABMDA" ] && $TYPE_IN_LABMDA "$c"
    fi
  done
  [ "$SEND_NEWLINE" = "true" ] && echo "sendkey kp_enter" | $QSEND
}


send_cmd() {
  exit_if_no_monitor_setup

  cmd="$@"
  echo "$cmd" | $QSEND
  sleep 0.1
  [ -n "$SEND_CMD_LABMDA" ] && $SEND_CMD_LABMDA "$cmd"
}
