import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../services/session_controller.dart';
import '../design_system/design_system.dart';

final _loginNotifierProvider = ChangeNotifierProvider.autoDispose
    .family<LoginNotifier, SessionController>(
      (ref, sessionController) => LoginNotifier(sessionController),
    );

enum LoginAction { google, email }

/// Riverpod notifier that coordinates sign-in UI state.
class LoginNotifier extends ChangeNotifier {
  LoginNotifier(this._sessionController);

  final SessionController _sessionController;
  bool _isLoading = false;
  LoginAction? _loadingAction;
  String? _error;

  bool get isLoading => _isLoading;
  LoginAction? get loadingAction => _loadingAction;
  String? get error => _error;

  Future<bool> signInWithGoogle() {
    return _run(LoginAction.google, _sessionController.signInWithGoogle);
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
    required bool createAccount,
  }) {
    return _run(
      LoginAction.email,
      () => createAccount
          ? _sessionController.createAccountWithEmail(
              email: email,
              password: password,
            )
          : _sessionController.signInWithEmail(
              email: email,
              password: password,
            ),
    );
  }

  Future<bool> _run(LoginAction action, Future<void> Function() task) async {
    _setLoading(action);
    _error = null;

    try {
      await task();
      for (var attempt = 0; attempt < 12; attempt++) {
        if (_sessionController.currentUser != null) return true;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      _error =
          _sessionController.errorMessage ??
          'Erro ao fazer login. Tente novamente.';
      return false;
    } catch (_) {
      _error =
          _sessionController.errorMessage ??
          'Erro ao fazer login. Tente novamente.';
      return false;
    } finally {
      _clearLoading();
    }
  }

  void _setLoading(LoginAction action) {
    _isLoading = true;
    _loadingAction = action;
    notifyListeners();
  }

  void _clearLoading() {
    _isLoading = false;
    _loadingAction = null;
    notifyListeners();
  }
}

/// Login page with Google, Apple, and email/password authentication.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, required this.sessionController});

  final SessionController sessionController;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _createAccount = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(
      _loginNotifierProvider(widget.sessionController),
    );

    return Scaffold(
      backgroundColor: context.tokens.background,
      body: SafeArea(
        top: true,
        bottom: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 720;
            final bottomCard =
                _LoginBottomCard(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      createAccount: _createAccount,
                      notifier: notifier,
                      onCreateAccountChanged: (value) =>
                          setState(() => _createAccount = value),
                      onGoogleSignIn: () => _signInWithGoogle(notifier),
                      onEmailSignIn: () => _signInWithEmail(notifier),
                    )
                    .animate()
                    .slideY(
                      begin: .3,
                      end: 0,
                      delay: 200.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(delay: 200.ms, duration: 400.ms);

            if (isCompact) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenAuth,
                          AppSpacing.xxl,
                          AppSpacing.screenAuth,
                          AppSpacing.xl,
                        ),
                        child: _LoginHero(),
                      ),
                      bottomCard,
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenAuth,
                      ),
                      child: _LoginHero(),
                    ),
                  ),
                ),
                bottomCard,
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(LoginNotifier notifier) async {
    await _handleSignIn(notifier.signInWithGoogle());
  }

  Future<void> _signInWithEmail(LoginNotifier notifier) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.length < 6) {
      _showLoginError('Informe email e senha com pelo menos 6 caracteres.');
      return;
    }

    await _handleSignIn(
      notifier.signInWithEmail(
        email: email,
        password: password,
        createAccount: _createAccount,
      ),
    );
  }

  Future<void> _handleSignIn(Future<bool> signInTask) async {
    final success = await signInTask;
    if (!mounted) return;

    if (success) {
      context.go('/home');
      return;
    }

    final notifier = ref.read(_loginNotifierProvider(widget.sessionController));
    _showLoginError(notifier.error ?? 'Erro ao fazer login. Tente novamente.');
  }

  void _showLoginError(String message) {
    AppSnackBar.error(context, message);
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            boxShadow: context.tokens.glowShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: Image.asset(
              'assets/images/trophy_icon.png',
              width: 140,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Palpitero',
          textAlign: TextAlign.center,
          style: text.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Entre para fazer seus palpites',
          textAlign: TextAlign.center,
          style: text.bodyMedium,
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _LoginBottomCard extends StatelessWidget {
  const _LoginBottomCard({
    required this.emailController,
    required this.passwordController,
    required this.createAccount,
    required this.notifier,
    required this.onCreateAccountChanged,
    required this.onGoogleSignIn,
    required this.onEmailSignIn,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool createAccount;
  final LoginNotifier notifier;
  final ValueChanged<bool> onCreateAccountChanged;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onEmailSignIn;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final isLoading = notifier.isLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenAuth,
        AppSpacing.md,
        AppSpacing.screenAuth,
        AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.lg),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Bem-vindo',
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Acesse sua conta para registrar e acompanhar seus palpites.',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton.secondary(
              label: 'Continuar com o Google',
              icon: SvgPicture.asset(
                'assets/images/google_logo.svg',
                width: 22,
                height: 22,
              ),
              isLoading:
                  isLoading && notifier.loadingAction == LoginAction.google,
              onPressed: isLoading ? null : onGoogleSignIn,
            ).animate().fadeIn(delay: 500.ms, duration: 350.ms),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text('ou', style: text.bodyMedium),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: emailController,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              hintText: 'Email',
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: passwordController,
              enabled: !isLoading,
              obscureText: true,
              textInputAction: TextInputAction.done,
              hintText: 'Senha',
              onSubmitted: (_) {
                if (!isLoading) onEmailSignIn();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: createAccount,
              activeThumbColor: t.brand,
              title: Text('Criar nova conta', style: text.labelLarge),
              onChanged: isLoading ? null : onCreateAccountChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: createAccount ? 'Criar conta' : 'Entrar com email',
              isLoading:
                  isLoading && notifier.loadingAction == LoginAction.email,
              onPressed: isLoading ? null : onEmailSignIn,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _TermsText(),
          ],
        ),
      ),
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final caption = Theme.of(context).textTheme.bodySmall;

    return Text.rich(
      TextSpan(
        text: 'Ao continuar, você aceita nossos ',
        style: caption?.copyWith(color: t.textDisabled),
        children: [
          TextSpan(
            text: 'Termos de Uso',
            style: caption?.strong.copyWith(color: t.textSecondary),
            recognizer: TapGestureRecognizer()..onTap = () {},
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
