import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'register_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Başarılı girişte null, diğer durumlarda kullanıcıya gösterilecek hata döner.
Future<String?> apiIleGirisYap(String girilenId, String girilenSifre) async {
  // Diğer uygulama istekleriyle aynı yerel API adresi kullanılır.
  final String apiUrl = "https://kliniktakipapi.onrender.com/api/Auth/login";

  // 2. Arka plana göndereceğimiz dijital paket (JSON formatında)
  Map<String, String> veriPaketi = {
    "kullaniciId": girilenId,
    "sifre": girilenSifre,
  };

  try {
    // 3. Garsona (API) siparişi veriyoruz
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: jsonEncode(veriPaketi),
    );

    // 4. Gelen cevabı kontrol ediyoruz (200 = OK, Başarılı)
    if (response.statusCode == 200) {
      return null;
    }
    if (response.statusCode == 401) {
      return 'Kullanıcı adı veya şifre hatalı.';
    }
    return 'Giriş yapılamadı. (Sunucu kodu: ${response.statusCode})';
  } catch (e) {
    return 'Sunucuya bağlanılamadı. İnternet bağlantısını ve sunucuyu kontrol edin.';
  }
}

// ════════════════════════════════════════════
//  RENKLER & SABITLER
// ════════════════════════════════════════════
const _kBg = Color(0xFFF6FAFC); // Genel arka plan

const _kCard = Color(0xFFFFFFFF); // Kartlar
const _kBorder = Color(0xFFE2E8F0); // İnce sınırlar

const _kBlue1 = Color(0xFF7DD3FC); // Açık mavi
const _kBlue2 = Color(0xFF38BDF8); // Ana tema rengi
const _kBlue3 = Color(0xFF0EA5E9); // Vurgu rengi

const _kText = Color(0xFF1E293B); // Ana metin
const _kTextMuted = Color(0xFF64748B); // İkincil metin
const _kTextHint = Color(0xFF94A3B8); // Placeholder
const _kLabel = Color(0xFF475569); // Etiketler

// Kayıt ekranı ile ortak kullanılan tasarım sabitleri. Başında alt çizgi
// olmayan adlar, diğer Dart dosyalarından güvenle kullanılabilir.
const kBg = _kBg;
const kBlue1 = _kBlue1;
const kBlue3 = _kBlue3;
const kText = _kText;
const kTextMuted = _kTextMuted;

