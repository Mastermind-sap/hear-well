import '../../domain/entities/home_entity.dart';

class HomeModel extends HomeEntity {
  const HomeModel({required super.message});

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    return HomeModel(message: json['message'] as String);
  }
}
