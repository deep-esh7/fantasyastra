class SettingConfigModel {
  final bool isSubscriptionActive;
  final String lastUpdated;
  final bool schedulerEnabled;
  final String startedAt;
  final String startedBy;
  final List<String> offensiveWords; // List of offensive words

  SettingConfigModel({
    required this.isSubscriptionActive,
    required this.lastUpdated,
    required this.schedulerEnabled,
    required this.startedAt,
    required this.startedBy,
    required this.offensiveWords,
  });

  // Convert a SettingConfigModel object into a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'isSubscriptionActive': isSubscriptionActive,
      'lastUpdated': lastUpdated,
      'schedulerEnabled': schedulerEnabled,
      'startedAt': startedAt,
      'startedBy': startedBy,
      'offensiveWords': offensiveWords,
    };
  }

  // Create a SettingConfigModel object from a map
  factory SettingConfigModel.fromMap(Map<String, dynamic> map) {
    return SettingConfigModel(
      isSubscriptionActive: map['isSubscriptionActive'] ?? false,
      lastUpdated: map['lastUpdated'] ?? '',
      schedulerEnabled: map['schedulerEnabled'] ?? false,
      startedAt: map['startedAt'] ?? '',
      startedBy: map['startedBy'] ?? '',
      offensiveWords: List<String>.from(map['offensiveWords'] ?? []),
    );
  }
}
