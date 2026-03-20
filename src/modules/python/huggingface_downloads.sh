# Simple Hugging Face download wrappers.
hf_mirror_download() {
  HF_ENDPOINT=https://hf-mirror.com python3 -c "from huggingface_hub import snapshot_download; snapshot_download('$1')"
}
alias hf-mirror-download='hf_mirror_download'
hf_download() {
 python3 -c "from huggingface_hub import snapshot_download; snapshot_download('$1')"
}
alias hf-download='hf_download'
