#!/usr/bin/env bash
set -euo pipefail

exec python3 -m vllm.entrypoints.openai.api_server \
    --model "${MODEL_PATH:-/models/checkpoint}" \
    --served-model-name qwen2.5-coder-32b-instruct \
    --quantization awq \
    --max-model-len "${MAX_MODEL_LEN:-32768}" \
    --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION:-0.95}" \
    --enable-prefix-caching \
    --enforce-eager \
    --host 0.0.0.0 --port 8000 \
    "$@"
