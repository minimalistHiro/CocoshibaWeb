import 'dart:math';

import 'package:cocoshibaweb/models/owner_contact_info.dart';
import 'package:cocoshibaweb/pages/admin/_admin_widgets.dart';
import 'package:cocoshibaweb/services/owner_settings_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class OwnerSettingsPage extends StatefulWidget {
  const OwnerSettingsPage({super.key});

  @override
  State<OwnerSettingsPage> createState() => _OwnerSettingsPageState();
}

class _OwnerSettingsPageState extends State<OwnerSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final OwnerSettingsService _service = OwnerSettingsService();

  final _storeIdController = TextEditingController();
  final _siteUrlController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _xController = TextEditingController();
  final _businessHoursController = TextEditingController();

  final Random _random = Random.secure();
  static const int _storeIdLength = 28;
  static const String _storeIdChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  int _selectedRate = 5;
  bool _isLoading = true;
  bool _isSavingRate = false;
  bool _isSavingContact = false;
  String? _storeIdError;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _storeIdController.dispose();
    _siteUrlController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _xController.dispose();
    _businessHoursController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    if (Firebase.apps.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final rateFuture = _service.fetchPointRate();
      final contactFuture = _service.fetchContactInfo();
      final rate = await rateFuture;
      final contact = await contactFuture ?? OwnerContactInfo.empty;
      if (!mounted) return;
      if (rate != null && rate >= 1 && rate <= 100) {
        _selectedRate = rate;
      }
      _applyContact(contact);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyContact(OwnerContactInfo info) {
    final storeId = info.storeId.isNotEmpty ? info.storeId : _generateStoreId();
    _storeIdController.text = storeId;
    _storeIdError = null;
    _siteUrlController.text = info.siteUrl;
    _emailController.text = info.email;
    _phoneController.text = info.phoneNumber;
    _addressController.text = info.address;
    _facebookController.text = info.facebook;
    _instagramController.text = info.instagram;
    _xController.text = info.xAccount;
    _businessHoursController.text = info.businessHours;
  }

  String _generateStoreId() {
    final buffer = StringBuffer();
    for (var i = 0; i < _storeIdLength; i++) {
      buffer.write(_storeIdChars[_random.nextInt(_storeIdChars.length)]);
    }
    return buffer.toString();
  }

  bool _validateStoreId() {
    final value = _storeIdController.text.trim();
    final isValid = value.length == _storeIdLength &&
        RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);
    if (!isValid) {
      setState(() => _storeIdError = '28文字の英数字(-, _)で入力してください');
      return false;
    }
    if (_storeIdError != null) setState(() => _storeIdError = null);
    return true;
  }

  void _regenerateStoreId() {
    setState(() {
      _storeIdController.text = _generateStoreId();
      _storeIdError = null;
    });
  }

  Future<void> _saveRate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSavingRate = true);
    try {
      await _service.savePointRate(_selectedRate);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ポイント還元率を$_selectedRate%に設定しました')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ポイント還元率の保存に失敗しました')),
      );
    } finally {
      if (mounted) setState(() => _isSavingRate = false);
    }
  }

  Future<void> _saveContact() async {
    if (!_validateStoreId()) return;
    setState(() => _isSavingContact = true);
    final info = OwnerContactInfo(
      storeId: _storeIdController.text.trim(),
      siteUrl: _siteUrlController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      facebook: _facebookController.text.trim(),
      instagram: _instagramController.text.trim(),
      xAccount: _xController.text.trim(),
      businessHours: _businessHoursController.text.trim(),
    );

    try {
      await _service.saveContactInfo(info);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('店舗情報を保存しました')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('店舗情報の保存に失敗しました')),
      );
    } finally {
      if (mounted) setState(() => _isSavingContact = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return ListView(children: const [FirebaseNotReadyCard()]);
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);

    return ListView(
      children: [
        const AdminPageHeader(title: 'オーナー設定'),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ポイント還元率',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedRate,
                        decoration: const InputDecoration(labelText: '還元率（%）'),
                        items: List<int>.generate(100, (i) => i + 1)
                            .map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v%'),
                                ))
                            .toList(growable: false),
                        onChanged: _isSavingRate
                            ? null
                            : (value) => setState(
                                  () => _selectedRate = value ?? _selectedRate,
                                ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSavingRate ? null : _saveRate,
                          icon: _isSavingRate
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('還元率を保存'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '店舗情報',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _storeIdController,
                        decoration: InputDecoration(
                          labelText: '店舗ID',
                          errorText: _storeIdError,
                          suffixIcon: IconButton(
                            tooltip: '再生成',
                            onPressed: _regenerateStoreId,
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                        onChanged: (_) => _validateStoreId(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _siteUrlController,
                        decoration: const InputDecoration(labelText: 'WebサイトURL'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'メールアドレス'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: '電話番号'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: '住所'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _businessHoursController,
                        decoration: const InputDecoration(labelText: '営業時間'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _facebookController,
                        decoration: const InputDecoration(labelText: 'Facebook（任意）'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _instagramController,
                        decoration: const InputDecoration(labelText: 'Instagram（任意）'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _xController,
                        decoration: const InputDecoration(labelText: 'X（任意）'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSavingContact ? null : _saveContact,
                          icon: _isSavingContact
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('店舗情報を保存'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
