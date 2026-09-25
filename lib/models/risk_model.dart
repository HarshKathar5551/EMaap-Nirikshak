enum RiskLevel {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'LOW RISK';
      case RiskLevel.medium:
        return 'MEDIUM RISK';
      case RiskLevel.high:
        return 'HIGH RISK';
    }
  }

  static RiskLevel fromString(String level) {
    return RiskLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == level.toLowerCase() ||
             e.displayName.toLowerCase() == level.toLowerCase(),
      orElse: () => RiskLevel.low,
    );
  }
}

class RiskAssessmentModel {
  final String instrumentId;
  final String instrumentUniqueId;
  final RiskLevel riskLevel;
  final int score; // 0 - 100
  final List<String> reasons;
  final int previousFailuresCount;
  final int consumerComplaintsCount;
  final int daysOverdue;
  final bool hasMeasurementDiscrepancies;
  final DateTime assessedDate;

  const RiskAssessmentModel({
    required this.instrumentId,
    required this.instrumentUniqueId,
    required this.riskLevel,
    required this.score,
    required this.reasons,
    required this.previousFailuresCount,
    required this.consumerComplaintsCount,
    required this.daysOverdue,
    required this.hasMeasurementDiscrepancies,
    required this.assessedDate,
  });

  factory RiskAssessmentModel.fromJson(Map<String, dynamic> json) {
    return RiskAssessmentModel(
      instrumentId: json['instrumentId'] as String,
      instrumentUniqueId: json['instrumentUniqueId'] as String,
      riskLevel: RiskLevel.fromString(json['riskLevel'] as String),
      score: json['score'] as int,
      reasons: (json['reasons'] as List<dynamic>).map((e) => e as String).toList(),
      previousFailuresCount: json['previousFailuresCount'] as int? ?? 0,
      consumerComplaintsCount: json['consumerComplaintsCount'] as int? ?? 0,
      daysOverdue: json['daysOverdue'] as int? ?? 0,
      hasMeasurementDiscrepancies: json['hasMeasurementDiscrepancies'] as bool? ?? false,
      assessedDate: DateTime.parse(json['assessedDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instrumentId': instrumentId,
      'instrumentUniqueId': instrumentUniqueId,
      'riskLevel': riskLevel.displayName,
      'score': score,
      'reasons': reasons,
      'previousFailuresCount': previousFailuresCount,
      'consumerComplaintsCount': consumerComplaintsCount,
      'daysOverdue': daysOverdue,
      'hasMeasurementDiscrepancies': hasMeasurementDiscrepancies,
      'assessedDate': assessedDate.toIso8601String(),
    };
  }
}
