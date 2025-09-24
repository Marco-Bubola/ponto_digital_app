// Modelo para solicitações de ajuste de ponto
class AdjustmentRequest {
  final String id;
  final String userId;
  final String originalRecordId;
  final DateTime requestedTimestamp;
  final String reason;
  final String? aiGeneratedJustification;
  final AdjustmentStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;

  AdjustmentRequest({
    required this.id,
    required this.userId,
    required this.originalRecordId,
    required this.requestedTimestamp,
    required this.reason,
    this.aiGeneratedJustification,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
  });

  factory AdjustmentRequest.fromJson(Map<String, dynamic> json) {
    return AdjustmentRequest(
      id: json['id'],
      userId: json['user_id'],
      originalRecordId: json['original_record_id'],
      requestedTimestamp: DateTime.parse(json['requested_timestamp']),
      reason: json['reason'],
      aiGeneratedJustification: json['ai_generated_justification'],
      status: AdjustmentStatus.values.firstWhere(
        (e) => e.toString() == 'AdjustmentStatus.${json['status']}',
      ),
      createdAt: DateTime.parse(json['created_at']),
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at']) 
          : null,
      approvedBy: json['approved_by'],
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'original_record_id': originalRecordId,
      'requested_timestamp': requestedTimestamp.toIso8601String(),
      'reason': reason,
      'ai_generated_justification': aiGeneratedJustification,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'rejection_reason': rejectionReason,
    };
  }
}

// Status das solicitações de ajuste
enum AdjustmentStatus {
  pending,    // Pendente de aprovação
  approved,   // Aprovada
  rejected,   // Rejeitada
  cancelled   // Cancelada pelo usuário
}
