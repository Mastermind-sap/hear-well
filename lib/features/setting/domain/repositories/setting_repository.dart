import '../entities/setting_entity.dart';

abstract class SettingRepository {
  Future<SettingEntity> fetchSettings();
}
