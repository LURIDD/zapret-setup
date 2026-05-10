#!/bin/bash
set -e

# Renk kodları
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[x]${NC} $1"; exit 1; }

[ "$(id -u)" -eq 0 ] || error "Root olarak çalıştır: sudo bash install.sh"

ZAPRET_VERSION="v72.12"
ZAPRET_URL="https://github.com/bol-van/zapret/releases/download/${ZAPRET_VERSION}/zapret-${ZAPRET_VERSION}.tar.gz"
ZAPRET_DIR="/opt/zapret"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── 1. Eski kurulumu temizle ──────────────────────────────────────────────────
if [ -d "$ZAPRET_DIR" ]; then
    warn "Mevcut zapret kurulumu kaldırılıyor..."
    [ -f "$ZAPRET_DIR/uninstall_easy.sh" ] && bash "$ZAPRET_DIR/uninstall_easy.sh" 2>/dev/null || true
    systemctl stop zapret 2>/dev/null || true
    systemctl disable zapret 2>/dev/null || true
    rm -rf "$ZAPRET_DIR"
fi

# ── 2. zapret indir ve aç ────────────────────────────────────────────────────
info "zapret ${ZAPRET_VERSION} indiriliyor..."
TMP_DIR=$(mktemp -d)
curl -fsSL "$ZAPRET_URL" -o "$TMP_DIR/zapret.tar.gz"
tar -xzf "$TMP_DIR/zapret.tar.gz" -C "$TMP_DIR"
EXTRACTED=$(find "$TMP_DIR" -maxdepth 1 -type d -name "zapret-*" | head -1)
mv "$EXTRACTED" "$ZAPRET_DIR"
rm -rf "$TMP_DIR"
info "zapret $ZAPRET_DIR konumuna çıkarıldı"

# ── 3. install_easy.sh çalıştır ──────────────────────────────────────────────
info "install_easy.sh çalıştırılıyor (nftables, tpws)..."
printf '2\n\n\n\nN\nY\n\nY\n\n\n\n' | bash "$ZAPRET_DIR/install_easy.sh"

# ── 4. Çalışan config'i uygula ───────────────────────────────────────────────
info "Optimize edilmiş config uygulanıyor..."
cp "$SCRIPT_DIR/config" "$ZAPRET_DIR/config"

# ── 5. route_localnet kalıcı ayarla ─────────────────────────────────────────
info "route_localnet etkinleştiriliyor..."
cat > /etc/sysctl.d/99-zapret.conf << 'EOF'
net.ipv4.conf.all.route_localnet=1
EOF
sysctl -w net.ipv4.conf.all.route_localnet=1 >/dev/null

# ── 6. Servisi yeniden başlat ────────────────────────────────────────────────
info "Zapret servisi yeniden başlatılıyor..."
systemctl restart zapret
systemctl enable zapret >/dev/null 2>&1

sleep 2
if systemctl is-active --quiet zapret; then
    info "Kurulum tamamlandı! Zapret çalışıyor."
    echo ""
    echo "  Strateji: tpws --split-pos=sniext+4 --oob=tls --fix-seg"
    echo "  Test: curl -o /dev/null -w '%{http_code}' https://discord.com"
else
    error "Zapret başlatılamadı. 'systemctl status zapret' ile kontrol et."
fi
