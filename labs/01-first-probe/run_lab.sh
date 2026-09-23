#!/usr/bin/env bash
# Lab 01: Baseline Security Testing with agent-probe
# Copyright 2026 Radoslaw Brus. SPDX-License-Identifier: Apache-2.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_PATH="${AGENT_PROBE_BIN:-/home/rado/dev/agent-probe/bin/agent-probe}"

if [ ! -f "$BIN_PATH" ]; then
    if command -v agent-probe >/dev/null 2>&1; then
        BIN_PATH="$(command -v agent-probe)"
    else
        echo "[-] Error: agent-probe binary not found. Set AGENT_PROBE_BIN or install to PATH." >&2
        exit 1
    fi
fi

echo "================================================================================"
echo " [LAB 01] Automated Agent Red-Teaming Baseline"
echo " Scanner: $BIN_PATH"
echo " Target:  Local Atlas Mock Agent (Postures: none, basic, hardened)"
echo "================================================================================"

REPORT_DIR="$SCRIPT_DIR/reports"
mkdir -p "$REPORT_DIR"

run_posture_test() {
    local POSTURE="$1"
    local PORT="$2"
    echo ""
    echo ">>> [Phase 1] Launching target in posture: '$POSTURE' on port $PORT..."
    "$BIN_PATH" target --port "$PORT" --defense "$POSTURE" > "$REPORT_DIR/target_$POSTURE.log" 2>&1 &
    local TARGET_PID=$!
    
    # Wait for target readiness
    local RETRIES=10
    until curl -s "http://127.0.0.1:$PORT/chat" >/dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
        sleep 0.3
        RETRIES=$((RETRIES - 1))
    done

    echo ">>> [Phase 2] Executing agent-probe scan against $POSTURE target..."
    set +e
    "$BIN_PATH" scan \
        --target "http://127.0.0.1:$PORT/chat" \
        --field "message" \
        --reply-path "reply" \
        --format "md" \
        --output "$REPORT_DIR/report_$POSTURE.md"
    local SCAN_EXIT_CODE=$?
    set -e

    echo ">>> Scan finished with exit code: $SCAN_EXIT_CODE"
    kill "$TARGET_PID" 2>/dev/null || true
    wait "$TARGET_PID" 2>/dev/null || true
}

run_posture_test "none" 8391
run_posture_test "basic" 8392
run_posture_test "hardened" 8393

echo ""
echo "================================================================================"
echo " [LAB 01 COMPLETE] All 3 defense postures evaluated."
echo " Reports generated in: $REPORT_DIR"
ls -la "$REPORT_DIR"/*.md
echo "================================================================================"
