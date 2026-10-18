import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart'; // kBg, kCard, kBorder, kBlue1-3, kText, kTextMuted, kTextHint, kLabel, FieldLabel, GlassField, GradientButton buradan geliyor

// ════════════════════════════════════════════
//  KAYIT OL API ÇAĞRISI
// ════════════════════════════════════════════
// DÖNÜŞ DEĞERİ:
//   null           -> Başarılı kayıt
//   String (hata)  -> Backend'den dönen hata mesajı
Future<String?> apiIleKayitOl({
  required String kullaniciId,
  required String adSoyad,
  required String eposta,
  required String sifre,
  required String unvan,
}) async {
  final String apiUrl = "https://kliniktakipapi.onrender.com/api/Auth/register";

  Map<String, dynamic> veriPaketi = {
    "KullaniciId": kullaniciId.trim(),
    "AdSoyad": adSoyad.trim(),
    "Eposta": eposta.trim(),
    "Sifre": sifre,
    "Unvan": unvan.trim(),
  };

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: jsonEncode(veriPaketi),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return null; // Başarılı, hata yok
    } else {
      debugPrint("KAYIT HATASI [${response.statusCode}]: ${response.body}");
      try {
        final hata = jsonDecode(response.body);

        // Normal durum: bizim controller'ımızın döndürdüğü { "mesaj": "..." }
        if (hata is Map && hata['mesaj'] != null) {
          return hata['mesaj'].toString();
        }

        // ASP.NET Core'un otomatik model doğrulama hatası formatı:
        // { "errors": { "AlanAdi": ["Hata metni"], ... } }
        if (hata is Map && hata['errors'] is Map) {
          final errors = hata['errors'] as Map;
          final ilkHata = errors.values.isNotEmpty
              ? (errors.values.first as List).join(', ')
              : null;
          if (ilkHata != null) return ilkHata;
        }

        return 'Kayıt sırasında bir hata oluştu. (kod: ${response.statusCode})';
      } catch (_) {
        return response.body.isNotEmpty
            ? response.body
            : 'Kayıt sırasında bir hata oluştu. (kod: ${response.statusCode})';
      }
    }
  } catch (e) {
    return 'Sunucuya bağlanılamadı: $e';
  }
}

// ════════════════════════════════════════════
//  KAYIT OL SAYFASI
// ════════════════════════════════════════════
class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _adSoyadCtrl = TextEditingController();
  final _epostaCtrl = TextEditingController();
  final _unvanCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  final _sifreTekrarCtrl = TextEditingController();

  bool _showPass = false;
  bool _showPassRepeat = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _adSoyadCtrl.dispose();
    _epostaCtrl.dispose();
    _unvanCtrl.dispose();
    _sifreCtrl.dispose();
    _sifreTekrarCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sifreCtrl.text != _sifreTekrarCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreler birbiriyle eşleşmiyor.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final hata = await apiIleKayitOl(
      kullaniciId: _idCtrl.text.trim(),
      adSoyad: _adSoyadCtrl.text.trim(),
      eposta: _epostaCtrl.text.trim(),
      sifre: _sifreCtrl.text,
      unvan: _unvanCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (hata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt başarılı! Şimdi giriş yapabilirsiniz.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Login sayfasına geri dön
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hata), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.9,
                  colors: [
                    Color(0x383B82F6),
                    Color(0x143B82F6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    IconButton(
                      alignment: Alignment.centerLeft,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: kText,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'HESAP OLUŞTUR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: kBlue1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kayıt Ol',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: kText,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bilgilerinizi girerek hesabınızı oluşturun',
                      style: TextStyle(
                        fontSize: 13,
                        color: kTextMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Kullanıcı ID ──
                    const FieldLabel(label: 'Kullanıcı ID'),
                    const SizedBox(height: 6),
                    GlassField(
                      controller: _idCtrl,
                      hint: 'KULLANICI ID',
                      icon: Icons.badge_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Kullanıcı ID gerekli'
                          : null,
                    ),
                    const SizedBox(height: 18),

                    // ── Ad Soyad ──
                    const FieldLabel(label: 'Ad Soyad'),
                    const SizedBox(height: 6),
                    GlassField(
                      controller: _adSoyadCtrl,
                      hint: 'ADINIZ SOYADINIZ',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ad Soyad gerekli'
                          : null,
                    ),
                    const SizedBox(height: 18),

                    // ── Ünvan ──
                    const FieldLabel(label: 'Ünvan'),
                    const SizedBox(height: 6),
                    GlassField(
                      controller: _unvanCtrl,
                      hint: 'ÖR: DOKTOR, HEMŞİRE',
                      icon: Icons.work_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ünvan gerekli'
                          : null,
                    ),
                    const SizedBox(height: 18),

                    // ── E-posta ──
                    const FieldLabel(label: 'E-posta'),
                    const SizedBox(height: 6),
                    GlassField(
                      controller: _epostaCtrl,
                      hint: 'ORNEK@EPOSTA.COM',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'E-posta gerekli';
                        final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!regex.hasMatch(v.trim()))
                          return 'Geçerli bir e-posta girin';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // ── Şifre ──
                    const FieldLabel(label: 'Şifre'),
                    const SizedBox(height: 6),
                    GlassField(
                      controller: _sifreCtrl,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: !_showPass,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _showPass = !_showPass),
                        child: Icon(
                          _showPass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: kBlue1.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Şifre gerekli';
                        if (v.length < 6)
                          return 'Şifre en az 6 karakter olmalı';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // ── Şifre Tekrar ──
                    const FieldLabel(label: 'Şifre (Tekrar)'),
                    const SizedBox(height: 6),
                    GlassField(
                      controller: _sifreTekrarCtrl,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: !_showPassRepeat,
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _showPassRepeat = !_showPassRepeat),
                        child: Icon(
                          _showPassRepeat
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: kBlue1.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Şifre tekrarı gerekli'
                          : null,
                    ),
                    const SizedBox(height: 28),

                    // ── Kayıt Ol Butonu ──
                    _isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(color: kBlue3),
                          )
                        : GradientButton(label: 'Kayıt Ol', onTap: _register),
                    const SizedBox(height: 20),

                    // Zaten hesabın var mı?
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: kTextMuted),
                        children: [
                          const TextSpan(text: 'Zaten hesabın var mı?  '),
                          TextSpan(
                            text: 'Giriş Yap',
                            style: const TextStyle(
                              color: kBlue1,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
