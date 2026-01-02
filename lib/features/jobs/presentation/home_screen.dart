import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/job_repository.dart';
import 'home_view_model.dart';
import '../domain/job_model.dart';
import '../../auth/domain/user_model.dart';

import 'package:image_picker/image_picker.dart';
import '../../auth/data/auth_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _selectedFilter = 'Tümü';
  bool _isHovering = false;
  bool _isUploading = false;
  
  // Temporary simulation list. Change to [] to test empty state.
  final List<String> _notifications = [
    // 'Emre ilan paylaştı', 
    // 'Başvurunuz görüntülendi'
  ];

  Future<void> _pickAndUploadImage(String userId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // Check size (Max 2MB)
    final bytes = await image.readAsBytes();
    if (bytes.lengthInBytes > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya boyutu çok yüksek (Max 2MB)')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      await ref.read(authRepositoryProvider).uploadProfileImage(image, userId);
      // Force refresh user data
      ref.invalidate(authNotifierProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil resmi güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... existing build ...
    final authState = ref.watch(authNotifierProvider);
    final jobsAsync = ref.watch(filteredJobsProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, authState),
      // ... existing body ...
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilter(ref),
            const SizedBox(height: 16),
            Expanded(
              child: jobsAsync.when(
                data: (jobs) {
                  if (jobs.isEmpty) return _buildEmptyState();
                  return RefreshIndicator(
                    onRefresh: () => ref.read(homeViewModelProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: jobs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return JobCard(job: jobs[index]);
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Hata: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ((authState.asData?.value as UserModel?)?.isAdmin ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/add_job'),
              label: const Text('İş Ekle'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }


  Widget _buildHeader() {
    final user = ref.watch(authNotifierProvider).asData?.value;
    final notificationsAsync = user != null 
        ? ref.watch(notificationsStreamProvider(user.id))
        : const AsyncValue<List<Map<String, dynamic>>>.loading();

    if (user != null) {
      debugPrint('HomeScreen Current User ID: ${user.id}');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const Text(
            'Xen',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          Row(
            children: [
              notificationsAsync.when(
                data: (notifications) {
                   debugPrint('Bildirim Stream Gelen Veri Sayısı: ${notifications.length}');
                   if(notifications.isNotEmpty) {
                     debugPrint('İlk Bildirim ReceiverId: ${notifications.first['receiverId']}');
                   }
                   return PopupMenuButton<Map<String, dynamic>>(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined),
                        if (notifications.any((n) => n['isRead'] == false))
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) {
                      if (notifications.isEmpty) {
                        return [
                          const PopupMenuItem(
                            enabled: false,
                            child: Text('Hiç bildirim yok', style: TextStyle(color: Colors.grey)),
                          ),
                        ];
                      }
                      return notifications.map((n) {
                        return PopupMenuItem(
                          value: n,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['message'] ?? 'Bildirim', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                (n['timestamp'] as Timestamp?)?.toDate().toString().substring(0, 16) ?? '',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    onSelected: (notification) {
                      if (notification['type'] == 'job_application' && notification['applicationId'] != null) {
                        _showNotificationDetail(context, notification['applicationId']);
                      }
                    },
                  );
                },
                loading: () => const IconButton(
                  icon: Icon(Icons.notifications_none, color: Colors.grey),
                  onPressed: null,
                ),
                error: (err, stack) => IconButton(
                  icon: const Icon(Icons.error_outline, color: Colors.red),
                  onPressed: () {
                     debugPrint('Notification Error: $err');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showNotificationDetail(BuildContext context, String applicationId) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final jobRepo = ref.read(jobRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);

      // 1. Fetch Application Details
      final application = await jobRepo.getApplicationDetails(applicationId);
      
      if (application == null) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Başvuru detayları bulunamadı.')),
          );
        }
        return;
      }

      // 2. Fetch Linked Job and User Data
      final jobId = application['jobId'];
      final applicantId = application['applicantId'];

      final job = await jobRepo.getJob(jobId);
      final applicant = await authRepo.getUser(applicantId);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      // 3. Show Rich Dialog
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // --- Mini Job Card ---
                   if (job != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100, // Background color as requested
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.business, color: Colors.black),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  job.company,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Text('İlan bilgisine ulaşılamadı', style: TextStyle(color: Colors.red)),

                  const SizedBox(height: 24),
                  
                  // --- Applicant Info Header ---
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: (applicant?.photoUrl != null && applicant!.photoUrl!.isNotEmpty)
                            ? NetworkImage(applicant.photoUrl!)
                            : null,
                        child: (applicant?.photoUrl == null || applicant!.photoUrl!.isEmpty)
                            ? Text(
                                (applicant?.username ?? '?').substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (applicant?.fullName != null && applicant!.fullName!.isNotEmpty)
                                  ? applicant!.fullName!
                                  : (applicant?.username ?? 'Bilinmeyen Kullanıcı'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Başvuran',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // --- Offer Details & Duration ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Teklif Edilen Ücret', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '₺${(application['price'] as num).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                          ),
                        ],
                      ),
                      // Duration Info Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            const Text(
                              'Süre: ',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              application['duration'] ?? 'Belirtilmedi',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- Description ---
                   Text('Açıklama / Not', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                   const SizedBox(height: 8),
                   Container(
                     padding: const EdgeInsets.all(16),
                     constraints: const BoxConstraints(maxHeight: 180),
                     decoration: BoxDecoration(
                       color: Colors.grey.shade50,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: Colors.grey.shade200),
                     ),
                     child: SingleChildScrollView(
                       child: Text(
                         application['description'] ?? '',
                         style: const TextStyle(height: 1.5, fontSize: 14),
                       ),
                     ),
                   ),

                  const SizedBox(height: 32),

                  // --- Actions ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white, // Text color
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Kapat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

    } catch (e) {
      if (context.mounted) {
         Navigator.pop(context); // Close loading if active
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Detaylar yüklenirken hata oluştu: $e')),
         );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildSearchAndFilter(WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: 56, // h-14
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).set(value);
              },
              decoration: const InputDecoration(
                hintText: 'Pozisyon veya şirket ara...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Horizontal Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildFilterChip('Tümü', selectedCategory == 'Tümü'),
              const SizedBox(width: 8),
              _buildFilterChip('Uzaktan', selectedCategory == 'Uzaktan'),
              const SizedBox(width: 8),
              _buildFilterChip('Junior', selectedCategory == 'Junior'),
              const SizedBox(width: 8),
              _buildFilterChip('Senior', selectedCategory == 'Senior'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return InkWell(
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).set(label);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Sonuç Bulunamadı',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Filtreleri değiştirmeyi deneyin.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AsyncValue<dynamic> authState) {
    final user = authState.asData?.value as UserModel?;
    final photoUrl = user?.photoUrl; // Assuming UserModel has photoUrl?

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              (user?.username ?? 'MİSAFİR').toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            accountEmail: null,
            currentAccountPicture: MouseRegion(
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: InkWell(
                onTap: user == null ? null : () => _pickAndUploadImage(user.id),
                child: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 36, // Default size for header is often 72x72 total (36 radius)
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? Text(
                              (user?.username ?? 'M').substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                            )
                          : null,
                    ),
                    if (_isHovering && !_isUploading)
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            Text('Düzenle', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                    if (_isUploading)
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            decoration: const BoxDecoration(color: Colors.black),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Ana Sayfa'),
            onTap: () {
              context.pop(); // Close drawer
              final currentPath = GoRouterState.of(context).uri.path;
              if (currentPath == '/home' || currentPath == '/') {
                ref.invalidate(homeViewModelProvider);
              } else {
                context.go('/home');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.interests_outlined),
            title: const Text('İlgi Alanlarım'),
            onTap: () {
              context.pop(); // Close drawer
              context.push('/interests');
            },
          ),
          ListTile(
            leading: const Icon(Icons.recommend_outlined),
            title: const Text('Sana Özel İlanlar'),
            onTap: () => context.push('/personalized'),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Favoriler'),
            onTap: () => context.push('/favorites'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}

class JobCard extends ConsumerWidget {
  final JobModel job;
  final bool showSalary;

  const JobCard({
    super.key,
    required this.job,
    this.showSalary = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).asData?.value;
    final hasMatchingTag = user != null &&
        user.interests.any((interest) =>
            job.tags.any((tag) => tag.toLowerCase() == interest.toLowerCase()));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias, // Ensures button respects corners
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content height
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.push('/detail', extra: {'job': job, 'showSalary': showSalary});
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Logo + Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.business, color: Colors.black),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                job.company,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              if (showSalary) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '₺${job.salary.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final user = ref.watch(authNotifierProvider).asData?.value;
                            if (user == null) return const SizedBox.shrink();

                            final isFavorited = user.favoriteIds.contains(job.id);

                            return IconButton(
                              icon: Icon(
                                isFavorited ? Icons.favorite : Icons.favorite_border,
                                color: isFavorited ? Colors.red : Colors.grey,
                              ),
                              onPressed: () async {
                                final repo = ref.read(authRepositoryProvider);
                                try {
                                  if (isFavorited) {
                                    await repo.removeFavorite(user.id, job.id);
                                  } else {
                                    await repo.addFavorite(user.id, job.id);
                                  }
                                  // Silent refresh to update UI w/o reload
                                  ref.read(authNotifierProvider.notifier).refreshUser();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Hata: $e')),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: job.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),
                    
                    // Footer
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${job.location} • ${job.creatorName}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(job.datePosted),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                        if (job.isEdited)
                          Text(
                            ' (Düzenlendi)',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),

                    if ((ref.watch(authNotifierProvider).asData?.value as UserModel?)?.isAdmin ?? false) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
                            tooltip: 'Düzenle',
                            onPressed: () {
                              context.push('/add_job', extra: job);
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                            tooltip: 'Sil',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Emin misiniz?'),
                                  content: const Text('Bu ilanı silmek istediğinize emin misiniz?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('İptal'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        try {
                                          await ref.read(jobRepositoryProvider).deleteJob(job.id);
                                          ref.invalidate(homeViewModelProvider);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('İlan silindi')),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Hata: $e')),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text('Sil', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (hasMatchingTag)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.black,
              child: const Text(
                'Profilinle Eşleşiyor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}g önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s önce';
    } else {
      return 'Yeni';
    }
  }
}
