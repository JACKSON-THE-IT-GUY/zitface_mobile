import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF0A0F0D), // Pure Dynamic Dark Pro Base
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.4,
              colors: [
                const Color(0xFF11382B).withValues(alpha: 0.35), // Deep emerald glow
                Colors.transparent,
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF141A17).withValues(alpha: 0.7), // Solid Dark Pro surface
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)), // Subtle glass lip
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ZitFaceLogo extends StatelessWidget {
  const ZitFaceLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'ZITFACE',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class SocialAuthButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const SocialAuthButton({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF1E2622),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Or', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final TextEditingController controller;
  final Widget? suffix;

  const AuthTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF1A221E),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFF1F5C43).withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

class GradientAuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const GradientAuthButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF134D35), Color(0xFF1F5C43)]),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ),
    );
  }
}

class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Terms of Service', style: TextStyle(decoration: TextDecoration.underline, color: Colors.white.withValues(alpha: 0.4))),
            TextSpan(text: '  |  ', style: TextStyle(color: Colors.white.withValues(alpha: 0.2))),
            TextSpan(text: 'Privacy Policy', style: TextStyle(decoration: TextDecoration.underline, color: Colors.white.withValues(alpha: 0.4))),
          ],
        ),
        style: const TextStyle(fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }
}