# zapret-setup

Türkiye ISP'leri için DPI bypass kurulumu. Discord, Roblox ve diğer engelli sitelere stabil erişim sağlar.

## Strateji

`tpws --split-pos=sniext+4 --oob=tls --fix-seg`

TLS ClientHello'yu SNI extension sınırında böler ve Out-of-Band byte gönderir. TLS 1.2 ve TLS 1.3 ile çalışır.

## Kurulum

```bash
git clone https://github.com/LURIDD/zapret-setup.git
cd zapret-setup
sudo bash install.sh
```

## Test

```bash
curl -o /dev/null -w '%{http_code}\n' https://discord.com
curl -o /dev/null -w '%{http_code}\n' https://www.roblox.com
```

Her ikisi de `200` döndürmeli.

## Gereksinimler

- Arch Linux / CachyOS (veya systemd + nftables kullanan herhangi bir distro)
- Root erişimi
- `curl` paketi

## Teknik Detaylar

- **zapret v72.12** (bol-van/zapret)
- Firewall: nftables
- Daemon: yalnızca tpws (DNAT transparent proxy)
- `route_localnet=1` — tpws'nin 127.0.0.127'ye DNAT çalışması için gerekli
- HTTP bypass: `--hostspell=hoSt`
- HTTPS bypass: `--split-pos=sniext+4 --oob=tls --fix-seg`
- IPv6 devre dışı (ISP uyumsuzluğu nedeniyle)
