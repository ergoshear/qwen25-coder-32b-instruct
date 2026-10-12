# Primary Architect Node (mlops-node-6.lan): Qwen2.5-Coder-32B-Instruct

This node drives code-generation agents and real-time editing workloads. Its
target GPU is an NVIDIA RTX 4090 with 24 GB GDDR6X. This repository currently
builds a CUDA `llama.cpp` server using a Q4_K_M GGUF model. The supplied cluster
specification describes an AWQ 4-bit vLLM deployment; that is a different
runtime and quantized model from the image documented here.

## Model and context

- Model: [bartowski/Qwen2.5-Coder-32B-Instruct-GGUF](https://huggingface.co/bartowski/Qwen2.5-Coder-32B-Instruct-GGUF),
  `Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf` (about 19.85 GB). The downloader
  pins the Hugging Face revision on first use and verifies the file against its
  LFS SHA256.
- The default context is 32,768 tokens, the model's standard context length.
  The server uses one parallel slot and Q4_0 K/V cache.
- The Q4 weights nearly fill the RTX 4090 when runtime buffers and KV cache
  are included. By default, 40 layers are placed on the GPU and the remaining
  layers use host RAM. Adjust `GPU_LAYERS` to trade GPU memory for CPU work.
  Actual allocation depends on the llama.cpp revision, CUDA runtime, context,
  and other GPU processes; the startup log reports the allocation.

If startup runs out of memory, lower `GPU_LAYERS` first (for example, 32) or
reduce `CTX_SIZE`. One parallel slot preserves the full context for a single
request. Runtime settings include `GPU_LAYERS`, `CTX_SIZE`, `PARALLEL`,
`THREADS`, `BATCH_SIZE`, `UBATCH_SIZE`, `CACHE_TYPE_K`, `CACHE_TYPE_V`,
`FLASH_ATTN`, `TEMP`, `TOP_P`, and `TOP_K`.

## Host requirements

Use Linux with a working NVIDIA driver and NVIDIA Container Toolkit configured
for Docker or Podman. The container provides CUDA user space; it does not
install the host driver. Check `nvidia-smi` on the host before starting. The
image targets Ada GPU architecture 8.9.

## Build and download

Run from this directory. These examples use Podman; Docker can use the same
commands.

```sh
podman build --format docker -t qwen25-coder-32b-instruct-4090 .
podman volume create qwen25-coder-32b-instruct-model
podman run --rm --gpus all -v qwen25-coder-32b-instruct-model:/models \
  --entrypoint /usr/local/bin/download-model qwen25-coder-32b-instruct-4090
```

The public model does not need a token. If Hugging Face requires
authentication, pass `HF_TOKEN` only to the download command. Model files stay
in the named volume; reserve at least 22 GB for the model volume.

## Run the server

```sh
podman run -d --name qwen25-coder-32b-instruct \
  --gpus all --shm-size 8g \
  -v qwen25-coder-32b-instruct-model:/models:ro \
  -p 127.0.0.1:8080:8080 \
  qwen25-coder-32b-instruct-4090
podman logs -f qwen25-coder-32b-instruct
```

For example, add `-e GPU_LAYERS=32` or `-e CTX_SIZE=16384` if the default
allocation does not fit. Keep the API bound to loopback as shown. If it must be
reachable remotely, put it behind an authenticated TLS proxy.

Check readiness and make a small request after the model loads:

```sh
curl -fsS http://127.0.0.1:8080/health
curl -fsS http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen2.5-coder-32b-instruct","messages":[{"role":"user","content":"Write a Python function that returns the first n Fibonacci numbers."}],"max_tokens":128,"temperature":0}'
```

The image has not been built or run on `mlops-node-6.lan` as part of this
change. Confirm the startup log reports the allocated context and test an
inference request on the host before relying on the service.
