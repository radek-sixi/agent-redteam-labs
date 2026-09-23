# Makefile for Agent Red-Team Labs
# Copyright 2026 Radoslaw Brus. SPDX-License-Identifier: Apache-2.0

.PHONY: all test bench clean lab01 lab02 lab03 lab04 lab05 lab06 lab07 lab08 lab09

all: test

test:
	@bash scripts/run_all_labs.sh

lab01:
	@bash labs/01-first-probe/run_lab.sh

lab02:
	@bash labs/02-multi-transport/run_lab.sh

lab03:
	@bash labs/03-judge-evaluation/run_lab.sh

lab04:
	@bash labs/04-local-llm-target/run_lab.sh

lab05:
	@bash labs/05-local-attacker/run_lab.sh

lab06:
	@bash labs/06-tool-agency-abuse/run_lab.sh

lab07:
	@bash labs/07-cicd-sarif-gate/run_lab.sh

lab08:
	@bash labs/08-network-distributed/run_lab.sh

lab09:
	@bash labs/09-edge-to-edge/run_lab.sh

clean:
	rm -rf labs/*/reports labs/*/__pycache__ labs/*/build-artifacts /tmp/atlas_*.log
