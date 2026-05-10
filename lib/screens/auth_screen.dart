import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Sign-in / sign-up UI provided by Clerk (email, OAuth per Clerk Dashboard).
///
/// **Mã xác thực email (OTP):** bật chiến lược *Email verification code* trong
/// [Clerk Dashboard](https://dashboard.clerk.com) → *User & Authentication* →
/// *Email, Phone, Username* (và/hoặc *Sign-in / Sign-up*). Dán HTML trong
/// `clerk/email-templates/verification-code.html` (markup **Revolvapp** `re-*`, không phải HTML bảng thường)
/// vào template **Verification code** — xem `clerk/email-templates/README.md`.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;
    final testEmail = dotenv.env['TEST_ACCOUNT_EMAIL']?.trim() ?? '';
    final testPassword = dotenv.env['TEST_ACCOUNT_PASSWORD'] ?? '';
    final showTestHint = testEmail.isNotEmpty && testPassword.trim().isNotEmpty;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surface,
              cs.surfaceContainerHighest.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(color: cs.outlineVariant, width: 1.35),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.secondary.withValues(alpha: 0.7),
                            width: 1.4,
                          ),
                        ),
                        child: Icon(
                          Icons.eco_rounded,
                          size: 44,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Harvest & Hearth',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.primary,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t('auth_tagline'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(color: cs.outline, width: 1.3),
                  ),
                  child: const ClerkAuthentication(),
                ),
                if (showTestHint) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _signInWithTestAccount(
                      context,
                      testEmail,
                      testPassword.trim(),
                    ),
                    icon: const Icon(Icons.login_rounded),
                    label: Text('${t('auth_test_account')} (1 chạm)'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _signInWithTestAccount(
    BuildContext context,
    String email,
    String password,
  ) async {
    final authState = ClerkAuth.of(context, listen: false);
    await authState.safelyCall(
      context,
      () => authState.attemptSignIn(
        strategy: clerk.Strategy.password,
        identifier: email,
        password: password,
      ),
    );

    if (!context.mounted) return;
    if (authState.isSignedIn) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tài khoản thử chưa vào thẳng được. Vui lòng hoàn tất bước xác thực còn lại trên form Clerk.',
        ),
      ),
    );
  }
}
