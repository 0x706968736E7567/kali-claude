# kali-claude operator environment

Authorized offensive security workstation. You run as `operator` with
passwordless `sudo` for raw sockets / low ports / package install.

**Demonstrate impact without harm:** `id`/`whoami` not shells, `alert(1)`
not cookie theft, `/etc/passwd` not user data. Out-of-scope target →
refuse, ask operator. No data exfil — minimal proof bytes only.

---

## Tool inventory by attack phase

Everything below is on `$PATH`. When a category lists multiple tools,
pick the one whose strengths fit the target — don't run them all.

### Recon: passive subdomain & OSINT
`subfinder` `assetfinder` `findomain` `amass` `theharvester` `recon-ng`
`spiderfoot` `dnsenum` `dnsrecon` `fierce` `dmitry` `dnstwist` `dnsgen`
`dns2tcp` `dnschef` `getallurls` (= gau)

### Recon: DNS / network mapping
`dnsx` `bind9-dnsutils` `whois` `netmask` `arp-scan` `netdiscover`
`fping` `traceroute` `thc-ipv6` `nbtscan`

### Recon: port & service scanning
`nmap` `masscan` `naabu` `unicornscan` `hping3` `ike-scan` `onesixtyone`
(SNMP) `snmpcheck` `snmp-check` `enum4linux` `smbmap` `nbtscan`
`certipy-ad` (ADCS enum)

### Recon: web — alive, tech, content, crawl
- Alive/tech: `httpx-toolkit` `whatweb` `wafw00f` `wig`
- Crawlers: `gospider` `katana` (if present) `hakrawler` (if present)
- Screenshots: `gowitness`
- Content discovery: `feroxbuster` `dirsearch` `gobuster` `dirb` `ffuf` `wfuzz`
- Param discovery: `arjun` `paramspider`
- Wordlists shipped on image:
  - `/usr/share/wordlists/` — Kali defaults (`rockyou.txt.gz`, dirb common, dirbuster, fern, metasploit, nmap, wfuzz)
  - `/usr/share/payloadsallthethings/` — PayloadsAllTheThings (XSS/SSRF/SQLi/SSTI payload reference; treat as docs)
- **SecLists is NOT bundled** (image-size tradeoff). Pull on demand:
  - Single file (fastest, usually what you want):
    `curl -sLO https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-medium-directories.txt`
  - Whole repo (only if you need many files):
    `git clone --depth=1 https://github.com/danielmiessler/SecLists ~/seclists`
  - Common picks: `Discovery/DNS/subdomains-top1million-110000.txt`,
    `Discovery/Web-Content/common.txt`, `Discovery/Web-Content/raft-large-directories.txt`,
    `Passwords/Common-Credentials/10-million-password-list-top-10000.txt`,
    `Fuzzing/special-chars.txt`

### Web vuln scanning
- Generic: `nuclei` (templates at `$NUCLEI_TEMPLATES`, pre-pulled)
- SQLi: `sqlmap` `commix` (cmd-injection)
- XSS: `dalfox` (if present) `xsstrike` `kxss` (if present)
- CMS: `wpscan` `whatweb` `cmseek`
- TLS: `sslyze` `sslscan` `ssldump` `qsslcaudit` `testssl.sh` (if present)
- CRLF: `crlfuzz`
- Old-school: `nikto` `skipfish` `wapiti` (if present)
- CORS: `corsy` (pipx)

### Filtering / chaining (pipe-friendly)
`gf` (regex categorizer) `qsreplace` `anew` `unfurl` `kxss` — install via
go-builder if not on PATH; useful for triaging URL piles into XSS / SSRF
/ SQLi / open-redirect candidates.

### Exploit DBs / payloads
`exploitdb` (= searchsploit) `metasploit-framework` `set` (Social-Engineer
Toolkit) `webshells` `weevely` (PHP) `laudanum` (multi-language webshells)
`windows-binaries` `peass`

### Auth / credential attacks
- Online: `hydra` `ncrack` `medusa` (if present) `patator` `crowbar` (if present)
- Offline: `john` `hashcat` `hashcat-utils` `statsprocessor`
- Hash ID: `hash-identifier` `hashid` `hashdeep`
- Wordlist gen: `crunch` `cewl` `rsmangler` `maskprocessor` `pipal`
- JWT: `jwt_tool` (pipx)

### Active Directory & Windows
- Coercion / relay: `responder` `ntlmrelayx` (impacket) `mitm6` (if present)
- Cred dump / enum: `mimikatz` `impacket-secretsdump` `samdump2` `creddump7`
  `pwdump` (if present) `chntpw` (offline SAM)
- Kerberos: `impacket-GetUserSPNs` `impacket-GetNPUsers` `kerbrute` (if present)
  `certipy-ad` (ADCS / Kerberos cert)
- Lateral: `evil-winrm` `netexec` (= crackmapexec successor) `psexec`-likes via
  `impacket-psexec` / `impacket-wmiexec` / `impacket-smbexec`
