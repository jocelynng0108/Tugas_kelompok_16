import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'history_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<DetectionHistoryItem> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final data = await HistoryService.getHistory();
    setState(() {
      history = data;
    });
  }

  Future<void> deleteItem(int index) async {
    await HistoryService.removeItemAt(index);
    await loadHistory();
  }

  Future<void> clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Riwayat?'),
        content: const Text('Apakah Anda yakin ingin menghapus seluruh riwayat deteksi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm == true) {
      await HistoryService.clearHistory();
      await loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Deteksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Hapus Semua',
            onPressed: clearAll,
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(
              child: Text('Belum ada riwayat deteksi.'),
            )
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Slidable(
                  key: Key(item.timestamp.toIso8601String()),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.25,
                    children: [
                      SlidableAction(
                        onPressed: (_) => deleteItem(index),
                        backgroundColor: Colors.red,
                        icon: Icons.delete,
                        label: 'Hapus',
                      ),
                    ],
                  ),
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          child: Image.file(
                            File(item.imagePath),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                height: 200,
                                child: Center(child: Icon(Icons.broken_image, size: 50)),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Waktu Deteksi: ${DateFormat('dd MMM yyyy, HH:mm').format(item.timestamp)}',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(item.detectedLabels.length, (i) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.detectedLabels[i]} - ${(item.confidences[i] * 100).toStringAsFixed(2)}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Gejala: ${item.symptoms[i]}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
