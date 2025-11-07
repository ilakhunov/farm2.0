import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/auth_models.dart';
import 'phone_input_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({
    super.key,
    required this.formResult,
    required this.onSubmit,
    required this.onVerified,
    required this.onRestart,
    this.debugOtp,
  });

  final PhoneFormResult formResult;
  final Future<AuthResponse> Function(String code) onSubmit;
  final Future<void> Function(AuthResponse response) onVerified;
  final VoidCallback onRestart;
  final String? debugOtp;

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  int _secondsRemaining = 60;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_secondsRemaining == 0) {
        return false;
      }
      setState(() {
        _secondsRemaining -= 1;
      });
      return true;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final response = await widget.onSubmit(_codeController.text.trim());
      await widget.onVerified(response);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message ?? 'Request failed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.translate('auth_enter_code'),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              strings.translate('auth_code_sent').replaceFirst('{phone}', widget.formResult.phoneNumber),
              textAlign: TextAlign.center,
            ),
            if (widget.debugOtp != null) ...[
              const SizedBox(height: 8),
              Text(
                strings.translate('auth_debug_code').replaceFirst('{code}', widget.debugOtp!),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: strings.translate('auth_code_label'),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return strings.translate('auth_code_required');
                }
                if (value.trim().length < 4) {
                  return strings.translate('auth_code_invalid');
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _secondsRemaining == 0 ? widget.onRestart : null,
              child: Text(
                _secondsRemaining == 0
                    ? strings.translate('auth_resend')
                    : strings.translate('auth_resend_in').replaceFirst('{seconds}', _secondsRemaining.toString()),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.translate('auth_confirm')),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onRestart,
              child: Text(strings.translate('auth_change_phone')),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

