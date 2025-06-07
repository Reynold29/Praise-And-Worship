import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worshipcompanion/services/supabase_service.dart';
import 'package:vibration/vibration.dart';

class AddManualSongScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialLyrics;
  final String? initialAuthor;
  const AddManualSongScreen({super.key, this.initialTitle, this.initialLyrics, this.initialAuthor});

  @override
  _AddManualSongScreenState createState() => _AddManualSongScreenState();
}

class _AddManualSongScreenState extends State<AddManualSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _genreController = TextEditingController();
  final _keySignatureController = TextEditingController();
  final _bpmController = TextEditingController();
  final _youtubeLinkController = TextEditingController();
  final _reviewNotesController = TextEditingController();
  final _submittedByController = TextEditingController();
  
  String? _selectedLanguage;
  final List<String> _languages = [
    'English',
    'Kannada',
    'Hindi',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
    if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialLyrics != null && widget.initialLyrics!.isNotEmpty) {
      _lyricsController.text = widget.initialLyrics!;
    }
    if (widget.initialAuthor != null && widget.initialAuthor!.isNotEmpty) {
      _authorController.text = widget.initialAuthor!;
    }
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    setState(() {
      _submittedByController.text = username;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _lyricsController.dispose();
    _genreController.dispose();
    _keySignatureController.dispose();
    _bpmController.dispose();
    _youtubeLinkController.dispose();
    _reviewNotesController.dispose();
    _submittedByController.dispose();
    super.dispose();
  }

  void _performVibration() async {
    final bool? hasVibration = await Vibration.hasVibrator();
    if (hasVibration == true) {
      Vibration.vibrate(duration: 18, amplitude: 60);
    }
  }

  void _submitForReview() async {
    if (_formKey.currentState!.validate()) {
      _performVibration();
      final songData = {
        'title': _titleController.text,
        'author_name': _authorController.text,
        'lyrics': _lyricsController.text,
        'language': _selectedLanguage ?? '',
        'genre': _genreController.text,
        'key_signature': _keySignatureController.text,
        'bpm': int.tryParse(_bpmController.text),
        'youtube_link': _youtubeLinkController.text,
        'submitted_by': _submittedByController.text,
        'is_reviewed': false,
        'review_notes': '',
      };
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final success = await SupabaseService.instance.submitSongForReview(songData);
        Navigator.of(context).pop(); // Remove loading
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Song submitted for review!')),
          );
          Navigator.pop(context); // Pop back to options screen
          Navigator.pop(context); // Pop back to home screen (or wherever it came from before options)
        }
      } catch (e) {
        Navigator.of(context).pop(); // Remove loading
        String errorMsg = 'Failed to submit song: ';
        // Graceful handling for network errors
        if (e.toString().contains('SocketException') || e.toString().contains('ClientException') || e.toString().contains('Failed host lookup')) {
          errorMsg = 'Please check your internet connection and try again.';
        } else {
          errorMsg += e.toString();
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Submission Failed'),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () {
                  _performVibration();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Song Manually', style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.send_rounded, color: colorScheme.primary),
            onPressed: () {
              _performVibration();
              _submitForReview();
            },
            tooltip: 'Submit for Review',
          ),
        ],
      ),
      backgroundColor: colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              _buildTextField(
                controller: _titleController,
                labelText: 'Song Title',
                icon: Icons.music_note_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the song title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _authorController,
                labelText: 'Author/Artist',
                hintText: 'Enter author or \'Unknown\'',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the author or type \'Unknown\'';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lyricsController,
                labelText: 'Lyrics',
                icon: Icons.text_fields_rounded,
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the lyrics';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                items: _languages
                    .map((lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(lang),
                        ))
                    .toList(),
                onChanged: (val) {
                  _performVibration();
                  setState(() => _selectedLanguage = val);
                },
                decoration: InputDecoration(
                  labelText: 'Language',
                  prefixIcon: Icon(Icons.language_rounded, color: colorScheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withAlpha(100),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a language';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _genreController,
                labelText: 'Genre (Optional)',
                icon: Icons.library_music_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _keySignatureController,
                labelText: 'Key Signature (Optional)',
                icon: Icons.music_video_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bpmController,
                labelText: 'BPM (Optional)',
                icon: Icons.speed_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _youtubeLinkController,
                labelText: 'YouTube Link (Optional)',
                icon: Icons.link_rounded,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _submittedByController,
                labelText: 'Submitted By (Optional)',
                icon: Icons.account_circle_rounded,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded),
                label: const Text('Submit for Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  elevation: 4.0,
                  splashFactory: InkSparkle.splashFactory,
                ),
                onPressed: () {
                  _performVibration();
                  _submitForReview();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        floatingLabelStyle: TextStyle(color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withAlpha(100),
      ),
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: colorScheme.onSurfaceVariant),
      keyboardType: keyboardType,
      enabled: enabled,
      cursorColor: colorScheme.primary,
      selectionControls: MaterialTextSelectionControls(),
    );
  }
} 