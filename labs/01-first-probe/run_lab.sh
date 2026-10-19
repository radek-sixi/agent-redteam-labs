#!/usr/bin/env bash
# Lab 01: Baseline Security Testing with sixi-scanner
# Copyright 2026 Radoslaw Brus. SPDX-License-Identifier: Apache-2.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
MOCK_TARGET="$ROOT_DIR/scripts/mock_atlas_target.py"

# Resolve sixi-scanner (prefer PATH, $SIXI_SCANNER_BIN, or sibling checkout),
# falling back to legacy agent-probe if present.
SCANNER_KIND="sixi-scanner"
if command -v sixi-scanner >/dev/null 2>&1; then
    BIN_PATH="$(command -v sixi-scanner)"
elif [ -n "${SIXI_SCANNER_BIN:-}" ] && [ -x "$SIXI_SCANNER_BIN" ]; then
    BIN_PATH="$SIXI_SCANNER_BIN"
elif [ -x "$ROOT_DIR/../../rbrus-sixi-scanner/sixi-scanner" ]; then
    BIN_PATH="$(cd "$ROOT_DIR/../../rbrus-sixi-scanner" && pwd)/sixi-scanner"
elif command -v agent-probe >/dev/null 2>&1; then
    BIN_PATH="$(command -v agent-probe)"
    SCANNER_KIND="agent-probe"
elif [ -n "${AGENT_PROBE_BIN:-}" ] && [ -x "$AGENT_PROBE_BIN" ]; then
    BIN_PATH="$AGENT_PROBE_BIN"
    SCANNER_KIND="agent-probe"
else
    echo "[-] Error: sixi-scanner not found. Install it on your PATH or set SIXI_SCANNER_BIN." >&2
    exit 1
fi

echo "================================================================================"
echo " [LAB 01] Automated Agent Red-Teaming Baseline"
echo " Scanner: $BIN_PATH ($SCANNER_KIND)"
echo " Target:  Local Atlas Mock Agent (Postures: none, basic, hardened)"
echo "================================================================================"

REPORT_DIR="$SCRIPT_DIR/reports"
mkdir -p "$REPORT_DIR"

run_posture_test() {
    local POSTURE="$1"
    local PORT="$2"
    echo ""
    echo ">>> [Phase 1] Launching target in posture: '$POSTURE' on port $PORT..."
    python3 "$MOCK_TARGET" --port "$PORT" --defense "$POSTURE" > "$REPORT_DIR/target_$POSTURE.log" 2>&1 &
    local TARGET_PID=$!
    
    # Wait for target readiness
    local RETRIES=15
    until curl -s "http://127.0.0.1:$PORT/chat" >/dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
        sleep 0.2
        RETRIES=$((RETRIES - 1))
    done

    echo ">>> [Phase 2] Executing $SCANNER_KIND scan against $POSTURE target..."
    set +e
    if [ "$SCANNER_KIND" = "sixi-scanner" ]; then
        "$BIN_PATH" scan \
            --target chat \
            --url "http://127.0.0.1:$PORT/chat" \
            --format markdown \
            --out "$REPORT_DIR/report_$POSTURE.md" \
            --quiet
    else
        "$BIN_PATH" scan \
            --target "http://127.0.0.1:$PORT/chat" \
            --field "message" \
            --reply-path "reply" \
            --format "md" \
            --output "$REPORT_DIR/report_$POSTURE.md"
    fi
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
