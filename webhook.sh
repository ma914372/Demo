#!/bin/bash

# Get the Argo CD HTTPS port
PORT=$(cat /tmp/argocd_https_port.txt)
echo $PORT

# Get the public IP of your machine
IP=$(curl -s ifconfig.me)
echo $IP

# Construct the Argo CD webhook URL dynamically
ARGOCD_URL="https://$IP:$PORT/api/webhook"
echo $ARGOCD_URL

# Get the GitHub token from the secret file
TOKEN=$(grep 'password:' secret.yml | awk -F': ' '{print $2}')
echo $TOKEN

# Create the webhook on GitHub with SSL verification disabled
curl -k -X POST \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "$(printf '{
        "name": "web",
        "active": true,
        "events": ["push"],
        "config": {
          "url": "%s",
          "insecure_ssl": "1",
          "content_type": "json"
        }
      }' "$ARGOCD_URL")" \
  https://api.github.com/repos/ma914372/argocd/hooks
