import '../../domain/entities/connection_entity.dart';

class ConnectionModel extends ConnectionEntity {
  const ConnectionModel({required super.message});

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(message: json['message'] as String);
  }
}
