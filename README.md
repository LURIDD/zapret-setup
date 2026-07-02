# zapret-setup

Türkiye ISP'leri için DPI bypass kurulumu. Discord, Roblox ve otomatik öğrenen hostlist sayesinde diğer engelli sitelere de kararlı erişim sağlar.

## Strateji

```
nfqws --dpi-desync=fake --dpi-desync-ttl=3
```

Gerçek TLS ClientHello/HTTP isteğinin hemen ardından, hedefe gitmeyecek kadar düşük TTL'li (3 hop) sahte bir paket gönderilir. Bu sahte paket ISP'nin DPI cihazına (genelde istemciye yakın bir noktada) ulaşıp onu yanıltırken, gerçek uzak sunucuya hiç varmadan sönüyor. Böylece DPI, bağlantının gerçek hedefini (SNI/Host) doğru tespit edemiyor.

Bu strateji, `bol-van/zapret`'in kendi `blockcheck.sh` teşhis aracıyla — **zapret servisi tamamen durdurulmuş halde** (aksi durumda zaten aktif olan bypass, testleri yanıltabiliyor) — discord.com ve roblox.com için HTTP, TLS1.2 ve TLS1.3 kategorilerinin **üçünde birden, hiçbir uyarı olmadan** çalışan tek strateji olarak doğrulandı. `badseq`/`md5sig`/`ts`/`multisplit` gibi diğer teknikler de bazı testlerde çalıştı ama hepsi belirli sunucu/istemci koşullarına bağımlı uyarılar taşıyordu ya da tekrarlanan denemelerde kararsız çıktı verdi; `fake --dpi-desync-ttl=3` böyle bir kısıtı yok.

## Özellikler

- **autohostlist modu** — engelli olmayan sitelere dokunmaz; bağlantı başarısız olunca domain'i otomatik listeye ekler, sonraki denemelerde bypass uygular
- Tek, sade strateji — fooling/split kombinasyonu değil, tek bir TTL numarası

## Kurulum

```bash
git clone https://github.com/LURIDD/zapret-setup.git
cd zapret-setup
sudo bash install.sh
```

`install.sh`: en güncel zapret sürümünü indirir, `install_easy.sh` sihirbazını nftables + nfqws + autohostlist seçenekleriyle otomatik yürütür, ardından bu depodaki optimize edilmiş `config` dosyasını uygulayıp servisi başlatır.

## Test

```bash
curl -o /dev/null -w '%{http_code}\n' https://discord.com
curl -o /dev/null -w '%{http_code}\n' https://roblox.com
```

`discord.com` için `200`, `roblox.com` için `308` (www.roblox.com'a kalıcı yönlendirme — bağlantının başarılı kurulduğunu gösterir) dönmeli.

## Sorun giderme

Yeni bir site bloklu kalıyorsa, doğru stratejiyi bulmak için zapret'i **durdurup** temiz bir blockcheck çalıştırın (açıkken çalıştırmak yanıltıcı sonuç verir):

```bash
sudo systemctl stop zapret
cd /opt/zapret
sudo DOMAINS_DEFAULT="sorunlu-site.com" ./blockcheck.sh
# SUMMARY/COMMON bölümündeki, uyarısız çalışan stratejiyi config'deki
# NFQWS_OPT içine ekleyin, sonra:
sudo systemctl start zapret
```

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

- **zapret** (bol-van/zapret) — `install.sh` her zaman en güncel sürümü indirir
- Firewall: nftables
- Daemon: yalnızca nfqws (NFQUEUE tabanlı, DNAT/TPROXY gerektirmez)
- Filtreleme modu: `autohostlist` — bloklu domain'ler manuel eklenmeden, başarısız bağlantı denemelerinden otomatik öğrenilir
- TCP 80 ve 443: `--dpi-desync=fake --dpi-desync-ttl=3`
- UDP 443 (QUIC): `--dpi-desync=fake --dpi-desync-repeats=6`
- IPv6 devre dışı (ISP uyumsuzluğu nedeniyle)
