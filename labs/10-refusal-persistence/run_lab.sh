#!/usr/bin/env bash
# Lab 10: Refusal Persistence Harness — real ADK agent
# Copyright 2026 Radoslaw Brus. SPDX-License-Identifier: Apache-2.0
#
# Needs `google-adk` importable and the Atlas model reachable (Vertex AI creds).
# The adk-demo-target virtualenv satisfies the import requirement.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

TARGET_PATH="${ADK_DEMO_TARGET_PATH:-$(cd "$SCRIPT_DIR/../../../adk-demo-target" 2>/dev/null && pwd || true)}"

PY="${LAB10_PYTHON:-}"
if [[ -z "$PY" && -n "$TARGET_PATH" && -x "$TARGET_PATH/.venv/bin/python" ]]; then
    PY="$TARGET_PATH/.venv/bin/python"
fi
PY="${PY:-python3}"

echo ">>> Lab 10: refusal persistence against the REAL Atlas ADK agent"
echo "    Interpreter: $PY"
echo "    Target repo: ${TARGET_PATH:-<unset: set ADK_DEMO_TARGET_PATH>}"
echo

exec "$PY" refusal_persistence_test.py
