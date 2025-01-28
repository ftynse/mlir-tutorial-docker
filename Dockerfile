FROM ubuntu:24.10
ENV TZ=Europe/Paris DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y sudo
RUN useradd -ms /bin/bash mlir
RUN usermod -aG sudo mlir
RUN echo "mlir:mlir" | chpasswd
RUN echo "mlir ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/mlir
RUN chmod 044 /etc/sudoers.d/mlir
USER mlir
WORKDIR /home/mlir
CMD ["/bin/bash"]
RUN sudo apt-get install -y \
  bash-completion \
  ca-certificates \
  ccache \
  clang \
  cmake \
  cmake-curses-gui \
  git \
  lld \
  man-db \
  ninja-build \
  pybind11-dev \
  python3 \
  python3-numpy \
  python3-pybind11 \
  python3-yaml \
  unzip \
  wget \
  xz-utils
RUN git clone https://github.com/wjakob/nanobind && \
  cd nanobind && \
  git submodule update --init --recursive && \
  cmake \
    -G Ninja \
    -B build \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_INSTALL_PREFIX=$HOME/usr && \
  cmake --build build --target install && \
  cd
RUN wget -nv https://github.com/llvm/llvm-project/archive/1a8f49fdda5b14ccc894aacee653f19130df3a30.zip -O llvm-source.zip
ENV CMAKE_PREFIX_PATH=/home/mlir/usr
RUN unzip -q llvm-source.zip && mv llvm-project-1a8f49fdda5b14ccc894aacee653f19130df3a30 llvm-project
WORKDIR /home/mlir/llvm-project
RUN cmake llvm \
  -G Ninja \
  -B build \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_PREFIX_PATH=$HOME/usr \
  -DLLVM_BUILD_EXAMPLES=On \
  -DLLVM_TARGETS_TO_BUILD="Native;NVPTX;AMDGPU" \
  -DLLVM_CCACHE_BUILD=On \
  -DLLVM_CCACHE_DIR=$HOME/ccache \
  -DLLVM_ENABLE_ASSERTIONS=On \
  -DLLVM_ENABLE_LLD=On \
  -DLLVM_ENABLE_PROJECTS="mlir;clang;clang-tools-extra" \
  -DLLVM_USE_SPLIT_DWARF=On \
  -DMLIR_ENABLE_BINDINGS_PYTHON=On \
  -DMLIR_INCLUDE_INTEGRATION_TESTS=On
RUN cmake --build build -t mlir-opt mlir-translate mlir-transform-opt mlir-cpu-runner check-mlir || true
RUN cmake --build build -t clang
RUN cmake --build build -t libclangTooling.a
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
RUN cmake --build build -t opt
WORKDIR /home/mlir
RUN git clone https://github.com/EnzymeAD/Enzyme.git && mkdir Enzyme/enzyme/build
WORKDIR /home/mlir/Enzyme/enzyme/build
RUN cmake .. \
  -G Ninja \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_PREFIX_PATH=$HOME/usr \
  -DLLVM_CCACHE_BUILD=On \
  -DLLVM_CCACHE_DIR=$HOME/ccache \
  -DLLVM_DIR=$HOME/llvm-project/build/lib/cmake/llvm \
  -DLLVM_EXTERNAL_LIT=$HOME/llvm-project/build/bin/llvm-lit
RUN cmake --build . -t check-enzyme || true
