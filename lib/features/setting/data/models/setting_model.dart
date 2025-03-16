import '../../domain/entities/setting_entity.dart';

class SettingModel extends SettingEntity {
  const SettingModel({required super.notificationsEnabled});

  factory SettingModel.fromJson(Map<String, dynamic> json) {
    return SettingModel(
      notificationsEnabled: json['notificationsEnabled'] as bool,
    );
  }
}
