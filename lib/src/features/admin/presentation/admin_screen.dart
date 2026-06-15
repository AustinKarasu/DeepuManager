import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      appBar: AppBar(title: const Text('Admin Control')),
      body: bundle.when(
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Access Requests', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
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
            Text('Users', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            for (final user in data.users)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(user['name'].toString()),
                  subtitle: Text('${user['email']} • ${user['role']} • ${user['status']}'),
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
            Text('Audit Logs', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            for (final log in data.logs)
              ListTile(
                dense: true,
                leading: const Icon(Icons.history),
                title: Text('${log['action']} ${log['entity']}'),
                subtitle: Text(log['created_at'].toString()),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}
