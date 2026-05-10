#!/usr/bin/env bash
set -euo pipefail

REPO="sup3rt00ls/DeBuntu"
INSTALL_DIR="/opt/debuntu"
BIN="/usr/local/bin/debuntu"

RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
ORANGE="\033[38;5;208m"
GREEN="\033[38;5;76m"
RED="\033[38;5;196m"
GRAY="\033[38;5;245m"

info()  { echo -e "  ${ORANGE}›${RESET}  $*"; }
ok()    { echo -e "  ${GREEN}✓${RESET}  $*"; }
fail()  { echo -e "  ${RED}✗${RESET}  $*"; exit 1; }

echo -e ""
echo -e "  ${ORANGE}${BOLD}DeBuntu Installer${RESET}"
echo -e "  ${DIM}──────────────────────────────${RESET}"
echo -e ""

[[ "$EUID" -eq 0 ]] || fail "Run as root: sudo bash <(curl -s ...)"

command -v curl  &>/dev/null || { info "Installing curl…";  apt-get install -y curl  &>/dev/null; }
command -v unzip &>/dev/null || { info "Installing unzip…"; apt-get install -y unzip &>/dev/null; }
command -v python3 &>/dev/null || fail "python3 is required but not found."

info "Fetching latest release…"

RELEASES_JSON=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases")

DOWNLOAD_URL=$(echo "$RELEASES_JSON" | python3 -c "
import json, sys

releases = json.load(sys.stdin)
for r in releases:
    tag = r.get('tag_name', '')
    name = r.get('name', '')
    prerelease = r.get('prerelease', False)
    draft = r.get('draft', False)
    if prerelease or draft:
        continue
    if 'Sonnet' in tag or 'Sonnet' in name:
        continue
    for asset in r.get('assets', []):
        if asset['name'].endswith('.zip'):
            print(asset['browser_download_url'])
            sys.exit(0)
sys.exit(1)
") || fail "No eligible release found. (All releases may be tagged 'Sonnet Build' or have no .zip asset.)"

FILENAME=$(basename "$DOWNLOAD_URL")
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

info "Downloading ${FILENAME}…"
curl -fsSL "$DOWNLOAD_URL" -o "${TMP}/${FILENAME}"

info "Installing to ${INSTALL_DIR}…"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
unzip -q "${TMP}/${FILENAME}" -d "$INSTALL_DIR"

MAIN_SCRIPT=$(find "$INSTALL_DIR" -name "debuntu.py" | head -1)
[[ -n "$MAIN_SCRIPT" ]] || fail "debuntu.py not found in release zip."

chmod +x "$MAIN_SCRIPT"

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
ok "DeBuntu installed."
echo -e "  ${DIM}Run it with:${RESET}  ${BOLD}debuntu${RESET}"
echo -e ""
