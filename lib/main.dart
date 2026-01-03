import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SuVeriModeli(),
      child: const SuTakipUygulamasi(),
    ),
  );
}

// --- 1. VERİ VE MANTIK KATMANI (BACKEND MANTIĞI) ---
class SuVeriModeli extends ChangeNotifier {
  // Tarih ve Miktar tutan basit bir yapı: "2026-01-04": 2500
  Map<String, int> gunlukKayitlar = {};
  int gunlukHedef = 2500; // ml

  SuVeriModeli() {
    verileriYukle();
  }

  // Bugünün tarihi (Örn: "2026-01-04")
  String get bugunTarih => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Bugün içilen toplam su
  int get bugunIcilen => gunlukKayitlar[bugunTarih] ?? 0;

  // Su Ekleme Fonksiyonu
  void suEkle(int miktar) {
    int mevcut = gunlukKayitlar[bugunTarih] ?? 0;
    gunlukKayitlar[bugunTarih] = mevcut + miktar;
    verileriKaydet();
    notifyListeners(); // Ekranı güncelle
  }

  // Verileri Telefona Kaydet (JSON olarak)
  Future<void> verileriKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(gunlukKayitlar);
    prefs.setString('su_verileri', jsonString);
  }

  // Verileri Telefondan Oku
  Future<void> verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('su_verileri')) {
      String? jsonString = prefs.getString('su_verileri');
      Map<String, dynamic> decoded = json.decode(jsonString!);
      gunlukKayitlar = decoded.map((key, value) => MapEntry(key, value as int));
      notifyListeners();
    }
  }

  // Son 7 günün verisini grafik için hazırlar
  List<double> haftalikVeriGetir() {
    List<double> veriler = [];
    DateTime bugun = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime gun = bugun.subtract(Duration(days: i));
      String tarihKey = DateFormat('yyyy-MM-dd').format(gun);
      veriler.add((gunlukKayitlar[tarihKey] ?? 0).toDouble());
    }
    return veriler;
  }
}

// --- 2. UYGULAMA ARAYÜZÜ (UI) ---
class SuTakipUygulamasi extends StatelessWidget {
  const SuTakipUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1a1a2e), // Kali tarzı koyu tema
        primaryColor: Colors.cyanAccent,
      ),
      home: const AnaIskelet(),
    );
  }
}

class AnaIskelet extends StatefulWidget {
  const AnaIskelet({super.key});
  @override
  State<AnaIskelet> createState() => _AnaIskeletState();
}

class _AnaIskeletState extends State<AnaIskelet> {
  int _seciliSayfa = 0;
  final sayfalar = [const AnaMenuSayfasi(), const IstatistikSayfasi()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: sayfalar[_seciliSayfa],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _seciliSayfa,
        onTap: (index) => setState(() => _seciliSayfa = index),
        backgroundColor: Colors.black45,
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: "Ana Menü"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "İstatistik"),
        ],
      ),
    );
  }
}

// --- SAYFA 1: ANA MENÜ ---
class AnaMenuSayfasi extends StatelessWidget {
  const AnaMenuSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    var veri = Provider.of<SuVeriModeli>(context);
    double yuzde = (veri.bugunIcilen / veri.gunlukHedef).clamp(0.0, 1.0);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Bugünün Özeti", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 30),
          
          // Büyük İlerleme Halkası
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200, height: 200,
                child: CircularProgressIndicator(
                  value: yuzde,
                  strokeWidth: 20,
                  backgroundColor: Colors.grey[800],
                  color: Colors.cyanAccent,
                ),
              ),
              Column(
                children: [
                  Text("${(veri.bugunIcilen / 1000).toStringAsFixed(2)} L", 
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("/ ${veri.gunlukHedef} ml", style: const TextStyle(color: Colors.grey)),
                ],
              )
            ],
          ),
          
          const SizedBox(height: 50),
          const Text("Su Ekle", style: TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 20),
          
          // Butonlar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _suButonu(context, 200),
              const SizedBox(width: 15),
              _suButonu(context, 330),
              const SizedBox(width: 15),
              _suButonu(context, 500),
            ],
          )
        ],
      ),
    );
  }

  Widget _suButonu(BuildContext context, int miktar) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () {
        Provider.of<SuVeriModeli>(context, listen: false).suEkle(miktar);
      },
      child: Column(
        children: [
          const Icon(Icons.local_drink, color: Colors.cyanAccent),
          const SizedBox(height: 5),
          Text("$miktar ml", style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

// --- SAYFA 2: İSTATİSTİK ---
class IstatistikSayfasi extends StatelessWidget {
  const IstatistikSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    var veri = Provider.of<SuVeriModeli>(context);
    var grafikVerileri = veri.haftalikVeriGetir();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Son 7 Gün", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 30),
          
          // Grafik Alanı (FL Chart)
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: grafikVerileri.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: entry.value >= veri.gunlukHedef ? Colors.greenAccent : Colors.cyanAccent,
                        width: 15,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          const Divider(color: Colors.grey),
          
          // Metin İstatistikleri
          _metinIstatistik("Bugün İçilen", "${veri.bugunIcilen} ml"),
          _metinIstatistik("Hedef Durumu", "%${((veri.bugunIcilen/veri.gunlukHedef)*100).toInt()}"),
          _metinIstatistik("Toplam Kayıtlı Gün", "${veri.gunlukKayitlar.length} Gün"),
        ],
      ),
    );
  }

  Widget _metinIstatistik(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(baslik, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(deger, style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
