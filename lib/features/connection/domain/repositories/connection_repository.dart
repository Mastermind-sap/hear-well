import '../entities/connection_entity.dart';

abstract class ConnectionRepository {
  Future<ConnectionEntity> fetchHomeData();
}
