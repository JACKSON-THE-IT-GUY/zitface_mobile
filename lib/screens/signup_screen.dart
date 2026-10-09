import 'package:zitface_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../widget/auth_widgets.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ZitFaceLogo(),
                AuthCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create an Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'To create an account provide details verify email\nand set a password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          SocialAuthButton(
                            label: 'Google',
                            icon: const Text(
                              'G',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {},
                          ),
                          const SizedBox(width: 14),
                          SocialAuthButton(
                            label: 'Apple',
                            icon: const Icon(
                              Icons.apple,
                              color: AppColors.textPrimary,
                              size: 18,
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const OrDivider(),
                      const SizedBox(height: 20),
                      AuthTextField(
                        hint: 'Email address',
                        controller: _emailCtrl,
                      ),
                      const SizedBox(height: 20),
                      GradientAuthButton(
                        label: 'Continue',
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.85,
                              ),
                            ),
                            children: const [
                              TextSpan(text: 'Have an account? '),
                              TextSpan(
                                text: 'Log In',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
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
    );
  }
}
