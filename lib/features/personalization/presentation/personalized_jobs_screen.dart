import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../jobs/domain/job_model.dart';
// For JobCard

class PersonalizedJobsScreen extends ConsumerStatefulWidget {
  const PersonalizedJobsScreen({super.key});

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
    if (user == null || user.interests.isEmpty) {
      setState(() {
        _isLoading = false;
        _jobs = [];
      });
      return;
    }

    try {
      // Workaround for Firestore limit of 10 items in 'array-contains-any'
      final queryTags = user.interests.take(10).toList();

      final snapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('tags', arrayContainsAny: queryTags)
          .get();

      final jobs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return JobModel.fromJson(data);
      }).toList();

      if (mounted) {
        setState(() {
          _jobs = jobs;
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Önerilen İlanlar')),
        body: Center(child: Text('Hata: $_error')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Önerilen İlanlar')),
      body: _jobs.isEmpty
          ? const Center(child: Text('İlgi alanlarınıza uygun ilan bulunamadı.'))
          : ListView.builder(
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];
                // Override onTap to pass showSalary: true
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(job.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.company),
                        Text(
                            '${job.location} • ${job.datePosted.toString().split(' ')[0]}'),
                      ],
                    ),
                    onTap: () {
                      context.push('/detail',
                          extra: {'job': job, 'showSalary': true});
                    },
                  ),
                );
              },
            ),
    );
  }
}
