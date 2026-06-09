import 'package:flutter/material.dart';

import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/screens/home/home_screen.dart';
import 'package:estatetrack1/screens/login/create_account_screen.dart';
import 'package:estatetrack1/screens/login/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final userId = int.tryParse(_identifierController.text.trim());
    if (userId == null || userId < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid user number.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final account = await EstateApi.instance.login(
        userId: userId,
        password: _passwordController.text,
      );
      if (!mounted) return;

      if (account == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid user number or password.')),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => HomeScreen(account: account),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToCreateAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const CreateAccountScreen(),
      ),
    );
  }

  void _goToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.domain_rounded, size: 64, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                'EstateTrack',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Real estate management',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _identifierController,
                keyboardType: TextInputType.number,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'User number',
                  hintText: 'e.g. 1',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _onLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _goToForgotPassword,
                child: const Text('Forgot Password?'),
              ),
              TextButton(
                onPressed: _goToCreateAccount,
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 8),
              const _QuickAccessHint(),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessHint extends StatelessWidget {
  const _QuickAccessHint();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Text(
      'Use your backend UserID and password',
      textAlign: TextAlign.center,
      style: style,
    );
  }
}
