// Modelo de dados para usuário/colaborador
class User {
  final String id;
  final String name;
  final String email;
  final String cpf;
  final String companyId;
  final String profileImageUrl;
  final List<String> authorizedDevices;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.cpf,
    required this.companyId,
    required this.profileImageUrl,
    required this.authorizedDevices,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      cpf: json['cpf'],
      companyId: json['company_id'],
      profileImageUrl: json['profile_image_url'],
      authorizedDevices: List<String>.from(json['authorized_devices']),
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'cpf': cpf,
      'company_id': companyId,
      'profile_image_url': profileImageUrl,
      'authorized_devices': authorizedDevices,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }
}