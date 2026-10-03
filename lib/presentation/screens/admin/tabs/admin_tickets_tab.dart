import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/supabase_data_service.dart';
import '../../../../data/models/user_ticket.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class AdminTicketsTab extends StatefulWidget {
  const AdminTicketsTab({super.key});

  @override
  State<AdminTicketsTab> createState() => _AdminTicketsTabState();
}

class _AdminTicketsTabState extends State<AdminTicketsTab> {
  List<UserTicket> _tickets = [];
  bool _isLoading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final tickets = await SupabaseDataService.getAllTickets(statusFilter: _statusFilter);
      if (mounted) setState(() => _tickets = tickets);
    } catch (e) {
      if (kDebugMode) debugPrint('AdminTicketsTab: talepler yüklenemedi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Talepler yüklenirken bir hata oluştu.'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _setFilter(String filter) {
    setState(() => _statusFilter = filter);
    _load();
  }

  Future<void> _showUpdateTicketDialog(UserTicket ticket) async {
    final messenger = ScaffoldMessenger.of(context);
    String selectedStatus = ticket.status;
    final notesController = TextEditingController(text: ticket.adminNotes ?? '');

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Talep Yanıtla #${ticket.id.substring(0, 6)}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Konu: ${ticket.subject}', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Açıklama: ${ticket.description}'),
                    const SizedBox(height: 16),
                    Text('Durum:', style: TextStyle(fontWeight: FontWeight.w600)),
                    DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'open', child: Text('Açık')),
                        DropdownMenuItem(value: 'in_progress', child: Text('İşlemde')),
                        DropdownMenuItem(value: 'resolved', child: Text('Çözüldü')),
                        DropdownMenuItem(value: 'closed', child: Text('Kapalı')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedStatus = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Admin Notu / Yanıt:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Kullanıcıya bildirmek istediğiniz notu yazın...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
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
                      await SupabaseDataService.updateTicketStatus(
                        ticketId: ticket.id,
                        status: selectedStatus,
                        adminNotes: notesController.text.trim(),
                      );
                      messenger.showSnackBar(
                        SnackBar(content: Text('Talep durumu güncellendi.')),
                      );
                      _load();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: const Text('Talep güncellenemedi. Lütfen tekrar dene.')),
                      );
                    }
                  },
                  child: Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
    notesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: Text('Tümü'),
                selected: _statusFilter == 'all',
                onSelected: (_) => _setFilter('all'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Açık'),
                selected: _statusFilter == 'open',
                onSelected: (_) => _setFilter('open'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('İşlemde'),
                selected: _statusFilter == 'in_progress',
                onSelected: (_) => _setFilter('in_progress'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Çözüldü'),
                selected: _statusFilter == 'resolved',
                onSelected: (_) => _setFilter('resolved'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tickets.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];
                    return ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(ticket.subject, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${ticket.typeLabel} • Durum: ${ticket.statusLabel}'),
                      trailing: ElevatedButton(
                        onPressed: () => _showUpdateTicketDialog(ticket),
                        child: Text('Yanıtla'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
