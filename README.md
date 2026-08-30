# DXS Tunnel v1.0

DXS Tunnel est un client Android basé sur Flutter et WireGuard.

## Fonctionnalités

- Client WireGuard Android
- Vrai tunnel VPN
- Import manuel de configuration WireGuard
- Connect / Disconnect
- Statut du tunnel
- Statistiques RX/TX
- Compilation APK automatique avec GitHub Actions

## Configuration

DXS Tunnel utilise le format WireGuard standard.

Exemple :

```ini
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY
Address = 10.0.0.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = SERVER_IP:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
