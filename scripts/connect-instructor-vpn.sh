#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="$repo_root/terraform/generated-clients/instructor.conf"

if grep -q "REPLACE_WITH_STUDENT_PRIVATE_KEY" "$config"; then
  echo "Instructor private key has not been inserted into $config" >&2
  exit 1
fi

sudo wg-quick up "$config"
echo "Mythic: $(cd "$repo_root/terraform" && terraform output -raw redirector_url)"
