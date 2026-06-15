import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../data/admin_repository.dart';

final adminBundleProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return (
    users: await repo.users(),
    requests: await repo.requests(),
    logs: await repo.auditLogs(),
  );
});

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(adminBundleProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Create user',
            onPressed: () => _createUser(context, ref),
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          IconButton(
            tooltip: 'Download all data',
            onPressed: () => _downloadAllData(context, ref),
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: bundle.when(
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(
              title: 'Access Requests',
              trailing: '${data.requests.length} pending',
            ),
            if (data.requests.isEmpty)
              const _EmptyLine('No pending access requests'),
            for (final request in data.requests)
              Card(
                child: ListTile(
                  title: Text(request['name'].toString()),
                  subtitle: Text(request['email'].toString()),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Approve',
                        onPressed: () async {
                          await ref.read(adminRepositoryProvider).approveRequest(request);
                          ref.invalidate(adminBundleProvider);
                        },
                        icon: const Icon(Icons.check_circle_outline),
                      ),
                      IconButton(
                        tooltip: 'Deny',
                        onPressed: () async {
                          await ref.read(adminRepositoryProvider).denyRequest(request['id'].toString());
                          ref.invalidate(adminBundleProvider);
                        },
                        icon: const Icon(Icons.cancel_outlined),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
            _Header(title: 'Users', trailing: '${data.users.length} total'),
            for (final user in data.users)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(_initial(user['name'])),
                  ),
                  title: Text(user['name'].toString()),
                  subtitle: Text(
                    '${user['email']}\n${user['role']} | ${user['status']} | ${user['mobile'] ?? 'No mobile'}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Delete user',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: user['role'] == 'admin'
                        ? null
                        : () async {
                            await ref.read(adminRepositoryProvider).deleteUser(user['id'].toString());
                            ref.invalidate(adminBundleProvider);
                          },
                  ),
                ),
              ),
            const SizedBox(height: 18),
            const _Header(title: 'Audit Logs', trailing: 'Latest 500'),
            for (final log in data.logs)
              Card(
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.history),
                  title: Text('${log['user_email'] ?? 'Unknown user'} ${log['action']}'),
                  subtitle: Text(
                    '${log['entity']} ${log['entity_id'] ?? ''}\n${_date(log['created_at'])}',
                  ),
                  isThreeLine: true,
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Future<void> _createUser(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final age = TextEditingController();
    final mobile = TextEditingController();
    String role = 'staff';
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 8),
                TextField(controller: age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age')),
                const SizedBox(height: 8),
                TextField(controller: mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  items: const [
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) => setState(() => role = value ?? 'staff'),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                await ref.read(adminRepositoryProvider).createUser(
                      name: name.text,
                      email: email.text,
                      password: password.text,
                      role: role,
                      age: int.tryParse(age.text),
                      mobile: mobile.text,
                    );
                ref.invalidate(adminBundleProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAllData(BuildContext context, WidgetRef ref) async {
    final data = await ref.read(adminRepositoryProvider).backup();
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/Deepu_Manager_Admin_Backup_$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data), flush: true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Admin data saved: ${file.path}')),
    );
  }

  String _date(Object? value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return DateFormat.yMMMd().add_jm().format(date.toLocal());
  }

  String _initial(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'U' : text[0].toUpperCase();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Chip(label: Text(trailing)),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
