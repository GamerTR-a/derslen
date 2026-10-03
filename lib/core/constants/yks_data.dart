/// YKS Konuları — TYT ve AYT konu listeleri
/// Web projesindeki `src/lib/yks-data.ts` dosyasından port edildi.
library;

import 'app_constants.dart';
import '../../data/models/konu.dart';

export '../../data/models/konu.dart' show Konu;

/// TYT Konuları (57 konu)
const List<Konu> tytKonulari = [
  // Türkçe (10)
  Konu(id: 'tyt-tr-1', ders: 'Türkçe', alan: SinavAlani.TYT, baslik: 'Sözcükte Anlam'),
  Konu(id: 'tyt-tr-2', ders: 'Türkçe', alan: SinavAlani.TYT, baslik: 'Cümlede Anlam'),
  Konu(id: 'tyt-tr-3', ders: 'Türkçe', alan: SinavAlani.TYT, baslik: 'Paragraf'),
  Konu(id: 'tyt-tr-4', ders: 'Türkçe', alan: SinavAlani.TYT, baslik: 'Ses Bilgisi'),
  Konu(id: 'tyt-tr-5', ders: 'Türkçe', alan: SinavAlani.TYT, baslik: 'Yazım Kuralları'),
  Konu(id: 'tyt-tr-6', ders: 'Türkçe', alan: SinavAlani.TYT, baslik: 'Noktalama İşaretleri'),
  Konu(id: 'tyt-tr-7', ders: 'Türkçe', alan: SinavAlani.TYT, baslik: 'Sözcük Türleri'),
  Konu(id: 'tyt-tr-8', ders: 'Türkçe', alan: SinavAlani.TYT, baslik: 'Cümle Türleri'),
  Konu(id: 'tyt-tr-9', ders: 'Türkçe', alan: SinavAlani.TYT, baslik: 'Anlatım Bozukluğu'),
  Konu(id: 'tyt-tr-10', ders: 'Türkçe', alan: SinavAlani.TYT, baslik: 'Dil Bilgisi'),
  // Matematik (15)
  Konu(id: 'tyt-mat-1', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Sayı Sistemleri'),
  Konu(id: 'tyt-mat-2', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Bölünebilme'),
  Konu(id: 'tyt-mat-3', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'EBOB-EKOK'),
  Konu(id: 'tyt-mat-4', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Rasyonel Sayılar'),
  Konu(id: 'tyt-mat-5', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Basit Eşitsizlikler'),
  Konu(id: 'tyt-mat-6', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Mutlak Değer'),
  Konu(id: 'tyt-mat-7', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Üslü Sayılar'),
  Konu(id: 'tyt-mat-8', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Köklü Sayılar'),
  Konu(id: 'tyt-mat-9', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Çarpanlara Ayırma'),
  Konu(id: 'tyt-mat-10', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Denklemler'),
  Konu(id: 'tyt-mat-11', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Oran Orantı'),
  Konu(id: 'tyt-mat-12', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Problemler'),
  Konu(id: 'tyt-mat-13', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Kümeler'),
  Konu(id: 'tyt-mat-14', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Mantık'),
  Konu(id: 'tyt-mat-15', ders: 'Matematik', alan: SinavAlani.TYT, baslik: 'Fonksiyonlar'),
  // Fen Bilimleri (8)
  Konu(id: 'tyt-fen-1', ders: 'Fen Bilimleri', alan: SinavAlani.TYT, baslik: 'Madde ve Özellikleri'),
  Konu(id: 'tyt-fen-2', ders: 'Fen Bilimleri', alan: SinavAlani.TYT, baslik: 'Atom Modelleri'),
  Konu(id: 'tyt-fen-3', ders: 'Fen Bilimleri', alan: SinavAlani.TYT, baslik: 'Periyodik Tablo'),
  Konu(id: 'tyt-fen-4', ders: 'Fen Bilimleri', alan: SinavAlani.TYT, baslik: 'Kimyasal Bağlar'),
  Konu(id: 'tyt-fen-5', ders: 'Fen Bilimleri', alan: SinavAlani.TYT, baslik: 'Hareket ve Kuvvet'),
  Konu(id: 'tyt-fen-6', ders: 'Fen Bilimleri', alan: SinavAlani.TYT, baslik: 'Enerji'),
  Konu(id: 'tyt-fen-7', ders: 'Fen Bilimleri', alan: SinavAlani.TYT, baslik: 'Hücre'),
  Konu(id: 'tyt-fen-8', ders: 'Fen Bilimleri', alan: SinavAlani.TYT, baslik: 'Canlıların Sınıflandırılması'),
  // Sosyal Bilimler (7)
  Konu(id: 'tyt-sos-1', ders: 'Sosyal Bilimler', alan: SinavAlani.TYT, baslik: 'Tarih Öncesi Çağlar'),
  Konu(id: 'tyt-sos-2', ders: 'Sosyal Bilimler', alan: SinavAlani.TYT, baslik: 'İlk Çağ Uygarlıkları'),
  Konu(id: 'tyt-sos-3', ders: 'Sosyal Bilimler', alan: SinavAlani.TYT, baslik: 'Coğrafyanın Konusu'),
  Konu(id: 'tyt-sos-4', ders: 'Sosyal Bilimler', alan: SinavAlani.TYT, baslik: 'Harita Bilgisi'),
  Konu(id: 'tyt-sos-5', ders: 'Sosyal Bilimler', alan: SinavAlani.TYT, baslik: 'Türkiye Coğrafyası'),
  Konu(id: 'tyt-sos-6', ders: 'Sosyal Bilimler', alan: SinavAlani.TYT, baslik: 'Felsefe ve Mantık'),
  Konu(id: 'tyt-sos-7', ders: 'Sosyal Bilimler', alan: SinavAlani.TYT, baslik: 'Din Kültürü'),
];

/// AYT Konuları (45 konu)
const List<Konu> aytKonulari = [
  // Matematik (8)
  Konu(id: 'ayt-mat-1', ders: 'Matematik', alan: SinavAlani.AYT, baslik: 'Polinomlar'),
  Konu(id: 'ayt-mat-2', ders: 'Matematik', alan: SinavAlani.AYT, baslik: 'İkinci Dereceden Denklemler'),
  Konu(id: 'ayt-mat-3', ders: 'Matematik', alan: SinavAlani.AYT, baslik: 'Trigonometri'),
  Konu(id: 'ayt-mat-4', ders: 'Matematik', alan: SinavAlani.AYT, baslik: 'Logaritma'),
  Konu(id: 'ayt-mat-5', ders: 'Matematik', alan: SinavAlani.AYT, baslik: 'Diziler'),
  Konu(id: 'ayt-mat-6', ders: 'Matematik', alan: SinavAlani.AYT, baslik: 'Limit ve Süreklilik'),
  Konu(id: 'ayt-mat-7', ders: 'Matematik', alan: SinavAlani.AYT, baslik: 'Türev'),
  Konu(id: 'ayt-mat-8', ders: 'Matematik', alan: SinavAlani.AYT, baslik: 'İntegral'),
  // Fizik (5)
  Konu(id: 'ayt-fiz-1', ders: 'Fizik', alan: SinavAlani.AYT, baslik: 'Kuvvet ve Hareket'),
  Konu(id: 'ayt-fiz-2', ders: 'Fizik', alan: SinavAlani.AYT, baslik: 'Enerji ve Momentum'),
  Konu(id: 'ayt-fiz-3', ders: 'Fizik', alan: SinavAlani.AYT, baslik: 'Elektrik'),
  Konu(id: 'ayt-fiz-4', ders: 'Fizik', alan: SinavAlani.AYT, baslik: 'Manyetizma'),
  Konu(id: 'ayt-fiz-5', ders: 'Fizik', alan: SinavAlani.AYT, baslik: 'Dalgalar'),
  // Kimya (5)
  Konu(id: 'ayt-kim-1', ders: 'Kimya', alan: SinavAlani.AYT, baslik: 'Mol Kavramı'),
  Konu(id: 'ayt-kim-2', ders: 'Kimya', alan: SinavAlani.AYT, baslik: 'Asit-Baz'),
  Konu(id: 'ayt-kim-3', ders: 'Kimya', alan: SinavAlani.AYT, baslik: 'Çözeltiler'),
  Konu(id: 'ayt-kim-4', ders: 'Kimya', alan: SinavAlani.AYT, baslik: 'Kimyasal Reaksiyonlar'),
  Konu(id: 'ayt-kim-5', ders: 'Kimya', alan: SinavAlani.AYT, baslik: 'Organik Kimya'),
  // Biyoloji (4)
  Konu(id: 'ayt-bio-1', ders: 'Biyoloji', alan: SinavAlani.AYT, baslik: 'Hücre Bölünmesi'),
  Konu(id: 'ayt-bio-2', ders: 'Biyoloji', alan: SinavAlani.AYT, baslik: 'Kalıtım'),
  Konu(id: 'ayt-bio-3', ders: 'Biyoloji', alan: SinavAlani.AYT, baslik: 'Ekosistem'),
  Konu(id: 'ayt-bio-4', ders: 'Biyoloji', alan: SinavAlani.AYT, baslik: 'Sinir Sistemi'),
  // Edebiyat (5)
  Konu(id: 'ayt-edb-1', ders: 'Türk Dili ve Edebiyatı', alan: SinavAlani.AYT, baslik: 'Divan Edebiyatı'),
  Konu(id: 'ayt-edb-2', ders: 'Türk Dili ve Edebiyatı', alan: SinavAlani.AYT, baslik: 'Tanzimat Edebiyatı'),
  Konu(id: 'ayt-edb-3', ders: 'Türk Dili ve Edebiyatı', alan: SinavAlani.AYT, baslik: 'Cumhuriyet Edebiyatı'),
  Konu(id: 'ayt-edb-4', ders: 'Türk Dili ve Edebiyatı', alan: SinavAlani.AYT, baslik: 'Şiir Türleri'),
  Konu(id: 'ayt-edb-5', ders: 'Türk Dili ve Edebiyatı', alan: SinavAlani.AYT, baslik: 'Nesir Türleri'),
  // Tarih (5)
  Konu(id: 'ayt-tar-1', ders: 'Tarih', alan: SinavAlani.AYT, baslik: 'Osmanlı Devleti Kuruluş'),
  Konu(id: 'ayt-tar-2', ders: 'Tarih', alan: SinavAlani.AYT, baslik: 'Osmanlı Klasik Dönem'),
  Konu(id: 'ayt-tar-3', ders: 'Tarih', alan: SinavAlani.AYT, baslik: 'Osmanlı Dağılma'),
  Konu(id: 'ayt-tar-4', ders: 'Tarih', alan: SinavAlani.AYT, baslik: 'Kurtuluş Savaşı'),
  Konu(id: 'ayt-tar-5', ders: 'Tarih', alan: SinavAlani.AYT, baslik: 'Türkiye Cumhuriyeti'),
  // Coğrafya (3)
  Konu(id: 'ayt-cog-1', ders: 'Coğrafya', alan: SinavAlani.AYT, baslik: 'Nüfus ve Yerleşme'),
  Konu(id: 'ayt-cog-2', ders: 'Coğrafya', alan: SinavAlani.AYT, baslik: 'Ekonomik Faaliyetler'),
  Konu(id: 'ayt-cog-3', ders: 'Coğrafya', alan: SinavAlani.AYT, baslik: 'Çevre ve Toplum'),
];

/// Tüm konular (TYT + AYT) - 102 konu
const List<Konu> tumKonular = [...tytKonulari, ...aytKonulari];

/// Ders bazında konu grupları
Map<String, List<Konu>> get dersBazindaKonular {
  final map = <String, List<Konu>>{};
  for (final konu in tumKonular) {
    map.putIfAbsent(konu.ders, () => []).add(konu);
  }
  return map;
}

/// Alan bazında konu grupları
Map<SinavAlani, List<Konu>> get alanBazindaKonular {
  final map = <SinavAlani, List<Konu>>{
    SinavAlani.TYT: [],
    SinavAlani.AYT: [],
  };
  for (final konu in tumKonular) {
    map[konu.alan]!.add(konu);
  }
  return map;
}

/// ID ile konu bulma
Konu? konuBul(String id) {
  try {
    return tumKonular.firstWhere((k) => k.id == id);
  } catch (_) {
    return null;
  }
}