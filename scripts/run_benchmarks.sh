#!/usr/bin/env bash
#
# One-shot benchmark collection for the cuda-foundations repo.
#
# Runs:
#   1. 01-sgemm-tutorial standalone benchmark (all standard sizes)
#   2. 02-tensorcraft-core gemm benchmark (Google Benchmark)
#
# The 01 benchmark writes roofline_data_<size>.csv next to the module; the
# distilled numbers are meant to be copied into docs/en/benchmarks/.
# Every step below pins its own working directory, so results land in the same
# place no matter where this script is invoked from.
# LD_PRELOAD is only needed on WSL2; it is set automatically when detected.

set -euo pipefail

# Resolve repo root from this script's location.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# WSL2 exposes the host GPU driver through /usr/lib/wsl/lib/libcuda.so.1.
if [[ -f /usr/lib/wsl/lib/libcuda.so.1 ]]; then
    export LD_PRELOAD=/usr/lib/wsl/lib/libcuda.so.1
fi

echo "== GPU info =="
nvidia-smi --query-gpu=name,driver_version,compute_cap --format=csv
echo
echo "== CUDA info =="
nvcc --version | tail -2
echo
echo "== Build =="
(cd "${REPO_ROOT}" && cmake --preset default)
(cd "${REPO_ROOT}" && cmake --build --preset default -j)
echo
echo "== 01 benchmark =="
# The benchmark writes roofline_data_<size>.csv to its cwd, so run it from the
# module directory rather than from wherever this script was called.
(cd "${REPO_ROOT}/01-sgemm-tutorial" && make benchmark)
(cd "${REPO_ROOT}/01-sgemm-tutorial" && ./build/sgemm_benchmark -a)
echo
echo "== 02 gemm benchmark =="
(cd "${REPO_ROOT}" && ./build/default/bin/gemm_benchmark \
    --benchmark_min_time=0.1s --benchmark_repetitions=3)
