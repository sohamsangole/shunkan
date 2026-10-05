import 'jlpt_level.dart';

/// User settings entity strictly isolated from user learning history.
class UserSettings {
  final JLPTLevel? jlptLevel;
  final bool onboardingCompleted;
  final bool notificationsEnabled;
  final bool lockscreenRefreshEnabled;
  final int notificationIntervalMinutes;

  const UserSettings({
    this.jlptLevel,
    this.onboardingCompleted = false,
    this.notificationsEnabled = true,
    this.lockscreenRefreshEnabled = true,
    this.notificationIntervalMinutes = 60,
  });

  UserSettings copyWith({
    JLPTLevel? jlptLevel,
    bool? onboardingCompleted,
    bool? notificationsEnabled,
    bool? lockscreenRefreshEnabled,
    int? notificationIntervalMinutes,
  }) {
    return UserSettings(
      jlptLevel: jlptLevel ?? this.jlptLevel,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lockscreenRefreshEnabled:
          lockscreenRefreshEnabled ?? this.lockscreenRefreshEnabled,
      notificationIntervalMinutes:
          notificationIntervalMinutes ?? this.notificationIntervalMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'jlptLevel': jlptLevel?.code,
    'onboardingCompleted': onboardingCompleted,
    'notificationsEnabled': notificationsEnabled,
    'lockscreenRefreshEnabled': lockscreenRefreshEnabled,
    'notificationIntervalMinutes': notificationIntervalMinutes,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      jlptLevel: JLPTLevelExtension.fromCode(json['jlptLevel'] as String?),
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      lockscreenRefreshEnabled:
          json['lockscreenRefreshEnabled'] as bool? ?? true,
      notificationIntervalMinutes:
          json['notificationIntervalMinutes'] as int? ?? 60,
    );
  }
}
