import 'package:flutter/material.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class AdminRoleElevationTab extends StatelessWidget {
  final VoidCallback onGoToUsers;

  const AdminRoleElevationTab({super.key, required this.onGoToUsers});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yetki Yükseltme Rehberi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '1. Öğrenci rolündeki kullanıcıları "Kullanıcılar" sekmesinden arayın.\n'
            '2. Kullanıcının sağındaki menüden "Başkan Yap" seçeneğine tıklayın.\n'
            '3. İlgili topluluğu seçtiğinizde kullanıcının rolü otomatik olarak "baskan" statüsüne yükseltilecektir.',
            style: TextStyle(fontSize: 14, height: 1.5, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onGoToUsers,
            icon: Icon(Icons.people),
            label: Text('Kullanıcı Listesine Git'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
