# Qwen2.5-Coder-32B-Instruct on mlops-node-6.lan

This image serves Qwen's AWQ 4-bit checkpoint with vLLM 0.30.0 on the node's RTX 4090.
It provides an OpenAI-compatible API on port 8000.

## Model and runtime

- Checkpoint: [Qwen/Qwen2.5-Coder-32B-Instruct-AWQ](https://huggingface.co/Qwen/Qwen2.5-Coder-32B-Instruct-AWQ).
- Default context: 32,768 tokens. Automatic prefix caching and eager execution are enabled.
- The downloader saves the complete Hugging Face revision on first use in
  `/models/model-source.json`. Set `MODEL_REVISION` to a full commit SHA on
  the first download to choose a revision. Use a fresh volume to change it.
- `MAX_MODEL_LEN` and `GPU_MEMORY_UTILIZATION` override the defaults. Additional
  vLLM server arguments can be passed after the image name.

A 32B AWQ model at 32K context may exceed 24 GB once the KV cache and runtime
buffers are allocated. If startup fails, lower `MAX_MODEL_LEN` and test the
desired prompt length on the target host. The image has not been run there yet.

## Build and run

Run these commands on the target Linux node. The GitHub workflow builds the
same image on an x86-64 runner.

```sh
docker build -t qwen25-coder-32b-instruct .
docker volume create qwen25-coder-32b-model
docker run --rm -v qwen25-coder-32b-model:/models \
  --entrypoint /usr/local/bin/download-model qwen25-coder-32b-instruct
docker run --rm --gpus all --shm-size 8g \
  -v qwen25-coder-32b-model:/models:ro \
  -p 127.0.0.1:8000:8000 qwen25-coder-32b-instruct
```

The host needs a working NVIDIA driver and NVIDIA Container Toolkit. For a
private checkpoint, pass `HF_TOKEN` only to the download command. Expose the
API outside loopback only behind the cluster's authenticated ingress.

```sh
curl -fsS http://127.0.0.1:8000/health
curl -fsS http://127.0.0.1:8000/v1/models
```

Kubernetes manifests are staged in `gitops/apps/qwen25-coder-32b-instruct/`.
They are not included in the active GitOps app list while node 6's existing
model uses the GPU.
