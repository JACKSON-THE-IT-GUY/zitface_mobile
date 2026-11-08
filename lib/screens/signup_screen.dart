import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/zitface_backend.dart';
import '../widget/auth_widgets.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_isSubmitting) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!ZitfaceBackend.isConfigured) {
      _showMessage('Configure Supabase to create an account.');
      return;
    }
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Enter your name, email address, and password.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Use a password with at least 6 characters.');
      return;
    }
    if (password != _confirmPasswordController.text) {
      _showMessage('The passwords do not match.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await ZitfaceBackend.client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name},
      );
      if (!mounted) return;

      if (response.session == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => LoginScreen(
              initialEmail: email,
              message:
                  'Check your email to confirm your account, then sign in.',
            ),
          ),
        );
      }
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } on Exception catch (error) {
      if (mounted) _showMessage('Could not create your account: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: AuthContentWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                const ZitFaceLogo(),
                AuthCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create an Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Create your account with your email address.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AuthTextField(
                        hint: 'Display name',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        hint: 'Email address',
                        controller: _emailController,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        hint: 'Password',
                        controller: _passwordController,
                        obscure: _obscurePassword,
                        suffix: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        hint: 'Confirm password',
                        controller: _confirmPasswordController,
                        obscure: true,
                      ),
                      const SizedBox(height: 20),
                      GradientAuthButton(
                        label: _isSubmitting
                            ? 'Creating account...'
                            : 'Continue',
                        onTap: _createAccount,
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => LoginScreen(
                                    initialEmail: _emailController.text.trim(),
                                  ),
                                ),
                              ),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.85),
                            ),
                            children: [
                              const TextSpan(text: 'Have an account? '),
                              TextSpan(
                                text: 'Log In',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const AuthFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
