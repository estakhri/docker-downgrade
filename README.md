# 🐳 Docker Downgrade & Backup Script

A complete **interactive shell script** for safely **downgrading Docker** on Ubuntu (22.04/24.04).  
It automatically **backs up** all containers, images, and volumes, completely **removes the current Docker installation**, lets you **select any version** from the Docker repository via `fzf`, and then **restores** everything.

---

## 🚀 Features

- 🧩 **Automatic Backup**
  - Exports containers, images, and volumes before uninstalling.
- ⚙️ **Full Docker Removal**
  - Completely purges Docker, containerd, and related files.
- 🔍 **Interactive Version Selection**
  - Lists all available Docker versions and lets you choose using [fzf](https://github.com/junegunn/fzf).
- 📦 **Automatic Restore**
  - Restores all your saved images, volumes, and containers after reinstall.
- 🧰 **Self-contained**
  - Works without manual configuration; handles repo setup and keyrings automatically.

---

## 🧱 Requirements

- Ubuntu 22.04 / 24.04 (tested)
- `sudo` privileges
- Internet connection (for package installation)

---

## ⚙️ Installation

Clone this repository and make the script executable:

```bash
git clone https://github.com/estakhri/docker-downgrade.git
cd docker-downgrade
chmod +x docker_downgrade.sh
```

---

## 🧭 Usage

Simply run the script:

```bash
./docker_downgrade.sh
```

You’ll see a list of all available Docker versions.  
Use the **arrow keys** and **Enter** to select the version you want to install.

Example interaction:

```
Select Docker version to install:
> 5:28.5.2-1~ubuntu.24.04~noble
  5:27.3.1-1~ubuntu.24.04~noble
  5:26.1.2-1~ubuntu.24.04~noble
```

Once confirmed, the script will:
1. Back up your containers, images, and volumes to `~/docker_backup_<date>`.
2. Remove the current Docker installation.
3. Install your selected Docker version.
4. Restore everything automatically.

---

## 🧩 Backup Files

All backups are saved under:
```
~/docker_backup_YYYYMMDD_HHMMSS/
```

Includes:
- `containers_list.txt` – list of containers
- `containers_inspect.json` – container configs
- `*.tar` – exported containers
- `docker_images.tar` – all Docker images
- `docker_volumes.tar.gz` – all volume data

---

## ⚠️ Important Notes

- Backups may be large — ensure enough disk space before running.
- Container **runtime state (running processes)** is not preserved (only filesystem and configuration).
- Script uses `docker export` (no history or layers).
- For production or Swarm clusters, perform manual volume backups instead of tar-based ones.

---

## 🔧 Tested Environments

| OS Version | Docker Version Tested | Status |
|-------------|-----------------------|---------|
| Ubuntu 24.04 (Noble) | 28.5.2 → 27.3.1 | ✅ Working |
| Ubuntu 22.04 (Jammy) | 27.3.1 → 26.1.2 | ✅ Working |

---

## 📜 License

MIT License.  
Feel free to use, modify, and distribute under the same terms.

---

## 👨‍💻 Author

**Nima Estakhri**  
Senior Software Engineer  
📧 Contact: [your.email@example.com]  
🌐 GitHub: [https://github.com/<your-username>](https://github.com/<your-username>)
