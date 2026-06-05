# syntax=docker/dockerfile:1.7
#
# Weaponized Kali bleeding-edge + Claude Code workstation.
# Authorized offensive security use only.

FROM kalilinux/kali-bleeding-edge:latest

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    SHELL=/bin/bash \
    PLAYWRIGHT_BROWSERS_PATH=/opt/playwright \
    NUCLEI_TEMPLATES=/root/nuclei-templates

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
      # Wordlists & payload corpora
      seclists payloadsallthethings \
      \
      # Mobile reverse engineering
      apktool jadx \
      \
      # SAST / secrets
      semgrep gitleaks trufflehog \
      \
      # Operator quality of life
      ca-certificates curl wget git gnupg sudo \
      jq ripgrep fd-find bat fzf vim tmux \
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
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && npm install -g --no-fund --no-audit \
      @anthropic-ai/claude-code@latest \
      @playwright/mcp@latest \
      @wonderwhy-er/desktop-commander@latest \
 && npm cache clean --force \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Pre-pull Chromium for Playwright (system libs already installed)
RUN npx -y playwright@latest install chromium

# Pre-pull nuclei templates for offline-fast first run
RUN nuclei -update-templates -silent || true

# ---- 3. Non-root operator user --------------------------------------------
RUN useradd -m -s /bin/bash operator \
 && echo "operator ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
 && chown -R operator:operator /opt/playwright /root/nuclei-templates 2>/dev/null || true

USER operator
WORKDIR /home/operator/workspace

# ---- 4. Project files (MCP config + operator brief) ----------------------
RUN mkdir -p /home/operator/workspace /home/operator/loot /home/operator/.claude
COPY --chown=operator:operator .mcp.json /home/operator/workspace/.mcp.json
COPY --chown=operator:operator CLAUDE.md /home/operator/.claude/CLAUDE.md

CMD ["/bin/bash"]
