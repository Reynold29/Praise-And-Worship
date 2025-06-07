import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AboutDeveloper extends StatelessWidget {
  const AboutDeveloper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Developer'),
      ),
      body: Center( 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container( 
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: AssetImage('assets/profile.png'),
                  fit: BoxFit.cover, 
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.6),
                    spreadRadius: 6,
                    blurRadius: 14,
                    offset: const Offset(0, 6), 
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 18),
            const Text(
              "Hey There, \nI'm Reynold Preetham!  👋🏼",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'plusJakartaSans'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            const Text(
              "I'𝘮 a Tech Support Engineer, with a passion for Cybersec, Software and Flutter Development.",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.github),
                  onPressed: () => _launchURL('https://github.com/Reynold29', context),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.telegram),
                  onPressed: () => _launchURL('https://t.me/Reynold29', context), 
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.circleUser),
                  onPressed: () => _launchURL('https://portfolio-reynold29.vercel.app/', context), 
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.globe),
                  onPressed: () => _launchURL('https://projects.reyziehomelab.com/linkfree/index.html', context), 
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      // Always try in-app webview first for a more integrated experience
      final bool launchedInApp = await launchUrl(uri, mode: LaunchMode.inAppWebView);
      
      if (!launchedInApp) {
        // If in-app webview failed, try external application as a fallback
        final bool launchedExternally = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launchedExternally) {
          // Both attempts failed
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to launch URL externally: $url'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while launching URL: $url - $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
} 