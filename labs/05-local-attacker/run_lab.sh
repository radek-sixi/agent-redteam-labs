#!/usr/bin/env bash
# Lab 05: Autonomous Adversarial Loop on Jetson Thor
# Copyright 2026 Radoslaw Brus. SPDX-License-Identifier: Apache-2.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB04_DIR="$SCRIPT_DIR/../04-local-llm-target"

PORT=8088

# Check if Atlas is already running on :8088, else launch it
if ! curl -s "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
    echo "[+] Launching Atlas target on port $PORT..."
    python3 "$LAB04_DIR/atlas_target.py" > /tmp/atlas_lab05.log 2>&1 &
    ATLAS_PID=$!
    trap 'kill $ATLAS_PID 2>/dev/null || true' EXIT
    sleep 2
else
    echo "[+] Atlas target already running on :$PORT."
fi

# Run the autonomous adversarial loop
export MAX_TURNS=2
python3 "$SCRIPT_DIR/autonomous_attacker.py"
