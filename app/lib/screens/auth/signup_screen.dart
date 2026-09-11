import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import 'biometric_offer.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      unawaited(AnalyticsService.instance.logSignUp());
      if (mounted) await offerBiometricLock(context);
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _messageForError(e.code));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _messageForError(String code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case 'email-already-in-use':
        return l10n.signUpErrorEmailInUse;
      case 'invalid-email':
        return l10n.loginErrorInvalidEmail;
      case 'weak-password':
        return l10n.signUpPasswordTooShort;
      default:
        return l10n.signUpErrorGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signUpTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.signUpNameLabel),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? l10n.signUpNameRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.loginEmailLabel),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? l10n.loginEmailRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.signUpPasswordLabel),
                  validator: (value) {
                    if (value == null || value.isEmpty) return l10n.loginPasswordRequired;
                    if (value.length < 8) return l10n.signUpPasswordTooShort;
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.signUpButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
