FROM ubuntu:22.04 as ton

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --no-install-recommends -y \
        build-essential \
        curl \
        git \
        wget \
        cmake \
        clang \
        libgflags-dev \
        zlib1g-dev \
        libssl-dev \
        libreadline-dev \
        libmicrohttpd-dev \
        pkg-config \
        libgsl-dev \
        python3 \
        python3-dev \
        python3-pip \
        libsecp256k1-dev \
        libsodium-dev \
        liblz4-dev \
        ninja-build \
        fio \
        rocksdb-tools \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --no-cache-dir psutil crc16 requests

ARG GLOBAL_CONFIG_URL=https://ton.org/global.config.json
ARG MYTONCTRL_VERSION=master

RUN wget https://raw.githubusercontent.com/ton-blockchain/mytonctrl/${MYTONCTRL_VERSION}/scripts/ton_installer.sh -O /tmp/ton_installer.sh \
    && /bin/bash /tmp/ton_installer.sh -c ${GLOBAL_CONFIG_URL} \
    && rm -rf /usr/src/ton/.git/modules/*

FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install --no-install-recommends -y wget gcc libsecp256k1-dev libsodium-dev liblz4-dev python3-dev python3-pip sudo git fio iproute2 plzip pv curl libjemalloc-dev \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/ton-work/db/static /var/ton-work/db/import /var/ton-work/db/keyring

ENV BIN_DIR /usr/bin/
ARG MYTONCTRL_VERSION=master
ARG TELEMETRY=false
ARG DUMP=false
ARG MODE=validator
ARG IGNORE_MINIMAL_REQS=true
ARG GLOBAL_CONFIG_URL=https://ton.org/global.config.json

COPY --from=ton ${BIN_DIR}/ton/lite-client/lite-client ${BIN_DIR}/ton/lite-client/
COPY --from=ton ${BIN_DIR}/ton/validator-engine/validator-engine ${BIN_DIR}/ton/validator-engine/
COPY --from=ton ${BIN_DIR}/ton/validator-engine-console/validator-engine-console ${BIN_DIR}/ton/validator-engine-console/
COPY --from=ton ${BIN_DIR}/ton/utils/generate-random-id ${BIN_DIR}/ton/utils/
COPY --from=ton ${BIN_DIR}/ton/crypto/fift ${BIN_DIR}/ton/crypto/
COPY --from=ton /usr/src/ton/crypto/fift/lib /usr/src/ton/crypto/fift/lib
COPY --from=ton /usr/src/ton/crypto/smartcont /usr/src/ton/crypto/smartcont
COPY --from=ton /usr/src/ton/.git/ /usr/src/ton/.git/

RUN wget -nv https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -O /usr/bin/systemctl  \
    && chmod +x /usr/bin/systemctl \
    && wget https://raw.githubusercontent.com/ton-blockchain/mytonctrl/${MYTONCTRL_VERSION}/scripts/install.sh -O /tmp/install.sh \
    && wget -nv ${GLOBAL_CONFIG_URL} -O ${BIN_DIR}/ton/global.config.json \
    && if [ "$TELEMETRY" = false ]; then export TELEMETRY="-t"; else export TELEMETRY=""; fi && if [ "$IGNORE_MINIMAL_REQS" = true ]; then export IGNORE_MINIMAL_REQS="-i"; else export IGNORE_MINIMAL_REQS=""; fi \
    && /bin/bash /tmp/install.sh ${TELEMETRY} ${IGNORE_MINIMAL_REQS} -b ${MYTONCTRL_VERSION} -m ${MODE} \
    && ln -sf /proc/$$/fd/1 /usr/local/bin/mytoncore/mytoncore.log \
    && ln -sf /proc/$$/fd/1 /var/log/syslog \
    && sed -i 's/--logname \/var\/ton-work\/log//g; s/--verbosity 1/--verbosity 3/g' /etc/systemd/system/validator.service \
    && sed -i 's/\[Service\]/\[Service\]\nStandardOutput=null\nStandardError=syslog/' /etc/systemd/system/validator.service \
    && sed -i 's/\[Service\]/\[Service\]\nStandardOutput=null\nStandardError=syslog/' /etc/systemd/system/mytoncore.service \
    && rm -rf /var/lib/apt/lists/* && rm -rf /root/.cache/pip

VOLUME ["/var/ton-work", "/usr/local/bin/mytoncore"]
COPY --chmod=755 scripts/entrypoint.sh/ /scripts/entrypoint.sh
ENTRYPOINT ["/scripts/entrypoint.sh"]
