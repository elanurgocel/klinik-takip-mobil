import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'new_patient_registration_page.dart';
import 'api_config.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  // API'den gelecek gerçek veritabanı listesi için değişkenlerimiz
  List<dynamic> _databasePatients = [];
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  // Silme işlemi süren hastaların TC'leri (çift tıklamayı önlemek için)
  final Set<String> _deletingTcs = {};

  @override
  void initState() {
    super.initState();
    _fetchPatients(); // Sayfa açılır açılmaz veritabanından hastaları çekiyoruz
    _searchCtrl.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchCtrl.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    if (!mounted) return; // Sayfa kapandıysa durdur
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse("$apiBaseUrl/api/Hastalar"));

      if (!mounted) return; // Veri geldikten sonra sayfa kapandıysa durdur

      if (response.statusCode == 200) {
        setState(() {
          _databasePatients = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        debugPrint("API Get Hatası: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      debugPrint("API Bağlantı Hatası: $e");
    }
  }

  // ---------------------------------------------------------------
  // HASTA SİLME
  // ---------------------------------------------------------------
  Future<void> _deletePatient(Map<String, dynamic> patient) async {
    final String tc = (patient['tcKimlik'] ?? '').toString();
    final String name = (patient['adSoyad'] ?? 'İsimsiz Hasta').toString();

    if (tc.isEmpty || _deletingTcs.contains(tc)) return;

    // 1. Onay penceresi
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hastayı Sil'),
        content: Text(
          '$name (TC: $tc) adlı hastayı ve ona ait tüm ölçüm kayıtlarını '
          'silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingTcs.add(tc));

    // 2. API'ye silme isteği
    try {
      final response = await http.delete(
        Uri.parse("$apiBaseUrl/api/Hastalar/${Uri.encodeComponent(tc)}"),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _databasePatients.removeWhere(
            (p) => (p['tcKimlik'] ?? '').toString() == tc,
          );
          _deletingTcs.remove(tc);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name kaydı silindi.')));
      } else {
        String message =
            'Silme işlemi başarısız (Sunucu kodu: ${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['mesaj'] != null) {
            message = body['mesaj'].toString();
          }
        } catch (_) {}

        setState(() => _deletingTcs.remove(tc));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingTcs.remove(tc));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sunucuya bağlanılamadı. İnternetinizi kontrol edin.'),
        ),
      );
      debugPrint("Silme Bağlantı Hatası: $e");
    }
  }

  Future<void> _openNewPatientRegistration() async {
    final result = await showNewPatientRegistrationPage(context);
    if (result == null) return;
    if (!mounted) return;

    // Yeni hasta eklendikten sonra listeyi veritabanından tekrar güncelleyelim
    setState(() {
      _isLoading = true;
    });
    await _fetchPatients();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.fullName} kaydı başarıyla eklendi.')),
    );
  }

  List<dynamic> get _filteredPatients {
    if (_searchQuery.isEmpty) return _databasePatients;

    final query = _searchQuery.toLowerCase();
    return _databasePatients.where((patient) {
      final name = (patient['adSoyad'] ?? '').toString().toLowerCase();
      final tc = (patient['tcKimlik'] ?? '').toString().toLowerCase();
      return name.contains(query) || tc.contains(query);
    }).toList();
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: 'TC veya isim ile ara',
        prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.blueAccent),
                onPressed: () {
                  _searchCtrl.clear();
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Hastalar',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (!mounted) return;
              setState(() => _isLoading = true);
              _fetchPatients();
            },
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            tooltip: 'Listeyi Güncelle',
          ),
          IconButton(
            onPressed: _openNewPatientRegistration,
            icon: const Icon(Icons.person_add_alt_1, color: Colors.blueAccent),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!mounted) return;
          setState(() => _isLoading = true);
          await _fetchPatients();
        },
        color: Colors.blueAccent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildSearchBar(),
            const SizedBox(height: 14),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredPatients.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Veritabanında kayıtlı hasta bulunamadı.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              for (final dbPatient in _filteredPatients) ...[
                _ApiPatientCard(
                  patient: dbPatient,
                  isDeleting: _deletingTcs.contains(
                    (dbPatient['tcKimlik'] ?? '').toString(),
                  ),
                  onDelete: () => _deletePatient(dbPatient),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PatientDetailPage(
                          patientName: dbPatient['adSoyad'] ?? 'İsimsiz Hasta',
                          tcKimlik: dbPatient['tcKimlik'] ?? '',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewPatientRegistration,
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Yeni Hasta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ApiPatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isDeleting;

  const _ApiPatientCard({
    required this.patient,
    required this.onTap,
    required this.onDelete,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: isDeleting ? null : onTap,
        contentPadding: const EdgeInsets.only(
          left: 16,
          right: 4,
          top: 10,
          bottom: 10,
        ),
        leading: const CircleAvatar(
          radius: 26,
          backgroundColor: Color(0xFFEFF6FF),
          child: Icon(
            Icons.storage_rounded,
            color: Colors.blueAccent,
            size: 28,
          ),
        ),
        title: Text(
          patient['adSoyad'] ?? 'İsimsiz Hasta',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'TC: ${patient['tcKimlik'] ?? '---'} • Tel: ${patient['telefon'] ?? '---'}\nAdres: ${patient['evAdresi'] ?? 'Belirtilmedi'}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
        trailing: isDeleting
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Hastayı Sil',
              ),
      ),
    );
  }
}

class PatientDetailPage extends StatefulWidget {
  final String patientName;
  final String tcKimlik;

  const PatientDetailPage({
    super.key,
    required this.patientName,
    required this.tcKimlik,
  });

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  bool _isLoading = true;
  List<PatientControl> _controls = [];
  String _latestDiagnosis = "Teşhis aranıyor...";

  @override
  void initState() {
    super.initState();
    _fetchPatientDetails();
  }

  Future<void> _fetchPatientDetails() async {
    if (widget.tcKimlik.isEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/KlinikVeriler/hasta/${widget.tcKimlik}"),
      );

      if (!mounted) {
        return; // Veri geldikten sonra sayfa kapandıysa işlemi durdur
      }

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          List<PatientControl> loadedControls = [];

          for (var row in data) {
            DateTime dt =
                DateTime.tryParse(row['olcumTarihi']?.toString() ?? '') ??
                DateTime.now();
            String formattedDate =
                "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}";
            String formattedTime =
                "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

            loadedControls.add(
              PatientControl(
                date: formattedDate,
                time: formattedTime,
                bloodPressure: row['tansiyon']?.toString() ?? "-",
                pulse: row['nabiz']?.toString() ?? "-",
                temperature: row['ates']?.toString() ?? "-",
                oxygen: row['oksijen']?.toString() ?? "-",
                note: row['ekNotlar']?.toString() ?? "Not eklenmedi.",
              ),
            );
          }

          setState(() {
            _controls = loadedControls;
            _latestDiagnosis =
                data.first['teshis']?.toString() ?? "Belirtilmedi";
            _isLoading = false;
          });
        } else {
          setState(() {
            _latestDiagnosis = "Kayıtlı ölçüm yok";
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
        debugPrint("Ölçüm Getirme Hatası: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint("Ölçüm Bağlantı Hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          widget.patientName,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blueAccent.withValues(
                          alpha: 0.12,
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          color: Colors.blueAccent,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _latestDiagnosis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Kayıtlı Hasta',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Yapılan Kontroller',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 12),
                if (_controls.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(
                      child: Text(
                        'Henüz kayıtlı kontrol verisi bulunmuyor.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  for (final control in _controls)
                    _ControlCard(control: control),
              ],
            ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  final PatientControl control;

  const _ControlCard({required this.control});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_outlined, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${control.date} • ${control.time}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ValueChip(label: 'Tansiyon', value: control.bloodPressure),
                _ValueChip(label: 'Nabız', value: control.pulse),
                _ValueChip(label: 'Ateş', value: control.temperature),
                _ValueChip(label: 'Oksijen', value: '%${control.oxygen}'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              control.note,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  final String label;
  final String value;

  const _ValueChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class PatientControl {
  final String date;
  final String time;
  final String bloodPressure;
  final String pulse;
  final String temperature;
  final String oxygen;
  final String note;

  const PatientControl({
    required this.date,
    required this.time,
    required this.bloodPressure,
    required this.pulse,
    required this.temperature,
    required this.oxygen,
    required this.note,
  });
}
