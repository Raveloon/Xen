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

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  
  void set(String value) => state = value;
}

final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, String>(SelectedCategoryNotifier.new);

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'Tümü';
  
  void set(String value) => state = value;
}

final filteredJobsProvider = Provider<AsyncValue<List<JobModel>>>((ref) {
  final jobsAsync = ref.watch(homeViewModelProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final category = ref.watch(selectedCategoryProvider);

  return jobsAsync.whenData((jobs) {
    // 1. Text Search Filter
    List<JobModel> filtered = jobs;
    if (query.isNotEmpty) {
      filtered = filtered.where((job) {
        return job.title.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Category Filter
    if (category != 'Tümü') {
      filtered = filtered.where((job) {
        if (category == 'Uzaktan') {
          return job.location.toLowerCase().contains('remote') || 
                 job.location.toLowerCase().contains('uzaktan') ||
                 job.tags.any((t) => t.toLowerCase().contains('remote') || t.toLowerCase().contains('uzaktan'));
        } else if (category == 'Junior') {
          return job.title.toLowerCase().contains('junior') || 
                 job.tags.any((t) => t.toLowerCase().contains('junior'));
        } else if (category == 'Senior') {
          return job.title.toLowerCase().contains('senior') || 
                 job.tags.any((t) => t.toLowerCase().contains('senior'));
        }
        return true;
      }).toList();
    }
    
    return filtered;
  });
});
