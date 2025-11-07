import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'detection_model.dart';
import 'disease_info.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final box = Hive.box('history');

  String normalizeLabel(String label) => label.toLowerCase().replaceAll(' ', '_');

  @override
  Widget build(BuildContext context) {
    final items = box.values.toList();
    final keys = box.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Deteksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Hapus Semua Riwayat',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Konfirmasi'),
                  content: const Text('Apakah kamu yakin ingin menghapus semua riwayat?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await box.clear();
                setState(() {});
              }
            },
          )
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Belum ada riwayat deteksi.'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) {
                final det = Detection.fromMap(Map<String, dynamic>.from(items[index]));
                final normalized = normalizeLabel(det.label.trim());
                final info = diseaseSolutions[normalized] ?? 'Solusi tidak tersedia';

                print('🔍 DEBUG Riwayat: label="${det.label}", normalized="$normalized"');
                print('✅ Solusi ditemukan: $info');

                return Dismissible(
                  key: Key(keys[index].toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await box.delete(keys[index]);
                    setState(() {});
                  },
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: const Icon(Icons.bug_report),
                      title: Text(det.label),
                      subtitle: Text(
                        'Confidence: ${(det.score * 100).toStringAsFixed(1)}%\nSolusi: $info',
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
