import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worshipcompanion/services/supabase_service.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:worshipcompanion/widgets/auth_provider.dart';
import 'package:worshipcompanion/widgets/app_config_provider.dart';
import 'package:worshipcompanion/utils/connectivity_guard.dart';
import 'package:worshipcompanion/utils/lyrics_format.dart';
import 'package:worshipcompanion/services/local_database_service.dart';

class AddManualSongScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialLyrics;
  final String? initialAuthor;
  const AddManualSongScreen(
      {super.key, this.initialTitle, this.initialLyrics, this.initialAuthor});

  @override
  State<AddManualSongScreen> createState() => _AddManualSongScreenState();
}

class _AddManualSongScreenState extends State<AddManualSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _englishTitleController = TextEditingController();
  final _authorController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _transLyricsController = TextEditingController();
  final _chordsController = TextEditingController();
  final _genreController = TextEditingController();
  final _keySignatureController = TextEditingController();
  final _bpmController = TextEditingController();
  final _youtubeLinkController = TextEditingController();
  final _submittedByController = TextEditingController();

  String? _selectedLanguage = 'English';
  bool _showOptional = false;

  static const _preservePaste = PreservePasteFormatter();

  @override
  void initState() {
    super.initState();
    _loadUsername();
    if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialLyrics != null && widget.initialLyrics!.isNotEmpty) {
      _lyricsController.text =
          LyricsFormat.normalizePaste(widget.initialLyrics!);
    }
    if (widget.initialAuthor != null && widget.initialAuthor!.isNotEmpty) {
      _authorController.text = widget.initialAuthor!;
    }
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    if (!mounted) return;
    setState(() => _submittedByController.text = username);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _englishTitleController.dispose();
    _authorController.dispose();
    _lyricsController.dispose();
    _transLyricsController.dispose();
    _chordsController.dispose();
    _genreController.dispose();
    _keySignatureController.dispose();
    _bpmController.dispose();
    _youtubeLinkController.dispose();
    _submittedByController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _vibrate() => HapticFeedback.lightImpact();

  Future<void> _pasteInto(TextEditingController controller) async {
    _vibrate();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty')),
      );
      return;
    }
    final normalized = LyricsFormat.normalizePaste(text);
    final existing = controller.text;
    if (existing.isEmpty) {
      controller.text = normalized;
    } else {
      final sel = controller.selection;
      if (sel.isValid) {
        final start = sel.start;
        final end = sel.end;
        controller.text =
            existing.replaceRange(start, end, normalized);
        controller.selection =
            TextSelection.collapsed(offset: start + normalized.length);
      } else {
        controller.text = '$existing\n$normalized';
      }
    }
    setState(() {});
  }

  Future<void> _submitForReview() async {
    if (!_formKey.currentState!.validate()) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }
    if (_selectedLanguage == null || _selectedLanguage!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a language')),
      );
      return;
    }

    _vibrate();
    if (!await ConnectivityGuard.ensureOnline(context,
        message: 'Adding or submitting a song needs an internet connection.',
        useDialog: true)) {
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final appConfig = Provider.of<AppConfigProvider>(context, listen: false);
    final isMaster = appConfig.isMasterUser(auth.email);

    // Preserve exact lyrics text — do not trim body content.
    final songData = <String, dynamic>{
      'title': _titleController.text.trim(),
      'english_title': _selectedLanguage != 'English'
          ? _englishTitleController.text.trim()
          : null,
      'author_name': _authorController.text.trim(),
      'lyrics': LyricsFormat.normalizePaste(_lyricsController.text),
      'trans_lyrics': (_selectedLanguage != 'English')
          ? LyricsFormat.normalizePaste(_transLyricsController.text)
          : null,
      'chords': LyricsFormat.normalizePaste(_chordsController.text),
      'language': _selectedLanguage ?? '',
      'genre': _genreController.text.trim(),
      'key_signature': _keySignatureController.text.trim(),
      'bpm': int.tryParse(_bpmController.text.trim()),
      'youtube_link': _youtubeLinkController.text.trim(),
      'submitted_by': _submittedByController.text.trim(),
      'submitted_by_user_id': auth.currentUser?.id,
      'is_reviewed': false,
      'review_notes': '',
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bool success;
      final language = (_selectedLanguage ?? '').toLowerCase();

      if (isMaster) {
        final directData = Map<String, dynamic>.from(songData)
          ..remove('submitted_by')
          ..remove('submitted_by_user_id')
          ..remove('is_reviewed')
          ..remove('review_notes');
        directData['category'] = language;

        if (language == 'english') {
          directData.remove('english_title');
          directData.remove('trans_lyrics');
          success = await SupabaseService.instance
              .addSongDirect('english_data', directData);
        } else if (language == 'kannada') {
          success = await SupabaseService.instance
              .addSongDirect('kannada_data', directData);
        } else {
          success = await SupabaseService.instance
              .addSongDirect('other_data', directData);
        }
      } else {
        success =
            await SupabaseService.instance.submitSongForReview(songData);
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        if (isMaster) {
          await LocalDatabaseService.instance.syncAllCategories(force: true);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMaster
                ? 'Song added to the library'
                : 'Song submitted for review'),
          ),
        );
        Navigator.pop(context);
        if (Navigator.canPop(context)) Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      String errorMsg = 'Failed to submit song: $e';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('Failed host lookup')) {
        errorMsg = 'Please check your internet connection and try again.';
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submission Failed'),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showLanguageDialog() {
    _vibrate();
    showDialog(
      context: context,
      builder: (context) {
        final predefinedLangs = [
          'English',
          'Kannada',
          'Hindi',
          'Tamil',
          'Malayalam',
          'Telugu'
        ];
        String tempSelected = _selectedLanguage ?? 'English';
        if (!predefinedLangs.contains(tempSelected)) {
          tempSelected = 'Other';
        }
        String otherText = (!predefinedLangs.contains(_selectedLanguage) &&
                _selectedLanguage != null)
            ? _selectedLanguage!
            : '';

        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            final colorScheme = Theme.of(context).colorScheme;
            return AlertDialog(
              title: const Text('Select Language'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...predefinedLangs.map((lang) => RadioListTile<String>(
                          title: Text(lang),
                          value: lang,
                          groupValue: tempSelected,
                          activeColor: colorScheme.primary,
                          onChanged: (val) {
                            setStateBuilder(() {
                              tempSelected = val!;
                              if (tempSelected != 'Other') otherText = '';
                            });
                          },
                        )),
                    RadioListTile<String>(
                      title: const Text('Other'),
                      value: 'Other',
                      groupValue: tempSelected,
                      activeColor: colorScheme.primary,
                      onChanged: (val) {
                        setStateBuilder(() => tempSelected = val!);
                      },
                    ),
                    if (tempSelected == 'Other')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Type language',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) =>
                              setStateBuilder(() => otherText = val),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (tempSelected == 'Other' && otherText.trim().isEmpty) {
                      return;
                    }
                    setState(() {
                      _selectedLanguage = tempSelected == 'Other'
                          ? otherText.trim()
                          : tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isEnglish = _selectedLanguage == 'English';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Add song'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _submitForReview,
            child: const Text('Submit'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              'Basics',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _field(
              controller: _titleController,
              label: 'Song title',
              icon: Icons.music_note_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _showLanguageDialog,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Language',
                  prefixIcon:
                      Icon(Icons.language_rounded, color: colorScheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(120),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedLanguage ?? 'Select language',
                        style: textTheme.bodyLarge,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded),
                  ],
                ),
              ),
            ),
            if (!isEnglish) ...[
              const SizedBox(height: 12),
              _field(
                controller: _englishTitleController,
                label: 'English / transliterated title',
                icon: Icons.translate_rounded,
              ),
            ],
            const SizedBox(height: 12),
            _field(
              controller: _authorController,
              label: 'Author / artist',
              icon: Icons.person_outline_rounded,
              hint: "Author or 'Unknown'",
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter an author' : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Lyrics',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _pasteInto(_lyricsController),
                  icon: const Icon(Icons.content_paste_rounded, size: 18),
                  label: const Text('Paste'),
                ),
              ],
            ),
            Text(
              'Spacing and line breaks are kept exactly as pasted.',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            _lyricsField(
              controller: _lyricsController,
              label: 'Lyrics',
              minLines: 12,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Paste or type lyrics' : null,
            ),
            if (!isEnglish) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Transliteration',
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _pasteInto(_transLyricsController),
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                    label: const Text('Paste'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _lyricsField(
                controller: _transLyricsController,
                label: 'Transliterated lyrics',
                minLines: 8,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Chords (optional)',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _pasteInto(_chordsController),
                  icon: const Icon(Icons.content_paste_rounded, size: 18),
                  label: const Text('Paste'),
                ),
              ],
            ),
            Text(
              'Paste chord lines aligned with lyrics. Spaces matter.',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            _lyricsField(
              controller: _chordsController,
              label: 'Chords',
              minLines: 6,
            ),
            const SizedBox(height: 20),
            ExpansionTile(
              initiallyExpanded: _showOptional,
              onExpansionChanged: (v) => setState(() => _showOptional = v),
              title: const Text('More details (optional)'),
              childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              children: [
                _field(
                  controller: _genreController,
                  label: 'Genre',
                  icon: Icons.library_music_rounded,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _keySignatureController,
                        label: 'Key',
                        icon: Icons.music_video_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        controller: _bpmController,
                        label: 'BPM',
                        icon: Icons.speed_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _youtubeLinkController,
                  label: 'YouTube link',
                  icon: Icons.link_rounded,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _submittedByController,
                  label: 'Submitted by',
                  icon: Icons.account_circle_rounded,
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitForReview,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Submit song'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(120),
      ),
    );
  }

  Widget _lyricsField({
    required TextEditingController controller,
    required String label,
    required int minLines,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      // Never auto-capitalize pasted lyrics — that destroys source casing.
      textCapitalization: TextCapitalization.none,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      minLines: minLines,
      maxLines: null,
      validator: validator,
      inputFormatters: [_preservePaste],
      style: TextStyle(
        color: colorScheme.onSurface,
        fontFamily: 'monospace',
        fontSize: 14,
        height: 1.45,
      ),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(90),
        contentPadding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      ),
    );
  }
}
