# vLLM throughput benchmark wrapper.
vllm_bench() {
  model=${1:-"Qwen/Qwen3-4B-Instruct-2507"}
  input_len=${2:-4096}
  output_len=${3:-256}
  num_prompts=${4:-100}

  # default max_model_len = input_len + output_len
  if [ -n "$5" ]; then
    max_model_len=$5
  else
    max_model_len=$((input_len + output_len))
  fi

  vllm bench throughput \
    --gpu-memory-utilization 0.9 \
    --model "$model" \
    --dataset-name random \
    --num-prompts "$num_prompts" \
    --input-len "$input_len" \
    --output-len "$output_len" \
    --max-model-len "$max_model_len" \
    --async-engine
}

alias hf_bench='vllm_bench'
alias vllm-bench='vllm_bench'
