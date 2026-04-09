# checks if lastlog exists, and if not, creates a portable fallback

if ! command -v lastlog >/dev/null 2>&1; then
  lastlog() {
    local user uid login_info

    case "$os_name" in
      Darwin)
        while IFS=' ' read -r user uid; do
          [[ $uid -ge 500 && $user != _* ]] || continue
          login_info=$(last -F -n 1 "$user" 2>/dev/null | awk 'NF && $1 != "reboot" && $1 != "wtmp" { print; exit }')
          if [[ -z $login_info ]]; then
            printf "%-15s **Never logged in**\n" "$user"
          else
            printf "%s\n" "$login_info"
          fi
        done < <(dscl . -list /Users UniqueID 2>/dev/null)
        ;;
      *)
        if command -v getent >/dev/null 2>&1; then
          while IFS=: read -r user _ uid _ _ _ _; do
            [[ $uid -ge 1000 && $uid -ne 65534 ]] || continue
            login_info=$(last -F -n 1 "$user" 2>/dev/null | awk 'NF && $1 != "reboot" && $1 != "wtmp" { print; exit }')
            if [[ -z $login_info ]]; then
              printf "%-15s **Never logged in**\n" "$user"
            else
              printf "%s\n" "$login_info"
            fi
          done < <(getent passwd)
        elif [[ -r /etc/passwd ]]; then
          while IFS=: read -r user _ uid _ _ _ _; do
            [[ $uid -ge 1000 && $uid -ne 65534 ]] || continue
            login_info=$(last -F -n 1 "$user" 2>/dev/null | awk 'NF && $1 != "reboot" && $1 != "wtmp" { print; exit }')
            if [[ -z $login_info ]]; then
              printf "%-15s **Never logged in**\n" "$user"
            else
              printf "%s\n" "$login_info"
            fi
          done < /etc/passwd
        else
          print -r -- "lastlog helper is not available on this system."
          return 1
        fi
        ;;
    esac
  }
fi
