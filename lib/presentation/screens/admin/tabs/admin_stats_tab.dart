import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/supabase_data_service.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class AdminStatsTab extends StatefulWidget {
  const AdminStatsTab({super.key});

  @override
  State<AdminStatsTab> createState() => _AdminStatsTabState();
}

class _AdminStatsTabState extends State<AdminStatsTab> {
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final stats = await SupabaseDataService.getAdminDashboardStats();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      if (kDebugMode) debugPrint('AdminStatsTab: istatistikler yüklenemedi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İstatistikler yüklenirken bir hata oluştu.'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StatCard(title: 'Toplam Kullanıcı', count: _stats['users'] ?? 0, color: Colors.blue),
          const SizedBox(height: 12),
          _StatCard(title: 'Toplam Gönderi', count: _stats['posts'] ?? 0, color: Colors.purple),
          const SizedBox(height: 12),
          _StatCard(title: 'Toplam Talep', count: _stats['tickets'] ?? 0, color: Colors.orange),
          const SizedBox(height: 12),
          _StatCard(title: 'Açık Talepler', count: _stats['open_tickets'] ?? 0, color: Colors.red),
          const SizedBox(height: 12),
          _StatCard(title: 'Aktif Topluluklar', count: _stats['communities'] ?? 0, color: Colors.green),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _StatCard({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
