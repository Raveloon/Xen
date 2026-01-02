import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/job_repository.dart';
import '../domain/job_model.dart';
import 'home_view_model.dart';
import '../../auth/presentation/auth_provider.dart';

class AddJobScreen extends ConsumerStatefulWidget {
  final JobModel? jobToEdit;

  const AddJobScreen({super.key, this.jobToEdit});

  @override
  ConsumerState<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends ConsumerState<AddJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _companyController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _salaryController;
  late final TextEditingController _tagsController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final job = widget.jobToEdit;
    _titleController = TextEditingController(text: job?.title ?? '');
    _companyController = TextEditingController(text: job?.company ?? '');
    _locationController = TextEditingController(text: job?.location ?? '');
    _descriptionController = TextEditingController(text: job?.description ?? '');
    _salaryController = TextEditingController(text: job?.salary.toString() ?? '');
    _tagsController = TextEditingController(text: job?.tags.join(', ') ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authNotifierProvider).asData?.value;
      if (user == null) {
        throw Exception('Oturum açmış kullanıcı bulunamadı.');
      }

      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) => e.length > 1 ? e[0].toUpperCase() + e.substring(1) : e.toUpperCase())
          .toList();

      final salary = double.tryParse(_salaryController.text) ?? 0.0;
      final isEditing = widget.jobToEdit != null;

      final jobData = JobModel(
        id: isEditing ? widget.jobToEdit!.id : '', // Keep existing ID if editing
        title: _titleController.text.trim(),
        company: _companyController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        salary: salary,
        datePosted: isEditing ? widget.jobToEdit!.datePosted : DateTime.now(),
        tags: tags,
        // Populate creator info from logged-in user if new, or preserve/backfill if editing
        creatorName: isEditing && widget.jobToEdit!.creatorName.isNotEmpty
            ? widget.jobToEdit!.creatorName
            : (user.username.isNotEmpty ? user.username : 'Anonim'),
        creatorId: isEditing && widget.jobToEdit!.creatorId.isNotEmpty
            ? widget.jobToEdit!.creatorId
            : user.id,
      );

      if (isEditing) {
        await ref.read(jobRepositoryProvider).updateJob(jobData);
      } else {
        await ref.read(jobRepositoryProvider).addJob(jobData);
      }

      // Yeni veri eklendiğinde/güncellendiğinde arayüzü tetiklemek için provider'ı geçersiz kılıp tekrar çalışmasını sağlıyoruz.
      ref.invalidate(homeViewModelProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'İlan güncellendi!' : 'İlan başarıyla eklendi!')),
        );
        context.pop(); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.jobToEdit != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'İlanı Düzenle' : 'Yeni İş İlanı Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'İş Başlığı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Şirket Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Konum',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: 'Maaş (Opsiyonel)',
                  border: OutlineInputBorder(),
                  suffixText: 'TL',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Etiketler (Virgülle ayırın)',
                  hintText: 'Flutter, Remote, Junior',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) => value!.isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitJob,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditing ? 'Değişiklikleri Kaydet' : 'İlanı Yayınla'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
