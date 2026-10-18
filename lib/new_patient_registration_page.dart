import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

Future<PatientRegistrationData?> showNewPatientRegistrationPage(
  BuildContext context,
) {
  return Navigator.of(context).push<PatientRegistrationData>(
    MaterialPageRoute(builder: (_) => const NewPatientRegistrationPage()),
  );
}

class NewPatientRegistrationPage extends StatefulWidget {
  const NewPatientRegistrationPage({super.key});

  @override
  State<NewPatientRegistrationPage> createState() =>
      _NewPatientRegistrationPageState();
}

class _NewPatientRegistrationPageState
    extends State<NewPatientRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _tcCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _tcCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final data = PatientRegistrationData(
      tcNo: _tcCtrl.text.trim(),
      fullName: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    setState(() => _isSaving = true);

    try {
      // Sunucu uykudan uyanıyorsa ilk istek ~1 dakika sürebilir,
      // bu yüzden zaman aşımı süresi uzun tutuldu.
      final response = await http
          .post(
            Uri.parse("$apiBaseUrl/api/Hastalar"),
            headers: {"Content-Type": "application/json; charset=utf-8"},
            body: jsonEncode({
              "TcKimlik": data.tcNo,
              "AdSoyad": data.fullName,
              "EvAdresi": data.address,
              "Telefon": data.phone,
              "KaydedenPersonel": "admin_01",
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Kayıt veritabanına ulaştı, önceki sayfaya bilgileri gönder
        Navigator.of(context).pop(data);
        return;
      }

      // API'nin döndürdüğü hata mesajını göster (örn. aynı TC zaten kayıtlı)
      String message = 'Kayıt başarısız (Sunucu kodu: ${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['mesaj'] != null) {
          message = body['mesaj'].toString();
        }
      } catch (_) {}

      _showMessage(message, isError: true);
    } on TimeoutException {
      _showMessage(
        'Sunucu yanıt vermedi. Biraz bekleyip tekrar deneyin.',
        isError: true,
      );
    } catch (e) {
      debugPrint("Hasta kayıt bağlantı hatası: $e");
      _showMessage(
        'Sunucuya bağlanılamadı. İnternetinizi kontrol edin.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Yeni Hasta Kaydı',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hasta Bilgileri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Yeni hasta temel kayıt bilgilerini gir.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                _Field(
                  controller: _tcCtrl,
                  label: 'TC No',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  enabled: !_isSaving,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'TC no gerekli';
                    if (text.length != 11) return 'TC no 11 haneli olmalı';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _nameCtrl,
                  label: 'Ad Soyad',
                  icon: Icons.person_outline,
                  enabled: !_isSaving,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Ad soyad gerekli';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _addressCtrl,
                  label: 'Ev Adresi',
                  icon: Icons.home_outlined,
                  maxLines: 3,
                  enabled: !_isSaving,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Adres gerekli';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _phoneCtrl,
                  label: 'Telefon Numarası',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: !_isSaving,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Telefon gerekli';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.blueAccent.withValues(
                        alpha: 0.6,
                      ),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }
}

class PatientRegistrationData {
  final String tcNo;
  final String fullName;
  final String address;
  final String phone;

  const PatientRegistrationData({
    required this.tcNo,
    required this.fullName,
    required this.address,
    required this.phone,
  });
}
