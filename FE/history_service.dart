import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DetectionHistoryItem {
  final String imagePath;
  final DateTime timestamp;
  final List<String> detectedLabels;
  final List<String> symptoms;
  final List<double> confidences;

  DetectionHistoryItem({
    required this.imagePath,
    required this.timestamp,
    required this.detectedLabels,
    required this.symptoms,
    required this.confidences,
  });

  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'timestamp': timestamp.toIso8601String(),
        'detectedLabels': detectedLabels,
        'symptoms': symptoms,
        'confidences': confidences,
      };

  factory DetectionHistoryItem.fromJson(Map<String, dynamic> json) =>
      DetectionHistoryItem(
        imagePath: json['imagePath'],
        timestamp: DateTime.parse(json['timestamp']),
        detectedLabels: List<String>.from(json['detectedLabels']),
        symptoms: List<String>.from(json['symptoms']),
        confidences:
            List<double>.from(json['confidences'].map((x) => x.toDouble())),
      );
}

class HistoryService {
  static const String _historyKey = 'detection_history';

  /// Simpan item ke dalam riwayat
  static Future<void> addToHistory(DetectionHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    history.insert(0, item); // Tambahkan di paling atas (terbaru)
    final encoded =
        history.map((e) => jsonEncode(e.toJson())).toList();

    await prefs.setStringList(_historyKey, encoded);
  }

  /// Ambil semua riwayat deteksi
  static Future<List<DetectionHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedList = prefs.getStringList(_historyKey) ?? [];

    return encodedList
        .map((e) => DetectionHistoryItem.fromJson(jsonDecode(e)))
        .toList();
  }

  /// Hapus semua riwayat
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Hapus satu item berdasarkan index
  static Future<void> removeItemAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      final encoded =
          history.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_historyKey, encoded);
    }
  }
}