// ════════════════════════════════════════════
//  LOGIN PAGE
// ════════════════════════════════════════════
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // DÜZELTME 1: Fonksiyona parametre eklendi ve const kelimesi kaldırıldı
  void _goToDashboard(String gecerliId) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DashboardPage(userId: gecerliId)),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // DÜZELTME 2: Girilen ID bir değişkene atandı ve _goToDashboard'a gönderildi
    final girilenId = _idCtrl.text.trim();
    final hata = await apiIleGirisYap(girilenId, _passCtrl.text);

    if (!mounted) return;

    if (hata == null) {
      _goToDashboard(girilenId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hata)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Arka plan ışıma efektleri ──
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
          Positioned(
            bottom: 80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1A3B64F6), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── İçerik ──
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 52),

                    // Logo
                    const HeartEcgLogo(),
                    const SizedBox(height: 28),

                    // Üst etiket
                    const Text(
                      'SAĞLIK SİSTEMİ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: _kBlue1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Ana başlık
                    const Text(
                      'Hoş Geldiniz',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _kText,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Alt açıklama
                    const Text(
                      'Hesabınıza giriş yapın',
                      style: TextStyle(
                        fontSize: 13,
                        color: _kTextMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── ID Alanı ──
                    const FieldLabel(label: 'Kullanıcı:'),
                    const SizedBox(height: 6),
                    GlassField(
                      controller: _idCtrl,
                      hint: 'KULLANICI ID',
                      icon: Icons.person_outline_rounded,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'ID gerekli' : null,
                    ),
                    const SizedBox(height: 18),

                    // ── Şifre Alanı ──
                    const FieldLabel(label: 'Şifre'),
                    const SizedBox(height: 6),
                    GlassField(
                      controller: _passCtrl,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: !_showPass,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _showPass = !_showPass),
                        child: Icon(
                          _showPass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: _kBlue1.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Şifre gerekli' : null,
                    ),
                    const SizedBox(height: 28),

                    // ── Giriş Butonu ──
                    GradientButton(label: 'Giriş Yap', onTap: _login),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Hesabın yok mu?',
                          style: TextStyle(fontSize: 12, color: _kTextMuted),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          ),
                          child: const Text(
                            'Kayıt Ol',
                            style: TextStyle(
                              color: _kBlue1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Şifremi unuttum
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 12, color: _kTextMuted),
                        children: [
                          TextSpan(text: 'Şifreni mi unuttun?  '),
                          TextSpan(
                            text: 'Sıfırla',
                            style: TextStyle(
                              color: _kBlue1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 44),
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

// ════════════════════════════════════════════
//  YARDIMCI WİDGETLER
// ════════════════════════════════════════════

class FieldLabel extends StatelessWidget {
  final String label;
  const FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: _kLabel,
      ),
    ),
  );
}

class GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const GlassField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: _kText, letterSpacing: 0.2),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextHint, fontSize: 14),
        prefixIcon: Icon(icon, color: _kBlue1, size: 20),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 14),
                child: suffixIcon,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        filled: true,
        fillColor: _kCard,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _kBlue1.withOpacity(0.55), width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.2),
        ),
        errorStyle: const TextStyle(color: Color(0xFFF87171), fontSize: 11),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [_kBlue1, _kBlue3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _kBlue2.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kText,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
//  HEART + ECG LOGO ANİMASYONU
// ════════════════════════════════════════════
class HeartEcgLogo extends StatefulWidget {
  const HeartEcgLogo({Key? key}) : super(key: key);

  @override
  State<HeartEcgLogo> createState() => _HeartEcgLogoState();
}

class _HeartEcgLogoState extends State<HeartEcgLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _draw;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _draw = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.72, curve: Curves.easeOut),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.72, 1.0, curve: Curves.easeInOut),
      ),
    );
    _ctrl.forward().then((_) {
      _ctrl.repeat(reverse: true, period: const Duration(milliseconds: 520));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _LogoPainter(
          draw: _draw.value,
          pulse: _ctrl.isCompleted ? _pulse.value : 1.0,
        ),
        size: const Size(140, 100),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final double draw;
  final double pulse;
  const _LogoPainter({required this.draw, required this.pulse});

  static const _c1 = Color(0xFF93C5FD);
  static const _c2 = Color(0xFF2563EB);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final heartCx = w * 0.5;
    final heartCy = h * 0.48;
    final heartR = w * 0.20;

    final ecgBaseY = heartCy;
    final ecgH = h * 0.24;
    final leftEndX = heartCx - heartR * 0.9;
    final rightStartX = heartCx + heartR * 0.9;

    final grad = const LinearGradient(
      colors: [_c1, _c2],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final strokePaint = Paint()
      ..shader = grad
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final ecgProgress = draw.clamp(0.0, 1.0);
    final leftPath = Path()
      ..moveTo(0, ecgBaseY)
      ..lineTo(w * 0.10, ecgBaseY)
      ..lineTo(w * 0.14, ecgBaseY - ecgH * 0.08)
      ..lineTo(w * 0.145, ecgBaseY - ecgH * 0.52)
      ..lineTo(w * 0.15, ecgBaseY + ecgH * 0.10)
      ..lineTo(w * 0.18, ecgBaseY)
      ..lineTo(w * 0.22, ecgBaseY - ecgH * 0.10)
      ..lineTo(w * 0.24, ecgBaseY)
      ..lineTo(w * 0.26, ecgBaseY - ecgH * 0.14)
      ..lineTo(w * 0.28, ecgBaseY)
      ..lineTo(w * 0.30, ecgBaseY - ecgH * 0.06)
      ..lineTo(leftEndX, ecgBaseY);

    final rightPath = Path()
      ..moveTo(w, ecgBaseY)
      ..lineTo(w * 0.90, ecgBaseY)
      ..lineTo(w * 0.86, ecgBaseY - ecgH * 0.08)
      ..lineTo(w * 0.855, ecgBaseY - ecgH * 0.52)
      ..lineTo(w * 0.85, ecgBaseY + ecgH * 0.10)
      ..lineTo(w * 0.82, ecgBaseY)
      ..lineTo(w * 0.78, ecgBaseY - ecgH * 0.10)
      ..lineTo(w * 0.76, ecgBaseY)
      ..lineTo(w * 0.74, ecgBaseY - ecgH * 0.14)
      ..lineTo(w * 0.72, ecgBaseY)
      ..lineTo(w * 0.70, ecgBaseY - ecgH * 0.06)
      ..lineTo(rightStartX, ecgBaseY);

    final leftMetric = leftPath.computeMetrics().toList();
    final rightMetric = rightPath.computeMetrics().toList();

    if (leftMetric.isNotEmpty && rightMetric.isNotEmpty) {
      _drawPartial(canvas, leftPath, ecgProgress, strokePaint);
      _drawPartial(canvas, rightPath, ecgProgress, strokePaint);

      if (ecgProgress < 1.0) {
        final leftTan = leftMetric.first.getTangentForOffset(
          leftMetric.first.length * ecgProgress,
        );
        final rightTan = rightMetric.first.getTangentForOffset(
          rightMetric.first.length * ecgProgress,
        );

        if (leftTan != null) {
          canvas.drawCircle(
            leftTan.position,
            4,
            Paint()
              ..shader = grad
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
        }
        if (rightTan != null) {
          canvas.drawCircle(
            rightTan.position,
            4,
            Paint()
              ..shader = grad
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
        }
      }
    }

    final heartProgress = (draw * 1.5).clamp(0.0, 1.0);
    if (heartProgress > 0) {
      canvas.save();
      canvas.translate(heartCx, heartCy);
      final s = draw >= 1.0 ? pulse : 1.0;
      canvas.scale(s, s);

      if (heartProgress > 0.8) {
        final fillOpacity = ((heartProgress - 0.8) / 0.2).clamp(0.0, 1.0);
        canvas.drawPath(
          _heartPath(heartR),
          Paint()
            ..shader =
                RadialGradient(
                  colors: [
                    _c1.withOpacity(0.15 * fillOpacity),
                    _c2.withOpacity(0.0),
                  ],
                  center: const Alignment(0, -0.3),
                  radius: 1.1,
                ).createShader(
                  Rect.fromCircle(center: Offset.zero, radius: heartR),
                ),
        );
      }

      _drawPartial(canvas, _heartPath(heartR), heartProgress, strokePaint);
      canvas.restore();
    }
  }

  Path _heartPath(double r) {
    final p = Path();
    p.moveTo(0, -r * 0.08);
    p.cubicTo(-r * 0.12, -r * 0.82, -r * 0.98, -r * 0.68, -r * 0.98, -r * 0.24);
    p.cubicTo(-r * 0.98, r * 0.18, -r * 0.46, r * 0.56, 0, r * 0.82);
    p.cubicTo(r * 0.46, r * 0.56, r * 0.98, r * 0.18, r * 0.98, -r * 0.24);
    p.cubicTo(r * 0.98, -r * 0.68, r * 0.12, -r * 0.82, 0, -r * 0.08);
    p.close();
    return p;
  }

  void _drawPartial(Canvas canvas, Path path, double progress, Paint paint) {
    if (progress <= 0) return;
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    double remaining =
        metrics.fold<double>(0, (s, m) => s + m.length) *
        progress.clamp(0.0, 1.0);
    for (final m in metrics) {
      final take = remaining.clamp(0.0, m.length);
      if (take > 0) canvas.drawPath(m.extractPath(0, take), paint);
      remaining -= take;
      if (remaining <= 0) break;
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.draw != draw || old.pulse != pulse;
}
