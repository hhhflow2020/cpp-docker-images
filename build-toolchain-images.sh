#!/usr/bin/env bash
set -euo pipefail

DOCKERFILE="${DOCKERFILE:-Dockerfile.toolchain}"
VERSION="${VERSION:-bookworm-v1}"

docker build -f "${DOCKERFILE}" --target runtime-base \
  -t "cpp-runtime-base:${VERSION}" .

docker build -f "${DOCKERFILE}" --target runtime-debug-base \
  -t "cpp-runtime-debug-base:${VERSION}" .

docker build -f "${DOCKERFILE}" --target builder-gcc \
  -t "cpp-builder-gcc:${VERSION}" .

docker build -f "${DOCKERFILE}" --target dev-gcc \
  -t "cpp-dev-gcc:${VERSION}" .

docker build -f "${DOCKERFILE}" --target dev-clang \
  -t "cpp-dev-clang:${VERSION}" .