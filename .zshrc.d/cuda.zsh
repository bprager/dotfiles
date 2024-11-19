# Check for NVIDIA kernel module
if lsmod | grep -q "nvidia"; then
    # Specify the path to the CUDA toolkit
    export CUDA_HOME=/usr/local/cuda
    export PATH=$CUDA_HOME/bin:$PATH
    export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
fi

