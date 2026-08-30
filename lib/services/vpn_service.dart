import 'package:wireguard_flutter/wireguard_flutter.dart';

class VpnService {
  static final _wireguard = WireGuardFlutter.instance;

  static Future<bool> startTunnel({
    required String serverIp,
    required String serverPort,
    required String username,
    required String password,
  }) async {
    try {
      // 1. Initialisation de la carte réseau virtuelle
      await _wireguard.initialize(interfaceName: 'wg0');

      // 2. Définition de la configuration au format WG-Quick
      // Note : Un vrai serveur WireGuard utilise un jeu de clés privées/publiques.
      // Le mot de passe et l'utilisateur sont simulés ici pour l'intégration de votre format.
      final String conf = '''
[Interface]
PrivateKey = aKcvGXB4Ym${password.padRight(32, '0').substring(0, 32)}=
Address = 10.8.0.4/32
DNS = 1.1.1.1

[Peer]
PublicKey = 6uZg6T0J1bHuEmdqPx8OmxQ2ebBJ8TnVpnCdV8jHliQ=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $serverIp:$serverPort
''';

      // 3. Lancement du moteur UDP natif
      await _wireguard.startVpn(
        serverAddress: "$serverIp:$serverPort",
        wgQuickConfig: conf,
        providerBundleIdentifier: 'com.dxstunnel.dxs_tunnel',
      );
      
      return true;
    } catch (e) {
      print("Erreur du moteur VPN UDP : $e");
      return false;
    }
  }

  static Future<void> stopTunnel() async {
    try {
      await _wireguard.stopVpn();
    } catch (e) {
      print("Erreur lors de l'arrêt : $e");
    }
  }
}
