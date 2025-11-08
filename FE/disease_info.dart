final Map<String, List<String>> diseaseDescriptions = {
  // Cabai
  'antraknosa': [
    'Bercak nekrotik muncul pada buah, berbentuk bulat, berwarna coklat hingga kehitaman.',
    'Buah bisa membusuk dan rontok sebelum matang.',
    'Sering muncul pada kondisi lembap dan hujan tinggi.',
  ],
  'bercak_cercospora': [
    'Bercak kecil berwarna coklat atau abu-abu dengan tepi berwarna ungu.',
    'Biasanya muncul di permukaan daun bagian bawah.',
    'Daun bisa mengering dan rontok jika parah.',
  ],
  'buah_sehat': [
    'Tidak ditemukan bercak atau kerusakan pada buah.',
    'Buah tampak segar dan tidak mengalami pembusukan atau perubahan warna.',
  ],
  'daun_cabai_sehat': [
    'Daun hijau segar tanpa bercak atau luka.',
    'Tidak ada gejala melingkar, bercak putih, atau kerusakan jaringan daun.',
  ],

  // Jagung
  'hawar_daun': [
    'Lesi memanjang berwarna abu-abu hingga coklat di sepanjang tulang daun.',
    'Tepi lesi tampak kekuningan.',
    'Jika parah, seluruh daun bisa mongering.',
  ],
  'penyakit_bulai': [
    'Daun muda tampak klorotik (warna kuning pucat) dan belang.',
    'Tanaman tumbuh kerdil dan mengeluarkan anakan banyak.',
    'Malai tidak terbentuk sempurna.',
  ],
  'penyakit_gosong': [
    'Tonjolan berwarna putih keperakan yang berubah menjadi hitam di tongkol atau daun.',
    'Struktur jaringan menjadi seperti massa hitam (spora).',
    'Menurunkan hasil panen secara drastis.',
  ],
  'penggerek_batang': [
    'Lubang kecil pada batang atau daun.',
    'Kotoran larva berwarna coklat terlihat di sekitar lubang.',
    'Tanaman mudah roboh dan pertumbuhan terhambat.',
  ],
  'penyakit_karat': [
    'Bercak oranye seperti serbuk muncul di permukaan daun.',
    'Bercak menyebar cepat ke seluruh daun.',
    'Daun mengering lebih awal.',
  ],

  // Padi
  'bacterial_leaf_blight': [
    'Daun menguning dari ujung ke bawah dan muncul garis coklat.',
    'Jika diraba terasa berminyak atau lengket.',
    'Penyakit cepat menyebar terutama saat musim hujan.',
  ],
  'brown_spot': [
    'Bercak coklat bulat di daun, terkadang ada tepi kuning.',
    'Tanaman kekurangan unsur gizi, terutama kalium.',
    'Bisa menyerang batang dan malai juga.',
  ],
  'leaf_smut': [
    'Garis hitam sempit di sepanjang tulang daun.',
    'Daun bisa menggulung dan mengering.',
    'Jarang menyebabkan kematian tanaman, tapi menurunkan produktivitas.',
  ],
  'padi_normal': [
    'Daun tampak hijau segar, tidak ada bercak atau gejala abnormal.',
    'Pertumbuhan normal tanpa adanya hambatan.',
  ],
};

List<String> getDiseaseDescription(String label) {
  return diseaseDescriptions[label] ?? ['Informasi gejala tidak tersedia untuk label ini.'];
}

final Map<String, List<String>> diseaseSolutions = {
  // Cabai
  'antraknosa': [
    'Gunakan fungisida berbahan aktif seperti mankozeb atau klorotalonil.',
    'Lakukan sanitasi lahan dan buang bagian tanaman yang terinfeksi.',
    'Hindari kelembaban berlebih dan perbaiki sistem drainase.',
  ],
  'bercak_cercospora': [
    'Semprotkan fungisida saat gejala awal muncul.',
    'Tanam varietas yang tahan penyakit jika tersedia.',
    'Rotasi tanaman untuk mencegah penyebaran.',
  ],
  'buah_sehat': [
    'Tidak memerlukan tindakan. Pertahankan kondisi pertumbuhan yang baik.',
  ],
  'daun_cabai_sehat': [
    'Lanjutkan perawatan rutin. Tidak ada gejala penyakit.',
  ],

  // Jagung
  'hawar_daun': [
    'Gunakan fungisida sistemik pada tahap awal serangan.',
    'Pangkas dan musnahkan daun yang terinfeksi.',
    'Gunakan benih yang tahan penyakit.',
  ],
  'penyakit_bulai': [
    'Gunakan benih jagung tahan bulai.',
    'Lakukan rotasi tanaman dan perendaman benih dengan fungisida.',
  ],
  'penyakit_gosong': [
    'Cabut dan musnahkan tanaman yang menunjukkan gejala.',
    'Hindari penanaman di lahan yang sebelumnya terinfeksi.',
  ],
  'penggerek_batang': [
    'Gunakan insektisida berbahan aktif klorpirifos.',
    'Perhatikan rotasi tanaman untuk mengurangi siklus hama.',
  ],
  'penyakit_karat': [
    'Semprotkan fungisida khusus karat seperti propikonazol.',
    'Pangkas daun yang terserang berat.',
  ],

  // Padi
  'bacterial_leaf_blight': [
    'Gunakan varietas tahan BLB dan perbaiki saluran air.',
    'Semprotkan bakterisida jika perlu.',
  ],
  'brown_spot': [
    'Berikan pupuk kalium dan silika untuk memperkuat tanaman.',
    'Gunakan fungisida bila serangan parah.',
  ],
  'leaf_smut': [
    'Tanam varietas tahan dan hindari pemupukan nitrogen berlebih.',
    'Jaga jarak tanam agar sirkulasi udara baik.',
  ],
  'padi_normal': [
    'Pertahankan pengelolaan air dan nutrisi yang optimal.',
  ],
};

List<String> getDiseaseSolution(String label) {
  return diseaseSolutions[label] ?? ['Solusi untuk penyakit ini belum tersedia.'];
}
