import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isLoading = true;
  List<_StatusGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // API'ye istek atıyoruz (Port numarasının Visual Studio'daki ile aynı olduğundan emin ol)
      final response = await http.get(
        Uri.parse("https://kliniktakipapi.onrender.com/api/Rapor/genel-durum"),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // API'den gelen JSON verisini Flutter modelimize çeviriyoruz
        final List<_StatusGroup> fetchedGroups = data.map((json) {
          String title = json['title'] ?? 'Belirsiz';
          return _StatusGroup(
            title: title,
            count: json['count'] ?? 0,
            icon: _getIconForStatus(title),
            color: _getColorForStatus(title),
            patients: (json['patients'] as List)
                .map(
                  (p) => _StatusPatient(
                    name: p['name'] ?? 'İsimsiz',
                    symptom: p['symptom'] ?? '-',
                    note: p['note'] ?? '-',
                  ),
                )
                .toList(),
          );
        }).toList();

        setState(() {
          _groups = fetchedGroups;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint("Rapor verisi çekilemedi: $e");
    }
  }

  // Backend'den gelen metne göre uygun rengi seçen yardımcı fonksiyon
  Color _getColorForStatus(String status) {
    switch (status) {
      case 'Stabil':
        return Colors.green;
      case 'İnceleme Gerekli':
        return Colors.orange;
      case 'Kritik':
        return Colors.redAccent;
      case 'AI İncelemesi':
        return Colors.deepPurple;
      default:
        return Colors.blueGrey;
    }
  }

  // Backend'den gelen metne göre uygun ikonu seçen yardımcı fonksiyon
  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'Stabil':
        return Icons.check_circle_outline;
      case 'İnceleme Gerekli':
        return Icons.report_outlined;
      case 'Kritik':
        return Icons.warning_amber_rounded;
      case 'AI İncelemesi':
        return Icons.psychology_outlined;
      default:
        return Icons.info_outline;
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
        title: const Text(
          'Raporlar',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list, color: Colors.blueAccent),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Genel Durum',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Eğer veritabanı boşsa veya veri gelmediyse bilgi mesajı göster
                  _groups.isEmpty
                      ? const Expanded(
                          child: Center(
                            child: Text("Henüz hasta verisi bulunmuyor."),
                          ),
                        )
                      : Expanded(
                          // Sayfanın kalan tüm boşluğunu kaplaması için eklendi
                          child: GridView.builder(
                            physics:
                                const BouncingScrollPhysics(), // Küçük ekranlarda aşağı kaydırma desteği
                            itemCount: _groups.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio:
                                      0.65, // Kartları aşağı doğru uzatan değer (0.92'den 0.65'e düşürüldü)
                                ),
                            itemBuilder: (context, index) {
                              return _StatusGroupCard(group: _groups[index]);
                            },
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}

class _StatusGroupCard extends StatefulWidget {
  final _StatusGroup group;

  const _StatusGroupCard({required this.group});

  @override
  State<_StatusGroupCard> createState() => _StatusGroupCardState();
}

class _StatusGroupCardState extends State<_StatusGroupCard> {
  // Kaydırma çubuğunu ve listeyi birbirine bağlayacak olan ortak kontrolcü
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    // Kart ekrandan silindiğinde hafıza sızıntısı olmaması için kontrolcüyü kapatıyoruz
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.group.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.group.icon,
                  color: widget.group.color,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.group.count}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.group.title,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              radius: const Radius.circular(8),
              child: ListView.separated(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(right: 8),
                itemCount: widget.group.patients.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final patient = widget.group.patients[index];
                  return _PatientMiniRow(
                    patient: patient,
                    color: widget.group.color,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientMiniRow extends StatelessWidget {
  final _StatusPatient patient;
  final Color color;

  const _PatientMiniRow({required this.patient, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            patient.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            patient.symptom,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            patient.note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _StatusGroup {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final List<_StatusPatient> patients;

  const _StatusGroup({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.patients,
  });
}

class _StatusPatient {
  final String name;
  final String symptom;
  final String note;

  const _StatusPatient({
    required this.name,
    required this.symptom,
    required this.note,
  });
}
