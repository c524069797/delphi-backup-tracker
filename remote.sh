#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
action=${1:-status}
remote_host=${DELPHI_SSH_HOST:-win-delphi}

case "$action" in
  sync)
    scp -o BatchMode=yes -o ConnectTimeout=8 \
      "$project_dir/BackupTracker.dpr" "$project_dir/BackupTracker.dproj" \
      "$project_dir/MainForm.pas" "$project_dir/MainForm.dfm" \
      "$project_dir/BackupTasks.pas" \
      "$project_dir/BackupTrackerTests.dpr" "$project_dir/BackupTrackerTests.dproj" \
      "$project_dir/remote.ps1" \
      "$remote_host:E:/Projects/delphi-backup-tracker/"
    ;;
  build|test|run|open|status)
    ssh -o BatchMode=yes -o ConnectTimeout=8 "$remote_host" \
      powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass \
      -File E:/Projects/delphi-backup-tracker/remote.ps1 -Action "$action"
    ;;
  *)
    printf 'Usage: %s [sync|build|test|run|open|status]\n' "$0" >&2
    exit 2
    ;;
esac
