/// Uygulamanın vektör illüstrasyonları (SVG metinleri). Her fonksiyon
/// temaya (gece) göre renklenmiş bir SVG döner; widget'lar
/// cizim_widgetlari.dart içinde `SvgPicture.string` ile çizer.
library;

String _hex(int c) => '#${(c & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

// ─── İkonlar ────────────────────────────────────────────────

String yildizSvg(int renk) =>
    '<svg viewBox="0 0 24 24"><path d="M12 2.5l2.9 6 6.6.8-4.9 4.5 1.3 6.5L12 17l-5.9 3.3 1.3-6.5L2.5 9.3l6.6-.8z" fill="${_hex(renk)}"/></svg>';

String damlaSvg(int renk) =>
    '<svg viewBox="0 0 20 24"><path d="M10 1C10 1 2 11 2 16a8 8 0 0 0 16 0C18 11 10 1 10 1z" fill="${_hex(renk)}"/><path d="M6 16a4 4 0 0 0 3 4" stroke="#FFFFFF" stroke-opacity=".6" stroke-width="1.6" fill="none" stroke-linecap="round"/></svg>';

String alevSvg(int renk) =>
    '<svg viewBox="0 0 24 24"><path d="M12 2c1 4 5 5.5 5 10.5A5 5 0 0 1 7 12.5c0-2 1-3.3 2-4.3.3 1.7 1.3 2.6 2.3 2.8C11 8 10.8 5 12 2z" fill="${_hex(renk)}"/></svg>';

// ─── Bitkiler ───────────────────────────────────────────────
// viewBox 0 0 80 100 — gövde tabanı (40,100); saksı ayrı çizilir.

class _Palet {
  final String sap, yaprak, yaprak2, govde;
  const _Palet(this.sap, this.yaprak, this.yaprak2, this.govde);
}

const _gunduz = _Palet('#2F7A55', '#5AA77B', '#4B9A6D', '#6E5238');
const _gece = _Palet('#4FA888', '#7FD8B4', '#5FC39E', '#B08968');

String bitkiSvg(String bitkiId, int asama, {bool gece = false, bool solgun = false}) {
  final p = gece ? _gece : _gunduz;
  final String govde;
  if (solgun && asama > 0) {
    govde = '<path d="M40 100c0-14 4-24 13-30" stroke="#8A9A7B" stroke-width="4" fill="none" stroke-linecap="round"/>'
        '<path d="M53 70c-3-9-12-12-19-7 3 9 12 12 19 7z" fill="#B7A99A"/>'
        '<path d="M44 84c-8-2-12 2-13 8 7 2 11-2 13-8z" fill="#C9BBA8"/>';
  } else {
    switch (asama) {
      case 0:
        govde = '<ellipse cx="40" cy="95" rx="10" ry="6" fill="#8B6B4A"/><path d="M40 90q2-6 6-7" stroke="${p.yaprak}" stroke-width="2.5" fill="none" stroke-linecap="round"/>';
      case 1:
        govde = '<path d="M40 100V78" stroke="${p.sap}" stroke-width="4" stroke-linecap="round"/>'
            '<path d="M40 86c-8 0-13-4-13-11 8 0 13 4 13 11z" fill="${p.yaprak}"/>'
            '<path d="M40 82c0-7 4-11 11-11 0 7-4 11-11 11z" fill="${p.yaprak2}"/>';
      case 2:
        govde = '<path d="M40 100V54" stroke="${p.sap}" stroke-width="4" stroke-linecap="round"/>'
            '<path d="M40 76c-11 0-17-6-17-15 11 0 17 6 17 15z" fill="${p.yaprak}"/>'
            '<path d="M40 68c0-10 6-16 16-16 0 10-6 16-16 16z" fill="${p.yaprak2}"/>'
            '<path d="M40 88c-7 0-11-4-11-10 7 0 11 4 11 10z" fill="${p.yaprak2}"/>'
            '<circle cx="40" cy="52" r="4" fill="${p.yaprak}"/>';
      default:
        govde = _olgun(bitkiId, p);
    }
  }
  return '<svg viewBox="0 0 80 100">$govde</svg>';
}

