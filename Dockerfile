FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y build-essential cmake git clang \
    && rm -rf /var/lib/apt/lists/*

# Clone and build ido-static-recomp (includes IDO 5.3 and 7.1)
WORKDIR /opt/
RUN git clone --recursive https://github.com/decompals/ido-static-recomp.git \
    && cd ido-static-recomp \
    && make setup \
    && make VERSION=5.3 -j$(nproc) \
    && make VERSION=7.1 -j$(nproc)

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y build-essential binutils-mips-linux-gnu python3 python3-pip git \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install -U splat64[mips]

COPY --from=builder /opt/ido-static-recomp/build/5.3/out /usr/local/bin/ido5.3
COPY --from=builder /opt/ido-static-recomp/build/7.1/out /usr/local/bin/ido7.1
ENV IDO_53_DIR=/usr/local/bin/ido5.3
ENV IDO_71_DIR=/usr/local/bin/ido7.1

# User & final working directory
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN useradd -ms /bin/bash bond
RUN usermod -aG sudo bond
USER bond
WORKDIR /goldeneye

CMD ["/bin/bash"]
