#!/usr/bin/env bash

# Print usage
function usage() {
  echo -e "screenshot [OPTIONS]"
  echo -e "Without specifying any options, this utility will take screenshot of entire screen\n"
  echo "-c Copy result to clipboard"
  echo "-w Screenshot of focused window"
  echo "-s Screenshot of selected area"
  echo "-h Print this help"
}

# Notification click handler (Taken from https://github.com/vlevit/notify-send.sh)
function monitor() {
  local notification_id=$1
  local filename=$2
  local delete_tmp=$3

  if [ "$filename" == "" ] || [ "$notification_id" == "" ];then
    exit 0
  fi

  local gdbus_monitor_pid=/tmp/screenshot-action-dbus-monitor.$$.pid
  local gdbus_monitor=(gdbus monitor --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications)
  rm -f "$gdbus_monitor_pid"
  umask 077
  touch "$gdbus_monitor_pid"
  ( "${gdbus_monitor[@]}" & echo $! >&3 ) 3>"$gdbus_monitor_pid" | while read -r line; do
    local closed_notification_id="$(sed '/^\/org\/freedesktop\/Notifications: org.freedesktop.Notifications.NotificationClosed (uint32 \([0-9]\+\), uint32 [0-9]\+)$/!d;s//\1/' <<< "$line")"
    if [[ -n "$closed_notification_id" ]]; then
      if [[ "$closed_notification_id" == "$notification_id" ]]; then
        if [ $delete_tmp == 1 ]; then
          rm -rf "$filename"
        fi
        break
      fi
    else
    local action_invoked="$(sed '/\/org\/freedesktop\/Notifications: org.freedesktop.Notifications.ActionInvoked (uint32 \([0-9]\+\), '\''\(.*\)'\'')$/!d;s//\1:\2/' <<< "$line")"
    IFS=: read invoked_id action_id <<< "$action_invoked"
    if [[ "$invoked_id" == "$notification_id" ]]; then
      xdg-open "$filename"
      break
    fi
    fi
  done
  kill $(<"$gdbus_monitor_pid")
  rm -rf "$gdbus_monitor_pid"
}

function send_notification() {
  local title=$1
  local body=$2
  local filename=$3

  local notification_id=$(gdbus call --session \
    --dest org.freedesktop.Notifications \
    --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.Notify \
    -- \
    "Screenshot" 0 "$filename" "$title" "$body" \
    "['default', '']" {} "int32 -1" | sed 's/(uint32 \([0-9]\+\),)/\1/g')

  monitor $notification_id "$filename" $4 &
}

function notify() {
  if ! command -v gdbus &> /dev/null; then
    return
  fi
  if [ "$1" == "" ] || [ "$2" == "" ]; then
    return
  fi

  local detail="Saved at $1"
  if [ $2 == 1 ]; then
    detail="Stored in clipboard"
  fi

  send_notification "Screenshot taken" "$detail" "$1" $2
}

function take_screenshot() {
  local screenshot_type=$1
  local copy_to_clipboard=$2
  local filename=""
  local cmd="grim"
  local geo=""

  
  if [ "$screenshot_type" == "window" ]; then
    cmd="grim -g"
    geo=$(swaymsg -t get_tree | jq -j '.. | select(.type?) | select(.focused).rect | "\(.x),\(.y) \(.width)x\(.height)"')
  elif [ "$screenshot_type" == "selection" ]; then
    cmd="grim -g"
    geo=$(slurp)
  fi

  if [ $copy_to_clipboard == 1 ]; then
    filename=$(mktemp /tmp/screenshot.XXXXXX.png)
  else
    filename=$(xdg-user-dir PICTURES)/$(date +'Screenshot_%Y-%m-%d_%H%M%S.png')
  fi


  if [ "$geo" == "" ]; then
    $cmd - | swappy -o "$filename" -f -
  else
    $cmd "$geo" - | swappy -o "$filename" -f -
  fi

  if [ $copy_to_clipboard == 1 ]; then
    wl-copy < "$filename"
  fi

  notify "$filename" $copy_to_clipboard
}

function main() {
  local print_help=0
  local copy_to_clipboard=0
  local window=0
  local selection=0

  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      -h|--help)
        print_help=1
        shift
        ;;
      -s|--selection)
        selection=1
        shift 
        ;;
      -w|--window)
        window=1
        shift
        ;;
      -c|--clipboard)
        copy_to_clipboard=1
        shift
        ;;
      *)
        shift 
        ;;
    esac
  done

  local screenshot_type="full"
  if [ $window == 1 ]; then
    screenshot_type="window"
  elif [ $selection == 1 ]; then
    screenshot_type="selection"
  fi

  if [ $print_help == 1 ]; then
    usage
    exit 0
  fi

  take_screenshot $screenshot_type $copy_to_clipboard
}

main $@
