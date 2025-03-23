import '../../domain/repositories/connection_repository.dart';
import '../../domain/entities/connection_entity.dart';
import '../models/connection_model.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  @override
  Future<ConnectionEntity> fetchHomeData() async {
    final homeJson = {'message': 'Hello from Home'};
    return ConnectionModel.fromJson(homeJson);
  }
}
