# kali-claude

Containerized Kali Linux (bleeding-edge) workstation pre-wired for
[Claude Code](https://docs.claude.com/en/docs/claude-code/overview)
with Playwright + shell MCP servers.

Use case: an authorized offensive-security workstation an LLM agent can
drive — recon, web/network testing, exploit verification — without
touching the host OS. Disposable, reproducible, networked through the
host's proxy if you want.

## What's inside

- **Base**: `kalilinux/kali-bleeding-edge:latest`, full `dist-upgrade`
- **Toolset**: `kali-linux-headless` (~200 pentest tools — nmap, sqlmap,
  hydra, john, hashcat, metasploit, ffuf, mitmproxy, impacket, responder,
  evil-winrm, certipy-ad, netexec, mimikatz, ...) plus targeted apt
  extras (ProjectDiscovery suite, semgrep, gitleaks, trufflehog,
  apktool, jadx, feroxbuster, ...)
- **Runtime**: Node.js LTS, Claude Code CLI, Playwright + Chromium
- **MCP servers** (via project-scoped `.mcp.json`):
  - `@playwright/mcp` — headless browser automation
  - `@wonderwhy-er/desktop-commander` — extended fs/shell ops
- **Operator brief**: `CLAUDE.md` baked into the image so Claude knows
  the full toolkit by attack phase on session start
- **User**: non-root `operator` with passwordless `sudo`
- **Caps**: `NET_RAW`, `NET_ADMIN`, `SYS_PTRACE`

## Requirements

- Docker Engine 20.10+ with Compose V2
- ~15 GB free disk (image is large; first build takes 10–15 min)
- An Anthropic API key

## Quick start

```bash
git clone <this-repo> kali-claude
cd kali-claude

cp .env.example .env
# edit .env, add your ANTHROPIC_API_KEY

mkdir -p workspace loot

docker compose up -d --build
docker compose exec kali-agent bash

# inside the container:
claude
```

## Inspecting / tampering with traffic (in-container)

The image includes `mitmproxy` / `mitmweb` / `mitmdump` — a Burp-style
HTTP history, inspector, intercept, and replay, all running inside the
container. No host proxy required.

Inside the container:

```bash
mitmweb --listen-host 0.0.0.0 --web-host 0.0.0.0
# in another shell, point tools at the local proxy:
export HTTPS_PROXY=http://127.0.0.1:8080
export HTTP_PROXY=http://127.0.0.1:8080
```

To browse the UI from the host, uncomment the `ports: ["8081:8081"]`
block in `docker-compose.yml`, then open `http://localhost:8081`.

For TLS interception, on first run mitmproxy writes a CA to
`~/.mitmproxy/`; trust it system-wide:

```bash
sudo cp ~/.mitmproxy/mitmproxy-ca-cert.pem \
        /usr/local/share/ca-certificates/mitmproxy.crt
sudo update-ca-certificates
```

## Daily commands

```bash
docker compose up -d                  # start
docker compose exec kali-agent bash   # shell in
docker compose stop                   # stop, keep state
docker compose down                   # stop + remove container (keeps volumes)
docker compose down -v                # nuke claude-config volume too (re-auth)
```

The named `claude-config` volume persists Claude's auth + history
across container restarts so you don't re-login each time.

## Layout

```
.
├── Dockerfile             # base + tools + Node + MCP servers
├── docker-compose.yml     # caps, networking, volumes
├── .mcp.json              # MCP server registrations
├── CLAUDE.md              # operator brief loaded by Claude on start
├── .env.example           # template for local secrets (gitignored)
├── workspace/             # bind-mounted into container (gitignored)
└── loot/                  # bind-mounted output dir (gitignored)
```

## Authorization

Use only against targets you have written permission to test. The
included `CLAUDE.md` instructs Claude to refuse out-of-scope targets
and to demonstrate impact without harm (`id`/`whoami`, not shells;
`alert(1)`, not cookie theft). That's a guardrail, not a contract —
the operator is responsible for staying inside scope.

## License

MIT
