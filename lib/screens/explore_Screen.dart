import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  final List<Map<String, String>> _appFeatures = const [
    {
      'title': 'Welcome Onboarding',
      'description': 'A personalized welcome experience to set up your profile.',
      'image': 'onboarding.png',
    },
    {
      'title': 'Intuitive Home Screen',
      'description': 'Your personalized hub for quick access to songs, profile, and more.',
      'image': 'homescreen.png',
    },
    {
      'title': 'Flexible Dark Mode',
      'description': 'Switch between light and dark themes, including AMOLED black for OLED screens.',
      'image': 'settings.png',
    },
    {
      'title': 'Custom Theme Colors',
      'description': 'Personalize your app\'s look with a wide range of custom seed colors.',
      'image': 'custom_theme.png',
    },
    {
      'title': 'Personal Profile',
      'description': 'Manage your username and add a profile picture.',
      'image': 'user.png',
    },
    {
      'title': 'Song Categories on Home',
      'description': 'Easily navigate through English and Kannada song collections directly from the home screen.',
      'image': 'categories.png',
    },
    {
      'title': 'Alphabetical Song Lists',
      'description': 'Browse extensive lists of English and Kannada songs, organized alphabetically for easy discovery.',
      'image': 'english-songs.png',
    },
    {
      'title': 'Detailed Song View',
      'description': 'Dive into full lyrics for every song.',
      'image': 'detail-song.png',
    },
    {
      'title': 'Chords & Transposition',
      'description': 'Toggle chords on/off and transpose them to any key instantly.',
      'image': 'chords.png',
    },
    {
      'title': 'Adjustable Text Size',
      'description': 'Customize the font size for a comfortable reading experience.',
      'image': 'song_detail_font_size.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("App Features"),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      backgroundColor: colorScheme.background,
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _appFeatures.length,
        itemBuilder: (context, index) {
          final feature = _appFeatures[index];
          return Card(
            elevation: 2.0,
            margin: const EdgeInsets.only(bottom: 16.0),
            color: colorScheme.surfaceVariant.withAlpha(200),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title']!,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature['description']!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Placeholder for the image
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        'assets/screenshots/${feature['image']!}', // Assumes screenshots are in assets/screenshots
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200, // Fixed height for placeholder
                            color: Colors.grey.shade300,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported_rounded, size: 50, color: Colors.grey.shade600),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Screenshot for "${feature['title']!}" here',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
