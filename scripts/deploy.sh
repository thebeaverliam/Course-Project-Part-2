#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Checking required tools..."
command -v terraform >/dev/null
command -v aws >/dev/null
command -v python3 >/dev/null
command -v nmap >/dev/null

echo "Running Terraform..."
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve

INSTANCE_ID="$(terraform -chdir=terraform output -raw instance_id)"
REGION="$(terraform -chdir=terraform output -raw aws_region)"

echo "Waiting for SSM connection..."
for i in {1..40}; do
  STATUS="$(aws ssm describe-instance-information \
    --region "$REGION" \
    --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
    --query "InstanceInformationList[0].PingStatus" \
    --output text 2>/dev/null || true)"

  if [ "$STATUS" = "Online" ]; then
    echo "SSM is online."
    break
  fi

  echo "Still waiting..."
  sleep 15
done

echo "Sending Minecraft setup script..."

python3 - <<'PY'
import base64
import json
from pathlib import Path

script = Path("scripts/install_minecraft.sh").read_bytes()
encoded = base64.b64encode(script).decode()

commands = {
    "commands": [
        f"echo {encoded} | base64 -d > /tmp/install_minecraft.sh",
        "chmod +x /tmp/install_minecraft.sh",
        "sudo /tmp/install_minecraft.sh"
    ]
}

Path("/tmp/minecraft-ssm.json").write_text(json.dumps(commands))
PY

COMMAND_ID="$(aws ssm send-command \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters file:///tmp/minecraft-ssm.json \
  --query "Command.CommandId" \
  --output text)"

aws ssm wait command-executed \
  --region "$REGION" \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID"

aws ssm get-command-invocation \
  --region "$REGION" \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text

PUBLIC_IP="$(terraform -chdir=terraform output -raw public_ip)"

echo
echo "Done."
echo "Minecraft address: ${PUBLIC_IP}:25565"
echo "Test command:"
echo "nmap -sV -Pn -p T:25565 ${PUBLIC_IP}"