String _olgun(String id, _Palet p) {
  switch (id) {
    case 'seed_papatya':
      final yap = List.generate(10, (i) => '<ellipse cx="40" cy="30" rx="4" ry="11" fill="#FFFFFF" stroke="#E6E1D6" stroke-width=".8" transform="rotate(${i * 36} 40 41)"/>').join();
      return '<path d="M40 100V44" stroke="${p.sap}" stroke-width="4"/><path d="M40 80c-10 0-15-5-15-13 10 0 15 5 15 13z" fill="${p.yaprak}"/>$yap<circle cx="40" cy="41" r="7" fill="#F2B544"/>';
    case 'seed_lale':
      return '<path d="M40 100V46" stroke="${p.sap}" stroke-width="4"/><path d="M40 92c-14-4-18-18-12-30 6 10 10 18 12 30z" fill="${p.yaprak}"/>'
          '<path d="M26 30c0 14 6 20 14 20s14-6 14-20l-7 6-7-10-7 10z" fill="#E0525B"/><path d="M33 36l7-10 7 10c-2 8-12 8-14 0z" fill="#F07A7F"/>';
    case 'seed_gunebakan':
      final yap = List.generate(12, (i) => '<ellipse cx="40" cy="18" rx="4.5" ry="10" fill="#F6C23E" transform="rotate(${i * 30} 40 32)"/>').join();
      return '<path d="M40 100V40" stroke="${p.sap}" stroke-width="5"/><path d="M40 76c-12 0-18-6-18-15 12 0 18 6 18 15zM40 66c0-11 6-17 18-17 0 11-6 17-18 17z" fill="${p.yaprak}"/>$yap<circle cx="40" cy="32" r="10" fill="#7A4B22"/><circle cx="37" cy="29" r="1.4" fill="#A0703D"/><circle cx="43" cy="34" r="1.4" fill="#A0703D"/>';
    case 'seed_kaktus':
      return '<rect x="31" y="34" width="18" height="66" rx="9" fill="#4F9A6A"/><path d="M31 66h-8a6 6 0 0 1-6-6V48a4 4 0 0 1 8 0v8h6zM49 58h8a6 6 0 0 0 6-6V42a4 4 0 0 0-8 0v8h-6z" fill="#5AA77B"/>'
          '<path d="M36 44v48M44 44v48" stroke="#3E8058" stroke-width="1.4"/><circle cx="40" cy="32" r="6" fill="#F29BB5"/><circle cx="40" cy="32" r="2.4" fill="#F6C23E"/>';
    case 'seed_limon':
      return '<path d="M40 100V52" stroke="${p.govde}" stroke-width="6" stroke-linecap="round"/><circle cx="40" cy="38" r="24" fill="${p.yaprak2}"/><circle cx="26" cy="46" r="14" fill="${p.yaprak}"/><circle cx="54" cy="46" r="14" fill="${p.yaprak}"/>'
          '<ellipse cx="30" cy="34" rx="5" ry="6" fill="#F6D54A"/><ellipse cx="50" cy="44" rx="5" ry="6" fill="#F6D54A"/><ellipse cx="42" cy="26" rx="4.5" ry="5.5" fill="#F6D54A"/>';
    case 'seed_hus':
      return '<path d="M40 100V30" stroke="#EDE8DE" stroke-width="7" stroke-linecap="round"/><path d="M37 84h4M39 66h4M37 48h3" stroke="#3A3A3A" stroke-width="2" stroke-linecap="round"/>'
          '<ellipse cx="24" cy="40" rx="16" ry="11" fill="#8CC79C"/><ellipse cx="56" cy="32" rx="17" ry="12" fill="${p.yaprak}"/><ellipse cx="40" cy="20" rx="18" ry="13" fill="#6CB384"/><ellipse cx="30" cy="60" rx="11" ry="7" fill="#8CC79C"/>';
    case 'seed_cam':
      return '<rect x="36" y="82" width="8" height="18" fill="${p.govde}"/><path d="M40 8L18 44h9L14 66h11L10 88h60L55 66h11L53 44h9z" fill="#2F6B4F"/><path d="M40 8L28 30h24z" fill="#3E8A64"/>';
    case 'seed_kiraz':
      return '<path d="M40 100V50" stroke="${p.govde}" stroke-width="6" stroke-linecap="round"/><path d="M40 62l-12-10M40 58l12-12" stroke="${p.govde}" stroke-width="3.5" stroke-linecap="round"/>'
          '<circle cx="40" cy="34" r="22" fill="#F4B6CB"/><circle cx="24" cy="44" r="13" fill="#F7C6D9"/><circle cx="56" cy="42" r="13" fill="#F7C6D9"/>'
          '<circle cx="32" cy="28" r="3" fill="#E57A9B"/><circle cx="48" cy="36" r="3" fill="#E57A9B"/><circle cx="40" cy="46" r="3" fill="#E57A9B"/><circle cx="54" cy="26" r="2.5" fill="#E57A9B"/>';
    default:
      return '<path d="M40 100V40" stroke="${p.sap}" stroke-width="4"/><circle cx="40" cy="36" r="16" fill="${p.yaprak}"/>';
  }
}

