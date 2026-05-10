#!/usr/bin/env bash
set -euo pipefail

REPO="sup3rt00ls/DeBuntu"
INSTALL_DIR="/opt/debuntu"
BIN="/usr/local/bin/debuntu"
VERSION_FILE="${INSTALL_DIR}/.version"

RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
ORANGE="\033[38;5;208m"
GREEN="\033[38;5;76m"
RED="\033[38;5;196m"
GRAY="\033[38;5;245m"

info()  { echo -e "  ${ORANGE}›${RESET}  $*"; }
ok()    { echo -e "  ${GREEN}✓${RESET}  $*"; }
skip()  { echo -e "  ${GRAY}–${RESET}  $*"; }
fail()  { echo -e "  ${RED}✗${RESET}  $*"; exit 1; }

echo -e ""
echo -e "  ${ORANGE}${BOLD}DeBuntu Installer${RESET}"
echo -e "  ${DIM}──────────────────────────────${RESET}"
echo -e ""

[[ "$EUID" -eq 0 ]] || fail "Run as root: curl ... | sudo bash"

command -v curl   &>/dev/null || { info "Installing curl…";   apt-get install -y curl   &>/dev/null; }
command -v unzip  &>/dev/null || { info "Installing unzip…";  apt-get install -y unzip  &>/dev/null; }
command -v python3 &>/dev/null || fail "python3 is required but not found."

info "Fetching release info…"

RELEASES_JSON=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases")

RELEASE_INFO=$(echo "$RELEASES_JSON" | python3 -c "
import json, sys, re

releases = json.load(sys.stdin)
for r in releases:
    tag    = r.get('tag_name', '')
    name   = r.get('name', '')
    labels = r.get('labels', [])
    if r.get('prerelease') or r.get('draft'):
        continue
    if 'Sonnet' in tag or 'Sonnet' in name:
        continue
    for asset in r.get('assets', []):
        if asset['name'].endswith('.zip'):
            # Collect all tags/labels on this release
            extra = [l['name'] for l in labels if l.get('name')]
            # Format: V0.1 - HOTFIX - PATCH etc
            version_part = tag.lstrip('vV').strip()
            if extra:
                suffix = ' - '.join(e.upper() for e in extra)
                version_str = f'V{version_part} - {suffix}'
            else:
                version_str = f'V{version_part}'
            print(tag)
            print(asset['browser_download_url'])
            print(version_str)
            sys.exit(0)
sys.exit(1)
") || fail "No eligible release found. (All may be Sonnet builds or missing .zip asset.)"

LATEST_TAG=$(echo "$RELEASE_INFO" | sed -n '1p')
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | sed -n '2p')
VERSION_STRING=$(echo "$RELEASE_INFO" | sed -n '3p')

# Version check
CURRENT_TAG=""
[[ -f "$VERSION_FILE" ]] && CURRENT_TAG=$(cat "$VERSION_FILE")

if [[ "$CURRENT_TAG" == "$LATEST_TAG" ]]; then
    skip "Already on latest version ${BOLD}${LATEST_TAG}${RESET}."
    echo -e ""
    exit 0
fi

if [[ -n "$CURRENT_TAG" ]]; then
    info "Updating ${GRAY}${CURRENT_TAG}${RESET} → ${ORANGE}${LATEST_TAG}${RESET}…"
else
    info "Installing version ${ORANGE}${LATEST_TAG}${RESET}…"
fi

FILENAME=$(basename "$DOWNLOAD_URL")
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

info "Downloading ${FILENAME}…"
curl -fsSL "$DOWNLOAD_URL" -o "${TMP}/${FILENAME}"

info "Extracting to ${INSTALL_DIR}…"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
unzip -q "${TMP}/${FILENAME}" -d "$INSTALL_DIR"

MAIN_SCRIPT=$(find "$INSTALL_DIR" -name "debuntu.py" | head -1)
[[ -n "$MAIN_SCRIPT" ]] || fail "debuntu.py not found in release zip."

chmod +x "$MAIN_SCRIPT"
echo "$VERSION_STRING" > "$VERSION_FILE"

cat > "$BIN" <<EOF
#!/usr/bin/env bash
if [[ "\$EUID" -ne 0 ]]; then
    exec sudo python3 "${MAIN_SCRIPT}" "\$@"
else
    exec python3 "${MAIN_SCRIPT}" "\$@"
fi
EOF
chmod +x "$BIN"

echo -e ""
if [[ -n "$CURRENT_TAG" ]]; then
    ok "DeBuntu updated to ${BOLD}${LATEST_TAG}${RESET}."
else
    ok "DeBuntu installed. Run with: ${BOLD}debuntu${RESET}"
fi
echo -e ""
