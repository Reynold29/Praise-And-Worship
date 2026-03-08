import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/auth_provider.dart';
import '../widgets/app_config_provider.dart';

/// Full-screen authentication sheet.
/// Google sign-in is the primary CTA; email/password is secondary.
class AuthScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const AuthScreen({super.key, this.onSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Register the navigation callback so any login method (email, Apple,
    // Google OAuth redirect) triggers a pop after _onAuthStateChange fires.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      auth.onLoginSuccess = () {
        if (mounted) {
          widget.onSuccess?.call();
          Navigator.of(context).pop(true);
        }
      };
    });
  }

  @override
  void dispose() {
    // Clear the callback to avoid referencing a dead context.
    try {
      context.read<AuthProvider>().onLoginSuccess = null;
    } catch (_) {}
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loginEnabled = context.watch<AppConfigProvider>().socialLoginEnabled;

    // If login is disabled remotely, show a friendly unavailable screen
    if (!loginEnabled) {
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Account',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_clock_rounded,
                    size: 64, color: cs.onSurfaceVariant),
                const SizedBox(height: 24),
                Text(
                  'Sign-in Temporarily Unavailable',
                  style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: cs.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We have temporarily paused account access. '
                  'Your local songs and favourites are unaffected. '
                  'Please check back soon.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Account',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 3, color: cs.primary),
            borderRadius: BorderRadius.circular(2),
          ),
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Sign In'), Tab(text: 'Register')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AuthForm(
              isRegister: false,
              onSuccess: widget.onSuccess,
              tabController: _tabController),
          _AuthForm(
              isRegister: true,
              onSuccess: widget.onSuccess,
              tabController: _tabController),
        ],
      ),
    );
  }
}

// ── Auth Form ─────────────────────────────────────────────────────────────────

class _AuthForm extends StatefulWidget {
  final bool isRegister;
  final VoidCallback? onSuccess;
  final TabController tabController;

  const _AuthForm({
    required this.isRegister,
    this.onSuccess,
    required this.tabController,
  });

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _showEmailForm = false; // collapsed by default — Google is primary
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail(AuthProvider auth) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    auth.clearError();

    if (widget.isRegister) {
      await auth.signUpWithEmail(_emailCtrl.text, _passwordCtrl.text);
    } else {
      await auth.signInWithEmail(_emailCtrl.text, _passwordCtrl.text);
    }

    if (!mounted) return;

