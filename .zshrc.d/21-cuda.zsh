# First check if lsmod is available and then look for the NVIDIA kernel module
if [[ "$os_name" == "Linux" ]] && command -v lsmod >/dev/null 2>&1 && lsmod | grep -q "nvidia"; then
  # Set environment variables for CUDA toolkit
  export CUDA_HOME=/usr/local/cuda
  path_prepend "$CUDA_HOME/bin"
  export LD_LIBRARY_PATH="$CUDA_HOME/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
  export TOKENIZERS_PARALLELISM=false
fi
