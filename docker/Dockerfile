# tailcat-relay — container build of Tailscale's DERP relay
# (cmd/derper, from the tailscale.com module), used as our tailcat
# break-glass rendezvous/relay node. BSD-3-Clause upstream.
# Upstream publishes no derper image or packages, so we build the pinned tag.

FROM golang:1.27-bookworm AS build
# Version comes from docker/.env via CI (--build-arg); no default on purpose,
# so a rebuild is always a deliberate diff, never whatever @latest resolves to.
ARG TAILSCALE_VERSION
# GOTOOLCHAIN=auto: tailscale.com bumps its minimum Go without warning.
ENV CGO_ENABLED=0 GOFLAGS=-trimpath GOTOOLCHAIN=auto
RUN test -n "$TAILSCALE_VERSION" && go install tailscale.com/cmd/derper@${TAILSCALE_VERSION}

# distroless/base, NOT -nonroot: derper binds 80/443 itself. Root-in-container
# on a single-purpose VM is the simpler choice.
FROM gcr.io/distroless/base-debian12
COPY --from=build /go/bin/derper /derper
EXPOSE 443/tcp 80/tcp 3478/udp
ENTRYPOINT ["/derper"]
