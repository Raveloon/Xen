import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../jobs/domain/job_model.dart';
import '../../jobs/presentation/home_screen.dart'; // For JobCard

class PersonalizedJobsScreen extends ConsumerStatefulWidget {
  final String? title;

  const PersonalizedJobsScreen({this.title, super.key});

  @override
  ConsumerState<PersonalizedJobsScreen> createState() =>
      _PersonalizedJobsScreenState();
}

class _PersonalizedJobsScreenState
    extends ConsumerState<PersonalizedJobsScreen> {
  List<JobModel> _jobs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPersonalizedJobs();
  }

  Future<void> _fetchPersonalizedJobs() async {
    final user = ref.read(authNotifierProvider).asData?.value;
    if (user == null) return;

    try {
      if (widget.title == 'Favoriler') {
        await _fetchFavorites(user.id);
      } else {
        await _fetchRecommendations(user);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFavorites(String userId) async {
    // 1. Get Favorite Job IDs (sorted by date)
    final favIds = await ref.read(authRepositoryProvider).getFavoriteJobIds(userId);

    if (favIds.isEmpty) {
      if (mounted) setState(() { _jobs = []; _isLoading = false; });
      return;
    }

    // 2. Fetch all jobs to find matches (Firestore limitation workaround for order)
    // For production with many jobs, use whereIn loops. For now, fetch all 50 latest or lookup one by one.
    // Looking up one by one preserves order easily.
    
    final List<JobModel> loadedJobs = [];
    
    // Fetching sequentially to maintain sort order from IDs
    for (final id in favIds) {
      final doc = await FirebaseFirestore.instance.collection('jobs').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        loadedJobs.add(JobModel.fromJson(data));
      }
    }

    if (mounted) {
      setState(() {
        _jobs = loadedJobs;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRecommendations(user) async {
    if (user.interests.isEmpty) {
      if (mounted) setState(() { _jobs = []; _isLoading = false; });
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .orderBy('datePosted', descending: true)
        .limit(50)
        .get();

    final allJobs = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return JobModel.fromJson(data);
    }).toList();

    final userInterests = user.interests.map((e) => (e as String).toLowerCase()).toSet();

    final filteredJobs = allJobs.where((job) {
      final title = job.title.toLowerCase();
      final tags = job.tags.map((t) => t.toLowerCase()).toSet();
      return userInterests.any((interest) =>
          title.contains(interest) || tags.contains(interest));
    }).toList();

    if (mounted) {
      setState(() {
        _jobs = filteredJobs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title ?? 'Önerilen İlanlar')),
        body: Center(child: Text('Hata: $_error')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Önerilen İlanlar')),
      body: _jobs.isEmpty
          ? const Center(child: Text('İlgi alanlarınıza uygun ilan bulunamadı.'))
          : ListView.builder(
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];
                final isFavorites = widget.title == 'Favoriler';
                return JobCard(
                  job: job,
                  showSalary: !isFavorites, // Show only if NOT Favorites (i.e. Recommended)
                );
              },
            ),
    );
  }
}
