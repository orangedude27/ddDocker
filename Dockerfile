# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DECOMP_WINDOW=0
ENV DECOMP_HOME=/data
ENV CODEX_HOME=/data/.codex
ENV PATH="/root/.opencode/bin:/root/.local/bin:$PATH"

# 1. Install prerequisites, Java 21 (required for Ghidra), Wine, Python, Nginx, Node.js/npm (for UI agent installs), ACL, unzip
RUN apt-get update && apt-get install -y --no-install-recommends \
    acl \
    ca-certificates \
    curl \
    git \
    nginx \
    ninja-build \
    nodejs \
    npm \
    openjdk-21-jdk-headless \
    patch \
    python3 \
    python3-pip \
    unzip \
    wine \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Astral uv (the app is installed last so new releases reuse the large tool layers).
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# 3. Pre-install Ghidra into decompdecomp's toolchain directory
ENV GHIDRA_VERSION=12.1.4
ENV GHIDRA_DATE=20260921
ENV GHIDRA_DIR=/root/.local/share/decompnet/toolchains/ghidra

RUN --mount=type=cache,target=/var/cache/decomp-downloads,sharing=locked \
    mkdir -p /root/.local/share/decompnet/toolchains && \
    archive="/var/cache/decomp-downloads/ghidra_${GHIDRA_VERSION}_${GHIDRA_DATE}.zip" && \
    if [ ! -s "$archive" ]; then \
        curl -fsSL --retry 3 -o "$archive.part" "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/ghidra_${GHIDRA_VERSION}_PUBLIC_${GHIDRA_DATE}.zip" && \
        mv "$archive.part" "$archive"; \
    fi && \
    unzip -q "$archive" -d /tmp && \
    mv /tmp/ghidra_${GHIDRA_VERSION}_PUBLIC "${GHIDRA_DIR}" && \
    chmod +x "${GHIDRA_DIR}/support/analyzeHeadless"

# 4. Remote ADD rechecks release metadata, invalidating the install layer when GitHub publishes a new release.
ADD https://api.github.com/repos/n-delic/decompdecomp/releases/latest /tmp/decomp-latest-release.json
RUN --mount=type=cache,target=/root/.cache/uv \
    tag=$(python3 -c 'import json; print(json.load(open("/tmp/decomp-latest-release.json"))["tag_name"])') && \
    uv tool install "https://github.com/n-delic/decompdecomp/archive/refs/tags/${tag}.tar.gz"

# Trust bind-mounted project repositories under /data owned by the host user.
RUN git config --global --add safe.directory '*'

# Configure nginx at startup from the current project's server.json.
COPY proxy_setup.py /proxy_setup.py
COPY entrypoint.sh /entrypoint.sh
COPY entrypoint.sh /proxy-entrypoint.sh
RUN chmod +x /entrypoint.sh /proxy-entrypoint.sh

WORKDIR /data
EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
