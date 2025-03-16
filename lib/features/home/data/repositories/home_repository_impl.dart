import '../../domain/repositories/home_repository.dart';
import '../../domain/entities/home_entity.dart';
import '../models/home_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  @override
  Future<HomeEntity> fetchHomeData() async {
    final homeJson = {'message': 'Hello from Home'};
    return HomeModel.fromJson(homeJson);
  }
}
