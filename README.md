# tailcat-relay

Standalone DERP relay for our tailcat break-glass path, at `tc.penwulf.com`.
Deliberately outside Camelot's management plane — no Komodo, no Semaphore,
no NetBird dependency. Provisioned by hand from OpenTofu run locally, built
by GitHub Actions, not by anything self-hosted.

The VM also runs a tailcat server of its own (`serve 22`), so the relay VM is
reachable through a tailcat tunnel too; its real sshd still does normal SSH auth.

## Layout

- `terraform/` — GCP e2-micro VM (Always Free eligible), static external IP,
  firewall rules (80/tcp, 443/tcp, 3478/udp, 22/tcp restricted to your IP).
  The startup script clones this repo to `/opt/tailwag-derper` and runs
  `docker compose pull && up -d` in `docker/` **on every boot**.
- `docker/` — derper image build, the compose stack (derper + tailcat), and
  `.env`, the single place versions and the relay hostname are pinned.
- `update.sh` — bumps the pins in `docker/.env` to the latest upstream releases.
- `.github/workflows/build-derper.yml` — builds derper at the pinned tailscale
  version and pushes `ghcr.io/moquito64/tailcat-relay:<version>` (+ `latest`).
- `.github/workflows/check-updates.yml` — weekly; opens a "Bump tailcat /
  derper versions" PR when upstream has new releases.

## Updating

1. Merge the weekly bump PR (or run `./update.sh` and push). Read the tailcat
   CHANGELOG first — upstream makes no CLI/API/wire-format stability promise.
2. Wait for the build workflow to finish (the compose file pulls the
   version-tagged derper image, which doesn't exist until CI pushes it).
3. On the VM: `sudo /opt/tailwag-derper/docker/deploy.sh` (or just reboot).
4. Bump `tailcat` on the nodes (wart, ...) and the client to the same tailcat
   version: `GOTOOLCHAIN=auto go install github.com/tailscale/tailcat/cmd/tailcat@<version>`.

Rollback: revert the `.env` commit, push, wait for CI if derper changed, deploy.

## Fresh VM, in order

1. **New GCP project**, separate from anything else.
2. Push this repo; let the build workflow run; keep the GHCR package **public**
   (the VM pulls anonymously).
3. `cd terraform && tofu init && tofu apply` (prompts for `project_id`,
   `ssh_source_ranges`, `repo_url`). Point `tc.penwulf.com`'s A record at the
   printed `derper_ip`.
4. `curl -v https://tc.penwulf.com/derp/probe` returns 200 once the cert issues.
5. Create the VM's own tailcat key: `sudo /opt/tailwag-derper/docker/init-key.sh`.
   Get its address later with `sudo docker logs tailcat | grep listening`.

Note: `metadata_startup_script` changes force VM replacement in the google
provider — prefer changing what the script runs (this repo) over the script.

## Baking this relay into a tailcat node key

```
tailcat genkey --key=default --region=tc.penwulf.com
```

The hostname form of `--region` fully embeds this relay's node info in the
address, so clients need no DERP map. Don't combine it with
`--embed-derp-map` (assumes a numeric region ID and panics on a hostname).
Changing `DERP_HOSTNAME` breaks every key made for the old name: the relay
only gets a certificate for one hostname, so each node needs a re-key and a
new DNS TXT record.

## Notes

- `--verify-clients=false` is deliberate: tailcat peers aren't tailnet nodes.
  `--allow=nodekey:...` on each tailcat node is the actual gate.
- No mesh key — single node.
- Uptime Kuma checks `https://tc.penwulf.com/derp/probe`.

## Naming leftovers

The GCP resources (VM `tailwag-derper`, static IP `tailwag-derper-ip`, firewall
rules and network tag) and the `/opt/tailwag-derper` checkout path keep the old
tailwag name: renaming any of them forces replacement in Terraform, and a new
static IP would change the relay's address. Rename them only as part of a full
VM rebuild.
