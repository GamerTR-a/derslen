import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/supabase_data_service.dart';
import '../../../../data/models/auth_user.dart';
import '../../../../data/models/community.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  List<LiseAuthUser> _users = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String query = ''}) async {
    setState(() => _isLoading = true);
    try {
      final users = await SupabaseDataService.getAllUsers(query: query);
      if (mounted) setState(() => _users = users);
    } catch (e) {
      if (kDebugMode) debugPrint('AdminUsersTab: kullanıcılar yüklenemedi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcılar yüklenirken bir hata oluştu.'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _showAssignChairmanDialog(LiseAuthUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    List<Community> communities;
    try {
      communities = await SupabaseDataService.getCommunities();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: const Text('Topluluklar yüklenemedi. Bağlantını kontrol et.')));
      return;
    }
    if (communities.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text('Atama yapılabilecek topluluk bulunamadı.')),
      );
      return;
    }
    if (!mounted) return;

    Community selectedComm = communities.first;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${user.name} - Başkan Atama'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lütfen başkan olarak atamak istediğiniz topluluğu seçin:'),
                  const SizedBox(height: 16),
                  DropdownButton<Community>(
                    value: selectedComm,
                    isExpanded: true,
                    items: communities.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedComm = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    try {
                      await SupabaseDataService.assignChairman(
                        userId: user.id,
                        userName: user.name,
                        communityId: selectedComm.id,
                      );
                      messenger.showSnackBar(
                        SnackBar(content: Text('${user.name}, ${selectedComm.name} başkanı atandı.')),
                      );
                      _load(query: _searchController.text);
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: const Text('Atama başarısız. Yetkini ve bağlantını kontrol et.')),
                      );
                    }
                  },
                  child: Text('Başkan Yap'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateRole(LiseAuthUser user, String role) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SupabaseDataService.updateUserRole(userId: user.id, role: role);
      _load(query: _searchController.text);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: const Text('Rol güncellenemedi. Yetkini ve bağlantını kontrol et.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Kullanıcı adı ile ara...',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: context.colors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) => _load(query: val),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _users.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEEF2FF),
                        child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U'),
                      ),
                      title: Text(user.name, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Rol: ${user.role} | Sınıf: ${user.grade ?? "Belirtilmemiş"}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'baskan') {
                            _showAssignChairmanDialog(user);
                          } else if (val == 'admin') {
                            _updateRole(user, 'admin');
                          } else if (val == 'student') {
                            _updateRole(user, 'student');
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'baskan', child: Text('Başkan Yap')),
                          const PopupMenuItem(value: 'admin', child: Text('Admin Yap')),
                          const PopupMenuItem(value: 'student', child: Text('Öğrenci Yap')),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
