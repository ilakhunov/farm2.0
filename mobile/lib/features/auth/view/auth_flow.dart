import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/storage/token_storage.dart';
import '../../products/view/product_catalog_screen.dart';
import '../data/auth_repository.dart';
import '../models/auth_models.dart';
import 'otp_verification_screen.dart';
import 'phone_input_screen.dart';

class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({super.key});

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> {
  final AuthRepository _authRepository = AuthRepository();
  PhoneFormResult? _currentForm;
  String? _debugOtp;

  Future<String?> _sendOtp(PhoneFormResult result) async {
    try {
      final debugOtp = await _authRepository.sendOtp(
        phoneNumber: result.phoneNumber,
        role: result.role,
        entityType: result.entityType,
      );
      if (!mounted) return null;
      setState(() {
        _currentForm = result;
        _debugOtp = debugOtp;
      });
      return debugOtp;
    } on DioException catch (error) {
      _showError(error.message ?? 'Request failed');
      rethrow;
    } catch (error) {
      _showError(error.toString());
      rethrow;
    }
  }

  Future<AuthResponse> _verifyOtp(String code) async {
    final form = _currentForm!;
    return _authRepository.verifyOtp(
      phoneNumber: form.phoneNumber,
      code: code,
      role: form.role,
      entityType: form.entityType,
      taxId: form.taxId,
      legalName: form.legalName,
    );
  }

  Future<void> _onVerified(AuthResponse response) async {
    await TokenStorage.saveTokens(
      accessToken: response.tokens.accessToken,
      refreshToken: response.tokens.refreshToken,
    );
    if (!mounted) return;
    final strings = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.translate('auth_success'))),
    );
    // Navigate to catalog
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProductCatalogScreen()),
    );
  }

  void _restart() {
    setState(() {
      _currentForm = null;
      _debugOtp = null;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    final strings = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.isEmpty ? strings.translate('auth_error') : message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.translate('auth_title'))),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _currentForm == null
            ? PhoneInputScreen(onSubmit: _sendOtp)
            : OTPVerificationScreen(
                formResult: _currentForm!,
                debugOtp: _debugOtp,
                onRestart: _restart,
                onSubmit: _verifyOtp,
                onVerified: _onVerified,
              ),
      ),
    );
  }
}
