import 'package:flutter/material.dart';
import 'package:stopwatch/widgets/animated_stopwatch.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutView extends StatelessWidget {
  static const _githubHandle = 'github.com/azevedo1z';
  static const _githubUrl = 'https://$_githubHandle';

  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AnimatedStopwatch(elapsed: Duration.zero),
              const SizedBox(height: 32),
              Text(
                'Stopwatch',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'v 2.1',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Developed by',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _openGithub(ScaffoldMessenger.of(context)),
                child: Text(
                  _githubHandle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _VersionChip(label: 'v1', date: '07/2023', theme: theme),
                  const SizedBox(width: 12),
                  _VersionChip(label: 'v2', date: '02/2025', theme: theme),
                  const SizedBox(width: 12),
                  _VersionChip(label: 'v2.1', date: '03/2026', theme: theme)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGithub(ScaffoldMessengerState messenger) async {
    final launched = await launchUrl(
      Uri.parse(_githubUrl),
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open $_githubUrl')),
      );
    }
  }
}

class _VersionChip extends StatelessWidget {
  final String label;
  final String date;
  final ThemeData theme;

  const _VersionChip({
    required this.label,
    required this.date,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $date',
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
