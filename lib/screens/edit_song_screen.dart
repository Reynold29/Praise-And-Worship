import 'package:material_ui/material_ui.dart';
import 'package:worshipcompanion/services/supabase_service.dart';
import 'package:worshipcompanion/services/local_database_service.dart';
import 'package:worshipcompanion/utils/app_logger.dart';
import 'package:worshipcompanion/utils/song_utils.dart';
import 'package:worshipcompanion/utils/connectivity_guard.dart';
import 'package:worshipcompanion/utils/lyrics_format.dart';

class EditSongScreen extends StatefulWidget {
  final Map<String, dynamic> tabData;
  const EditSongScreen({super.key, required this.tabData});

  @override
  State<EditSongScreen> createState() => _EditSongScreenState();
}

class _EditSongScreenState extends State<EditSongScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _englishTitleController;
  late TextEditingController _artistController;
  late TextEditingController _lyricsController;
  late TextEditingController _transLyricsController;
  late TextEditingController _chordsController;
  late TextEditingController _keyController;
  late TextEditingController _youtubeController;
  late TextEditingController _bpmController;
  late TextEditingController _genreController;

  bool _isSaving = false;
  static const _preservePaste = PreservePasteFormatter();

  @override
  void initState() {
    super.initState();
    final data = widget.tabData;
    _titleController = TextEditingController(
        text: data['original_title'] ?? data['title'] ?? '');
    _englishTitleController =
        TextEditingController(text: data['english_title'] ?? '');
    _artistController = TextEditingController(
        text: data['author_name'] ?? data['artist_name'] ?? '');
    _lyricsController = TextEditingController(
        text: LyricsFormat.normalizePaste((data['lyrics'] ?? '').toString()));
    _transLyricsController = TextEditingController(
        text: LyricsFormat.normalizePaste(
            (data['trans_lyrics'] ?? '').toString()));
    _chordsController = TextEditingController(
        text: LyricsFormat.normalizePaste((data['chords'] ?? '').toString()));
    _keyController = TextEditingController(text: data['key_signature'] ?? '');
    _youtubeController =
        TextEditingController(text: data['youtube_link'] ?? '');
    _bpmController = TextEditingController(text: data['bpm']?.toString() ?? '');
    _genreController = TextEditingController(text: data['genre'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _englishTitleController.dispose();
    _artistController.dispose();
    _lyricsController.dispose();
    _transLyricsController.dispose();
    _chordsController.dispose();
    _keyController.dispose();
    _youtubeController.dispose();
    _bpmController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (!await ConnectivityGuard.ensureOnline(context,
        message: 'Saving song edits needs an internet connection.',
        useDialog: true)) {
      return;
    }

    setState(() => _isSaving = true);

    final String songId = widget.tabData['id'].toString();
    final String category = widget.tabData['category'] as String;

    final updatedData = {
      'title': _titleController.text.trim(),
      'english_title': _englishTitleController.text.trim(),
      'author_name': _artistController.text.trim(),
      'lyrics': LyricsFormat.normalizePaste(_lyricsController.text),
      'trans_lyrics': _transLyricsController.text.isEmpty
          ? null
          : LyricsFormat.normalizePaste(_transLyricsController.text),
      'chords': LyricsFormat.normalizePaste(_chordsController.text),
      'key_signature': _keyController.text.trim(),
      'youtube_link': _youtubeController.text.trim(),
      'bpm': int.tryParse(_bpmController.text.trim()),
      'genre': _genreController.text.trim(),
    };

    String tableName = category;
    if (!tableName.endsWith('_data')) {
      if (tableName == 'english')
        tableName = 'english_data';
      else if (tableName == 'kannada')
        tableName = 'kannada_data';
      else
        tableName = 'other_data';
    }

    // english_data doesn't have english_title or trans_lyrics
    if (tableName == 'english_data') {
      updatedData.remove('english_title');
      updatedData.remove('trans_lyrics');
    }

    try {
      // 1. Update Cloud (Supabase)
      await SupabaseService.instance.updateSong(tableName, songId, updatedData);

      // 2. Update Local Cache
      await LocalDatabaseService.instance.updateLocalSong(tableName, {
        'id': songId,
        ...updatedData,
      });

      if (mounted) {
        // Prepare data to return to SongDetailScreen
        final returnData = Map<String, dynamic>.from(widget.tabData);
        returnData.addAll(updatedData);

        // Also re-parse lines for UI refresh
        returnData['lines'] = SongUtils.parseLyricsToLines(
            updatedData['lyrics'] as String, updatedData['chords'] as String);
        if (updatedData['trans_lyrics'] != null) {
          returnData['trans_lines'] = SongUtils.parseLyricsToLines(
              updatedData['trans_lyrics'] as String,
              updatedData['chords'] as String);
        } else {
          returnData['trans_lines'] = null;
        }
        returnData['artist_name'] =
            updatedData['author_name']; // ensure consistency

        Navigator.pop(context, returnData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song updated successfully!')),
        );
      }
    } catch (e) {
      AppLogger.e('EditSong', 'Failed to save changes', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Song Details'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _saveChanges,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionHeader('Basic Information', colorScheme),
              _buildTextField(
                controller: _titleController,
                label: 'Original Title',
                hint: 'e.g. Hosanna',
                validator: (v) => v!.isEmpty ? 'Title is required' : null,
              ),
              _buildTextField(
                controller: _englishTitleController,
                label: 'English Title',
                hint: 'Optional English translation',
              ),
              _buildTextField(
                controller: _artistController,
                label: 'Artist / Author',
                hint: 'e.g. Hillsong Worship',
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Lyrics & Chords', colorScheme),
              Text(
                'Spacing and line breaks are kept exactly as pasted.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _lyricsController,
                label: 'Lyrics (UTF-8)',
                hint: 'Paste lyrics here...',
                maxLines: 8,
                preservePaste: true,
                validator: (v) => v!.isEmpty ? 'Lyrics are required' : null,
              ),
              _buildTextField(
                controller: _chordsController,
                label: 'Chords (Dot notation)',
                hint: 'e.g. .G ... .C',
                maxLines: 4,
                preservePaste: true,
              ),
              _buildTextField(
                controller: _transLyricsController,
                label: 'Transliterated Lyrics (Optional)',
                hint: 'Latin script version...',
                maxLines: 6,
                preservePaste: true,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Music Data', colorScheme),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _keyController,
                      label: 'Original Key',
                      hint: 'e.g. G',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _bpmController,
                      label: 'BPM',
                      hint: 'e.g. 72',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              _buildTextField(
                controller: _genreController,
                label: 'Genre / Theme',
                hint: 'e.g. Praise, Adoration',
              ),
              _buildTextField(
                controller: _youtubeController,
                label: 'YouTube Link',
                hint: 'https://youtube.com/watch?v=...',
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: const Icon(Icons.cloud_upload_rounded),
                label:
                    Text(_isSaving ? 'Saving Changes...' : 'Save & Sync Cloud'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool preservePaste = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
        textInputAction:
            maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        textCapitalization: preservePaste
            ? TextCapitalization.none
            : TextCapitalization.sentences,
        style: preservePaste
            ? const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.45,
              )
            : null,
        inputFormatters: preservePaste ? const [_preservePaste] : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor:
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        ),
      ),
    );
  }
}
