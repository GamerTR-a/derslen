import 'package:flutter/material.dart';
import '../../../core/services/supabase_data_service.dart';
import '../../../data/models/user_ticket.dart';
import 'create_ticket_screen.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  late Future<List<UserTicket>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _ticketsFuture = SupabaseDataService.getUserTickets();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress':
        return context.colors.warning;
      case 'resolved':
        return context.colors.success;
      case 'closed':
        return const Color(0xFF6B7280);
      case 'open':
      default:
        return context.colors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Taleplerim & Şikayetlerim', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
          );
          _refresh();
        },
        backgroundColor: context.colors.primary,
        icon: Icon(Icons.add, color: context.colors.onPrimary),
        label: Text('Yeni Talep', style: TextStyle(color: context.colors.onPrimary, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<UserTicket>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Talepler yüklenirken hata oluştu: ${snapshot.error}'),
            );
          }
          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: context.colors.textMuted),
                  const SizedBox(height: 16),
                  Text('Henüz oluşturulmuş bir talebiniz yok.', style: TextStyle(color: context.colors.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
                      );
                      _refresh();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary),
                    child: Text('İlk Talebini Oluştur', style: TextStyle(color: context.colors.onPrimary)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final statusColor = _getStatusColor(ticket.status);
              return Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ticket.typeLabel,
                            style: TextStyle(
                              color: context.colors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ticket.statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ticket.subject,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticket.description,
                      style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
                    ),
                    if (ticket.adminNotes != null && ticket.adminNotes!.isNotEmpty) ...[
                      Divider(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yönetim Yanıtı / Notu:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ticket.adminNotes!,
                              style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
