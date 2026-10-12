FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch 3.41.1 https://github.com/flutter/flutter.git /opt/flutter \
    && chown -R vscode:vscode /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

USER vscode
RUN flutter config --enable-web --no-analytics \
    && flutter precache --web \
    && flutter --version
