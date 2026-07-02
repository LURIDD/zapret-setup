#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
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

# ── 3. install_easy.sh çalıştır (nftables + nfqws + autohostlist) ─────────────
# install_easy.sh interaktif bir sihirbaz. Aşağıdaki cevaplar sırasıyla:
#   1) firewall tipi          -> 2 (nftables)
#   2) ipv6 desteği aç        -> N (kapalı kalsın, DISABLE_IPV6=1)
#   3) flow offloading        -> [Enter] (none, varsayılan)
#   4) filtreleme modu        -> 4 (autohostlist - blok tespit edilen domain'i otomatik öğrenir)
#   5) tpws socks etkinleştir -> [Enter] (N, kullanmıyoruz)
#   6) tpws transparent       -> [Enter] (N, kullanmıyoruz)
#   7) nfqws etkinleştir      -> Y
#   8) nfqws seçeneklerini düzenle -> [Enter] (N, varsayılanı kabul et; adım 4'te zaten üzerine yazılacak)
#   9) LAN arayüzü            -> [Enter] (NONE)
#  10) WAN arayüzü            -> [Enter] (ANY)
#  11) otomatik ip/host listesi indir -> [Enter] (N, autohostlist zaten kendi listesini öğreniyor)
#
# Not: install_easy.sh'ın zapret sürümleri arasında prompt sırası değişebilir.
# Eğer bu adım beklenmedik bir yerde takılırsa Ctrl+C ile durdurup
# "sudo bash /opt/zapret/install_easy.sh" komutunu elle çalıştırın ve
# yukarıdaki cevapları sırasıyla girin, ardından bu betiği adım 4'ten devam ettirin.
info "install_easy.sh çalıştırılıyor (nftables, nfqws, autohostlist)..."
printf '2\nN\n\n4\n\n\nY\n\n\n\n\n' | bash "$ZAPRET_DIR/install_easy.sh"

# ── 4. Çalışan config'i uygula ───────────────────────────────────────────────
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
    echo "  Strateji : nfqws --dpi-desync=fake --dpi-desync-ttl=3 (TCP 80/443) + fake repeat x6 (UDP 443)"
    echo "  Mod      : autohostlist — engelli olmayan sitelere dokunmaz"
    echo "  Test     : curl -o /dev/null -w '%{http_code}\\n' https://discord.com"
    echo "  Liste    : cat /opt/zapret/ipset/zapret-hosts-auto.txt"
else
    error "Zapret başlatılamadı. 'systemctl status zapret' ile kontrol et."
fi
