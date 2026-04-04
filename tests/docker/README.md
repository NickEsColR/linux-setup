# Testing in Docker Containers

Interactive shell per distro — clone the repo and run `guide.sh` or `setup.sh` as if you were on a fresh machine.

> **PowerShell**: commands below are single-line. No `\` continuation.
> **Linux/macOS**: replace `$(pwd)` with your path or use `\` for multiline.

## Debian / Ubuntu / Mint

```powershell
docker run --rm -it -v "$(pwd):/setup:ro" -w /setup --privileged debian:bookworm-slim bash
```

Inside the container:

```bash
# 1. Install dependencies AS ROOT
apt update && apt install -y curl sudo

# 2. Create a non-root user with passwordless sudo
useradd -m -G sudo -s /bin/bash tester
echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester
chmod 0440 /etc/sudoers.d/tester

# 3. Switch to the user
su - tester
cd /setup

# 4. Install yq
curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# 5. Run guided installer (recommended)
bash guide.sh

# Or try full automated install (may fail)
# bash setup.sh
```

## Fedora

```powershell
docker run --rm -it -v "$(pwd):/setup:ro" -w /setup --privileged fedora:40 bash
```

Inside the container:

```bash
# 1. Install dependencies AS ROOT
dnf install -y curl sudo

# 2. Create a non-root user with passwordless sudo
useradd -m -G wheel -s /bin/bash tester
echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester
chmod 0440 /etc/sudoers.d/tester

# 3. Switch to the user
su - tester
cd /setup

# 4. Install yq
curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# 5. Run guided installer (recommended)
bash guide.sh

# Or try full automated install (may fail)
# bash setup.sh
```

## Arch Linux

```powershell
docker run --rm -it -v "$(pwd):/setup:ro" -w /setup --privileged archlinux:latest bash
```

Inside the container:

```bash
# 1. Install dependencies AS ROOT
pacman -Syu --noconfirm curl sudo

# 2. Create a non-root user with passwordless sudo
useradd -m -G wheel -s /bin/bash tester
echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester
chmod 0440 /etc/sudoers.d/tester

# 3. Switch to the user
su - tester
cd /setup

# 4. Install yq
curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# 5. Run guided installer (recommended)
bash guide.sh

# Or try full automated install (may fail)
# bash setup.sh
```

## pikaOS

pikaOS uses `pikman` (custom package manager) which cannot be emulated in Docker.
Test on a real pikaOS installation.

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
