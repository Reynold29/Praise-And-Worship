import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:worshipcompanion/services/local_database_service.dart';
import 'package:worshipcompanion/services/supabase_service.dart';
import 'package:worshipcompanion/utils/connectivity_guard.dart';
import 'package:worshipcompanion/utils/lyrics_format.dart';
import 'package:worshipcompanion/widgets/app_config_provider.dart';
import 'package:worshipcompanion/widgets/auth_provider.dart';
import 'package:worshipcompanion/widgets/snappy_transitions.dart';

/// Master-only hub: pending reviews, lyric correction, app config, sync.
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final config = context.watch<AppConfigProvider>();
    final isMaster = config.isMasterUser(auth.email);
    final colorScheme = Theme.of(context).colorScheme;

    if (!isMaster) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(child: Text('Master access required.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin controls')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Signed in as ${auth.email ?? 'unknown'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _ModuleCard(
            icon: Icons.pending_actions_rounded,
            title: 'Pending reviews',
            subtitle: 'Approve, reject, and correct submitted songs',
            color: colorScheme.primaryContainer,
            onColor: colorScheme.onPrimaryContainer,
            onTap: () {
              Navigator.push(
                context,
                snappyPageRoute(page: const _PendingReviewsModule()),
              );
            },
          ),
          _ModuleCard(
            icon: Icons.tune_rounded,
            title: 'App config',
            subtitle: 'Toggle login, QR base URL, domains, master emails',
            color: colorScheme.secondaryContainer,
            onColor: colorScheme.onSecondaryContainer,
            onTap: () {
              Navigator.push(
                context,
                snappyPageRoute(page: const _AppConfigModule()),
              );
            },
          ),
          _ModuleCard(
            icon: Icons.cloud_sync_rounded,
            title: 'Library sync',
            subtitle: 'Force re-download of English, Kannada, Other caches',
            color: colorScheme.tertiaryContainer,
            onColor: colorScheme.onTertiaryContainer,
            onTap: () {
              Navigator.push(
                context,
                snappyPageRoute(page: const _LibrarySyncModule()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                foregroundColor: onColor,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pending reviews ───────────────────────────────────────────────────────────

class _PendingReviewsModule extends StatefulWidget {
  const _PendingReviewsModule();

  @override
  State<_PendingReviewsModule> createState() => _PendingReviewsModuleState();
}

class _PendingReviewsModuleState extends State<_PendingReviewsModule> {
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    if (!await ConnectivityGuard.ensureOnline(context,
        message: 'Pending reviews need internet.', useDialog: true)) {
      setState(() {
        _loading = false;
        _error = 'Offline';
      });
      return;
    }
    try {
      final rows = await SupabaseService.instance.fetchPendingSongs();
      if (!mounted) return;
      setState(() {
        _pending = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _approve(Map<String, dynamic> song) async {
    final id = song['id']?.toString();
    if (id == null) return;
    if (!await ConnectivityGuard.ensureOnline(context)) return;
    try {
      await SupabaseService.instance.approvePendingSong(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved "${song['title'] ?? 'song'}"')),
      );
      await LocalDatabaseService.instance.syncAllCategories(force: true);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approve failed: $e')),
      );
    }
  }

  Future<void> _reject(Map<String, dynamic> song) async {
    final id = song['id']?.toString();
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject song?'),
        content: Text(
            'Delete "${song['title'] ?? 'this submission'}" from the queue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reject')),
        ],
      ),
    );
    if (confirm != true) return;
    if (!await ConnectivityGuard.ensureOnline(context)) return;
    try {
      await SupabaseService.instance.rejectPendingSong(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission rejected')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending reviews'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _pending.isEmpty
                  ? Center(
                      child: Text('No pending songs',
                          style:
                              TextStyle(color: colorScheme.onSurfaceVariant)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: _pending.length,
                      itemBuilder: (context, i) {
                        final song = _pending[i];
                        final title =
                            (song['title'] ?? 'Untitled').toString();
                        final lang = (song['language'] ??
                                song['category'] ??
                                '')
                            .toString();
                        final author =
                            (song['author_name'] ?? '').toString();
                        final by = (song['submitted_by'] ?? '').toString();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (lang.isNotEmpty) lang,
                                    if (author.isNotEmpty) author,
                                    if (by.isNotEmpty) 'by $by',
                                  ].join(' · '),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        final updated =
                                            await Navigator.push<bool>(
                                          context,
                                          snappyPageRoute(
                                            page: _PendingEditScreen(
                                                song: Map<String, dynamic>.from(
                                                    song)),
                                          ),
                                        );
                                        if (updated == true) await _load();
                                      },
                                      child: const Text('Edit lyrics'),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => _reject(song),
                                      child: Text('Reject',
                                          style: TextStyle(
                                              color: colorScheme.error)),
                                    ),
                                    const SizedBox(width: 4),
                                    FilledButton(
                                      onPressed: () => _approve(song),
                                      child: const Text('Approve'),
                                    ),
                                  ],
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

class _PendingEditScreen extends StatefulWidget {
  final Map<String, dynamic> song;
  const _PendingEditScreen({required this.song});

  @override
  State<_PendingEditScreen> createState() => _PendingEditScreenState();
}

class _PendingEditScreenState extends State<_PendingEditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _englishTitle;
  late final TextEditingController _author;
  late final TextEditingController _lyrics;
  late final TextEditingController _trans;
  late final TextEditingController _chords;
  late final TextEditingController _language;
  late final TextEditingController _notes;
  bool _saving = false;
  static const _preservePaste = PreservePasteFormatter();

  @override
  void initState() {
    super.initState();
    final s = widget.song;
    _title = TextEditingController(text: (s['title'] ?? '').toString());
    _englishTitle =
        TextEditingController(text: (s['english_title'] ?? '').toString());
    _author =
        TextEditingController(text: (s['author_name'] ?? '').toString());
    _lyrics = TextEditingController(
        text: LyricsFormat.normalizePaste((s['lyrics'] ?? '').toString()));
    _trans = TextEditingController(
        text:
            LyricsFormat.normalizePaste((s['trans_lyrics'] ?? '').toString()));
    _chords = TextEditingController(
        text: LyricsFormat.normalizePaste((s['chords'] ?? '').toString()));
    _language = TextEditingController(
        text: (s['language'] ?? s['category'] ?? '').toString());
    _notes =
        TextEditingController(text: (s['review_notes'] ?? '').toString());
  }

  @override
  void dispose() {
    _title.dispose();
    _englishTitle.dispose();
    _author.dispose();
    _lyrics.dispose();
    _trans.dispose();
    _chords.dispose();
    _language.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save({bool approveAfter = false}) async {
    final id = widget.song['id']?.toString();
    if (id == null) return;
    if (!await ConnectivityGuard.ensureOnline(context,
        message: 'Saving needs internet.', useDialog: true)) {
      return;
    }
    setState(() => _saving = true);
    try {
      await SupabaseService.instance.updatePendingSong(id, {
        'title': _title.text.trim(),
        'english_title': _englishTitle.text.trim().isEmpty
            ? null
            : _englishTitle.text.trim(),
        'author_name': _author.text.trim(),
        'lyrics': LyricsFormat.normalizePaste(_lyrics.text),
        'trans_lyrics':
            _trans.text.isEmpty ? null : LyricsFormat.normalizePaste(_trans.text),
        'chords': LyricsFormat.normalizePaste(_chords.text),
        'language': _language.text.trim(),
        'review_notes': _notes.text.trim(),
      });
      if (approveAfter) {
        await SupabaseService.instance.approvePendingSong(id);
        await LocalDatabaseService.instance.syncAllCategories(force: true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approveAfter
              ? 'Corrected and approved'
              : 'Pending song updated'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correct lyrics'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(),
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
                labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _englishTitle,
            decoration: const InputDecoration(
                labelText: 'English title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _author,
            decoration: const InputDecoration(
                labelText: 'Author', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _language,
            decoration: const InputDecoration(
                labelText: 'Language', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Text(
            'Spacing and line breaks are kept exactly as pasted.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _lyrics,
            minLines: 10,
            maxLines: 20,
            textCapitalization: TextCapitalization.none,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              height: 1.45,
            ),
            inputFormatters: const [_preservePaste],
            decoration: const InputDecoration(
                labelText: 'Lyrics', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _trans,
            minLines: 6,
            maxLines: 14,
            textCapitalization: TextCapitalization.none,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              height: 1.45,
            ),
            inputFormatters: const [_preservePaste],
            decoration: const InputDecoration(
                labelText: 'Translation / romanization',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chords,
            minLines: 4,
            maxLines: 10,
            textCapitalization: TextCapitalization.none,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              height: 1.45,
            ),
            inputFormatters: const [_preservePaste],
            decoration: const InputDecoration(
                labelText: 'Chords', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: 'Review notes', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : () => _save(approveAfter: true),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: const Text('Save & approve'),
          ),
        ],
      ),
    );
  }
}

// ── App config ────────────────────────────────────────────────────────────────

class _AppConfigModule extends StatefulWidget {
  const _AppConfigModule();

  @override
  State<_AppConfigModule> createState() => _AppConfigModuleState();
}

class _AppConfigModuleState extends State<_AppConfigModule> {
  late final TextEditingController _qrUrl;
  late final TextEditingController _domains;
  late final TextEditingController _minVersion;
  late final TextEditingController _masters;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final config = context.read<AppConfigProvider>();
    _qrUrl = TextEditingController(text: config.qrBaseUrl);
    _domains =
        TextEditingController(text: config.whitelistedQrDomains.join(', '));
    _minVersion = TextEditingController(text: config.appMinVersion);
    _masters = TextEditingController(text: config.masterEmails.join(', '));
    config.load();
  }

  @override
  void dispose() {
    _qrUrl.dispose();
    _domains.dispose();
    _minVersion.dispose();
    _masters.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    if (!await ConnectivityGuard.ensureOnline(context,
        message: 'Saving config needs internet.', useDialog: true)) {
      return;
    }
    final config = context.read<AppConfigProvider>();
    setState(() => _saving = true);
    try {
      await config.setQrBaseUrl(_qrUrl.text);
      await config.setWhitelistedQrDomains(
          _domains.text.split(RegExp(r'[,;\s]+')));
      await config.setAppMinVersion(_minVersion.text);
      await config.setMasterEmails(_masters.text.split(RegExp(r'[,;\s]+')));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App config saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfigProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('App config'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveAll,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SwitchListTile(
            title: const Text('Social login enabled'),
            subtitle: const Text('Show Google / Apple sign-in in the app'),
            value: config.socialLoginEnabled,
            onChanged: (v) async {
              if (!await ConnectivityGuard.ensureOnline(context,
                  message: 'Toggling config needs internet.',
                  useDialog: true)) {
                return;
              }
              try {
                await config.setSocialLoginEnabled(v);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Toggle failed: $e')),
                );
              }
            },
          ),
          const Divider(),
          const SizedBox(height: 8),
          TextField(
            controller: _qrUrl,
            decoration: const InputDecoration(
              labelText: 'QR base URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _domains,
            decoration: const InputDecoration(
              labelText: 'Whitelisted QR domains',
              helperText: 'Comma-separated',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minVersion,
            decoration: const InputDecoration(
              labelText: 'Minimum app version',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _masters,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Master emails',
              helperText: 'Comma-separated. Be careful — this controls Admin.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _saveAll,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save config'),
          ),
        ],
      ),
    );
  }
}

// ── Library sync ──────────────────────────────────────────────────────────────

class _LibrarySyncModule extends StatefulWidget {
  const _LibrarySyncModule();

  @override
  State<_LibrarySyncModule> createState() => _LibrarySyncModuleState();
}

class _LibrarySyncModuleState extends State<_LibrarySyncModule> {
  bool _syncing = false;

  Future<void> _sync() async {
    if (!await ConnectivityGuard.ensureOnline(context,
        message: 'Force sync needs internet.')) {
      return;
    }
    setState(() => _syncing = true);
    try {
      await LocalDatabaseService.instance.syncAllCategories(force: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local song cache refreshed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library sync')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Re-download English, Kannada, and Other song tables into the on-device cache. Use after approving songs or bulk DB edits.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _syncing ? null : _sync,
              icon: _syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download_rounded),
              label: Text(_syncing ? 'Syncing…' : 'Force sync now'),
            ),
          ],
        ),
      ),
    );
  }
}
