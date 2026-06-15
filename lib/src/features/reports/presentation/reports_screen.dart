import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/backup/backup_service.dart';
import '../../register/data/stock_register_repository.dart';
import '../../register/presentation/spreadsheet_editor.dart';
import '../data/export_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registers = ref.watch(stockRegistersProvider(const RegisterQuery(limit: 500)));
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Sheet')),
      body: registers.when(
        data: (rows) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _save(context, ExportService().exportXlsx(rows)),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('XLSX'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _save(context, ExportService().exportPdf(rows)),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ReportTile(
              icon: Icons.today_outlined,
              title: 'Daily Report',
              subtitle: 'Export today\'s stock movement as PDF',
              onTap: () {
                final now = DateTime.now();
                final filtered = rows.where((row) =>
                    row.entryDate.year == now.year &&
                    row.entryDate.month == now.month &&
                    row.entryDate.day == now.day);
                _save(context, ExportService().exportPdf(filtered.toList()));
              },
            ),
            _ReportTile(
              icon: Icons.calendar_month_outlined,
              title: 'Monthly Inventory Report',
              subtitle: 'Export this month in traditional register layout',
              onTap: () {
                final now = DateTime.now();
                final filtered = rows.where((row) =>
                    row.entryDate.year == now.year &&
                    row.entryDate.month == now.month);
                _save(context, ExportService().exportXlsx(filtered.toList()));
              },
            ),
            _ReportTile(
              icon: Icons.backup_outlined,
              title: 'Backup & Restore',
              subtitle: 'Download server backup or restore stock rows from JSON',
              onTap: () => _backupDialog(context),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 520,
              child: SpreadsheetEditor(
                rows: rows,
                onAdd: () => context.go('/registers/new'),
                onEdit: (row) => context.go('/registers/${row.id}'),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Future<void> _save(BuildContext context, Future<File> future) async {
    try {
      final file = await future;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: ${file.path}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $error')),
      );
    }
  }

  Future<void> _backupDialog(BuildContext context) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Backup & Restore',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                final file = await BackupService().createBackendSnapshot();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Backup saved: ${file.path}')),
                  );
                }
              },
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download Backup'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Paste backup JSON to restore stock rows',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await BackupService().restoreFromJson(controller.text);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.restore),
              label: const Text('Restore Backup'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
