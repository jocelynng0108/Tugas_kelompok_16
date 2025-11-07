import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img_pkg;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'detection_model.dart';
import 'disease_info.dart';
import 'history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox('history');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Interpreter? _interpreter;
  List<String>? _labels;
  File? _imageFile;
  List<Detection> _detections = [];
  bool _busy = false;
  bool _isDarkMode = false;

  static const int INPUT_SIZE = 416;
  static double CONF_THRESH = 0.3;

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
  }

  Future<void> _loadModelAndLabels() async {
    setState(() {
      _busy = true;
    });
    _interpreter = await Interpreter.fromAsset('assets/best_float32.tflite');
    final raw = await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
    _labels = raw.split('\n').where((s) => s.isNotEmpty).toList();
    setState(() {
      _busy = false;
    });
  }

  Future<void> _pickAndDetect() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _busy = true;
      _imageFile = File(picked.path);
      _detections.clear();
    });
    await _runDetection();
  }

  Future<void> _captureFromCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return;
    setState(() {
      _busy = true;
      _imageFile = File(picked.path);
      _detections.clear();
    });
    await _runDetection();
  }

  Future<void> _runDetection() async {
    final bytes = await _imageFile!.readAsBytes();
    final orig = img_pkg.bakeOrientation(img_pkg.decodeImage(bytes)!);
    final w = orig.width;
    final h = orig.height;

    int minSide = min(orig.width, orig.height);
    int offsetX = (orig.width - minSide) ~/ 2;
    int offsetY = (orig.height - minSide) ~/ 2;
    final cropped = img_pkg.copyCrop(orig, offsetX, offsetY, minSide, minSide);
    final resized = img_pkg.copyResize(cropped, width: INPUT_SIZE, height: INPUT_SIZE);

    final inputBuffer = Float32List(INPUT_SIZE * INPUT_SIZE * 3);
    int idx = 0;
    for (int y = 0; y < INPUT_SIZE; y++) {
      for (int x = 0; x < INPUT_SIZE; x++) {
        final p = resized.getPixel(x, y);
        inputBuffer[idx++] = img_pkg.getRed(p) / 255.0;
        inputBuffer[idx++] = img_pkg.getGreen(p) / 255.0;
        inputBuffer[idx++] = img_pkg.getBlue(p) / 255.0;
      }
    }

    final input = inputBuffer.reshape([1, INPUT_SIZE, INPUT_SIZE, 3]);
    final outputRaw = List.generate(1, (_) => List.generate(19, (_) => List.filled(3549, 0.0)));
    _interpreter!.run(input, outputRaw);
    final flat = outputRaw[0];

    List<Detection> dets = [];
    for (int c = 0; c < 3549; c++) {
      double maxConf = -1.0;
      int maxIdx = -1;
      int numClasses = 14;
      for (int j = 5; j < 5 + numClasses; j++) {
        if (flat[j][c] > maxConf) {
          maxConf = flat[j][c];
          maxIdx = j - 5;
        }
      }

      if (maxConf > CONF_THRESH) {
        final cx = flat[0][c];
        final cy = flat[1][c];
        final bw = flat[2][c];
        final bh = flat[3][c];

        final x1 = cx - bw / 2;
        final y1 = cy - bh / 2;
        final x2 = cx + bw / 2;
        final y2 = cy + bh / 2;

        if ([x1, y1, x2, y2].any((v) => v < 0 || v > 1)) continue;

        // final label = _labels![maxIdx];
        final originalLabel = _labels![maxIdx];
        final label = normalizeLabel(originalLabel);
        dets.add(Detection(
          label: label,
          score: maxConf,
          rect: Rect.fromLTWH(
            x1 * w,
            y1 * h,
            (x2 - x1) * w,
            (y2 - y1) * h,
          ),
        ));
      }
    }

    dets = applyNms(dets, 0.5);

    if (dets.isNotEmpty) {
      final det = dets.first;
      print('=== MENYIMPAN DETEKSI ===');
      print('Original label: ${det.label}');
      print('Confidence: ${det.score}');
      final box = Hive.box('history');
      box.add(det.toMap());
    }


    setState(() {
      _detections = dets;
      _busy = false;
    });
  }

  Color getColorForConfidence(double score) {
    if (score < 0.5) return Colors.red;
    if (score < 0.7) return Colors.orange;
    if (score < 0.8) return Colors.yellow[700]!;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Roboto'),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[700],
          title: const Text(
            'Leaf Disease Detector',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
              tooltip: 'Toggle Dark Mode',
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Riwayat',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              ),
            )
          ],
        ),
        body: _busy
            ? const Center(
                child: SpinKitFadingCube(
                  color: Colors.green,
                  size: 50.0,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galeri'),
                          onPressed: _pickAndDetect,
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Kamera'),
                          onPressed: _captureFromCamera,
                        ),
                      ],
                    ),
                    if (_imageFile != null) ...[
                      const SizedBox(height: 20),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final image = img_pkg.decodeImage(_imageFile!.readAsBytesSync())!;
                            final imageWidth = image.width.toDouble();
                            final imageHeight = image.height.toDouble();
                            final displayWidth = constraints.maxWidth;
                            final displayHeight = displayWidth * (imageHeight / imageWidth);
                            final scaleX = displayWidth / imageWidth;
                            final scaleY = displayHeight / imageHeight;

                            return SizedBox(
                              width: displayWidth,
                              height: displayHeight,
                              child: Stack(
                                children: [
                                  Image.file(
                                    _imageFile!,
                                    width: displayWidth,
                                    height: displayHeight,
                                    fit: BoxFit.fill,
                                  ),
                                  ..._detections.map((d) {
                                    final box = d.rect;
                                    return Positioned(
                                      left: box.left * scaleX,
                                      top: box.top * scaleY,
                                      width: box.width * scaleX,
                                      height: box.height * scaleY,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: getColorForConfidence(d.score),
                                            width: 2,
                                          ),
                                        ),
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Container(
                                            color: Colors.black.withOpacity(0.5),
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: Text(
                                              '${d.label} ${(d.score * 100).toStringAsFixed(1)}%',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Hasil Deteksi:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._detections.map((d) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Icon(
                                Icons.bug_report,
                                color: getColorForConfidence(d.score),
                              ),
                              title: Text(
                                d.label,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                'Confidence: ${(d.score * 100).toStringAsFixed(1)}%',
                              ),
                            ),
                          )),
                    ]
                  ],
                ),
              ),
      ),
    );
  }
}

List<Detection> applyNms(List<Detection> dets, double iouTh) {
  dets.sort((a, b) => b.score.compareTo(a.score));
  List<Detection> res = [];
  for (var d in dets) {
    if (res.every((r) => _iou(d.rect, r.rect) <= iouTh)) res.add(d);
  }
  return res;
}

double _iou(Rect a, Rect b) {
  final x1 = max(a.left, b.left);
  final y1 = max(a.top, b.top);
  final x2 = min(a.right, b.right);
  final y2 = min(a.bottom, b.bottom);
  final inter = max(0, x2 - x1) * max(0, y2 - y1);
  final union = a.width * a.height + b.width * b.height - inter;
  return inter / union;
}

String normalizeLabel(String label) => label.toLowerCase().replaceAll(' ', '_');