    // "Check your email" is an info message — show snackbar + switch tab
    final err = auth.error;
    if (err != null && err.toLowerCase().contains('check your email')) {
      auth.clearError();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ));
      widget.tabController.animateTo(0);
      return;
    }

    // onLoginSuccess callback handles navigation if the stream fired;
    // fallback check for immediate email flow.
    if (auth.error == null && auth.isLoggedIn && mounted) {
      widget.onSuccess?.call();
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _submitGoogle(AuthProvider auth) async {
    auth.clearError();
    await auth.signInWithGoogle();
    // Google is an external OAuth — the browser opens and returns via URL
    // scheme. The onLoginSuccess callback registered in AuthScreen.initState
    // handles navigation when _onAuthStateChange fires.
    // If the user is already signed in by the time we return here (e.g.
    // token already cached), handle it directly too.
    if (!mounted) return;
    if (auth.error == null && auth.isLoggedIn) {
      widget.onSuccess?.call();
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _submitApple(AuthProvider auth) async {
    auth.clearError();
    await auth.signInWithApple();
    // Native Apple Sign-In is synchronous — we get the result immediately.
    if (!mounted) return;
    if (auth.error == null && auth.isLoggedIn) {
      widget.onSuccess?.call();
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isRegister
                    ? Icons.person_add_rounded
                    : Icons.lock_open_rounded,
                size: 36,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isRegister ? 'Create your account' : 'Welcome back',
            style: tt.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            widget.isRegister
                ? 'Your favourites will sync across devices'
                : 'Sign in to access your synced favourites',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // ── Error banner ──────────────────────────────────────────────
          if (auth.error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.error.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: cs.onErrorContainer, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      auth.error!,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onErrorContainer, height: 1.5),
                    ),
                  ),
                  GestureDetector(
                    onTap: auth.clearError,
                    child: Icon(Icons.close_rounded,
                        color: cs.onErrorContainer, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // ── PRIMARY: Google sign-in ────────────────────────────────────
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: auth.loading ? null : () => _submitGoogle(auth),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.surface,
                foregroundColor: cs.onSurface,
                elevation: 2,
                shadowColor: cs.shadow.withOpacity(0.3),
                side: BorderSide(color: cs.outlineVariant, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GoogleLogoIcon(size: 22),
                  const SizedBox(width: 12),
                  Text(
                    widget.isRegister
                        ? 'Sign up with Google'
                        : 'Continue with Google',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (auth.loadingGoogle) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.primary)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Apple sign-in (iOS / macOS only) ──────────────────────────
          if (Theme.of(context).platform == TargetPlatform.iOS ||
              Theme.of(context).platform == TargetPlatform.macOS) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: auth.loading ? null : () => _submitApple(auth),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.surface,
                  foregroundColor: cs.onSurface,
                  elevation: 2,
                  shadowColor: cs.shadow.withOpacity(0.3),
                  side: BorderSide(color: cs.outlineVariant, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/apple_logo.svg',
                      height: 22,
                      width: 22,
                      colorFilter:
                          ColorFilter.mode(cs.onSurface, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.isRegister
                          ? 'Sign up with Apple'
                          : 'Continue with Apple',
                      style:
                          tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (auth.loadingApple) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.primary)),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // ── "Recommended" badge (below both social buttons) ────────────
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '⭐ Recommended',
                style: tt.labelSmall?.copyWith(
                    color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Divider ───────────────────────────────────────────────────
          Row(children: [
            Expanded(child: Divider(color: cs.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or use email',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            Expanded(child: Divider(color: cs.outlineVariant)),
          ]),
          const SizedBox(height: 12),

          // ── Toggle to reveal email form ───────────────────────────────
          if (!_showEmailForm)
            OutlinedButton.icon(
              onPressed: () => setState(() => _showEmailForm = true),
              icon: const Icon(Icons.email_outlined, size: 18),
              label: Text(widget.isRegister
                  ? 'Register with Email instead'
                  : 'Sign in with Email instead'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurfaceVariant,
                side: BorderSide(color: cs.outlineVariant),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: tt.bodyMedium,
              ),
            )
          else ...[
            // ── Email form ────────────────────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDec(cs,
                        label: 'Email address', icon: Icons.email_outlined),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePass,
                    textInputAction: widget.isRegister
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onFieldSubmitted:
                        widget.isRegister ? null : (_) => _submitEmail(auth),
                    decoration: _fieldDec(cs,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        suffix: _eye(
                            _obscurePass,
                            () =>
                                setState(() => _obscurePass = !_obscurePass))),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (widget.isRegister && v.length < 6) {
                        return 'At least 6 characters required';
                      }
                      return null;
                    },
                  ),
                  if (widget.isRegister) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitEmail(auth),
                      decoration: _fieldDec(cs,
                          label: 'Confirm password',
                          icon: Icons.lock_outline_rounded,
                          suffix: _eye(
                              _obscureConfirm,
                              () => setState(
                                  () => _obscureConfirm = !_obscureConfirm))),
                      validator: (v) {
                        if (v != _passwordCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: auth.loading ? null : () => _submitEmail(auth),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: auth.loading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: cs.onPrimary))
                          : Text(
                              widget.isRegister ? 'Create Account' : 'Sign In',
                              style: tt.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Switch tab hint ───────────────────────────────────────────
          Center(
            child: TextButton(
              onPressed: () =>
                  widget.tabController.animateTo(widget.isRegister ? 0 : 1),
              child: RichText(
                text: TextSpan(
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  children: [
                    TextSpan(
                        text: widget.isRegister
                            ? 'Already have an account? '
                            : "Don't have an account? "),
                    TextSpan(
                      text: widget.isRegister ? 'Sign In' : 'Register',
                      style: TextStyle(
                          color: cs.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── T&C footer ────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: _launchTerms,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
                  children: [
                    const TextSpan(text: 'By continuing, you agree to our '),
                    TextSpan(
                      text: 'Privacy Policy & Terms',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: cs.primary,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _launchTerms() async {
    final uri = Uri.parse(
        'https://sites.google.com/view/worshipcompanionprivacypolicy/home');
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _eye(bool obscure, VoidCallback toggle) => IconButton(
        icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20),
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        onPressed: toggle,
      );

  InputDecoration _fieldDec(
    ColorScheme cs, {
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: cs.onSurfaceVariant, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: cs.surfaceContainerLow,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant, width: 1)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 2)),
    );
  }
}

// ── Full-colour Google logo via flutter_svg (inline — no asset lookup) ────────

// The raw SVG is embedded directly so it never fails with "asset not found"
// errors caused by Flutter build cache issues on incremental builds.
const _kGoogleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48">
  <path fill="#FFC107" d="M43.611,20.083H42V20H24v8h11.303c-1.649,4.657-6.08,8-11.303,8c-6.627,0-12-5.373-12-12c0-6.627,5.373-12,12-12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C12.955,4,4,12.955,4,24c0,11.045,8.955,20,20,20c11.045,0,20-8.955,20-20C44,22.659,43.862,21.35,43.611,20.083z"/>
  <path fill="#FF3D00" d="M6.306,14.691l6.571,4.819C14.655,15.108,18.961,12,24,12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C16.318,4,9.656,8.337,6.306,14.691z"/>
  <path fill="#4CAF50" d="M24,44c5.166,0,9.86-1.977,13.409-5.192l-6.19-5.238C29.211,35.091,26.715,36,24,36c-5.202,0-9.619-3.317-11.283-7.946l-6.522,5.025C9.505,39.556,16.227,44,24,44z"/>
  <path fill="#1976D2" d="M43.611,20.083H42V20H24v8h11.303c-0.792,2.237-2.231,4.166-4.087,5.571c0.001-0.001,0.002-0.001,0.003-0.002l6.19,5.238C36.971,39.205,44,34,44,24C44,22.659,43.862,21.35,43.611,20.083z"/>
</svg>
''';

class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _kGoogleSvg,
      width: size,
      height: size,
    );
  }
}
