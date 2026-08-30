class VpnStatus {
  final bool connected;
  final String state;
  final int downloadBytes;
  final int uploadBytes;

  const VpnStatus({
    required this.connected,
    required this.state,
    required this.downloadBytes,
    required this.uploadBytes,
  });

  factory VpnStatus.fromMap(Map<dynamic, dynamic> map) {
    return VpnStatus(
      connected: map['connected'] == true,
      state: map['state']?.toString() ?? 'DOWN',
      downloadBytes: (map['downloadBytes'] as num?)?.toInt() ?? 0,
      uploadBytes: (map['uploadBytes'] as num?)?.toInt() ?? 0,
    );
  }

  factory VpnStatus.disconnected() {
    return const VpnStatus(
      connected: false,
      state: 'DOWN',
      downloadBytes: 0,
      uploadBytes: 0,
    );
  }
}
