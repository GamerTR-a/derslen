import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/supabase_data_service.dart';
import '../../../../data/models/community.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class AdminCommunitiesTab extends StatefulWidget {
  const AdminCommunitiesTab({super.key});

  @override
  State<AdminCommunitiesTab> createState() => _AdminCommunitiesTabState();
}

class _AdminCommunitiesTabState extends State<AdminCommunitiesTab> {
  List<Community> _communities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final communities = await SupabaseDataService.getCommunities();
      if (mounted) setState(() => _communities = communities);
    } catch (e) {
      if (kDebugMode) debugPrint('AdminCommunitiesTab: topluluklar yüklenemedi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Topluluklar yüklenirken bir hata oluştu.'),
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
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _communities.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final comm = _communities[index];
          return ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: CircleAvatar(child: Icon(Icons.group)),
            title: Text(comm.name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Başkan: ${comm.chairmanName ?? "Atanmamış"} | Üye: ${comm.memberCount}'),
          );
        },
      ),
    );
  }
}
