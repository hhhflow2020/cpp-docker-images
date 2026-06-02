#!/usr/bin/env bash
set -euo pipefail

DOCKERFILE="${DOCKERFILE:-Dockerfile.toolchain}"
VERSION="${VERSION:-bookworm-v1}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"
DEBIAN_VERSION="${DEBIAN_VERSION:-bookworm}"
UV_VERSION="${UV_VERSION:-0.11.10}"
CONAN_VERSION="${CONAN_VERSION:-2.28.1}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12.0}"
GCC_VERSION="${GCC_VERSION:-12}"
LLVM_VERSION="${LLVM_VERSION:-14}"
DEV_USERNAME="${DEV_USERNAME:-dev}"
DEV_UID="${DEV_UID:-1000}"
DEV_GID="${DEV_GID:-1000}"
APP_UID="${APP_UID:-65532}"
APP_GID="${APP_GID:-65532}"
IMAGE_SOURCE="${IMAGE_SOURCE:-local}"
IMAGE_REVISION="${IMAGE_REVISION:-$(git rev-parse --short HEAD 2>/dev/null || echo unknown)}"
PLATFORM="${PLATFORM:-}"
PULL="${PULL:-false}"
TARGETS="${TARGETS:-all}"

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

selected_targets=()

if [[ "${TARGETS}" == "all" || -z "${TARGETS}" ]]; then
  selected_targets=("${targets[@]}")
else
  for requested in ${TARGETS//,/ }; do
    matched=""
    for entry in "${targets[@]}"; do
      target="${entry%%:*}"
      image="${entry##*:}"
      if [[ "${requested}" == "${target}" || "${requested}" == "${image}" ]]; then
        matched="${entry}"
        break
      fi
    done

    if [[ -z "${matched}" ]]; then
      echo "Unknown target: ${requested}" >&2
      echo "Available targets:" >&2
      printf '  %s\n' "${targets[@]%%:*}" >&2
      exit 1
    fi

    selected_targets+=("${matched}")
  done
fi

common_args=(
  -f "${DOCKERFILE}"
  --build-arg "DEBIAN_VERSION=${DEBIAN_VERSION}"
  --build-arg "UV_VERSION=${UV_VERSION}"
  --build-arg "CONAN_VERSION=${CONAN_VERSION}"
  --build-arg "PYTHON_VERSION=${PYTHON_VERSION}"
  --build-arg "GCC_VERSION=${GCC_VERSION}"
  --build-arg "LLVM_VERSION=${LLVM_VERSION}"
  --build-arg "USERNAME=${DEV_USERNAME}"
  --build-arg "UID=${DEV_UID}"
  --build-arg "GID=${DEV_GID}"
  --build-arg "APP_UID=${APP_UID}"
  --build-arg "APP_GID=${APP_GID}"
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

for entry in "${selected_targets[@]}"; do
  target="${entry%%:*}"
  image="${entry##*:}"

  echo "==> Building ${image}:${VERSION} (${target})"
  docker build "${common_args[@]}" --target "${target}" -t "${image}:${VERSION}" "${BUILD_CONTEXT}"
done
