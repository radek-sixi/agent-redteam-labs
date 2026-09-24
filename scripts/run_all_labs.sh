#!/usr/bin/env bash
# Master Automated Test Suite & Benchmark Runner for Agent Red-Team Labs
# Copyright 2026 Radoslaw Brus. SPDX-License-Identifier: Apache-2.0

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "================================================================================"
echo "      AGENT RED-TEAM LABS — FULL CURRICULUM AUTOMATION & VERIFICATION"
echo " Hardware Node: NVIDIA Jetson Thor GB10 (122 GiB Unified Memory)"
echo " OS Platform:   Linux 6.8 tegra aarch64"
echo " Time:          $(date -u)"
echo "================================================================================"

PASSED=0
FAILED=0
SKIPPED=0
TOTAL=10

# Exit code a lab uses to say "I could not run because a dependency (ADK agent,
# model, credentials) is unavailable" — a deliberate abort, not a test failure.
SKIP_EXIT=4

run_lab() {
    local LAB_NUM="$1"
    local LAB_NAME="$2"
    local SCRIPT_PATH="$3"

    echo ""
    echo "================================================================================"
    echo " >>> EXECUTING LAB $LAB_NUM: $LAB_NAME"
    echo "================================================================================"

    local T0
    T0=$(date +%s)

    if [ ! -f "$SCRIPT_PATH" ]; then
        echo "[-] Script not found: $SCRIPT_PATH"
        FAILED=$((FAILED + 1))
        return
    fi

    chmod +x "$SCRIPT_PATH"
    local RC=0
    "$SCRIPT_PATH" || RC=$?
    local T1
    T1=$(date +%s)

    if [ "$RC" -eq 0 ]; then
        echo "[✓] LAB $LAB_NUM ($LAB_NAME) PASSED (Elapsed: $((T1 - T0))s)"
        PASSED=$((PASSED + 1))
    elif [ "$RC" -eq "$SKIP_EXIT" ]; then
        echo "[~] LAB $LAB_NUM ($LAB_NAME) SKIPPED — dependency unavailable (Elapsed: $((T1 - T0))s)"
        SKIPPED=$((SKIPPED + 1))
    else
        echo "[✗] LAB $LAB_NUM ($LAB_NAME) FAILED (exit $RC, Elapsed: $((T1 - T0))s)"
        FAILED=$((FAILED + 1))
    fi
}

run_lab "01" "First Autonomous Probe" "$ROOT_DIR/labs/01-first-probe/run_lab.sh"
run_lab "02" "Multi-Transport Red-Teaming (redwire)" "$ROOT_DIR/labs/02-multi-transport/run_lab.sh"
run_lab "03" "Autonomous Judge Evaluation (laya-as-judge)" "$ROOT_DIR/labs/03-judge-evaluation/run_lab.sh"
run_lab "04" "Local LLM Target Hardening (Jetson Thor)" "$ROOT_DIR/labs/04-local-llm-target/run_lab.sh"
run_lab "05" "Local Adversarial Attacker Loop" "$ROOT_DIR/labs/05-local-attacker/run_lab.sh"
run_lab "06" "Tool Agency Abuse & Confused Deputy" "$ROOT_DIR/labs/06-tool-agency-abuse/run_lab.sh"
run_lab "07" "CI/CD DevSecOps SARIF Gate" "$ROOT_DIR/labs/07-cicd-sarif-gate/run_lab.sh"
run_lab "08" "Distributed Network Red-Teaming" "$ROOT_DIR/labs/08-network-distributed/run_lab.sh"
run_lab "09" "Edge-to-Edge Tactical Red-Teaming" "$ROOT_DIR/labs/09-edge-to-edge/run_lab.sh"
run_lab "10" "Refusal Persistence (didn't accept no)" "$ROOT_DIR/labs/10-refusal-persistence/run_lab.sh"

echo ""
echo "================================================================================"
echo " CURRICULUM VERIFICATION COMPLETE"
echo " Passed:  $PASSED / $TOTAL labs"
echo " Skipped: $SKIPPED / $TOTAL labs (dependency unavailable — not a failure)"
echo " Failed:  $FAILED / $TOTAL labs"
echo " Telemetry Log: $ROOT_DIR/telemetry/jetson-thor-kpis.json"
echo "================================================================================"

if [ "$FAILED" -eq 0 ]; then
    exit 0
else
    exit 1
fi
