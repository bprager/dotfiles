# ~/.zshrc.d/20-gcloud-gsutil-path.zsh

GCLOUD_SDK_BIN="/opt/homebrew/share/google-cloud-sdk/bin"
GSUTIL="${GCLOUD_SDK_BIN}/gsutil"

# If gsutil exists and is executable, ensure the SDK bin dir is on PATH
if [[ -x "$GSUTIL" ]]; then
  case ":$PATH:" in
    *":$GCLOUD_SDK_BIN:"*) ;;  # already present
    *) export PATH="$GCLOUD_SDK_BIN:$PATH" ;;
  esac
fi

