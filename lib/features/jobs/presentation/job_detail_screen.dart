import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/job_repository.dart';
import '../domain/job_model.dart';
import '../../auth/data/auth_repository.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final JobModel job;
  final bool showSalary;

  const JobDetailScreen({
    super.key,
    required this.job,
    required this.showSalary,
  });

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  // Logic moved to StreamBuilder, no local state needed.

  Future<void> _showApplicationSheet(BuildContext context, JobModel job, String userId) async {
    // ... (rest of the function)
    // Debug Logs requested by user
    debugPrint('Gelen Job ID: ${job.id}');
    debugPrint('Job İçindeki Owner Name: ${job.creatorName}');
    debugPrint('Job İçindeki Owner ID: ${job.creatorId}');

    String targetOwnerId = job.creatorId;

    if (targetOwnerId.isEmpty) {
      debugPrint('Owner ID is empty, attempting fallback lookup by name: ${job.creatorName}');
      try {
        final foundId = await ref
            .read(authRepositoryProvider)
            .findUserIdByUsername(job.creatorName);
        
        if (foundId != null) {
          targetOwnerId = foundId;
          debugPrint('Fallback successful. Found Owner ID: $targetOwnerId');
        } else {
          debugPrint('Fallback failed. User not found by name.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hata: İlan sahibi veritabanında bulunamadı (${job.creatorName})')),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('Fallback error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hata: İlan sahibi sorgulanırken sorun oluştu.')),
          );
        }
        return;
      }
    }

    if (!mounted) return;

    final priceController = TextEditingController();
    final durationController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'İlana Başvur',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (targetOwnerId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'İlan Sahibi ID: $targetOwnerId',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),

                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ücret Beklentisi (TL)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Lütfen bir ücret girin';
                    if (double.tryParse(value) == null) return 'Geçerli bir sayı girin';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Teslim Süresi (Opsiyonel)',
                    hintText: 'Örn: 3 Gün, 1 Hafta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama / Not',
                    hintText: 'Neden sizi seçmeliyiz?',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Lütfen bir açıklama yazın' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    print("Butona tıklandı! (Modal Gönder)");
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context); // Close modal first
                      
                      try {
                        print("Başvuru gönderiliyor...");
                        await ref.read(jobRepositoryProvider).applyToJob(
                          jobId: job.id,
                          applicantId: userId,
                          jobOwnerId: targetOwnerId,
                          price: double.parse(priceController.text),
                          duration: durationController.text,
                          description: descController.text,
                        );
                        print("Başvuru başarılı!");

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Başvurunuz başarıyla gönderildi!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        print("HATA OLUŞTU: $e");
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Hata: $e')),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Gönder',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').doc(widget.job.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(), body: Center(child: Text('Bir hata oluştu: ${snapshot.error}')));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
           return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('İlan bulunamadı veya silinmiş.')));
        }

        // Parse Live Data
        final data = snapshot.data!.data() as Map<String, dynamic>;
        data['id'] = snapshot.data!.id;
        final liveJob = JobModel.fromJson(data);

        final authState = ref.watch(authNotifierProvider);
        final user = authState.asData?.value;
        final isEmre = user?.username == 'emre';

        // Intersection Logic
        final isMatch = user != null &&
            user.interests.any((interest) => liveJob.tags
                .any((tag) => tag.toLowerCase() == interest.toLowerCase()));
        
        return Scaffold(
          appBar: AppBar(title: Text(liveJob.title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  liveJob.company,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${liveJob.location} • ${liveJob.datePosted.toString().split(' ')[0]} • ${liveJob.creatorName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                
                if (isMatch) ...[
                  const SizedBox(height: 16),
                  _buildSalarySection(context, liveJob),
                ],

                const SizedBox(height: 24),
                Text(
                  'İş Tanımı',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(liveJob.description),
                const SizedBox(height: 24),
                Text(
                  'Etiketler',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: liveJob.tags
                      .map((tag) => Chip(label: Text(tag)))
                      .toList(),
                ),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
          bottomNavigationBar: isMatch && user != null
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SafeArea(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('applications')
                          .where('jobId', isEqualTo: liveJob.id)
                          .where('applicantId', isEqualTo: user.id)
                          .snapshots(),
                      builder: (context, appSnapshot) {
                        if (appSnapshot.hasData) {
                          debugPrint('Application Stream Update: ${appSnapshot.data!.docs.length} docs found.');
                        }
                        if (appSnapshot.hasError) {
                          debugPrint('Application Stream Error: ${appSnapshot.error}');
                        }

                        final bool isLoading = appSnapshot.connectionState == ConnectionState.waiting;
                        final bool hasApplied = appSnapshot.hasData && appSnapshot.data!.docs.isNotEmpty;

                        return ElevatedButton(
                          onPressed: () {
                            print("Butona tıklandı! (Ana Ekran)");
                            if (hasApplied || isLoading) return;
                            _showApplicationSheet(context, liveJob, user.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasApplied ? Colors.grey : Colors.black,
                            disabledBackgroundColor: Colors.grey,
                            disabledForegroundColor: Colors.white,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  hasApplied ? 'Zaten Başvurdun' : 'İlana Başvur',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        );
                      },
                    ),
                  ),
                )
              : null,
          floatingActionButton: isEmre
              ? FloatingActionButton.extended(
                  onPressed: () {
                    context.push('/edit_job', extra: liveJob);
                  },
                  label: const Text('Düzenle'),
                  icon: const Icon(Icons.edit),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                )
              : null,
        );
      },
    );
  }

  Widget _buildSalarySection(BuildContext context, JobModel job) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            'Maaş: ₺${job.salary.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
