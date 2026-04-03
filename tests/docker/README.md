# Testing in Docker Containers

Interactive shell per distro — clone the repo and run `setup.sh` as if you were on a fresh machine.

> **PowerShell**: commands below are single-line. No `\` continuation.
> **Linux/macOS**: replace `$(pwd)` with your path or use `\` for multiline.

## Debian / Ubuntu / Mint

```powershell
docker run --rm -it -v "$(pwd):/setup:ro" -w /setup --privileged debian:bookworm-slim bash
```

Inside the container:

```bash
# Create a non-root user (setup.sh blocks root)
useradd -m -G sudo tester
echo 'tester ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
su - tester
cd /setup

# Install dependencies
apt update && apt install -y curl sudo
curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# Run installer
bash setup.sh
```

## Fedora

```powershell
docker run --rm -it -v "$(pwd):/setup:ro" -w /setup --privileged fedora:40 bash
```

Inside the container:

```bash
# Create a non-root user
useradd -m -G wheel tester
echo 'tester ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/tester
su - tester
cd /setup

# Install dependencies
dnf install -y curl sudo
curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# Run installer
bash setup.sh
```

## Arch Linux

```powershell
docker run --rm -it -v "$(pwd):/setup:ro" -w /setup --privileged archlinux:latest bash
```

Inside the container:

```bash
# Create a non-root user
pacman -Syu --noconfirm sudo
useradd -m -G wheel tester
echo 'tester ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/tester
su - tester
cd /setup

# Install dependencies
curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# Run installer
bash setup.sh
```

## pikaOS

pikaOS is based on Debian Sid (unstable):

```powershell
docker run --rm -it -v "$(pwd):/setup:ro" -w /setup --privileged debian:sid-slim bash
```

Inside the container:

```bash
# Create a non-root user
useradd -m -G sudo tester
echo 'tester ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
su - tester
cd /setup

# Fake pikaOS detection
echo 'ID=pikaos' > /etc/os-release

# Install dependencies
apt update && apt install -y curl sudo
curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# Run installer
bash setup.sh
```

## Dry-run (preview only)

If you just want to see what would be installed without actually installing:

```bash
bash setup.sh --dry-run
```

## ARM64 (Apple Silicon / Raspberry Pi)

If your host is ARM64, change the yq binary:

```bash
curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm64 \
  -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq
```
