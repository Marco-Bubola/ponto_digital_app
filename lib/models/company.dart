// Modelo para empresas
class Company {
  final String id;
  final String name;
  final String cnpj;
  final List<WorkLocation> locations;
  final WorkingHours workingHours;
  final CompanySettings settings;
  final bool isActive;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.name,
    required this.cnpj,
    required this.locations,
    required this.workingHours,
    required this.settings,
    required this.isActive,
    required this.createdAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      cnpj: json['cnpj'],
      locations: (json['locations'] as List)
          .map((location) => WorkLocation.fromJson(location))
          .toList(),
      workingHours: WorkingHours.fromJson(json['working_hours']),
      settings: CompanySettings.fromJson(json['settings']),
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Modelo para locais de trabalho
class WorkLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  WorkLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  factory WorkLocation.fromJson(Map<String, dynamic> json) {
    return WorkLocation(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      radiusMeters: json['radius_meters'].toDouble(),
    );
  }
}

// Modelo para horários de trabalho
class WorkingHours {
  final String startTime;
  final String endTime;
  final String lunchStart;
  final String lunchEnd;
  final List<String> workDays;

  WorkingHours({
    required this.startTime,
    required this.endTime,
    required this.lunchStart,
    required this.lunchEnd,
    required this.workDays,
  });

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      startTime: json['start_time'],
      endTime: json['end_time'],
      lunchStart: json['lunch_start'],
      lunchEnd: json['lunch_end'],
      workDays: List<String>.from(json['work_days']),
    );
  }
}

// Configurações da empresa
class CompanySettings {
  final bool requireFaceRecognition;
  final bool requireGpsValidation;
  final bool allowOfflineMode;
  final int maxDevicesPerUser;
  final bool enableAiJustifications;

  CompanySettings({
    required this.requireFaceRecognition,
    required this.requireGpsValidation,
    required this.allowOfflineMode,
    required this.maxDevicesPerUser,
    required this.enableAiJustifications,
  });

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    return CompanySettings(
      requireFaceRecognition: json['require_face_recognition'],
      requireGpsValidation: json['require_gps_validation'],
      allowOfflineMode: json['allow_offline_mode'],
      maxDevicesPerUser: json['max_devices_per_user'],
      enableAiJustifications: json['enable_ai_justifications'],
    );
  }
}
