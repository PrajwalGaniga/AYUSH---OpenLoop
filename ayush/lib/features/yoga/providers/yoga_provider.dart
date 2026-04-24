import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/yoga_repository.dart';
import '../models/asana.dart';

final yogaRepositoryProvider = Provider<YogaRepository>((ref) {
  return YogaRepository(ref.watch(dioClientProvider));
});

final asanasProvider = FutureProvider<List<Asana>>((ref) async {
  final repo = ref.watch(yogaRepositoryProvider);
  return repo.fetchAsanas();
});
