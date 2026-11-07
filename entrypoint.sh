#!/bin/bash
set -e

export DECOMP_HOME="${DECOMP_HOME:-/data}"
mkdir -p "$DECOMP_HOME"

# The server rewrites this ephemeral file with a fresh secret on every launch.
rm -f "$DECOMP_HOME/.decomp/server.json"
decomp &
decomp_pid=$!
trap 'kill "$decomp_pid" 2>/dev/null || true' TERM INT

ready=0
for i in {1..120}; do
    if python3 /proxy_setup.py "$decomp_pid"; then
        ready=1
        break
    fi
    if ! kill -0 "$decomp_pid" 2>/dev/null; then
        wait "$decomp_pid" || true
        exit 1
    fi
    sleep 1
done
if [ "$ready" -ne 1 ]; then
    echo 'Timed out waiting for decomp server state' >&2
    kill "$decomp_pid" 2>/dev/null || true
    exit 1
fi
nginx
wait "$decomp_pid"
