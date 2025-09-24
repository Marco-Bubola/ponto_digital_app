import '../utils/constants.dart';

// Modelo de dados para registro de ponto
class TimeRecord {
  final String id;
  final String userId;
  final TimeRecordType type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String deviceId;
  final String? faceImageUrl;
  final ValidationStatus validationStatus;
  final bool isSynced;
  final Map<String, dynamic>? metadata;

  TimeRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.deviceId,
    this.faceImageUrl,
    required this.validationStatus,
    required this.isSynced,
    this.metadata,
  });

  factory TimeRecord.fromJson(Map<String, dynamic> json) {
    return TimeRecord(
      id: json['id'],
      userId: json['user_id'],
      type: TimeRecordType.values.firstWhere(
        (e) => e.toString() == 'TimeRecordType.${json['type']}',
      ),
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      deviceId: json['device_id'],
      faceImageUrl: json['face_image_url'],
      validationStatus: ValidationStatus.values.firstWhere(
        (e) => e.toString() == 'ValidationStatus.${json['validation_status']}',
      ),
      isSynced: json['is_synced'] ?? true,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'device_id': deviceId,
      'face_image_url': faceImageUrl,
      'validation_status': validationStatus.toString().split('.').last,
      'is_synced': isSynced,
      'metadata': metadata,
    };
  }

  // Método para obter o emoji do tipo de registro
  String getTypeEmoji() {
    switch (type) {
      case TimeRecordType.entrada:
        return '✅';
      case TimeRecordType.pausa:
        return '⏸️';
      case TimeRecordType.retorno:
        return '▶️';
      case TimeRecordType.saida:
        return '🏁';
    }
  }

  // Método para obter o nome amigável do tipo
  String getTypeName() {
    switch (type) {
      case TimeRecordType.entrada:
        return 'Entrada';
      case TimeRecordType.pausa:
        return 'Pausa';
      case TimeRecordType.retorno:
        return 'Retorno';
      case TimeRecordType.saida:
        return 'Saída';
    }
  }
}