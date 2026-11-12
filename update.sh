#!/usr/bin/env bash
# Bump docker/.env pins to the latest tailcat and tailscale (derper) releases.
#   ./update.sh          rewrite docker/.env, print old -> new
#   ./update.sh --check  only report
# tailcat has no stability guarantees (CLI/Go API/wire format) -- read
# https://github.com/tailscale/tailcat/blob/main/CHANGELOG.md before merging,
# and bump the tailcat nodes (wart, ...) and client to the same version.
set -euo pipefail
cd "$(dirname "$0")"
env=docker/.env
latest() { curl -fsSL "https://api.github.com/repos/$1/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p'; }
cur_tc=$(sed -n 's/^TAILCAT_VERSION=//p' "$env")
cur_ts=$(sed -n 's/^TAILSCALE_VERSION=//p' "$env")
new_tc=$(latest tailscale/tailcat)
new_ts=$(latest tailscale/tailscale)
[ -n "$new_tc" ] && [ -n "$new_ts" ] || { echo "failed to query GitHub releases" >&2; exit 1; }
echo "tailcat:   $cur_tc -> $new_tc"
echo "tailscale: $cur_ts -> $new_ts (derper)"
[ "${1:-}" = "--check" ] && exit 0
sed -i "s/^TAILCAT_VERSION=.*/TAILCAT_VERSION=$new_tc/; s/^TAILSCALE_VERSION=.*/TAILSCALE_VERSION=$new_ts/" "$env"
