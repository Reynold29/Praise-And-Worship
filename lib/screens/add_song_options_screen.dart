import 'package:flutter/material.dart';
import 'package:worshipcompanion/screens/add_manual_song_screen.dart'; // TODO: Create AddManualSongScreen
import 'package:vibration/vibration.dart';

class AddSongOptionsScreen extends StatelessWidget {
  const AddSongOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add a New Song', style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      backgroundColor: colorScheme.background,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildOptionCard(
            context: context,
            icon: Icons.document_scanner_outlined,
            title: 'Scan Song from Image',
            subtitle: 'Automatically extract lyrics and chords from a picture.',
            onTap: () {
              // TODO: Implement Scan Song functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan Song from Image - Coming Soon!')),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context: context,
            icon: Icons.edit_note_rounded,
            title: 'Add Lyrics Manually',
            subtitle: 'Type or paste lyrics and optionally add chords.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddManualSongScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context: context,
            icon: Icons.search_rounded,
            title: 'Search Online & Add',
            subtitle: 'Find songs from online resources to add to your companion.',
            onTap: () {
              // TODO: Implement Search Online functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search Online & Add - Coming Soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      color: colorScheme.surfaceVariant.withAlpha(200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () async {
          final bool? hasVibration = await Vibration.hasVibrator();
          if (hasVibration == true) {
            Vibration.vibrate(duration: 18, amplitude: 60);
          }
          onTap();
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 36, color: colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
} 