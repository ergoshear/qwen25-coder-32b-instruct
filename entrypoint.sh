#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
    exec /opt/llama/bin/llama-server \
        --model /models/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf \
        --alias qwen2.5-coder-32b-instruct \
        --host 0.0.0.0 --port 8080 \
        --n-gpu-layers "${GPU_LAYERS:-40}" \
        --ctx-size "${CTX_SIZE:-32768}" \
        --parallel "${PARALLEL:-1}" \
        --threads "${THREADS:-16}" \
        --batch-size "${BATCH_SIZE:-128}" \
        --ubatch-size "${UBATCH_SIZE:-64}" \
        --cache-type-k "${CACHE_TYPE_K:-q4_0}" \
        --cache-type-v "${CACHE_TYPE_V:-q4_0}" \
        --flash-attn "${FLASH_ATTN:-on}" --jinja \
        --temp "${TEMP:-0.2}" --top-p "${TOP_P:-0.95}" --top-k "${TOP_K:-40}"
fi

exec /opt/llama/bin/llama-server "$@"
