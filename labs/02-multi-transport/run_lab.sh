#!/usr/bin/env bash
# Lab 02: Multi-Protocol Red-Teaming with Redwire
# Copyright 2026 Radoslaw Brus. SPDX-License-Identifier: Apache-2.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v go >/dev/null 2>&1; then
    echo "[-] Error: Go compiler not found on PATH." >&2
    exit 1
fi

echo ">>> Building and running Lab 02 Multi-Transport redwire harness..."
go run main.go
