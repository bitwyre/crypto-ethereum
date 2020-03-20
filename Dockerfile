# Stage 1 - Build

FROM bitwyre/native-builder:latest as builder
WORKDIR /app/parity

# YASM
COPY yasm yasm
RUN cd yasm && \
    ./autogen.sh && \
    ./configure && \
    make -j4 install

# Open-Ethereum
COPY openethereum openethereum
WORKDIR /app/parity/openethereum
ENV PATH /root/.cargo/bin:/usr/lib/llvm-10/bin:$PATH
RUN RUSTFLAGS="-C link-args=-s -C codegen-units=1" cargo build --release --features final && \
    echo "\nBinary info:" && file target/release/parity && size target/release/parity


# Stage 2 - Production Image

FROM ubuntu:18.04

LABEL maintainer "Yefta Sutanto (yefta@bitwyre.com), Aditya Kresna (kresna@bitwyre.com)"

RUN apt-get update && \
    apt-get install -y --no-install-recommends gosu && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -r ethereum && useradd -r -m -g ethereum ethereum
RUN mkdir -p /home/ethereum/.local/share/io.parity.ethereum && \
    chown -R ethereum:ethereum /home/ethereum

COPY --from=builder /app/parity/openethereum/target/release/parity /usr/local/bin/parity
COPY testnet-config.toml /home/ethereum/.local/share/io.parity.ethereum/config.toml
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh && \
    # Take ownership once again
    chown -R ethereum:ethereum /home/ethereum

VOLUME ["/home/ethereum/.local/share/io.parity.ethereum"]
EXPOSE 8082 8083 8545 8546 8547 30303 30303/udp

ENV ETHEREUM_DATA "/home/ethereum/.local/share/io.parity.ethereum"

ENTRYPOINT ["/./docker-entrypoint.sh"]
CMD ["parity"]
