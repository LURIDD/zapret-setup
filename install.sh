#!/bin/bash
set -e

RED='[0;31m'; GREEN='[0;32m'; YELLOW='[1;33m'; NC='[0m'
info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; exit 1; }

[ "$(id -u)" -eq 0 ] || error "Root olarak çalıştır: sudo bash install.sh"

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

# ── 2. En son sürümü indir ───────────────────────────────────────────────────
info "En son zapret sürümü alınıyor..."
ZAPRET_VERSION=$(curl -fsSL https://api.github.com/repos/bol-van/zapret/releases/latest | grep 'tag_name' | cut -d'"' -f4)
[ -z "$ZAPRET_VERSION" ] && error "Sürüm alınamadı, internet bağlantısını kontrol et."
ZAPRET_URL="https://github.com/bol-van/zapret/releases/download/${ZAPRET_VERSION}/zapret-${ZAPRET_VERSION}.tar.gz"

info "zapret ${ZAPRET_VERSION} indiriliyor..."
TMP_DIR=$(mktemp -d)
curl -fsSL "$ZAPRET_URL" -o "$TMP_DIR/zapret.tar.gz"
tar -xzf "$TMP_DIR/zapret.tar.gz" -C "$TMP_DIR"
EXTRACTED=$(find "$TMP_DIR" -maxdepth 1 -type d -name "zapret-*" | head -1)
mv "$EXTRACTED" "$ZAPRET_DIR"
rm -rf "$TMP_DIR"
info "zapret $ZAPRET_DIR konumuna çıkarıldı"

# ── 3. install_easy.sh çalıştır (nfqws + nftables) ───────────────────────────
info "install_easy.sh çalıştırılıyor (nfqws, nftables)..."
printf '1
2



N
Y

Y



' | bash "$ZAPRET_DIR/install_easy.sh"

# ── 4. Çalışan config'i uygula ────────────────────────────────────────────
info "Optimize edilmiş config uygulanıyor..."
cp "$SCRIPT_DIR/config" "$ZAPRET_DIR/config"

# ── 5. Servisi yeniden başlat ────────────────────────────────────────────────
info "Zapret servisi yeniden başlatılıyor..."
systemctl restart zapret
systemctl enable zapret >/dev/null 2>&1

sleep 2
if systemctl is-active --quiet zapret; then
    info "Kurulum tamamlandı! Zapret çalışıyor."
    echo ""
    echo "  Strateji : nfqws fake,multisplit (TCP 80/443) + fake repeat x6 (UDP 443)"
    echo "  Mod      : autohostlist — engelli olmayan sitelere dokunmaz"
    echo "  Test     : curl -o /dev/null -w '%{http_code}' https://discord.com"
    echo "  Liste    : cat /opt/zapret/ipset/zapret-hosts-auto.txt"
else
    error "Zapret başlatılamadı. 'systemctl status zapret' ile kontrol et."
fi
