# ~/.zshrc.d/20-gcloud-gsutil-path.zsh

typeset -a gcloud_sdk_bins
gcloud_sdk_bins=()

if command -v brew >/dev/null 2>&1; then
  gcloud_prefix="$(brew --prefix google-cloud-sdk 2>/dev/null)"
  [[ -n $gcloud_prefix ]] && gcloud_sdk_bins+=("$gcloud_prefix/bin")
fi

gcloud_sdk_bins+=(
  "$HOME/homebrew/share/google-cloud-sdk/bin"
  "/opt/homebrew/share/google-cloud-sdk/bin"
  "/usr/local/share/google-cloud-sdk/bin"
  "/usr/share/google-cloud-sdk/bin"
)

for candidate in $gcloud_sdk_bins; do
  [[ -x "$candidate/gsutil" ]] || continue
  path_prepend "$candidate"
  break
done

unset gcloud_prefix gcloud_sdk_bins candidate
