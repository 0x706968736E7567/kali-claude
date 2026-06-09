# syntax=docker/dockerfile:1.7
#
# Weaponized Kali bleeding-edge + Claude Code workstation.
# Authorized offensive security use only.

# Base pinned by digest for a reproducible released artifact. 'bleeding-edge'
# still floats packages at apt time, but the digest fixes the starting layer so
# a known-good image can always be rebuilt. Refresh deliberately:
#   docker manifest inspect kalilinux/kali-bleeding-edge:latest
FROM kalilinux/kali-bleeding-edge:latest@sha256:49a856f4b78795f2800802da836bcaedd1983d35eda3c61bedef791c3b92c8ad

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    SHELL=/bin/bash \
    PLAYWRIGHT_BROWSERS_PATH=/opt/playwright

# ---- 1. Base + headless toolset + targeted hunting extras + Playwright libs
# kali-linux-headless brings ~200 pentest packages (nmap, sqlmap, hydra,
# john, hashcat, msf, ffuf, mitmproxy, impacket, responder, evil-winrm,
# certipy-ad, netexec, mimikatz, ...). Below adds tools that headless
# DOESN'T pull but are worth having for web/recon/SAST/mobile work.
RUN apt-get update && apt-get -y dist-upgrade \
 && apt-get install -y --no-install-recommends \
      kali-linux-headless \
      \
      # ProjectDiscovery + recon extras (not in headless)
      subfinder dnsx naabu nuclei httpx-toolkit \
      getallurls gowitness gospider \
      feroxbuster dirsearch findomain assetfinder \
      arjun xsstrike crlfuzz dnstwist dnsgen \
      \
      # Payload reference corpus (PayloadsAllTheThings — XSS/SSRF/SQLi/etc).
      # SecLists intentionally NOT bundled — too large (~700MB) and most jobs
      # only need a specific file. Fetch on demand from GitHub when needed.
      payloadsallthethings \
      \
      # Mobile reverse engineering
      apktool jadx \
      \
      # SAST / secrets (semgrep installed via pipx below — not in apt)
      gitleaks trufflehog \
      python3-pip pipx \
      \
      # Operator quality of life
      ca-certificates curl wget git gnupg sudo \
      jq ripgrep fd-find bat fzf vim tmux \
      # Build toolchain retained at runtime on purpose: several pipx tools
      # (semgrep, frida-tools) and on-demand `go install` / source builds the
      # operator runs need a compiler + headers present. Adds image size; kept
      # deliberately rather than purged.
      build-essential pkg-config libffi-dev libssl-dev \
      \
      # Playwright/Chromium runtime libs
      libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 \
      libdrm2 libdbus-1-3 libxcb1 libxkbcommon0 libx11-6 \
      libxcomposite1 libxdamage1 libxext6 libxfixes3 libxrandr2 \
      libgbm1 libpango-1.0-0 libcairo2 libatspi2.0-0 \
      fonts-liberation fonts-noto-color-emoji \
 && (apt-get install -y --no-install-recommends libasound2t64 \
     || apt-get install -y --no-install-recommends libasound2) \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---- 2. Node.js LTS + Claude Code + MCP servers ----------------------------
# The NodeSource setup script runs its own `apt-get update`, but we add an
# explicit one too so the nodejs install does not silently depend on that side
# effect (the previous stage cleared /var/lib/apt/lists/*).
# npm packages are pinned to exact versions so the runtime MCP servers and the
# Claude Code CLI cannot drift to an unverified release on rebuild.
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
 && apt-get update \
 && apt-get install -y --no-install-recommends nodejs \
 && npm install -g --no-fund --no-audit \
      @anthropic-ai/claude-code@2.1.169 \
      @playwright/mcp@0.0.75 \
      @wonderwhy-er/desktop-commander@0.2.42 \
 && npm cache clean --force \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Pre-pull Chromium for Playwright (system libs already installed). Pinned to
# match the @playwright/mcp version installed above.
RUN npx -y playwright@1.60.0 install chromium

