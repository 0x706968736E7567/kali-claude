#!/bin/bash
# Seed the project MCP config into the workspace on every startup.
#
# `claude` discovers project MCP servers from .mcp.json in its working dir
# (/home/operator/workspace). That dir is bind-mounted from the host in compose,
# which shadows any copy baked into the image — and Docker can't reliably mount a
# single file *inside* a bind-mounted dir (fails on Docker Desktop's virtiofs).
# `claude` also has no flag or env var to point at a config elsewhere. So we keep
# the canonical copy outside the mount and refresh it into the workspace here.
#
# We OVERWRITE on every start (not seed-if-absent) so the config always tracks
# the image/repo and can't go stale: rebuild with a new .mcp.json and the next
# `up` picks it up. To change the server set, edit the repo's .mcp.json and
# rebuild — not the copy in workspace/, which is treated as derived state.
set -e

SRC=/opt/kali-claude/mcp.json
DEST=/home/operator/workspace/.mcp.json

if [ -f "$SRC" ]; then
  cp -f "$SRC" "$DEST" 2>/dev/null \
    || echo "entrypoint: warning — could not refresh $DEST (workspace not writable?)" >&2
fi

exec "$@"
