import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img_pkg;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'disease_info.dart';
import 'diagnosis_detail.dart';
import 'history_page.dart';
import 'history_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DiagnosisPage(),
    );
  }
}

class DiagnosisPage extends StatefulWidget {
  const DiagnosisPage({Key? key}) : super(key: key);

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  File? _imageFile;
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _loading = false;

  static const int INPUT_SIZE = 416;

  List<Rect> _boxes = [];
  List<String> _boxLabels = [];
  List<double> _boxScores = [];

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/best_float32.tflite');
    final raw = await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
    _labels = raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final numChannels = outputShape[1];
    final numClasses = numChannels - 4;

    if (_labels!.length != numClasses) {
      throw Exception('Jumlah label (${_labels!.length}) tidak cocok dengan jumlah kelas model ($numClasses).');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    setState(() {
      _loading = true;
      _imageFile = File(picked.path);
    });
    await Future.delayed(const Duration(milliseconds: 800));
    await _runModel();
  }

  Future<void> _runModel() async {
    final bytes = await _imageFile!.readAsBytes();
    final originalImage = img_pkg.decodeImage(bytes)!;

    final inputImage = img_pkg.copyResizeCropSquare(originalImage, INPUT_SIZE);
    final input = Float32List(INPUT_SIZE * INPUT_SIZE * 3);
    int i = 0;
    for (int y = 0; y < INPUT_SIZE; y++) {
      for (int x = 0; x < INPUT_SIZE; x++) {
        final pixel = inputImage.getPixel(x, y);
        input[i++] = img_pkg.getRed(pixel) / 255.0;
        input[i++] = img_pkg.getGreen(pixel) / 255.0;
        input[i++] = img_pkg.getBlue(pixel) / 255.0;
      }
    }

    final reshaped = input.reshape([1, INPUT_SIZE, INPUT_SIZE, 3]);
    var output = List.generate(1, (_) => List.generate(17, (_) => List.filled(3549, 0.0)));
    _interpreter!.run(reshaped, output);

    final detections = List.generate(3549, (i) => List.generate(17, (j) => output[0][j][i]));

    List<Rect> boxes = [];
    List<String> labels = [];
    List<double> scores = [];

    for (var det in detections) {
      final x = det[0];
      final y = det[1];
      final w = det[2];
      final h = det[3];
      final classScores = det.sublist(4);
      final maxScore = classScores.reduce(max);
      final classIndex = classScores.indexOf(maxScore);

      if (maxScore > 0.4) {
        final left = (x - w / 2) * INPUT_SIZE;
        final top = (y - h / 2) * INPUT_SIZE;
        final box = Rect.fromLTWH(left, top, w * INPUT_SIZE, h * INPUT_SIZE);

        boxes.add(box);
        labels.add(_labels![classIndex]);
        scores.add(maxScore);
      }
    }

    final filtered = _applyNMS(boxes, scores, labels, iouThreshold: 0.45);

    setState(() {
      _boxes = filtered.map((e) => e.box).toList();
      _boxScores = filtered.map((e) => e.score).toList();
      _boxLabels = filtered.map((e) => e.label).toList();
      _loading = false;
    });

    // ✅ Simpan ke riwayat
    if (_boxLabels.isNotEmpty) {
      final detectedSymptoms = _boxLabels.map((l) {
        final info = getDiseaseDescription(l.toLowerCase().replaceAll(' ', '_'));
        return info.join(', ');
      }).toList();

      final item = DetectionHistoryItem(
        imagePath: _imageFile!.path,
        timestamp: DateTime.now(),
        detectedLabels: _boxLabels,
        confidences: _boxScores,
        symptoms: detectedSymptoms,
      );
      await HistoryService.addToHistory(item);
    }
  }

  List<_Detection> _applyNMS(List<Rect> boxes, List<double> scores, List<String> labels,
      {double iouThreshold = 0.5}) {
    final List<_Detection> detections = List.generate(
      boxes.length,
      (i) => _Detection(boxes[i], scores[i], labels[i]),
    );

    detections.sort((a, b) => b.score.compareTo(a.score));

    final List<_Detection> finalDetections = [];

    while (detections.isNotEmpty) {
      final best = detections.removeAt(0);
      finalDetections.add(best);

      detections.removeWhere((d) =>
          d.label == best.label && _iou(best.box, d.box) > iouThreshold);
    }

    return finalDetections;
  }

  double _iou(Rect a, Rect b) {
    final double interArea = (a.intersect(b)).width * (a.intersect(b)).height;
    final double unionArea = a.width * a.height + b.width * b.height - interArea;
    return unionArea == 0 ? 0 : interArea / unionArea;
  }

  @override
  Widget build(BuildContext context) {
    final uniqueLabels = _boxLabels.toSet().toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Deteksi Penyakit Tanaman Lokal', style: TextStyle(fontWeight: FontWeight.bold,),),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Deteksi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          )
        ],
      ),
      body: _loading
        ? const Center(
          child: SpinKitWave(
            color: Colors.green,
            size: 50.0,
          ),
        )
    : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ Highlight Informasi Atas
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Text(
                'Silakan periksa apakah salah satu penyakit di bawah ini cocok dengan kerusakan pada tanaman Anda',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

            if (_imageFile != null)
              LayoutBuilder(
                builder: (context, constraints) {
                  final displaySize = Size(INPUT_SIZE.toDouble(), INPUT_SIZE.toDouble());
                  return Center(
                    child: SizedBox(
                      width: displaySize.width,
                      height: displaySize.height,
                      child: Stack(
                        children: [
                          Image.file(
                            _imageFile!,
                            width: displaySize.width,
                            height: displaySize.height,
                            fit: BoxFit.cover,
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: BoundingBoxPainter(_boxes, _boxLabels, _boxScores),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),

            if (uniqueLabels.isNotEmpty)
              ...uniqueLabels.map((label) {
                final gejala = getDiseaseDescription(label.toLowerCase().replaceAll(' ', '_'));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 6),
                        Text('Gejala', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...gejala.map((desc) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text('• $desc'),
                        )),
                    const SizedBox(height: 12),

                    // ✅ Tombol Rapi & Konsisten
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.medical_services_outlined),
                        label: const Text('Lihat Diagnosis'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DiagnosisDetailPage(label: label),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),

            if (uniqueLabels.isEmpty)
              // ✅ Highlight jika belum ada gambar
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 8, bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: const Text(
                  'Belum ada gambar yang dipilih',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
              ),

            // ✅ Tombol Pilih Gambar dari Galeri
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Pilih dari Galeri'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 12),

            // ✅ Tombol Ambil dari Kamera
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil dari Kamera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detection {
  final Rect box;
  final double score;
  final String label;

  _Detection(this.box, this.score, this.label);
}

class BoundingBoxPainter extends CustomPainter {
  final List<Rect> boxes;
  final List<String> labels;
  final List<double> scores;

  BoundingBoxPainter(this.boxes, this.labels, this.scores);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      backgroundColor: Colors.black.withOpacity(0.7),
    );

    for (int i = 0; i < boxes.length; i++) {
      final rect = boxes[i];
      canvas.drawRect(rect, paint);

      final textSpan = TextSpan(
        text: '${labels[i]} (${(scores[i] * 100).toStringAsFixed(0)}%)',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
