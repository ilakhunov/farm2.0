import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class PhoneFormResult {
  const PhoneFormResult({
    required this.phoneNumber,
    required this.role,
    this.entityType,
    this.taxId,
    this.legalName,
  });

  final String phoneNumber;
  final String role;
  final String? entityType;
  final String? taxId;
  final String? legalName;
}

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key, required this.onSubmit});

  final Future<String?> Function(PhoneFormResult result) onSubmit;

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _legalNameController = TextEditingController();
  bool _isSubmitting = false;
  String _role = 'farmer';
  String _entityType = 'legal_entity';
  String? _lastDebugOtp;

  @override
  void dispose() {
    _phoneController.dispose();
    _taxIdController.dispose();
    _legalNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final strings = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final fullPhone = '+998$phoneDigits';
    final result = PhoneFormResult(
      phoneNumber: fullPhone,
      role: _role,
      entityType: _role == 'shop' ? _entityType : null,
      taxId: _role == 'shop' && _taxIdController.text.trim().isNotEmpty ? _taxIdController.text.trim() : null,
      legalName: _role == 'shop' && _legalNameController.text.trim().isNotEmpty ? _legalNameController.text.trim() : null,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final debugOtp = await widget.onSubmit(result);
      if (!mounted) return;
      setState(() {
        _lastDebugOtp = debugOtp;
      });
      if (debugOtp != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.translate('auth_debug_code').replaceFirst('{code}', debugOtp))),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.translate('auth_enter_phone'),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _RoleSelector(
                value: _role,
                onChanged: (value) {
                  setState(() {
                    _role = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: strings.translate('auth_phone_label'),
                  prefixText: '+998 ',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return strings.translate('auth_phone_required');
                  }
                  if (value.replaceAll(RegExp(r'\D'), '').length != 9) {
                    return strings.translate('auth_phone_invalid');
                  }
                  return null;
                },
              ),
              if (_role == 'shop') ...[
                const SizedBox(height: 16),
                _EntityTypeSelector(
                  value: _entityType,
                  onChanged: (value) => setState(() => _entityType = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taxIdController,
                  decoration: InputDecoration(
                    labelText: strings.translate('auth_tax_id_label'),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _legalNameController,
                  decoration: InputDecoration(
                    labelText: strings.translate('auth_legal_name_label'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(strings.translate('auth_send_code')),
                ),
              ),
              if (_lastDebugOtp != null) ...[
                const SizedBox(height: 12),
                Text(
                  strings.translate('auth_debug_code').replaceFirst('{code}', _lastDebugOtp!),
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      decoration: InputDecoration(
        labelText: strings.translate('auth_role_label'),
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(value: 'farmer', child: Text(strings.translate('auth_role_farmer'))),
        DropdownMenuItem(value: 'shop', child: Text(strings.translate('auth_role_shop'))),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _EntityTypeSelector extends StatelessWidget {
  const _EntityTypeSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      decoration: InputDecoration(
        labelText: strings.translate('auth_entity_type_label'),
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(value: 'legal_entity', child: Text(strings.translate('auth_entity_legal'))),
        DropdownMenuItem(value: 'sole_proprietor', child: Text(strings.translate('auth_entity_sole'))),
        DropdownMenuItem(value: 'self_employed', child: Text(strings.translate('auth_entity_self'))),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
