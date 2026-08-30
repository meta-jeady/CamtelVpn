import 'package:flutter/services.dart';

import '../models/vpn_status.dart';

class WireGuardService {
  WireGuardService._();

  static final WireGuardService instance = WireGuardService._();

  static const MethodChannel _channel =
      MethodChannel('dxs_tunnel/wireguard');

  Future<void> connect({
    required String tunnelName,
    required String config,
  }) async {
    await _channel.invokeMethod(
      'connect',
      {
        'name': tunnelName,
        'config': config,
      },
    );
  }

  Future<void> disconnect() async {
    await _channel.invokeMethod('disconnect');
  }

  Future<VpnStatus> getStatus() async {
    final result =
        await _channel.invokeMapMethod<dynamic, dynamic>('status');

    if (result == null) {
      return VpnStatus.disconnected();
    }

    return VpnStatus.fromMap(result);
  }

  Future<String> getVersion() async {
    final result =
        await _channel.invokeMethod<String>('version');

    return result ?? 'Unknown';
  }
}
