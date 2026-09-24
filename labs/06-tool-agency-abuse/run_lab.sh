#!/usr/bin/env bash
# Lab 06: Tool Agency Abuse Harness — real ADK agent
# Copyright 2026 Radoslaw Brus. SPDX-License-Identifier: Apache-2.0
#
# This lab drives the real Atlas agent from the adk-demo-target repo and reads
# its session state for ground truth. It needs `google-adk` importable and the
# agent's model reachable (Vertex AI credentials). The adk-demo-target repo's
# own virtualenv satisfies the import requirement.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

TARGET_PATH="${ADK_DEMO_TARGET_PATH:-$(cd "$SCRIPT_DIR/../../../adk-demo-target" 2>/dev/null && pwd || true)}"

# Prefer an explicit interpreter, then the adk-demo-target venv, then python3.
PY="${LAB06_PYTHON:-}"
if [[ -z "$PY" && -n "$TARGET_PATH" && -x "$TARGET_PATH/.venv/bin/python" ]]; then
    PY="$TARGET_PATH/.venv/bin/python"
fi
PY="${PY:-python3}"

echo ">>> Lab 06: tool agency abuse against the REAL Atlas ADK agent"
echo "    Interpreter: $PY"
echo "    Target repo: ${TARGET_PATH:-<unset: set ADK_DEMO_TARGET_PATH>}"
echo

exec "$PY" tool_hijack_test.py
