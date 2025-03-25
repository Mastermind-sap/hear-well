import '../../domain/repositories/profile_repository.dart';
import '../../domain/entities/profile_entity.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  @override
  Future<ProfileEntity> getProfile() async {
    final profileJson = {'username': 'HearWellUser'};
    return ProfileModel.fromJson(profileJson);
  }
}
