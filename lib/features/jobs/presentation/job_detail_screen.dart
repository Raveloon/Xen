import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/job_model.dart';

class JobDetailScreen extends ConsumerWidget {
  final JobModel job;
  final bool showSalary;

  const JobDetailScreen({
    super.key,
    required this.job,
    required this.showSalary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isEmre = authState.asData?.value?.username == 'emre';

    return Scaffold(
      appBar: AppBar(title: Text(job.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.company,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${job.location} • ${job.datePosted.toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            _buildSalarySection(context),
            const SizedBox(height: 24),
            Text(
              'İş Tanımı',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(job.description),
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
              children: job.tags
                  .map((tag) => Chip(label: Text(tag)))
                  .toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: isEmre
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/edit_job', extra: job);
              },
              label: const Text('Düzenle'),
              icon: const Icon(Icons.edit),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildSalarySection(BuildContext context) {
    if (showSalary) {
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
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          children: [
            const Icon(Icons.money_off, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Maaş Bilgisi Gizli',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      );
    }
  }
}
