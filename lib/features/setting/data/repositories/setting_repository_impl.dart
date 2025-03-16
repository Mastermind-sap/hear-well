import '../../domain/repositories/setting_repository.dart';
import '../../domain/entities/setting_entity.dart';
import '../models/setting_model.dart';

class SettingRepositoryImpl implements SettingRepository {
  @override
  Future<SettingEntity> fetchSettings() async {
    final settingsJson = {'notificationsEnabled': true};
    return SettingModel.fromJson(settingsJson);
  }
}
