# Lab 04 — Local LLM Target Hardening on NVIDIA Jetson Thor

[![Lab](https://img.shields.io/badge/Lab-04-blue.svg)](.)
[![Target LLM](https://img.shields.io/badge/Model-Qwen3.6--35B--abliterated-orange.svg)](#)
[![Hardware](https://img.shields.io/badge/Hardware-NVIDIA_Jetson_Thor_GB10-76B900.svg)](#)
[![Level](https://img.shields.io/badge/Difficulty-Intermediate-yellow.svg)](#)

---

## 🎯 Objective

Most agent red-teaming guides assume you are calling a closed frontier API (like GPT-4 or Gemini) with baked-in RLHF guardrails. However, in enterprise and sovereign deployments, agents frequently run on **local open-weight models** (such as Qwen, Llama, or Gemma) running directly on hardware like **NVIDIA DGX Spark / Jetson Thor GB10**.

In this lab, you will deploy **Atlas** backed by an uncensored / abliterated local LLM (`ttempvnn/Huihui-Qwen3.6-35B-A3B-abliterated-Q4-K-M:latest`) on Jetson Thor and learn:
1. Why models with removed refusal vectors cannot defend themselves via system prompts alone.
2. How to implement **application-layer defensive postures** (`none`, `basic`, `hardened`).
3. How `agent-probe` scans expose the failure of prompt-only defenses against abliterated weights.

```mermaid
graph TD
    User["Red Teamer / Scanner"]
    
    subgraph JetsonThor ["NVIDIA Jetson Thor GB10 (122 GiB Unified Memory)"]
        subgraph AtlasApp ["Atlas Target HTTP Service (:8088)"]
            Stage1["Stage 1: Input Pattern Scrubbing<br/>(Regex Delimiter Normalizer)"]
            SystemPrompt["System Prompt Layer<br/>(Instructions + Escalation Code)"]
            Stage2["Stage 2: Output Canary Filter<br/>(Secret Scrubbing & Masking)"]
        end
        
        subgraph OllamaEngine ["Local Ollama Engine (:11434)"]
            Qwen["ttempvnn/Huihui-Qwen3.6-35B-A3B-abliterated<br/>Throughput: ~44.5 tok/s<br/>VRAM: 21 GiB"]
        end
    end
    
    User -->|POST /chat| Stage1
    Stage1 -->|Clean Message| SystemPrompt
    Stage1 -.->|Blocked| Reject["403 Security Policy Rejection"]
    SystemPrompt -->|Inference Query| Qwen
    Qwen -->|Raw Response| Stage2
    Stage2 -->|Filtered Output| User
```

---

## 🔬 Hardware Specifications & Model Baseline

- **Hardware Platform**: NVIDIA Jetson Thor GB10 / DGX Spark (Linux 6.8 tegra aarch64)
- **Unified System Memory**: 122 GiB Unified RAM (zero CPU-GPU copy bottlenecks)
- **Local Target Model**: `ttempvnn/Huihui-Qwen3.6-35B-A3B-abliterated-Q4-K-M:latest`
- **Measured Throughput**: **44.5 tokens/sec**
- **Inference Latency**: ~3.2 seconds for full 128-token response

---

## 🛠️ Step-by-Step Walkthrough

### Step 1: Start the Local Target Server

```bash
# Set defense posture to 'none' for baseline testing
export ATLAS_DEFENSE=none
python3 atlas_target.py
```

The server listens on `http://0.0.0.0:8088`.

### Step 2: Probing with `agent-probe`

Run `agent-probe` against the live local 35B model:

```bash
agent-probe scan --target http://127.0.0.1:8088/chat \
  --field "message" \
  --reply-path "reply"
```

Because the underlying model is abliterated, prompts asking for internal escalation codes succeed easily without application guards.

### Step 3: Enabling Hardened Defense

Switch to `hardened` posture:

```bash
export ATLAS_DEFENSE=hardened
python3 atlas_target.py
```

Now, incoming injection sequences are intercepted before reaching the LLM, and outbound outputs are scrubbed for the canary string `DEMO-ESCALATION-CODE-7f3a9c`.

---

## ⚡ Automated Runner Script

Run the automated test comparing `none` vs `hardened` against the live 35B model:

```bash
chmod +x ./run_lab.sh
./run_lab.sh
```

---

## 💡 Key Takeaways

1. **Model safety is not application security**: When using open-weight or fine-tuned enterprise models, you cannot rely on model refusals for perimeter defense.
2. **Dual-stage filtering is mandatory**: Input sanitization prevents prompt hijacking; output canary inspection prevents accidental disclosures.
3. **Jetson Thor achieves workstation-class throughput**: 44.5 tok/s on a 35B model allows real-time agent defense and red-teaming directly at the edge.
