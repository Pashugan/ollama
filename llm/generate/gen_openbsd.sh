#!/bin/sh
set -eo pipefail

# This script is intended to run inside the go generate
# working directory must be llm/generate/

# We build our default built-in library which will be linked into the CGO
# binary as a normal dependency. This default build is CPU based.

export CC=$(command -v clang)
export CXX=$(command -v clang++)

echo "Starting OpenBSD generate script"

. $(dirname $0)/gen_common.sh
git_module_setup
apply_patches

# Users building from source can tune the exact flags we pass to cmake for configuring
# llama.cpp, and we'll build only 1 CPU variant in that case as the default.
if [ -n "${OLLAMA_CUSTOM_CPU_DEFS}" ]; then
    echo "OLLAMA_CUSTOM_CPU_DEFS=\"${OLLAMA_CUSTOM_CPU_DEFS}\""
    init_vars
    CMAKE_DEFS="${OLLAMA_CUSTOM_CPU_DEFS} -DCMAKE_POSITION_INDEPENDENT_CODE=on ${CMAKE_DEFS}"
    BUILD_DIR="${LLAMACPP_DIR}/build/openbsd/cpu"
    echo "Building custom CPU"
    build
    compress_libs
else
    # Darwin Rosetta x86 emulation does NOT support AVX, AVX2, AVX512
    # -DLLAMA_AVX -- 2011 Intel Sandy Bridge & AMD Bulldozer
    # -DLLAMA_F16C -- 2012 Intel Ivy Bridge & AMD 2011 Bulldozer (No significant improvement over just AVX)
    # -DLLAMA_AVX2 -- 2013 Intel Haswell & 2015 AMD Excavator / 2017 AMD Zen
    # -DLLAMA_FMA (FMA3) -- 2013 Intel Haswell & 2012 AMD Piledriver
    # Note: the following seem to yield slower results than AVX2 - ymmv
    # -DLLAMA_AVX512 -- 2017 Intel Skylake and High End DeskTop (HEDT)
    # -DLLAMA_AVX512_VBMI -- 2018 Intel Cannon Lake
    # -DLLAMA_AVX512_VNNI -- 2021 Intel Alder Lake

    COMMON_CPU_DEFS="-DCMAKE_POSITION_INDEPENDENT_CODE=on -DLLAMA_NATIVE=off"
    #
    # CPU first for the default library, set up as lowest common denominator for maximum compatibility (including Rosetta)
    #
    init_vars
    CMAKE_DEFS="${COMMON_CPU_DEFS} -DLLAMA_AVX=off -DLLAMA_AVX2=off -DLLAMA_AVX512=off -DLLAMA_FMA=off -DLLAMA_F16C=off ${CMAKE_DEFS}"
    BUILD_DIR="${LLAMACPP_DIR}/build/openbsd/cpu"
    echo "Building LCD CPU"
    build
    compress_libs

    #
    # ~2011 CPU Dynamic library with more capabilities turned on to optimize performance
    # Approximately 400% faster than LCD on same CPU
    #
    init_vars
    CMAKE_DEFS="${COMMON_CPU_DEFS} -DLLAMA_AVX=on -DLLAMA_AVX2=off -DLLAMA_AVX512=off -DLLAMA_FMA=off -DLLAMA_F16C=off ${CMAKE_DEFS}"
    BUILD_DIR="${LLAMACPP_DIR}/build/openbsd/cpu_avx"
    echo "Building AVX CPU"
    build
    compress_libs

    #
    # ~2013 CPU Dynamic library
    # Approximately 10% faster than AVX on same CPU
    #
    init_vars
    CMAKE_DEFS="${COMMON_CPU_DEFS} -DLLAMA_AVX=on -DLLAMA_AVX2=on -DLLAMA_AVX512=off -DLLAMA_FMA=on -DLLAMA_F16C=on ${CMAKE_DEFS}"
    BUILD_DIR="${LLAMACPP_DIR}/build/openbsd/cpu_avx2"
    echo "Building AVX2 CPU"
    build
    compress_libs
fi

cleanup
