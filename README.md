# C++ Docker Images

This repository builds shared C++ runtime, builder, and development images on Debian slim.

## Targets

| Target | Image | Purpose |
| --- | --- | --- |
| `runtime-base` | `cpp-runtime-base` | Minimal non-root runtime base for C++ services. |
| `runtime-debug-base` | `cpp-runtime-debug-base` | Runtime base plus debugging/network tools. |
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
```

Build one target directly:

```bash
docker build -f Dockerfile.toolchain --target builder-gcc -t cpp-builder-gcc:local .
```

## Development Images

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
