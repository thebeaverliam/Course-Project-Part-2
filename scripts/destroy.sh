#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
terraform -chdir=terraform destroy -auto-approve
