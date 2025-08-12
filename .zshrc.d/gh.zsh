# check recent gh run log
if which gh >/dev/null 2>&1; then
  function gh-run-log {
    local run_id
    run_id=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
    if [[ -n "$run_id" ]]; then
      GH_PAGER= gh run view "$run_id" --log
    else
      echo "No recent GitHub Actions run found."
    fi
  }
fi

