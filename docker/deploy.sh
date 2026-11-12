#!/usr/bin/env bash
# On the VM: pull the repo and roll the stack to whatever docker/.env pins.
# Same thing the GCP startup script does on every boot. Wait for the
# "build tailcat-relay" workflow to finish first so the derper tag exists.
set -euo pipefail
git -C /opt/tailwag-derper pull --ff-only
cd /opt/tailwag-derper/docker
docker compose pull
docker compose up -d
docker image prune -f >/dev/null
docker compose ps
