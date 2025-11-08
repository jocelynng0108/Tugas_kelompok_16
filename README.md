# Aplikasi Deteksi Penyakit Tanaman
Proyek ini adalah aplikasi berbasis Flutter untuk mendeteksi berbagai penyakit tanaman menggunakan YOLOv8 yang dikonversi ke TensorFlow Lite (TFLite). Proyek ini dibuat untuk tugas kuliah.
________________________________________________________________________________________________________________________________________________________________________________
# Daftar Anggota Kelompok 16

221110108 - Jocelyn

221112816 - Maesi Sarah Natasia Br. Simanjuntak

Link URL : https://mikroskilacid-my.sharepoint.com/:f:/g/personal/221110108_students_mikroskil_ac_id/Eg8PfS_h2U1KuEJO4XOlyqwB4XWKWoukrmC6FXn3OlST9w?e=0iw6ik
Petunjuk Penggunaan Aplikasi:
1.	Buka Link URL dan download file APK nya  dengan catatan harus menggunakan mobile karena aplikasinya hanya bisa digunakan dalam mobile  
2.	Buka aplikasi yang telah didownload 
3.	Ambil gambar tanaman yang memiliki penyakit dari Pilih dari Galeri
4.	Muncul hasil deteksi penyakit tanamannya 
5.	Pilih Lihat  Diagnosis jika ingin mengetahui gejala penyakit dan solusi untuk mengatasinya

______________________________________________________________________________________________________________________________________________________________________________ 
1. Tahap Training Data di Google Colab
Install Library
!pip install ultralytics

from ultralytics import YOLO

model = YOLO('yolov8n.pt')  # load a pretrained model (disarankan)

results = model.train(

    data='datasetPenyakitTanaman/data.yaml', 

    epochs=50, 

    imgsz=416, 

    device=0  # gunakan GPU 0

)
Hasil Training
Class	Images	Instances	Precision	Recall	mAP50	mAP50-95
Antraknosa	83	83	0.970	0.988	0.985	0.800
Bercak Cercospora	80	227	0.907	0.559	0.762	0.364
Buah sehat	86	91	0.987	0.978	0.988	0.851
Daun Cabai Sehat	78	83	0.995	1.000	0.995	0.934
Hawar_Daun	68	86	0.929	0.884	0.916	0.630
Penyakit_Bulai	61	61	0.994	0.984	0.995	0.938
Penyakit_Gosong	101	103	0.994	0.981	0.995	0.866
Penggerek_Batang	67	67	0.963	1.000	0.988	0.840
Penyakit_Karat	69	87	1.000	0.746	0.782	0.609
Bacterial Leaf Blight	147	147	0.998	1.000	0.995	0.886
Brown Spot	86	86	0.996	1.000	0.995	0.940
Leaf Smut	70	70	0.995	1.000	0.995	0.875
Padi Normal	43	43	0.991	1.000	0.995	0.912
Total	1038	1234	0.978	0.932	0.953	0.804
2. Konversi Model ke TensorFlow Lite
from ultralytics import YOLO

model = YOLO("runs/detect/train/weights/best.pt")  

model.export(format="tflite", dynamic=False, int8=False)  # menghasilkan best_float32.tflite
3. Pengembangan Aplikasi Flutter
Struktur Projek
disease_plant/

├─ assets/

│ ├─ best_float32.tflite # model TFLite

│ └─ labels.txt # daftar kelas penyakit tanaman

├─ lib/

│ ├─ main.dart # proses parsing dan inference model TFLite

│ ├─ diagnosis_detail.dart # menampilkan detail hasil diagnosa

│ ├─ disease_info.dart # menampilkan informasi penyakit

│ ├─ history_page.dart # halaman riwayat diagnosa

│ └─ history_service.dart # manajemen penyimpanan dan pengambilan data riwayat

└─ install.bat # otomatis download library TFLite C untuk Android (CPU/GPU delegate)
Penjelasan File Dart
File	Fungsi Singkat
main.dart	Inisialisasi TFLite, capture kamera, dan jalankan inference model
diagnosis_detail.dart	Menampilkan detail diagnosis untuk satu deteksi
disease_info.dart	Menampilkan info umum tentang penyakit (gejala, pencegahan, dll.)
history_page.dart	Menampilkan riwayat diagnosa sebelumnya
history_service.dart	Mengelola penyimpanan dan pengambilan data riwayat secara lokal
pubspec.yaml Dependencies
Package	Fungsi
cupertino_icons	Ikon iOS
image_picker	Pilih gambar dari galeri atau kamera
image	Proses dan manipulasi gambar
tflite_flutter	Integrasi model TensorFlow Lite ke Flutter
camera	Capture live camera input
flutter_spinkit	Animasi loading/spinner
path_provider	Akses path penyimpanan lokal
shared_preferences	Penyimpanan data ringan seperti riwayat diagnosa
flutter_slidable	Widget slide untuk list item (misal hapus riwayat)
intl	Format tanggal/waktu
Build & Konfigurasi Android
Compile SDK: 33

Min SDK: 26

NDK Version: 27.0.12077973

Kotlin JVM target: 11

ProGuard aktif untuk release
Cara Menjalankan
flutter pub get

flutter run
Catatan
Model yang digunakan adalah YOLOv8n yang dikonversi ke TFLite.

install.bat berguna untuk menyiapkan library TFLite native di Android.

Labels disesuaikan dengan dataset penyakit tanaman yang digunakan.

https://colab.research.google.com/drive/19i2XGIO7CP9NFHg6UuCn7ipPyS8ACzPE
