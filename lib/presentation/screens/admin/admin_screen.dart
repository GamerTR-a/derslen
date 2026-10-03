import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tabs/admin_stats_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'tabs/admin_tickets_tab.dart';
import 'tabs/admin_communities_tab.dart';
import 'tabs/admin_role_elevation_tab.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAuthorized = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _checkAdminRouteGuard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Katı Admin Route Guard Kontrolü
  Future<void> _checkAdminRouteGuard() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .single();

      final role = profile['role'] as String?;
      if (role != 'admin') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bu ekrana erişim yetkiniz bulunmamaktadır.'),
              backgroundColor: context.colors.danger,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isAuthorized = true;
          _isCheckingAuth = false;
        });
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthorized) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('DersNet Admin Paneli', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.colors.textMuted,
          indicatorColor: context.colors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'İstatistikler'),
            Tab(icon: Icon(Icons.people), text: 'Kullanıcılar'),
            Tab(icon: Icon(Icons.support_agent), text: 'Talepler'),
            Tab(icon: Icon(Icons.groups), text: 'Topluluklar'),
            Tab(icon: Icon(Icons.verified_user), text: 'Yetki Yükseltme'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const AdminStatsTab(),
          const AdminUsersTab(),
          const AdminTicketsTab(),
          const AdminCommunitiesTab(),
          AdminRoleElevationTab(onGoToUsers: () => _tabController.animateTo(1)),
        ],
      ),
    );
  }
}
