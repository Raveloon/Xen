import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/job_repository.dart';
import '../domain/job_model.dart';

class HomeViewModel extends AsyncNotifier<List<JobModel>> {
  @override
  FutureOr<List<JobModel>> build() async {
    return _fetchJobs();
  }

  Future<List<JobModel>> _fetchJobs() {
    return ref.read(jobRepositoryProvider).getJobs();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchJobs());
  }
}

final homeViewModelProvider = AsyncNotifierProvider<HomeViewModel, List<JobModel>>(() {
  return HomeViewModel();
});
