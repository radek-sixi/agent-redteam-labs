#!/usr/bin/env bash
# Lab 07: CI/CD Security Gating & SARIF Generation
# Copyright 2026 Radoslaw Brus. SPDX-License-Identifier: Apache-2.0

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

bash "$SCRIPT_DIR/sarif_gate.sh"
