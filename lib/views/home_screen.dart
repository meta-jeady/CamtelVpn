import 'dart:async';

import 'package:flutter/material.dart';

import '../models/vpn_status.dart';
import '../services/wireguard_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _configController =
      TextEditingController();

  final TextEditingController _nameController =
      TextEditingController(text: 'dxs0');

  final WireGuardService _vpn =
      WireGuardService.instance;

  Timer? _timer;

  bool _loading = false;

  VpnStatus _status =
      VpnStatus.disconnected();

  @override
  void initState() {
    super.initState();

    _refreshStatus();

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshStatus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    _configController.dispose();
    _nameController.dispose();

    super.dispose();
  }

  Future<void> _refreshStatus() async {
    try {
      final status =
          await _vpn.getStatus();

      if (!mounted) return;

      setState(() {
        _status = status;
      });
    } catch (_) {}
  }

  Future<void> _connect() async {
    final config =
        _configController.text.trim();

    final name =
        _nameController.text.trim();

    if (name.isEmpty) {
      _showError(
        'Le nom du tunnel est obligatoire.',
      );

      return;
    }

    if (config.isEmpty) {
      _showError(
        'Collez une vraie configuration WireGuard.',
      );

      return;
    }

    if (!config.contains('[Interface]') ||
        !config.contains('[Peer]')) {
      _showError(
        'Configuration WireGuard invalide.',
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _vpn.connect(
        tunnelName: name,
        config: config,
      );

      await _refreshStatus();

      if (!mounted) return;

      _showMessage(
        'Tunnel démarré.',
      );
    } catch (error) {
      if (!mounted) return;

      _showError(
        'Erreur VPN : $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _loading = true;
    });

    try {
      await _vpn.disconnect();

      await _refreshStatus();

      if (!mounted) return;

      _showMessage(
        'Tunnel arrêté.',
      );
    } catch (error) {
      if (!mounted) return;

      _showError(
        'Erreur : $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final connected =
        _status.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DXS Tunnel v1.0',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),

            Icon(
              Icons.security,
              size: 80,
              color: connected
                  ? Colors.green
                  : Colors.grey,
            ),

            const SizedBox(height: 15),

            Center(
              child: Text(
                connected
                    ? 'CONNECTÉ'
                    : 'DÉCONNECTÉ',
                style:
                    Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                          color: connected
                              ? Colors.green
                              : Colors.red,
                        ),
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: _nameController,
              enabled:
                  !connected && !_loading,
              decoration:
                  const InputDecoration(
                labelText:
                    'Nom du tunnel',
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.vpn_key),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller:
                  _configController,
              enabled:
                  !connected && !_loading,
              minLines: 14,
              maxLines: 22,
              keyboardType:
                  TextInputType.multiline,
              decoration:
                  const InputDecoration(
                labelText:
                    'Configuration WireGuard',
                hintText: '''
[Interface]
PrivateKey = ...
Address = 10.0.0.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = ...
Endpoint = example.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
''',
                alignLabelWithHint: true,
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _statRow(
                      'État',
                      _status.state,
                    ),
                    const Divider(),
                    _statRow(
                      'Téléchargement',
                      _formatBytes(
                        _status.downloadBytes,
                      ),
                    ),
                    const Divider(),
                    _statRow(
                      'Upload',
                      _formatBytes(
                        _status.uploadBytes,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 58,
              child:
                  _loading
                      ? const Center(
                          child:
                              CircularProgressIndicator(),
                        )
                      : ElevatedButton.icon(
                          icon: Icon(
                            connected
                                ? Icons.stop
                                : Icons.play_arrow,
                          ),
                          label: Text(
                            connected
                                ? 'DÉCONNECTER'
                                : 'CONNECTER',
                          ),
                          onPressed:
                              connected
                                  ? _disconnect
                                  : _connect,
                        ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Utilisez uniquement une configuration WireGuard valide provenant d’un serveur VPN que vous contrôlez ou auquel vous êtes autorisé à vous connecter.',
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
