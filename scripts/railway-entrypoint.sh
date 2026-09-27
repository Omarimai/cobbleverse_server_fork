#!/bin/sh
set -e

# ---- railway-entrypoint.sh -------------------------------------------------
# Combined entrypoint for the single-service Railway deployment.
#
# The docker-compose setup uses two containers: one that installs the
# modpack into a shared volume, and itzg/minecraft-server which waits for
# that install to finish before starting. Railway volumes only attach to one
# service, so both steps run here, in one container, on one volume:
#   1. Install/refresh the modpack (skips if already done for this world).
#   2. Hand off to the base image's own startup script.
# -----------------------------------------------------------------------------

export MC_UID=${MC_UID:-1000}
export MC_GID=${MC_GID:-1000}
export DATA_DIR=${DATA_DIR:-/data}
export MODPACK_DIR=${MODPACK_DIR:-/data/modpack}

echo "[railway-entrypoint] Installing modpack for world: ${SERVER_WORLDNAME:-<unset>}"
/railway/install-modpack.sh

echo "[railway-entrypoint] Handing off to the Minecraft server entrypoint…"
if [ -x /image/scripts/start ]; then
  exec /image/scripts/start
elif [ -x /start ]; then
  exec /start
else
  echo "[railway-entrypoint] ERROR: could not find the itzg/minecraft-server startup script" >&2
  exit 1
fi
