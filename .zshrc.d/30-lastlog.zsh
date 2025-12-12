# checks if lastlog exists, and if not, creates a fallback alias

if ! command -v lastlog >/dev/null 2>&1; then
  alias lastlog='
  getent passwd | awk -F: '\''$3 >= 1000 && $3 != 65534 {print $1}'\'' | while read user; do
    login_info=$(last -F -n 1 "$user" | grep -vE "^(reboot|wtmp|$)" | head -n 1)
    if [ -z "$login_info" ]; then
      printf "%-15s **Never logged in**\n" "$user"
    else
      printf "%s\n" "$login_info"
    fi
  done
  '
fi