/// Saksı — viewBox 0 0 80 44.
String saksiSvg({bool gece = false, bool bos = false}) {
  final govde = gece ? '#5B6488' : (bos ? '#D9C3A5' : '#C8693F');
  final kenar = gece ? '#4A5277' : (bos ? '#C9B08E' : '#B2582F');
  return '<svg viewBox="0 0 80 44"><path d="M11 8h58l-7 34a3 3 0 0 1-3 2H21a3 3 0 0 1-3-2z" fill="$govde"/>'
      '<rect x="6" y="0" width="68" height="11" rx="4" fill="$kenar"/><path d="M20 24h40" stroke="#000" stroke-opacity=".08" stroke-width="3"/></svg>';
}

// ─── Dekorlar — viewBox 0 0 90 90 ───────────────────────────

String dekorSvg(String id, {bool gece = false}) {
  switch (id) {
    case 'deco_bank':
      return '<svg viewBox="0 0 90 90"><rect x="10" y="30" width="70" height="9" rx="3" fill="#A07C57"/><rect x="10" y="46" width="70" height="10" rx="3" fill="#8B6B4A"/><rect x="16" y="56" width="6" height="24" rx="2" fill="#6E5238"/><rect x="68" y="56" width="6" height="24" rx="2" fill="#6E5238"/></svg>';
    case 'deco_fener':
      return '<svg viewBox="0 0 90 90"><circle cx="45" cy="30" r="20" fill="#FFC66B" opacity="${gece ? '.35' : '.18'}"/><rect x="43" y="40" width="4" height="44" fill="#35554F"/><rect x="32" y="16" width="26" height="28" rx="6" fill="#35554F"/><rect x="37" y="21" width="16" height="18" rx="4" fill="#F6CD6B"/><path d="M36 16l9-8 9 8z" fill="#35554F"/></svg>';
    case 'deco_kus':
      return '<svg viewBox="0 0 90 90"><rect x="43" y="52" width="4" height="34" fill="#6E5238"/><path d="M24 34l21-18 21 18z" fill="#B2582F"/><rect x="29" y="34" width="32" height="24" fill="#D9C3A5"/><circle cx="45" cy="46" r="5.5" fill="#35554F"/><path d="M58 22q5-5 10 0" stroke="#35554F" stroke-width="2" fill="none" stroke-linecap="round"/></svg>';
    case 'deco_gol':
      return '<svg viewBox="0 0 90 90"><ellipse cx="45" cy="60" rx="40" ry="16" fill="${gece ? '#3A4E7A' : '#8FC3DA'}"/><ellipse cx="45" cy="60" rx="18" ry="6" fill="none" stroke="#FFFFFF" stroke-opacity=".6" stroke-width="2"/><ellipse cx="64" cy="56" rx="9" ry="4.5" fill="#5AA77B"/><circle cx="66" cy="53" r="3" fill="#F7C6D9"/></svg>';
    default:
      return '<svg viewBox="0 0 90 90"><circle cx="45" cy="45" r="20" fill="#5AA77B"/></svg>';
  }
}

// ─── Hediye kutusu (onboarding) — viewBox 0 0 160 120 ─────

String kutuGovdeSvg({bool gece = false}) {
  final g = gece ? '#A5B4FF' : '#2F7A55';
  final s = gece ? '#FFC66B' : '#F2B544';
  return '<svg viewBox="0 0 120 90"><rect x="4" y="0" width="112" height="86" rx="10" fill="$g"/><rect x="50" y="0" width="20" height="86" fill="$s"/><rect x="4" y="0" width="112" height="8" fill="#000" fill-opacity=".12"/></svg>';
}

String kutuKapakSvg({bool gece = false}) {
  final g = gece ? '#7C8CE0' : '#23473A';
  final s = gece ? '#FFC66B' : '#F2B544';
  return '<svg viewBox="0 0 136 56"><path d="M68 30c-14-22-34-18-28-4 4 6 16 6 28 4zM68 30c14-22 34-18 28-4-4 6-16 6-28 4z" fill="$s"/><rect x="0" y="28" width="136" height="28" rx="8" fill="$g"/><rect x="58" y="28" width="20" height="28" fill="$s"/></svg>';
}
