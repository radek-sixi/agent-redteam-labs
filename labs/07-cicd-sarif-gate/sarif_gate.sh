#!/usr/bin/env bash
# Lab 07: CI/CD Security Gating & SARIF Generation
# Copyright 2026 Radoslaw B. SPDX-License-Identifier: Apache-2.0

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

OUT_DIR="$SCRIPT_DIR/build-artifacts"
mkdir -p "$OUT_DIR"

echo "================================================================================"
echo " [LAB 07] CI/CD Security Gate & SARIF v2.1.0 Pipeline Gating"
echo " Scanner: $BIN_PATH ($SCANNER_KIND)"
echo "================================================================================"

# Step 1: Simulate Vulnerable Pull Request (Defense: none)
echo ""
echo ">>> [STAGE 1: Scanning Vulnerable PR Build (posture: none)]..."
python3 "$MOCK_TARGET" --port 8395 --defense none > "$OUT_DIR/target_vulnerable.log" 2>&1 &
VULN_PID=$!
sleep 0.5

set +e
if [ "$SCANNER_KIND" = "sixi-scanner" ]; then
    "$BIN_PATH" scan \
        --target chat \
        --url "http://127.0.0.1:8395/chat" \
        --format sarif \
        --out "$OUT_DIR/scan_vulnerable.sarif" \
        --min-severity critical \
        --quiet >/dev/null
else
    "$BIN_PATH" scan \
        --target "http://127.0.0.1:8395/chat" \
        --format "sarif" \
        --output "$OUT_DIR/scan_vulnerable.sarif" \
        --fail-on "critical"
fi
GATE_EXIT_VULN=$?
set -e

kill $VULN_PID 2>/dev/null || true
wait $VULN_PID 2>/dev/null || true
echo "[!] Vulnerable Build Result: Exit Code $GATE_EXIT_VULN (Expected: 1 - Pipeline BLOCKED)"

# Step 2: Simulate Hardened Release Build (Defense: hardened)
echo ""
echo ">>> [STAGE 2: Scanning Hardened Release Candidate (posture: hardened)]..."
python3 "$MOCK_TARGET" --port 8396 --defense hardened > "$OUT_DIR/target_hardened.log" 2>&1 &
HARD_PID=$!
sleep 0.5

set +e
if [ "$SCANNER_KIND" = "sixi-scanner" ]; then
    "$BIN_PATH" scan \
        --target chat \
        --url "http://127.0.0.1:8396/chat" \
        --format sarif \
        --out "$OUT_DIR/scan_hardened.sarif" \
        --min-severity critical \
        --quiet >/dev/null
else
    "$BIN_PATH" scan \
        --target "http://127.0.0.1:8396/chat" \
        --format "sarif" \
        --output "$OUT_DIR/scan_hardened.sarif" \
        --fail-on "critical"
fi
GATE_EXIT_HARD=$?
set -e

kill $HARD_PID 2>/dev/null || true
wait $HARD_PID 2>/dev/null || true
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
    print(f'  • [{lvl.upper():<8}] {rule_id:<32}: {msg[:60]}...')
"

# Step 4: Anti-Flapping Statistical Evaluation
echo ""
echo ">>> [STAGE 4: Statistical Anti-Flapping Evaluation (k-of-n Pass Criteria)]..."
python3 "$SCRIPT_DIR/anti_flap_gate.py"

echo ""
echo "================================================================================"
echo " [LAB 07 COMPLETE] CI/CD SARIF gate & anti-flap controls verified."
echo " Output files in: $OUT_DIR"
ls -la "$OUT_DIR"/*.sarif
echo "================================================================================"
