# zapret-setup

Türkiye ISP'leri için DPI bypass kurulumu. Discord, Roblox ve diğer engelli sitelere stabil erişim sağlar.

## Strateji

`nfqws --dpi-desync=fake,multisplit --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig`

TLS ClientHello paketini parçalara böler ve ISP'nin DPI sisteminin okuyamamasını sağlar. Paketler doğru sırayla gönderildiği için sunucu tarafında bağlantı reddi yaşanmaz.

## Özellikler

- **autohostlist modu** — engelli olmayan sitelere dokunmaz; bağlantı başarısız olunca domain'i otomatik listeye ekler, sonraki denemelerde bypass uygular
- **multisplit** — `multidisorder`'a kıyasla daha stabil, ~%100 başarı oranı
- IPv6 devre dışı (ISP uyumsuzluğu nedeniyle)

## Kurulum

```bash
git clone https://github.com/LURIDD/zapret-setup.git
cd zapret-setup
sudo bash install.sh
```

## Test

```bash
curl -o /dev/null -w '%{http_code}
' https://discord.com
curl -o /dev/null -w '%{http_code}
' https://www.roblox.com
```

Her ikisi de `200` döndürmeli.

## Autohostlist Yönetimi

```bash
# Listeyi görüntüle
cat /opt/zapret/ipset/zapret-hosts-auto.txt

# Manuel domain ekle
echo "domain.com" | sudo tee -a /opt/zapret/ipset/zapret-hosts-auto.txt
```

## Gereksinimler

- Arch Linux / CachyOS (veya systemd + nftables kullanan herhangi bir distro)
- Root erişimi
- `curl` paketi

## Teknik Detaylar

- **zapret** (bol-van/zapret)
- Firewall: nftables
- Daemon: nfqws
- Filtre modu: autohostlist
- HTTP bypass: `fake,multisplit --dpi-desync-split-pos=method+2 --dpi-desync-fooling=md5sig`
- HTTPS bypass: `fake,multisplit --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig`
- UDP/QUIC bypass: `fake --dpi-desync-repeats=6`
- IPv6 devre dışı (ISP uyumsuzluğu nedeniyle)
