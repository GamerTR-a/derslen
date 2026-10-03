import 'package:flutter/material.dart';
import '../../../core/services/supabase_data_service.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'request';
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (_formKey.currentState!.validate()) {
      final subject = _subjectController.text.trim();
      final description = _descriptionController.text.trim();

      if (subject.isEmpty || description.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lütfen konu ve açıklama alanlarını eksiksiz doldurun.'),
            backgroundColor: context.colors.danger,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        await SupabaseDataService.createTicket(
          type: _selectedType,
          subject: subject.length > 150 ? subject.substring(0, 150) : subject,
          description: description.length > 3000 ? description.substring(0, 3000) : description,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Talebiniz başarıyla yönetime iletildi!'),
              backgroundColor: context.colors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().contains('Günlük talep')
                  ? 'Günlük talep sınırına ulaştın. Yarın tekrar deneyebilirsin.'
                  : 'Talep iletilirken bir sorun oluştu. Lütfen tekrar deneyin.'),
              backgroundColor: context.colors.danger,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Talep / Şikayet Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Konu Türü',
                style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.primary, width: 2),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'request', child: Text('Talep / İstek')),
                  DropdownMenuItem(value: 'complaint', child: Text('Şikayet')),
                  DropdownMenuItem(value: 'suggestion', child: Text('Öneri')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 20),

              Text(
                'Başlık',
                style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                maxLength: 150,
                decoration: InputDecoration(
                  hintText: 'Kısaca konuyu özetleyin',
                  filled: true,
                  fillColor: context.colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Lütfen bir başlık girin.';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Text(
                'Açıklama ve Detaylar',
                style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                maxLength: 3000,
                decoration: InputDecoration(
                  hintText: 'Detaylı bilgi veya mesajınızı yazın...',
                  filled: true,
                  fillColor: context.colors.surface,
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Lütfen açıklama yazın.';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: context.colors.onPrimary, strokeWidth: 2),
                        )
                      : Text(
                          'Talebi Gönder',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