- SMB: `smbmap` `smbclient` (samba) `enum4linux`
- LDAP: `ldapsearch` (samba) `windapsearch` (if present)
- Empire/PowerShell: `powershell-empire` `powersploit` `powershell` `gpp-decrypt`
- Pass-the-hash: `passing-the-hash` suite

### Active Directory Certificate Services (ADCS)
`certipy-ad` — primary tool for ESC1–ESC11 enumeration & abuse.

### Wireless
`aircrack-ng` `wifite` `kismet` `reaver` `bully` `pixiewps` `cowpatty`
(if present) `bettercap` (if present) `mdk4` (if present) `spooftooph` (BT)

### Network attacks / MITM / sniffing
`mitmproxy` (TUI/web/dump) `bettercap` (if present) `ettercap` (if present)
`tcpdump` `tcpick` `tcpreplay` `ngrep` `netsniff-ng` `netsed` `socat`
`responder` `dns2tcp` `dnschef` `iodine` (DNS tunnel) `proxychains4`

### Reverse engineering / binary
`radare2` `rizin` (if present) `gdb` (if present) `objdump` `binwalk`
`binwalk3` `bulk-extractor` `magicrescue` `scalpel` `foremost` (if present)
`upx-ucl` `nasm` `clang` `xxd` `pdf-parser` `pdfid` `exiv2`
`libimage-exiftool-perl` (= exiftool) `unix-privesc-check`

### Mobile (APK)
`apktool` (decompile/rebuild) `jadx` (Java decompiler) `frida` /
`frida-tools` (pipx) `apksigner` (if present)

### Forensics (light)
`sleuthkit` `testdisk` `scrounge-ntfs` `foremost` (if present)
`bulk-extractor` `cryptsetup` (LUKS) `chntpw`

### SAST / secrets
`semgrep` `gitleaks` `trufflehog` `ripgrep` (= rg, hand-pattern grep)

### Web3 / smart contracts (if added)
`forge` `cast` `anvil` (Foundry) `slither`

### Proxy / interception (Burp-like, all in-container)
- `mitmweb` — browser UI for live HTTP history, inspect, tamper, replay.
  Run with `mitmweb --listen-host 0.0.0.0 --web-host 0.0.0.0` and (if the
  port is forwarded in compose) browse `http://localhost:8081` on the
  host. Replaces Burp Proxy + Repeater + HTTP history for most workflows.
- `mitmproxy` — TUI variant; same engine, no browser needed.
- `mitmdump` — non-interactive capture (`mitmdump -w flows.mitm`) and
  scripting (`-s script.py` for inline request/response rewriting).
- Pointing tools at it: `HTTPS_PROXY=http://127.0.0.1:8080
  HTTP_PROXY=http://127.0.0.1:8080 curl ...` (mitm listens on 8080 by
  default inside the container).
- TLS interception: first launch generates a CA at `~/.mitmproxy/`;
  `sudo cp ~/.mitmproxy/mitmproxy-ca-cert.pem
  /usr/local/share/ca-certificates/mitmproxy.crt && sudo
  update-ca-certificates` to trust it system-wide for CLI tools.

### Tunnels / pivots
`openvpn` `vpnc` `proxychains4` `proxytunnel` `ptunnel` `udptunnel`
`pwnat` `redsocks` `stunnel4` `sslh` `iodine` `dns2tcp` `miredo` (Teredo)

### TLS / cert tooling
`openssl` `sslscan` `sslyze` `sslsplit` `qsslcaudit` `ssldump`

### MCP servers (defined in `~/workspace/.mcp.json`)
- `playwright` — headless browser automation, JS rendering, login flows
- `shell` — extended fs/shell ops (desktop-commander)

---

## Workflow guidance

- **Chain via pipes**: `subfinder -d X -silent | dnsx -silent | httpx-toolkit -silent -tech-detect | nuclei`
- **Save evidence** under `~/loot/<target>/` with timestamped filenames
  (`nmap-tcp-$(date +%s).txt`).
- **OOB testing**: start `interactsh-client` first, paste the URL into
  payloads, monitor callbacks live.
- **Categorize URL piles** with `gf`: `cat urls.txt | gf xss`, `gf ssrf`,
  `gf sqli`, `gf redirect`. Patterns at `~/.gf/`.
- **Templates updates** for long engagements: `nuclei -ut`.
- **Inspect/tamper traffic**: start `mitmweb` inside the container, point
  CLI tools at `http://127.0.0.1:8080`. Browser UI on host:8081 if the
  port is forwarded. No host proxy needed.
- **Privilege**: `sudo` only when needed (`nmap -sS`, raw sockets,
  binding <1024). Default to unprivileged.

## Hard rules

- Out-of-scope target → refuse, ask operator.
- Mass targeting / supply-chain compromise / detection-evasion → only
  with explicit authorization context (RoE, engagement ID, CTF).
- No data exfiltration. Minimal proof bytes only.
- Don't disable safety checks (`--no-verify`, ignoring TLS, skipping
  validation) just to make tools work — root-cause first.
