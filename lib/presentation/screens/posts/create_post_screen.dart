import 'package:flutter/material.dart';
import '../../../core/services/supabase_data_service.dart';
import '../../../data/models/community.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  List<Community> _communities = [];
  Community? _selectedCommunity;
  bool _isLoadingCommunities = true;
  bool _isSubmitting = false;
  String _tur = '';

  static const List<(String, String)> _turler = [
    ('', 'Genel'),
    ('#soru', 'Soru'),
    ('#rutin', 'Çalışma rutini'),
    ('#koçarıyorum', 'Koç arıyorum'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    try {
      final list = await SupabaseDataService.getCommunities();
      if (mounted) {
        setState(() {
          _communities = list;
          if (list.isNotEmpty) _selectedCommunity = list.first;
          _isLoadingCommunities = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCommunities = false);
    }
  }

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        await SupabaseDataService.createPost(
          content: _tur.isEmpty || _contentController.text.contains(_tur)
              ? _contentController.text
              : '$_tur ${_contentController.text.trim()}',
          communityId: _selectedCommunity?.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gönderi başarıyla paylaşıldı!'),
              backgroundColor: context.colors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: context.colors.danger,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Yeni Gönderi Paylaş', style: TextStyle(fontWeight: FontWeight.bold)),
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
                'Topluluk Seçin',
                style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary),
              ),
              const SizedBox(height: 8),
              _isLoadingCommunities
                  ? const LinearProgressIndicator()
                  : DropdownButtonFormField<Community>(
                      initialValue: _selectedCommunity,
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
                      items: _communities.map((comm) {
                        return DropdownMenuItem<Community>(
                          value: comm,
                          child: Text(comm.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCommunity = val);
                      },
                    ),
              const SizedBox(height: 20),

              Text(
                'Gönderi Türü',
                style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (etiket, ad) in _turler)
                    ChoiceChip(
                      label: Text(ad),
                      selected: _tur == etiket,
                      onSelected: (_) => setState(() => _tur = etiket),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Gönderi İçeriği',
                style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 6,
                maxLength: 5000,
                decoration: InputDecoration(
                  hintText: 'Duyuru, tavsiye veya çalışma materyalini paylaşın...',
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
                  if (val == null || val.trim().isEmpty) return 'Gönderi içeriği boş kalamaz.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: context.colors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Telefon, adres, okul adı gibi kişisel bilgilerini paylaşma. Kurallara aykırı gönderiler şikâyet üzerine gizlenir.',
                      style: TextStyle(fontSize: 12, color: context.colors.textMuted, height: 1.35),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: context.colors.onPrimary, strokeWidth: 2),
                        )
                      : Text(
                          'Gönderiyi Yayınla',
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
