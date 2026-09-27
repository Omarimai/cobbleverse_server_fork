# ---------------------------------------------------------------------------
# Single-container build for platforms (Railway) that don't support sharing a
# volume across two docker-compose services. This combines what
# Dockerfile.modinstaller + docker-compose.yml split into two containers
# (mc-modpack-installer, mc) into one image: install the modpack, then hand
# off to itzg/minecraft-server's own startup script.
#
# Local development still uses `docker-compose up` with the two-container
# setup (docker-compose.yml + Dockerfile.modinstaller) — this file is not
# used there.
# ---------------------------------------------------------------------------
FROM itzg/minecraft-server:latest

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends jq wget unzip rsync moreutils \
 && rm -rf /var/lib/apt/lists/*

COPY scripts/install-modpack.sh /railway/install-modpack.sh
COPY scripts/railway-entrypoint.sh /railway/railway-entrypoint.sh
RUN chmod +x /railway/install-modpack.sh /railway/railway-entrypoint.sh

ENTRYPOINT ["/railway/railway-entrypoint.sh"]
