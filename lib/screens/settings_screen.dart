import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:playermusic1/providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Music Player',
      applicationVersion: '1.0.1',
      applicationIcon: const Icon(Icons.music_note, size: 50),
      applicationLegalese: '© 2025 Music Player. All rights reserved.',
      children: const [
        SizedBox(height: 10),
        Text('A beautiful music player app for your favorite tunes.'),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Change app theme'),
            leading: const Icon(Icons.color_lens_outlined),
            trailing: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(),
              ),
            ),
            onTap: () {
              final themeProvider = Provider.of<ThemeProvider>(
                context,
                listen: false,
              );
              themeProvider.toggleTheme();
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Music player version 1.0.1'),
            leading: const Icon(Icons.info_outline),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }
}
