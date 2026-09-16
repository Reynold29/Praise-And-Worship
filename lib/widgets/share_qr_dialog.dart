import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

const Color _kQrInk = Color(0xFF0B3D91);

/// Shows a scannable QR for a song or playlist share URL.
///
/// Uses [Dialog] instead of [AlertDialog] because [QrImageView] is a
/// [LayoutBuilder], and AlertDialog's IntrinsicWidth cannot measure that.
void showShareQrDialog({
  required BuildContext context,
  required String heading,
  required String subtitle,
  required String qrUrl,
  required String caption,
  String? detail,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
          child: SizedBox(
            width: 312,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  heading,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: _kQrInk.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: _BrandedQrView(data: qrUrl, size: 236),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  caption,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                if (detail != null && detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      detail,
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                SelectableText(
                  qrUrl,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: qrUrl));
                          if (!dialogContext.mounted) return;
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Link copied')),
                          );
                        },
                        icon: const Icon(Icons.link_rounded, size: 18),
                        label: const Text('Copy Link'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          final shareText = detail != null && detail.isNotEmpty
                              ? '$caption\n$detail\n$qrUrl'
                              : '$caption\n$qrUrl';
                          await SharePlus.instance.share(
                            ShareParams(
                              text: shareText,
                              subject: heading,
                            ),
                          );
                        },
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _BrandedQrView extends StatelessWidget {
  const _BrandedQrView({required this.size, required this.data});

  final double size;
  final String data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size,
            padding: EdgeInsets.zero,
            gapless: false,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.circle,
              color: _kQrInk,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle,
              color: _kQrInk,
            ),
            errorStateBuilder: (context, error) => const Center(
              child: Text(
                'Could not build this QR',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icons/app_logo.png',
                fit: BoxFit.cover,
                cacheWidth: 160,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
