#!/usr/bin/env bash
set -e

# === Config ===
BACKUP_DIR="$HOME/docker_backup_$(date +%Y%m%d_%H%M%S)"
DOCKER_PACKAGES=("docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin")

echo "=== Step 1: Preparing environment ==="
sudo apt update -y
sudo apt install -y jq fzf curl ca-certificates gnupg lsb-release

echo "=== Step 2: Adding Docker repository (if missing) ==="
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi

if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

sudo apt update -y

echo "=== Step 3: Fetching available Docker versions ==="
apt-cache madison docker-ce | awk '{print $3}' > /tmp/docker_versions.txt
if [ ! -s /tmp/docker_versions.txt ]; then
    echo "No Docker versions found in repo! Exiting..."
    exit 1
fi

echo "Select Docker version to install:"
SELECTED_VERSION=$(cat /tmp/docker_versions.txt | fzf --height 20 --reverse --prompt="Choose version: ")
if [ -z "$SELECTED_VERSION" ]; then
    echo "No version selected. Exiting."
    exit 1
fi
echo "Chosen Docker version: $SELECTED_VERSION"

# === Backup Phase ===
echo "=== Step 4: Creating backup directory ==="
mkdir -p "$BACKUP_DIR"
echo "Backup directory: $BACKUP_DIR"

echo "=== Step 5: Stopping Docker containers ==="
sudo systemctl stop docker || true

echo "=== Step 6: Backing up containers, images, and volumes ==="
docker ps -a > "$BACKUP_DIR/containers_list.txt" || true
docker inspect $(docker ps -aq) > "$BACKUP_DIR/containers_inspect.json" || true

for c in $(docker ps -aq); do
    name=$(docker inspect --format='{{.Name}}' $c | sed 's/^\///')
    echo "Exporting container $name..."
    docker export $c -o "$BACKUP_DIR/${name}.tar" || true
done

echo "Saving all Docker images..."
docker save -o "$BACKUP_DIR/docker_images.tar" $(docker images -q) || true

echo "Backing up Docker volumes..."
sudo tar czf "$BACKUP_DIR/docker_volumes.tar.gz" -C /var/lib/docker/volumes . || true

# === Removal Phase ===
echo "=== Step 7: Removing Docker completely ==="
sudo systemctl stop docker || true
sudo apt purge -y "${DOCKER_PACKAGES[@]}" || true
sudo apt autoremove -y
sudo rm -rf /var/lib/docker /etc/docker /var/lib/containerd
sudo rm -rf ~/.docker /usr/local/bin/docker-compose /var/run/docker.sock

# === Installation Phase ===
echo "=== Step 8: Installing Docker version ${SELECTED_VERSION} ==="
sudo apt install -y \
  docker-ce=${SELECTED_VERSION} \
  docker-ce-cli=${SELECTED_VERSION} \
  containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker
docker --version

# === Restore Phase ===
echo "=== Step 9: Restoring images and volumes ==="
if [ -f "$BACKUP_DIR/docker_images.tar" ]; then
    docker load -i "$BACKUP_DIR/docker_images.tar"
fi

if [ -f "$BACKUP_DIR/docker_volumes.tar.gz" ]; then
    sudo tar xzf "$BACKUP_DIR/docker_volumes.tar.gz" -C /var/lib/docker/volumes
fi

echo "=== Step 10: Restoring containers ==="
for tarfile in "$BACKUP_DIR"/*.tar; do
    [ -f "$tarfile" ] || continue
    name=$(basename "$tarfile" .tar)
    echo "Importing container $name..."
    docker import "$tarfile" "$name:restored" || true
done

echo "=== Step 11: Done! ==="
echo "Backup directory: $BACKUP_DIR"
docker ps -a
docker images