# (nuclei templates are pulled as the operator further down, once that user and
# its HOME exist — see the operator section. nuclei reads templates from its own
# config under ~/nuclei-templates, not from an env var, and /root is mode 0700
# so a root-pulled copy would be unreadable by the non-root operator.)

# ---- Python tools not packaged in Kali apt --------------------------------
# pipx isolates each tool in its own venv; binaries land in /usr/local/bin
# so they're on PATH for the non-root operator too. PyPI tools first, then
# GitHub-only tools via git URLs. All pinned (PyPI by ==version, git by commit
# SHA) so a rebuild gets the same code and a compromised upstream cannot inject
# silently. semgrep/frida-tools are core SAST/RE tooling and hard-fail (no
# `|| true`) so a broken build surfaces loudly; the git-sourced extras keep
# `|| true` since a single repo rename/outage shouldn't tank a long build.
ENV PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin
RUN pipx install 'semgrep==1.165.0' \
 && pipx install 'frida-tools==14.9.0' \
 && (pipx install 'git+https://github.com/s0md3v/Corsy@2985ae24da524ba6905d36bfbadca7fe71a9f199'              || true) \
 && (pipx install 'git+https://github.com/devanshbatham/paramspider@c44bdaae54789b237028e309b603d1aa5ad52e5e' || true) \
 && (pipx install 'git+https://github.com/ticarpi/jwt_tool@3bc7407cf2222d6a821dcc19c776e5a1b1cb9a9b'           || true)

# ---- 3. Non-root operator user --------------------------------------------
# The Debian/Kali base ships a historical system group `operator` at GID 37, so
# `useradd -g operator` would silently make GID 37 the user's primary group
# instead of a dedicated one. Create an explicit `opgroup` (idempotent) and use
# it so file ownership is unambiguous and not shared with the legacy group.
#
# SECURITY NOTE — passwordless sudo: the operator has `NOPASSWD:ALL`, so the
# "non-root operator" is a cosmetic boundary, NOT a privilege-separation control.
# Anything running in the container (the agent, the shell MCP server, any tool)
# can become root at will. This is a deliberate trade-off: dozens of the bundled
# tools (responder, tcpdump, ettercap, bettercap, aircrack-ng, raw-socket scans,
# binding <1024) genuinely need root, and an allowlist would break the primary
# use case. We narrow the COMMON path instead — file capabilities on nmap/masscan
# let the default scan workflow run with no sudo at all. Treat the container as
# root-equivalent; isolation comes from the container boundary, not the user.
#
# Split into two RUNs so a chown failure on optional dirs can't silently
# swallow a useradd failure (which would manifest later as "user not found"
# at the USER directive).
RUN getent group opgroup >/dev/null || groupadd opgroup \
 && useradd -m -s /bin/bash -g opgroup operator \
 && echo "operator ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
 && (setcap cap_net_raw,cap_net_admin+eip /usr/bin/nmap    2>/dev/null || true) \
 && (setcap cap_net_raw,cap_net_admin+eip /usr/bin/masscan 2>/dev/null || true) \
 && id operator
RUN chown -R operator:opgroup /opt/playwright /opt/pipx 2>/dev/null || true

USER operator
WORKDIR /home/operator/workspace

# Pre-pull nuclei templates as the operator, into the HOME dir nuclei actually
# reads (~/nuclei-templates), for an offline-fast first run that is genuinely
# usable by this non-root user.
RUN nuclei -update-templates -ud /home/operator/nuclei-templates -silent || true

# ---- 4. Project files (MCP config + operator brief) ----------------------
# These are also delivered via read-only bind mounts in docker-compose.yml (so
# edits to the repo take effect without a rebuild, and a named volume can't
# shadow them). The COPYs are kept so a plain `docker run` (no compose) still
# ships a working config + brief.
RUN mkdir -p /home/operator/workspace /home/operator/loot /home/operator/.claude
COPY --chown=operator:opgroup .mcp.json /home/operator/workspace/.mcp.json
COPY --chown=operator:opgroup CLAUDE.md /home/operator/.claude/CLAUDE.md

CMD ["/bin/bash"]
