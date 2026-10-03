import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yks_kocu/core/theme/theme_extensions.dart';

/// Gizlilik politikasını (assets/legal/privacy_policy.md) uygulama içinden,
/// harici bir bağlantıya veya WebView'e ihtiyaç duymadan gösterir.
/// Mağaza gereksinimi: gizlilik politikası uygulama içinden erişilebilir olmalı.
class GizlilikPolitikasiScreen extends StatelessWidget {
  const GizlilikPolitikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: const Text('Gizlilik Politikası')),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/legal/privacy_policy.md'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildBody(context, snapshot.data!),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, String markdown) {
    final lines = markdown.split('\n');
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line.substring(2),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            line.substring(3),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
          ),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            line.substring(4),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.colors.textSecondary),
          ),
        ));
      } else if (line.startsWith('- ') || RegExp(r'^\d+\.\s').hasMatch(line)) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            '•  ${line.replaceFirst(RegExp(r'^(-\s|\d+\.\s)'), '')}',
            style: TextStyle(fontSize: 13.5, color: context.colors.textSecondary, height: 1.4),
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line,
            style: TextStyle(fontSize: 13.5, color: context.colors.textSecondary, height: 1.4),
          ),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}
