#!/usr/bin/env bash
# One-time (fresh VM only): create the relay VM's persistent tailcat server key,
# pinned to our own relay. Prints the tailcat address -- treat it as a secret.
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./.env; set +a
docker compose run --rm --no-deps tailcat genkey --key=default --region="${DERP_HOSTNAME}"
docker compose up -d tailcat
