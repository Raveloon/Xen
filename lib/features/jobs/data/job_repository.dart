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
      data['updatedAt'] = FieldValue.serverTimestamp(); // Güncelleme zamanı
      
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
      // Performans için sıralama DB seviyesinde yapıldı.
      final snapshot = await _firestore
          .collection('jobs')
          .orderBy('datePosted', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return JobModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs: $e');
    }
  }

  Future<JobModel?> getJob(String jobId) async {
    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return JobModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch job: $e');
    }
  }
  Future<void> deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
    } catch (e) {
      throw Exception('Failed to delete job: $e');
    }
  }

  // --- Application System ---

  Future<void> applyToJob({
    required String jobId,
    required String applicantId,
    required String jobOwnerId,
    required double price,
    String? duration,
    required String description,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Create Application
      final appRef = _firestore.collection('applications').doc();
      batch.set(appRef, {
        'jobId': jobId,
        'applicantId': applicantId,
        'jobOwnerId': jobOwnerId,
        'price': price,
        'duration': duration,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Create Notification for Job Owner
      final notifRef = _firestore.collection('notifications').doc();
      batch.set(notifRef, {
        'receiverId': jobOwnerId,
        'senderId': applicantId,
        'message': 'İlanınıza yeni bir başvuru yapıldı!', // Or fetch user name
        'isRead': false,
        'type': 'job_application',
        'relatedId': jobId,
        'applicationId': appRef.id, // Link to Application explicitly
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print("✅ Başvuru veritabanına kaydedildi. Doc ID: ${appRef.id}"); // Validation Log
    } catch (e) {
      throw Exception('Failed to apply for job: $e');
    }
  }

  Future<bool> checkIfApplied(String jobId, String applicantId) async {
    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('applicantId', isEqualTo: applicantId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check application status: $e');
    }
  }

  // --- Notification System ---

  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        // .orderBy('timestamp', descending: true) // TODO: Enable this after creating Firestore Index
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<Map<String, dynamic>?> getApplicationDetails(String applicationId) async {
    try {
      final doc = await _firestore.collection('applications').doc(applicationId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to fetch application details: $e');
    }
  }
}

final notificationsStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return ref.watch(jobRepositoryProvider).getUserNotifications(userId);
});

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(FirebaseFirestore.instance);
});
