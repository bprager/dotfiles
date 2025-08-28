# checks if lastlog exists, and if not, creates a fallback alias

if ! command -v lastlog >/dev/null 2>&1; then
  alias lastlog='last -F | awk '\''!seen[$1]++ && $1 != "reboot" && $1 != "wtmp" && $1 != "" {print $1, $3, $4, $5, $6, $7, $8, $9}'\'''
fi
