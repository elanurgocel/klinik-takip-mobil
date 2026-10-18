import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'new_patient_data_sheet.dart';
import 'patients_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';
import 'app_header_actions.dart';
import 'header_action_panels.dart';

class DashboardPage extends StatefulWidget {
  // DÜZELTME: Giriş yapan kullanıcının ID'sini artık dışarıdan alıyoruz.
  final String userId;

  const DashboardPage({Key? key, required this.userId}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // API'den gelecek verileri tutacağımız liste
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;

  // AI Özeti için dinamik sayaçlar
  int _aiAlertCount = 0;
  String _latestAlertName = "";

  @override
  void initState() {
    super.initState();
    _fetchDailyData(); // Ekran açılır açılmaz bugünün verilerini çek
  }

  // C# API'sinden SADECE BUGÜNÜN verilerini çeken fonksiyon
  Future<void> _fetchDailyData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          "https://kliniktakipapi.onrender.com/api/KlinikVeriler/gunluk",
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> mappedPatients = [];

        int alertCount = 0;
        String alertName = "";

        for (var item in data) {
          String name = item['adSoyad'] ?? 'İsimsiz Hasta';

          // Tarihi saat formatına (HH:mm) çevirme
          String timeStr = "00:00";
          if (item['olcumTarihi'] != null) {
            DateTime dt = DateTime.parse(item['olcumTarihi']).toLocal();
            timeStr =
                "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
          }

          // === YAPAY ZEKA KARAR DESTEK SİMÜLASYONU ===
          String status = "Stabil";
          Color color = Colors.green;
          IconData icon = Icons.check_circle;
          String detail =
              item['teshis']?.toString() ?? "Değerler normal seyrediyor.";

          double? ates = item['ates'] != null
              ? double.tryParse(item['ates'].toString())
              : null;
          int? nabiz = item['nabiz'] != null
              ? int.tryParse(item['nabiz'].toString())
              : null;
          String tansiyon = item['tansiyon']?.toString() ?? "";

          // Kritik Durum (Örn: Ateş 38 üstü veya Nabız 120 üstü)
          if ((ates != null && ates >= 38.0) ||
              (nabiz != null && nabiz >= 120)) {
            status = "Kritik";
            color = Colors.redAccent;
            icon = Icons.error_outline;
            detail = "Acil kontrol: Ateş veya nabız yüksek.";
            alertCount++;
            alertName = name;
          }
          // AI Uyarısı (Örn: Tansiyon 120/80 değilse - Basit bir anomali kontrolü)
          else if (tansiyon.isNotEmpty && tansiyon != "120/80") {
            status = "AI Uyarısı";
            color = Colors.orange;
            icon = Icons.warning_amber_rounded;
            detail = "Tansiyon verilerinde dalgalanma ($tansiyon).";
            alertCount++;
            alertName = name;
          }

          mappedPatients.add({
            "name": name,
            "status": status,
            "detail": detail,
            "time": timeStr,
            "icon": icon,
            "color": color,
          });
        }

        if (!mounted) return;
        setState(() {
          _patients = mappedPatients;
          _aiAlertCount = alertCount;
          _latestAlertName = alertName;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("API Bağlantı Hatası: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openNewDataForm() async {
    final newPatient = await showNewPatientDataSheet(context);
    if (newPatient == null) return;

    // Veritabanına yeni bir veri eklendiğini varsayarak listeyi yeniliyoruz
    await _fetchDailyData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Hasta Takip Paneli',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        /* actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TopRightHeaderActions(
              notificationCount:
                  _aiAlertCount, // Bildirim ikonunda anomali sayısını göster
              userInitials: 'EG',
              onNotificationsTap: () {},
              onProfileTap: () {},
            ),
          ),
        ],*/
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- AI DOKTOR ÖZET KARTI ---
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Colors.white, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Doktor AI Özeti',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // AI Metni Verilere Göre Dinamik Değişir
                      Text(
                        _aiAlertCount > 0
                            ? 'Bugün $_aiAlertCount hastada düzensiz veri tespit edildi. Lütfen "$_latestAlertName" kaydını inceleyin.'
                            : 'Bugün kontrol edilen tüm hastaların değerleri stabil seyrediyor. Herhangi bir anomali bulunmuyor.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- HASTA LİSTESİ BAŞLIĞI ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Text(
              'Günlük Takip Listesi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
          ),

          // --- HASTALAR LİSTESİ (Pull-to-Refresh ile entegre) ---
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchDailyData,
              color: Colors.blueAccent,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _patients.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              "Bugün için girilmiş klinik veri bulunmuyor.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _patients.length,
                      itemBuilder: (context, index) {
                        final patient = _patients[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          shadowColor: Colors.black12,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: patient['color'].withValues(
                                alpha: 0.1,
                              ),
                              radius: 25,
                              child: Icon(
                                patient['icon'],
                                color: patient['color'],
                                size: 28,
                              ),
                            ),
                            title: Text(
                              patient['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                patient['detail'],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  patient['time'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: patient['color'].withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    patient['status'],
                                    style: TextStyle(
                                      color: patient['color'],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              // TODO: Detay sayfasına yönlendirme eklenebilir
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),

      // --- YENİ VERİ GİRİŞİ BUTONU ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewDataForm,
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add_chart, color: Colors.white),
        label: const Text(
          "Yeni Veri Gir",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // --- ALT NAVİGASYON ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PatientsPage()));
            return;
          }
          if (index == 1) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ReportsPage()));
            return;
          }
          if (index == 2) {
            // DÜZELTME: Ayarlar sayfasına artık giriş yapan kullanıcının ID'si iletiliyor.
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsPage(userId: widget.userId),
              ),
            );
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt),
            label: 'Hastalar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Raporlar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}

// ALTTAN ÇIKAN VERİ GİRİŞ SAYFASI FORMU (Alt Kısmı Değiştirilmedi, Sadece Eski Haliyle Korundu)
class _NewPatientDataSheet extends StatefulWidget {
  const _NewPatientDataSheet();

  @override
  State<_NewPatientDataSheet> createState() => _NewPatientDataSheetState();
}

class _NewPatientDataSheetState extends State<_NewPatientDataSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _bloodPressureCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _temperatureCtrl = TextEditingController();
  final _oxygenCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _diagnosisCtrl.dispose();
    _bloodPressureCtrl.dispose();
    _pulseCtrl.dispose();
    _temperatureCtrl.dispose();
    _oxygenCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = TimeOfDay.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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

    Navigator.of(context).pop({
      "name": _nameCtrl.text.trim(),
      "status": "Yeni Kayıt",
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
                          Icons.add_chart,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yeni Veri Gir',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Hasta bilgileri ve günlük değerler',
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
                    controller: _nameCtrl,
                    label: 'Hasta Adı Soyadı',
                    icon: Icons.person_outline,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Hasta adı soyadı gerekli'
                        : null,
                  ),
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
                      label: const Text('Kaydet'),
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
