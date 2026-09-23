#!/usr/bin/env bash
# Lab 06: Tool Agency Abuse Harness
# Copyright 2026 Radoslaw Brus. SPDX-License-Identifier: Apache-2.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v python3 >/dev/null 2>&1; then
    echo "[-] Error: python3 not found." >&2
    exit 1
fi

echo ">>> Running Lab 06 Tool Agency & Privilege Escalation tests..."
python3 tool_hijack_test.py
