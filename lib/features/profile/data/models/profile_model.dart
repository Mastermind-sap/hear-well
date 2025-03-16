import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({required super.username});

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(username: json['username'] as String);
  }
}
