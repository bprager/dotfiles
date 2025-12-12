# First check if lsmod is available and then look for the NVIDIA kernel module
if command -v lsmod &> /dev/null && lsmod | grep -q "nvidia"; then
    # Set environment variables for CUDA toolkit
    export CUDA_HOME=/usr/local/cuda
    export PATH=$CUDA_HOME/bin:$PATH
    export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
    export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
    export TOKENIZERS_PARALLELISM=false
fi

