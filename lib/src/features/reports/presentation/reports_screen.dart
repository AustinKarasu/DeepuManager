import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../register/data/stock_register_repository.dart';
import '../../register/presentation/spreadsheet_editor.dart';
import '../data/export_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registers = ref.watch(stockRegistersProvider(const RegisterQuery(limit: 500)));
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: registers.when(
        data: (rows) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final file = await ExportService().exportXlsx(rows);
                      await Share.shareXFiles([XFile(file.path)]);
                    },
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('XLSX Export'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final file = await ExportService().exportPdf(rows);
                      await Share.shareXFiles([XFile(file.path)]);
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF Export'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.today_outlined),
                title: const Text('Daily Report'),
                subtitle: const Text('Printable stock movement report'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Monthly Inventory Report'),
                subtitle: const Text('Traditional stock register layout'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('Backup & Restore'),
                subtitle: const Text('Manual backup, restore, and auto-backup daily'),
                trailing: Switch(value: true, onChanged: (_) {}),
              ),
            ),
            const SizedBox(height: 16),
            Text('In-app Sheet Editor', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SizedBox(height: 420, child: SpreadsheetEditor(rows: rows)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}
