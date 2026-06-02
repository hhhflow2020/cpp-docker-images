# C++ Docker Images

This repository builds shared C++ runtime, builder, and development images on Debian slim.

## Targets

| Target | Image | Purpose |
| --- | --- | --- |
| `runtime-base` | `cpp-runtime-base` | Minimal Debian non-root runtime base for C++ services. |
| `runtime-debug-base` | `cpp-runtime-debug-base` | Debian runtime with shell plus debugging/network tools. |
| `builder-gcc` | `cpp-builder-gcc` | GCC CI builder with CMake, Ninja, ccache, Python, and Conan. |
| `builder-clang` | `cpp-builder-clang` | Clang CI builder with CMake, Ninja, ccache, Python, and Conan. |
| `dev-gcc` | `cpp-dev-gcc` | GCC development image with SSH, sudo, debugging tools, and Conan profile. |
| `dev-clang` | `cpp-dev-clang` | Clang development image with SSH, clangd, clang-tidy, and Conan profile. |

## Local Build

Build all images:

```bash
./build-toolchain-images.sh
```

Common overrides:

```bash
VERSION=bookworm-v1.0.6 PULL=true ./build-toolchain-images.sh
PLATFORM=linux/amd64 VERSION=bookworm-v1.0.6 ./build-toolchain-images.sh
DEBIAN_VERSION=bookworm PYTHON_VERSION=3.12.0 ./build-toolchain-images.sh
TARGETS=builder-clang,dev-clang VERSION=local ./build-toolchain-images.sh
```

Build one target directly:

```bash
docker build -f Dockerfile.toolchain --target builder-gcc -t cpp-builder-gcc:local .
```

## Runtime Images

`runtime-base` is built from the same Debian slim base as the builder images and installs Debian's `libstdc++6` and `libgcc-s1`, so standard C/C++ runtime libraries come from the same distribution source as the build toolchain.

Runtime images run as UID/GID `65532` by default. Override `APP_UID` and `APP_GID` at build time when a project needs a different fixed runtime identity.

Use `runtime-debug-base` when you need `/bin/sh`, `gdb`, `strace`, `curl`, or other debugging tools.

Sanitizer runtime libraries are intentionally installed in builder and dev images. `runtime-base` stays minimal; only add sanitizer shared libraries to a downstream runtime image when a dynamically linked sanitizer binary actually needs them.

## Development Images

The development images keep the default toolset lean. They include core build/debug tooling, but omit low-frequency or heavy convenience packages such as Valgrind, full Vim runtime, bash completion, `tree`, `file`, `tzdata`, and `lldb`. Add these in a downstream image when a project needs them.

Builder and dev images use `uv` for the Python runtime that hosts Conan. The `uv` and `uvx` binaries are also available in the image for project-level Python tooling.

The dev images start `sshd` by default:

```bash
docker run -d --name cpp-dev-gcc -p 2222:22 cpp-dev-gcc:bookworm-v1
```

Install an SSH public key into the running container:

```bash
docker cp ~/.ssh/id_ed25519.pub cpp-dev-gcc:/home/dev/.ssh/authorized_keys
docker exec cpp-dev-gcc chown dev:dev /home/dev/.ssh/authorized_keys
docker exec cpp-dev-gcc chmod 600 /home/dev/.ssh/authorized_keys
ssh -p 2222 dev@localhost
```

When a command is provided instead of the default `sshd` command, the entrypoint runs it as the `dev` user:

```bash
docker run --rm cpp-dev-gcc:bookworm-v1 bash -lc 'id && conan --version'
```

For Linux bind mounts, either build the dev image with matching IDs or set them at runtime:

```bash
DEV_UID="$(id -u)" DEV_GID="$(id -g)" TARGETS=dev-gcc VERSION=local ./build-toolchain-images.sh
docker run --rm -e DEV_UID="$(id -u)" -e DEV_GID="$(id -g)" -v "$PWD:/workspace" cpp-dev-gcc:bookworm-v1 bash -lc 'touch /workspace/.write-test'
```

You can provide an SSH public key through an environment variable instead of copying files after startup:

```bash
docker run -d --name cpp-dev-gcc -p 2222:22 \
  -e DEV_AUTHORIZED_KEYS="$(cat ~/.ssh/id_ed25519.pub)" \
  cpp-dev-gcc:bookworm-v1
```

Useful cache mounts:

```bash
docker run --rm \
  -v "$PWD:/workspace" \
  -v cpp-conan:/home/dev/.conan2 \
  -v cpp-ccache:/home/dev/.cache/ccache \
  cpp-dev-gcc:bookworm-v1 \
  bash -lc 'cmake -S . -B build -G Ninja && cmake --build build'
```

## Release

The GitHub Actions workflow publishes tags matching `bookworm-v*`. It always publishes to GHCR. Docker Hub publishing is enabled only when both `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets are configured.

Docker tags must match Docker's tag format:

```text
^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$
```
