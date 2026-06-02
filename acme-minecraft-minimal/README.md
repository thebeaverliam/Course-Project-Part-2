# Acme Minecraft Server AWS Setup

This project automatically creates and configures a Minecraft Java server on AWS.

It uses:

- Terraform for the AWS infrastructure
- AWS CLI / SSM to run the server setup script
- systemd so the Minecraft server starts again after reboot
- nmap to test the Minecraft port

## Pipeline Diagram

```text
Local computer
   |
   | run ./scripts/deploy.sh
   v
Terraform creates AWS resources
   |
   v
EC2 instance starts
   |
   v
AWS SSM runs install script
   |
   v
Minecraft service starts on port 25565
   |
   v
nmap checks the public IP
```

## Requirements

Install these tools:

- Terraform
- AWS CLI
- Python 3
- nmap

You also need AWS Academy Learner Lab credentials.

The project assumes the AWS Academy instance profile is named:

```text
LabInstanceProfile
```

## AWS Credentials

Start the AWS Learner Lab and paste your credentials into the terminal:

```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_SESSION_TOKEN="your_session_token"
export AWS_DEFAULT_REGION="us-east-1"
```

Check that AWS works:

```bash
aws sts get-caller-identity
```

## How to Run

From the project folder, run:

```bash
./scripts/deploy.sh
```

This will:

1. Run Terraform
2. Create the AWS networking and EC2 instance
3. Wait for AWS SSM to connect
4. Install Java and the Minecraft server
5. Create a `minecraft.service` systemd service
6. Print the public IP address

## How to Test the Server

After deployment, run:

```bash
nmap -sV -Pn -p T:25565 $(terraform -chdir=terraform output -raw public_ip)
```

If it works, port `25565/tcp` should show as open.

## How to Connect in Minecraft

Open Minecraft Java Edition.

Go to:

```text
Multiplayer > Direct Connection
```

Use:

```text
<public-ip>:25565
```

You can get the public IP with:

```bash
terraform -chdir=terraform output -raw public_ip
```

## Restart and Shutdown

The setup script creates a systemd service called:

```text
minecraft.service
```

It uses:

```text
Restart=on-failure
KillSignal=SIGINT
TimeoutStopSec=120
```

This lets the server restart after a reboot and gives Minecraft time to shut down cleanly.

## Cleanup

Destroy the AWS resources when finished:

```bash
./scripts/destroy.sh
```

## Sources

- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- AWS Systems Manager Run Command: https://docs.aws.amazon.com/systems-manager/latest/userguide/execute-remote-commands.html
- AWS CLI Documentation: https://docs.aws.amazon.com/cli/
- Minecraft Server Download: https://www.minecraft.net/en-us/download/server
- GitHub Markdown Help: https://docs.github.com/en/get-started/writing-on-github
