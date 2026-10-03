/// profil_sos_tab.dart için sade, kendi kendine yeten (self-contained) kartlar.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class YasalBilgilendirmeCard extends StatelessWidget {
  const YasalBilgilendirmeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Text(
            'Yasal Bilgilendirme & Resmi Kaynaklar',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'DersNet, MEB veya ÖSYM ile resmi bağı bulunmayan bağımsız bir çalışma takip uygulamasıdır. Konu listeleri MEB müfredatı ve ÖSYM sınav kapsamı esas alınarak hazırlanmıştır; soru ve kart içerikleri DersNet tarafından özgün olarak yazılmıştır.',
            style: TextStyle(fontSize: 11, color: context.colors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.push('/gizlilik-politikasi'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
            child: Text(
              'Gizlilik Politikasını Görüntüle',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
