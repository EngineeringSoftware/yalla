FROM ubuntu:20.04

WORKDIR /yalla-artifact

# Install basic build essentials
RUN apt-get update && apt-get install -y \
    bc \
    wget \
    build-essential \
    git \
    ninja-build \
    # Clean up apt cache to reduce image size
    && rm -rf /var/lib/apt/lists/*

# Install cmake
ADD https://cmake.org/files/v3.22/cmake-3.22.0-linux-x86_64.sh /cmake-3.22.0-linux-x86_64.sh
RUN mkdir /opt/cmake
RUN sh /cmake-3.22.0-linux-x86_64.sh --prefix=/opt/cmake --skip-license
RUN ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake

# Install miniconda
RUN mkdir -p ~/miniconda3
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
RUN bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
RUN rm ~/miniconda3/miniconda.sh
RUN ~/miniconda3/bin/conda init --all

COPY . .

# Yalla Setup
# RUN ./run.sh get_repos