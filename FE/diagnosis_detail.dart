import 'package:flutter/material.dart';
import 'disease_info.dart';

class DiagnosisDetailPage extends StatelessWidget {
  final String label;

  const DiagnosisDetailPage({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedLabel = label.toLowerCase().replaceAll(' ', '_');
    final gejalaList = getDiseaseDescription(formattedLabel);
    final solusiList = getDiseaseSolution(formattedLabel);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          label.replaceAll('_', ' ').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        color: const Color(0xFFF5F5F5), // Warna latar lembut
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul Penyakit
              Center(
                child: Text(
                  label.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Gejala
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            "Gejala Penyakit",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...gejalaList.map((desc) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text("• $desc"),
                          )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Solusi
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.lightbulb_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            "Solusi / Penanganan",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...solusiList.map((solution) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text("• $solution"),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
