# decompdecomp Docker Setup

Dockerized environment for running [decompdecomp](https://github.com/n-delic/decompdecomp) headless on a server with **Ghidra 12.1.4**, **OpenJDK 21**, **Wine**, **Node.js/npm**, and **Nginx**.

## Directory Structure

```
DDDocker/
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── proxy_setup.py
├── .dockerignore
├── .gitignore
├── README.md
├── data/            # Persistent workspace, projects, and .decomp database (mounted to /data)
└── decompnet_tools/ # Toolchains & compilers cache (mounted to /root/.local/share/decompnet/toolchains)
```

## Quick Start

1. **Build and start the container:**
   ```bash
   docker compose up -d --build
   ```

2. **Check logs to see decompdecomp starting:**
   ```bash
   docker compose logs -f
   ```

3. **Access the Web Interface:**
   Navigate in your browser to:
   ```
   http://<server-ip>:6464/
   ```

On each launch, `entrypoint.sh` waits for `$DECOMP_HOME/.decomp/server.json` (defaults to `/data/.decomp/server.json`); `proxy_setup.py` configures Nginx to send its fresh window secret as the upstream User-Agent and to target the active port. Browser requests therefore authenticate seamlessly without exposing the backend port directly.

> **Customizing `DECOMP_HOME`:** By default, `DECOMP_HOME` is `/data`. To point at an existing project subdirectory (for example `/data/my-project`), set `DECOMP_HOME=/data/my-project` in a `.env` file or your environment before running `docker compose up -d`.

## Installing Agents

Agent CLIs (Claude Code, Codex, OpenCode, Antigravity, Cursor, Kimi, ZCode) are **not** pre-installed in the image. Because `nodejs`, `npm`, `curl`, and the agent install paths (`/root/.local/bin` and `/root/.opencode/bin`) are configured in the image, you can install any agent directly from the **Agents & models** page in the web UI ("Install it for me") or via `docker exec -it decompdecomp ...`.

## Included Components

- **Ubuntu 24.04** base image
- **decompnet** (installed via `uv` from the latest GitHub release)
- **Ghidra 12.1.4** pre-installed with headless analyzer enabled
- **OpenJDK 21** (`openjdk-21-jdk-headless`)
- **Wine** (for Windows compilers) & **ACL** (`acl`)
- **Node.js & npm** (for installing Node-based agent CLIs at runtime)
- **Ninja**, **Python 3**, and **Git**
- **Nginx** reverse proxy to expose decompdecomp across the network while satisfying local host/user-agent security checks
