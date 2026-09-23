#!/usr/bin/env bash
# Lab 08: Distributed Network Red-Teaming Runner
# Copyright 2026 Radoslaw Brus. SPDX-License-Identifier: Apache-2.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v python3 >/dev/null 2>&1; then
    echo "[-] Error: python3 not found." >&2
    exit 1
fi

# Ensure target is running locally if not running remotely
TARGET_HOST="${JETSON_THOR_HOST:-127.0.0.1}"
TARGET_PORT="${JETSON_THOR_PORT:-8088}"

if ! curl -s "http://$TARGET_HOST:$TARGET_PORT/health" >/dev/null 2>&1; then
    echo "[+] Launching local Atlas target on $TARGET_PORT..."
    python3 "$SCRIPT_DIR/../04-local-llm-target/atlas_target.py" > /tmp/atlas_lab08.log 2>&1 &
    ATLAS_PID=$!
    trap 'kill $ATLAS_PID 2>/dev/null || true' EXIT
    sleep 2
fi

echo ">>> Launching Lab 08 Distributed Network Red-Teaming campaign..."
python3 workstation_probe.py
