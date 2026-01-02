import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_model.dart';

class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  bool _isLoading = false; // This might become less relevant with async providers, but keeping for now.

  // Local set for optimistic UI updates for user's selected interests
  Set<String>? _optimisticInterests;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Refresh user data silently (no loading spinner) to ensure we have the latest
      // interests from Firestore without triggering router redirects.
      ref.read(authNotifierProvider.notifier).refreshUser();
      ref.invalidate(globalTagsProvider);
    });
  }

  // Admin Global Actions
  Future<void> _addGlobalTag(String tag) async {
    try {
      await ref.read(authRepositoryProvider).addGlobalTag(tag);
      ref.invalidate(globalTagsProvider); // Invalidate to refetch global tags
      if (mounted) {
        Navigator.pop(context); // Pop the dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Global etiket eklendi: $tag')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _removeGlobalTag(String tag) async {
    try {
      await ref.read(authRepositoryProvider).removeGlobalTag(tag);
      ref.invalidate(globalTagsProvider); // Invalidate to refetch global tags
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Global etiket silindi: $tag')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  void _showAddGlobalTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Global Etiket Ekle (Admin)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Örn: Docker'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addGlobalTag(controller.text.trim());
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  // Helper for toggle with optimistic update logic
  Future<void> _toggleInterestAction(String tag, bool isSelected) async {
    final user = ref.read(authNotifierProvider).asData?.value;
    if (user == null) return;

    // Update optimistic state immediately for UI feedback
    setState(() {
       _optimisticInterests ??= user.interests.toSet(); // Initialize if null
       if (isSelected) {
         _optimisticInterests!.add(tag);
       } else {
         _optimisticInterests!.remove(tag);
       }
    });

    try {
      if (isSelected) {
        await ref.read(authRepositoryProvider).addInterest(user.id, tag);
      } else {
        await ref.read(authRepositoryProvider).removeInterest(user.id, tag);
      }
      
      // Update global user state silently to match DB
      await ref.read(authNotifierProvider.notifier).refreshUser();
      
      // No explicit ref.invalidate(authNotifierProvider) to avoid potential router issues.
      // The optimistic update handles immediate UI feedback.
      // The actual user object will eventually reflect changes on next app load or background sync.
    } catch (e) {
      // Revert optimistic state on error
      setState(() {
         if (isSelected) {
           _optimisticInterests!.remove(tag);
         } else {
           _optimisticInterests!.add(tag);
         }
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('İşlem başarısız: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final globalTagsAsync = ref.watch(globalTagsProvider);
    
    final user = authState.asData?.value;
    final isAdmin = user?.isAdmin ?? false;

    // Determine the user's currently selected interests for display
    // Prioritize _optimisticInterests if available, otherwise use user.interests
    final userInterests = _optimisticInterests ?? user?.interests.toSet() ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlgi Alanları'),
        // Removed the save button as interests are now toggled individually
      ),
      body: globalTagsAsync.when(
        data: (globalTags) {
          // Display only the global tags.
          // If a user has a tag not in globalTags, it won't be shown here for selection.
          // This aligns with "tüm kullanıcılar bu ortak havuzu görsün"
          final displayTags = List<String>.from(globalTags);

          if (displayTags.isEmpty) {
            return const Center(child: Text('Henüz etiket eklenmemiş.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isAdmin)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Admin Modu: Havuza etiket ekle/sil.',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: displayTags.map((tag) {
                  final isSelected = userInterests.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) async {
                      await _toggleInterestAction(tag, selected);
                    },
                    // Admin deletes GLOBAL tag
                    deleteIcon: isAdmin ? const Icon(Icons.close, size: 18) : null,
                    onDeleted: isAdmin ? () => _removeGlobalTag(tag) : null,
                  );
                }).toList(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Hata: $e')),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showAddGlobalTagDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
