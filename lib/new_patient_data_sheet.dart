import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>?> showNewPatientDataSheet(BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _NewPatientDataSheet(),
  );
}

class _NewPatientDataSheet extends StatefulWidget {
  const _NewPatientDataSheet();

  @override
  State<_NewPatientDataSheet> createState() => _NewPatientDataSheetState();
}

class _NewPatientDataSheetState extends State<_NewPatientDataSheet> {
  final _formKey = GlobalKey<FormState>();

  final _tcCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _bloodPressureCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _temperatureCtrl = TextEditingController();
  final _oxygenCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _tcCtrl.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _diagnosisCtrl.dispose();
    _bloodPressureCtrl.dispose();
    _pulseCtrl.dispose();
    _temperatureCtrl.dispose();
    _oxygenCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    debugPrint("========> BUTONA BASILDI <========");
    if (!_formKey.currentState!.validate()) return;

    final now = TimeOfDay.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final tcKimlik = _tcCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final diagnosis = _diagnosisCtrl.text.trim();
    final bloodPressure = _bloodPressureCtrl.text.trim();
    final pulse = _pulseCtrl.text.trim();
    final temperature = _temperatureCtrl.text.trim();
    final oxygen = _oxygenCtrl.text.trim();
    final note = _noteCtrl.text.trim();

    final values = <String>[
      if (bloodPressure.isNotEmpty) 'Tansiyon: $bloodPressure',
      if (pulse.isNotEmpty) 'Nabız: $pulse',
      if (temperature.isNotEmpty) 'Ateş: $temperature',
      if (oxygen.isNotEmpty) 'Oksijen: $oxygen',
    ].join(' • ');

    final String baseUrl = "https://kliniktakipapi.onrender.com/api";

    bool hastaVarMi = false;

    try {
      final checkResponse = await http.get(
        Uri.parse("$baseUrl/Hastalar"),
        headers: {"Content-Type": "application/json"},
      );

      if (checkResponse.statusCode == 200) {
        final List<dynamic> hastalar = jsonDecode(checkResponse.body);
        hastaVarMi = hastalar.any(
          (h) =>
              h['tcKimlik']?.toString() == tcKimlik ||
              h['TcKimlik']?.toString() == tcKimlik,
        );
        debugPrint("Hasta var mı: $hastaVarMi");
      }

      if (!hastaVarMi) {
        final hastaResponse = await http.post(
          Uri.parse("$baseUrl/Hastalar"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: jsonEncode({
            "TcKimlik": tcKimlik,
            "AdSoyad": name,
            "EvAdresi": "Belirtilmedi",
            "Telefon": phone.isNotEmpty ? phone : "Belirtilmedi",
            "KaydedenPersonel": "admin_01",
            "KayitTarihi": DateTime.now().toUtc().toIso8601String(),
          }),
        );

        debugPrint("Hasta kayıt status: ${hastaResponse.statusCode}");
        debugPrint("Hasta kayıt body: ${hastaResponse.body}");

        if (hastaResponse.statusCode != 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Hasta kayıt hatası: ${hastaResponse.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      int? tansiyonBuyuk;
      int? tansiyonKucuk;
      if (bloodPressure.isNotEmpty && bloodPressure.contains('/')) {
        final parts = bloodPressure.split('/');
        tansiyonBuyuk = int.tryParse(parts[0].trim());
        tansiyonKucuk = int.tryParse(parts[1].trim());
      }

      final klinikResponse = await http.post(
        Uri.parse("$baseUrl/KlinikVeriler"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode({
          "HastaTc": tcKimlik,
          "Ates": temperature.isNotEmpty ? double.tryParse(temperature) : null,
          "Nabiz": pulse.isNotEmpty ? int.tryParse(pulse) : null,
          "Tansiyon": bloodPressure.isNotEmpty ? bloodPressure : null,
          "Teshis": diagnosis.isNotEmpty ? diagnosis : null,
          "Oksijen": oxygen.isNotEmpty ? double.tryParse(oxygen) : null,
          "EkNotlar": note.isNotEmpty ? note : null,
          "KaydedenPersonel": "admin_01",
          "OlcumTarihi": DateTime.now().toUtc().toIso8601String(),
        }),
      );

      debugPrint("Klinik veri status: ${klinikResponse.statusCode}");
      debugPrint("Klinik veri body: ${klinikResponse.body}");

      if (!mounted) return;

      if (klinikResponse.statusCode == 200 ||
          klinikResponse.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kayıt başarıyla tamamlandı!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Klinik veri hatası: ${klinikResponse.statusCode} - ${klinikResponse.body}",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint("Bağlantı Hatası: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bağlantı hatası: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop({
      "name": name,
      "status": hastaVarMi ? "Mevcut Hasta" : "Yeni Kayıt",
      "detail": [
        diagnosis,
        if (values.isNotEmpty) values,
        if (note.isNotEmpty) note,
      ].join(' - '),
      "time": time,
      "icon": Icons.medical_information_outlined,
      "color": Colors.blueAccent,
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yeni Teşhis Kaydı',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Kimlik bilgileri ve klinik değerler',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SheetTextField(
                    controller: _tcCtrl,
                    label: 'TC Kimlik Numarası',
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value == null || value.trim().length != 11
                        ? '11 haneli TC Kimlik gereklidir'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _SheetTextField(
                    controller: _nameCtrl,
                    label: 'Hasta Adı Soyadı',
                    icon: Icons.person_outline,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Hasta adı soyadı gerekli'
                        : null,
                  ),
                  // const SizedBox(height: 12),
                  //_SheetTextField(
                  // controller: _phoneCtrl,
                  //label: 'Telefon Numarası',
                  //hint: '05XX XXX XX XX',
                  //icon: Icons.phone_outlined,
                  //keyboardType: TextInputType.phone,
                  //),
                  const SizedBox(height: 12),
                  _SheetTextField(
                    controller: _diagnosisCtrl,
                    label: 'Hastalık Teşhisi',
                    icon: Icons.local_hospital_outlined,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Teşhis bilgisi gerekli'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SheetTextField(
                          controller: _bloodPressureCtrl,
                          label: 'Tansiyon',
                          hint: '120/80',
                          icon: Icons.monitor_heart_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SheetTextField(
                          controller: _pulseCtrl,
                          label: 'Nabız',
                          hint: '72',
                          icon: Icons.favorite_border,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SheetTextField(
                          controller: _temperatureCtrl,
                          label: 'Ateş',
                          hint: '36.7',
                          icon: Icons.thermostat_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SheetTextField(
                          controller: _oxygenCtrl,
                          label: 'Oksijen',
                          hint: '%98',
                          icon: Icons.air_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SheetTextField(
                    controller: _noteCtrl,
                    label: 'Not',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Kaydet ve Gönder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
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
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
