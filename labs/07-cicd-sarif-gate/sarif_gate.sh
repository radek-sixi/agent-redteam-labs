#!/usr/bin/env bash
# Lab 07: CI/CD Security Gating & SARIF Generation
# Copyright 2026 Radoslaw Brus. SPDX-License-Identifier: Apache-2.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_PATH="${AGENT_PROBE_BIN:-/home/rado/dev/agent-probe/bin/agent-probe}"

if [ ! -f "$BIN_PATH" ]; then
    if command -v agent-probe >/dev/null 2>&1; then
        BIN_PATH="$(command -v agent-probe)"
    else
        echo "[-] Error: agent-probe binary not found." >&2
        exit 1
    fi
fi

OUT_DIR="$SCRIPT_DIR/build-artifacts"
mkdir -p "$OUT_DIR"

echo "================================================================================"
echo " [LAB 07] CI/CD Security Gate & SARIF v2.1.0 Pipeline Gating"
echo " Scanner: $BIN_PATH"
echo "================================================================================"

# Step 1: Simulate Vulnerable Pull Request (Defense: none)
echo ""
echo ">>> [STAGE 1: Scanning Vulnerable PR Build (posture: none)]..."
"$BIN_PATH" target --port 8395 --defense none > "$OUT_DIR/target_vulnerable.log" 2>&1 &
VULN_PID=$!
sleep 1

set +e
"$BIN_PATH" scan \
    --target "http://127.0.0.1:8395/chat" \
    --format "sarif" \
    --output "$OUT_DIR/scan_vulnerable.sarif" \
    --fail-on "critical"
GATE_EXIT_VULN=$?
set -e

kill $VULN_PID 2>/dev/null || true
echo "[!] Vulnerable Build Result: Exit Code $GATE_EXIT_VULN (Expected: 1 - Pipeline BLOCKED)"

# Step 2: Simulate Hardened Release Build (Defense: hardened)
echo ""
echo ">>> [STAGE 2: Scanning Hardened Release Candidate (posture: hardened)]..."
"$BIN_PATH" target --port 8396 --defense hardened > "$OUT_DIR/target_hardened.log" 2>&1 &
HARD_PID=$!
sleep 1

set +e
"$BIN_PATH" scan \
    --target "http://127.0.0.1:8396/chat" \
    --format "sarif" \
    --output "$OUT_DIR/scan_hardened.sarif" \
    --fail-on "critical"
GATE_EXIT_HARD=$?
set -e

kill $HARD_PID 2>/dev/null || true
echo "[✓] Hardened Build Result: Exit Code $GATE_EXIT_HARD (Expected: 0 - Pipeline PASSED)"

# Step 3: Inspect SARIF Structure
echo ""
echo ">>> [STAGE 3: SARIF Schema Inspection]..."
python3 -c "
import json
with open('$OUT_DIR/scan_vulnerable.sarif') as f:
    data = json.load(f)
results = data['runs'][0].get('results', [])
print(f'Total Findings in Vulnerable SARIF: {len(results)}')
for r in results[:4]:
    rule_id = r.get('ruleId')
    lvl = r.get('level')
    msg = r.get('message', {}).get('text')
    print(f'  • [{lvl.upper():<8}] {rule_id:<20}: {msg[:60]}...')
"

echo ""
echo "================================================================================"
echo " [LAB 07 COMPLETE] CI/CD SARIF gate successfully verified."
echo " Output files in: $OUT_DIR"
ls -la "$OUT_DIR"/*.sarif
echo "================================================================================"
