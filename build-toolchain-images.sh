#!/usr/bin/env bash
set -euo pipefail

DOCKERFILE="${DOCKERFILE:-Dockerfile.toolchain}"
VERSION="${VERSION:-bookworm-v1}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"
DEBIAN_VERSION="${DEBIAN_VERSION:-bookworm}"
RUNTIME_BASE_IMAGE="${RUNTIME_BASE_IMAGE:-gcr.io/distroless/cc-debian12:nonroot}"
UV_VERSION="${UV_VERSION:-0.11.10}"
CONAN_VERSION="${CONAN_VERSION:-2.28.1}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12.0}"
IMAGE_SOURCE="${IMAGE_SOURCE:-local}"
IMAGE_REVISION="${IMAGE_REVISION:-$(git rev-parse --short HEAD 2>/dev/null || echo unknown)}"
PLATFORM="${PLATFORM:-}"
PULL="${PULL:-false}"

if [[ ! "${VERSION}" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]]; then
  echo "Invalid Docker tag: ${VERSION}" >&2
  exit 1
fi

targets=(
  "runtime-base:cpp-runtime-base"
  "runtime-debug-base:cpp-runtime-debug-base"
  "builder-gcc:cpp-builder-gcc"
  "builder-clang:cpp-builder-clang"
  "dev-gcc:cpp-dev-gcc"
  "dev-clang:cpp-dev-clang"
)

common_args=(
  -f "${DOCKERFILE}"
  --build-arg "DEBIAN_VERSION=${DEBIAN_VERSION}"
  --build-arg "RUNTIME_BASE_IMAGE=${RUNTIME_BASE_IMAGE}"
  --build-arg "UV_VERSION=${UV_VERSION}"
  --build-arg "CONAN_VERSION=${CONAN_VERSION}"
  --build-arg "PYTHON_VERSION=${PYTHON_VERSION}"
  --build-arg "IMAGE_SOURCE=${IMAGE_SOURCE}"
  --build-arg "IMAGE_REVISION=${IMAGE_REVISION}"
  --build-arg "IMAGE_VERSION=${VERSION}"
)

if [[ -n "${PLATFORM}" ]]; then
  common_args+=(--platform "${PLATFORM}")
fi

if [[ "${PULL}" == "true" ]]; then
  common_args+=(--pull)
fi

for entry in "${targets[@]}"; do
  target="${entry%%:*}"
  image="${entry##*:}"

  echo "==> Building ${image}:${VERSION} (${target})"
  docker build "${common_args[@]}" --target "${target}" -t "${image}:${VERSION}" "${BUILD_CONTEXT}"
done
