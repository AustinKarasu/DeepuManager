import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';

class RequestAccessScreen extends ConsumerStatefulWidget {
  const RequestAccessScreen({super.key});

  @override
  ConsumerState<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends ConsumerState<RequestAccessScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _reason = TextEditingController();
  bool _saved = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Access')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(
                  controller: _reason,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(_saving ? 'Submitting...' : 'Submit Request'),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Back to Login'),
                ),
                if (_saved)
                  const Text(
                    'Request submitted. Open the app later to see if admin approved or denied it.',
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).requestAccess(
            email: _email.text,
            name: _name.text,
            reason: _reason.text,
          );
      if (!mounted) return;
      setState(() {
        _saved = true;
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}
