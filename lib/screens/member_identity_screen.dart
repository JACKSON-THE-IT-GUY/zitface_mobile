import 'package:flutter/material.dart';
import '../services/cbu_identity_validation.dart';
import '../services/zitface_backend.dart';
import '../widget/auth_widgets.dart';
import 'main_shell_screen.dart';

class MemberIdentityGate extends StatefulWidget {
  const MemberIdentityGate({super.key});

  @override
  State<MemberIdentityGate> createState() => _MemberIdentityGateState();
}

class _MemberIdentityGateState extends State<MemberIdentityGate> {
  late Future<String?> _membershipStatus;

  @override
  void initState() {
    super.initState();
    _membershipStatus = _loadMembershipStatus();
  }

  Future<String?> _loadMembershipStatus() async {
    final result = await ZitfaceBackend.client.rpc(
      'get_my_membership_status',
    );
    return result as String?;
  }

  void _retry() {
    setState(() => _membershipStatus = _loadMembershipStatus());
  }

  void _onApplicationSubmitted(String status) {
    setState(() => _membershipStatus = Future<String?>.value(status));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _membershipStatus,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not check your account setup.'),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _retry, child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.data == 'approved') return const MainShellScreen();
        if (snapshot.data == 'pending') {
          return MemberApplicationPendingScreen(onCheck: _retry);
        }
        return MemberApplicationScreen(
          isRejected: snapshot.data == 'rejected',
          onSubmitted: _onApplicationSubmitted,
        );
      },
    );
  }
}

class MemberApplicationScreen extends StatefulWidget {
  const MemberApplicationScreen({
    super.key,
    required this.isRejected,
    required this.onSubmitted,
  });

  final bool isRejected;
  final ValueChanged<String> onSubmitted;

  @override
  State<MemberApplicationScreen> createState() =>
      _MemberApplicationScreenState();
}

class _MemberApplicationScreenState extends State<MemberApplicationScreen> {
  final _memberNumberController = TextEditingController();
  String? _memberType;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _memberNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    final memberNumber = _memberNumberController.text.trim();
    if (_memberType == null) {
      setState(() => _errorMessage = 'Choose your university role.');
      return;
    }
    if (memberNumber.isEmpty) {
      setState(() => _errorMessage = 'Enter your university ID number.');
      return;
    }
    if (_memberType == 'student' && !isValidCbuStudentSin(memberNumber)) {
      setState(
        () => _errorMessage =
          'Student SIN must be 8 digits, with a year prefix from 19 to 27.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final status = await ZitfaceBackend.client.rpc(
        'submit_my_membership_application',
        params: {
          'p_member_type': _memberType!,
          'p_member_number': memberNumber,
        },
      );
      if (mounted) widget.onSubmitted(status as String);
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not submit your application: $error');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = _memberType == 'student';

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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.isRejected
                            ? 'Update your application'
                            : 'CBU membership',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _memberType == 'student'
                          ? 'Enter your CBU student ID. It must be 8 digits, '
                            'starting with a year from 19 to 27. A matching '
                            'format is approved automatically, but does not '
                            'verify enrollment with CBU.'
                          : _memberType == 'staff'
                          ? 'Enter your university staff number. An '
                            'administrator will review staff applications '
                            'before access is granted.'
                          : 'Choose Student or Lecturer / Staff to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        initialValue: _memberType,
                        decoration: const InputDecoration(
                          labelText: 'University role',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'student',
                            child: Text('Student'),
                          ),
                          DropdownMenuItem(
                            value: 'staff',
                            child: Text('Lecturer / Staff'),
                          ),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _memberType = value);
                                }
                              },
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        hint: _memberType == 'student'
                            ? 'Copperbelt University SIN number'
                            : _memberType == 'staff'
                            ? 'University staff number'
                            : 'University ID number',
                        controller: _memberNumberController,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      GradientAuthButton(
                        label: _isSubmitting
                            ? 'Submitting...'
                            : isStudent
                            ? 'Continue'
                            : 'Submit for review',
                        onTap: _isSubmitting ? () {} : _submitApplication,
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MemberApplicationPendingScreen extends StatelessWidget {
  const MemberApplicationPendingScreen({
    super.key,
    required this.onCheck,
  });

  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AuthCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    size: 44,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Application pending',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your CBU membership details are waiting for an '
                    'administrator to review them. You can check again later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: onCheck,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check approval'),
                  ),
                  TextButton(
                    onPressed: () => ZitfaceBackend.client.auth.signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}