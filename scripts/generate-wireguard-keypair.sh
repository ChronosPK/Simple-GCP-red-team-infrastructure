#!/usr/bin/env bash
set -euo pipefail

output_dir="${1:-secrets}"
umask 077
mkdir -p "$output_dir"

if ! command -v wg >/dev/null 2>&1; then
  echo "WireGuard tools are required (command: wg)." >&2
  exit 1
fi

wg genkey | tee "$output_dir/server.key" | wg pubkey >"$output_dir/server.pub"
echo "Created $output_dir/server.key and $output_dir/server.pub"
