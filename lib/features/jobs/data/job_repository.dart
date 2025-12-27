import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/job_model.dart';

class JobRepository {
  final FirebaseFirestore _firestore;

  JobRepository(this._firestore);

  Future<void> updateJob(JobModel job) async {
    try {
      final data = job.toJson();
      data.remove('id'); // ID is in the document reference, not the data
      
      await _firestore.collection('jobs').doc(job.id).update(data);
    } catch (e) {
      throw Exception('Failed to update job: $e');
    }
  }

  Future<void> addJob(JobModel job) async {
    try {
      // Convert JobModel to JSON, excluding 'id' as Firestore generates it
      final data = job.toJson();
      data.remove('id'); 
      
      await _firestore.collection('jobs').add(data);
    } catch (e) {
      throw Exception('Failed to add job: $e');
    }
  }

  Future<List<JobModel>> getJobs() async {
    try {
      final snapshot = await _firestore.collection('jobs').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return JobModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs: $e');
    }
  }
}

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(FirebaseFirestore.instance);
});
