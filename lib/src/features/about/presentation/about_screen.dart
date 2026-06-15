import 'package:flutter/material.dart';

import '../../../core/widgets/brand_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: BrandLogo(size: 84)),
          const SizedBox(height: 18),
          Text(
            'Deepu Manager',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A professional stock register and inventory management app for digital register workflows.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const _InfoTile(
            icon: Icons.person_outline,
            title: 'Created By',
            subtitle: 'Aayan Parmar',
          ),
          const _InfoTile(
            icon: Icons.verified_outlined,
            title: 'Version',
            subtitle: '1.0.5',
          ),
          const _InfoTile(
            icon: Icons.security_outlined,
            title: 'Data Model',
            subtitle: 'VPS-backed authentication, stock data, audit logs, backup, and admin control.',
          ),
          const _InfoTile(
            icon: Icons.favorite_border,
            title: 'Credits',
            subtitle: 'Designed for clean, simple, and reliable stock register management.',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
