FROM vllm/vllm-openai:latest

# Set environment variables for optimal CUDA performance
ENV CUDA_VISIBLE_DEVICES=0
ENV VLLM_WORKER_MULTIPROCESS_METHOD=spawn

# Expose the standard OpenAI-compatible port
EXPOSE 8000

# Launch vLLM with PagedAttention and Automatic Prefix Caching enabled by default
# Utilizing the AWQ quantized version to fit within 24GB VRAM
ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
CMD ["--model", "Qwen/Qwen2.5-Coder-32B-Instruct-AWQ", \
     "--quantization", "awq", \
     "--max-model-len", "32768", \
     "--gpu-memory-utilization", "0.95", \
     "--enforce-eager"]
