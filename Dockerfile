# Stage 1 - Build

FROM golang:1.14-buster as builder

COPY go-ethereum /app/src/go-ethereum
WORKDIR /app/src/go-ethereum

RUN apt-get update && apt-get install -y build-essential
RUN echo "\nSubmodule files:"&& \
    ls -Falg --group-directories-first && \
    echo && \
    gcc --version && \
    make -j$(nproc) geth
RUN cd /app/src/go-ethereum/build && \
    ls -Falg --group-directories-first && \
    strip bin/geth


# Stage 2 - Production Image

FROM ubuntu:18.04

LABEL maintainer "Yefta Sutanto <yefta@bitwyre.com>"

RUN apt-get update && \
    apt-get install -y --no-install-recommends gosu && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -r ethereum && useradd -r -m -g ethereum ethereum
RUN mkdir -p /home/ethereum/.ethereum && \
    chown -R ethereum:ethereum /home/ethereum

COPY --from=builder /app/src/go-ethereum/build/bin /usr/local/bin
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

VOLUME ["/home/ethereum/.ethereum"]
EXPOSE 8545 8546 8547 30303 30303/udp

ENV ETHEREUM_DATA "/home/ethereum/.ethereum"

ENTRYPOINT ["/./docker-entrypoint.sh"]
CMD ["geth"]
