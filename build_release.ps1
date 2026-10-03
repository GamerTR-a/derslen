# LiseNET — Release (App Bundle) build scripti.
#
# kontrol.md denetim bulgusu: release build'ler obfuscation olmadan alınıyordu
# (Dart kodu ters mühendisliğe karşı korumasızdı). Bu script, gerekli
# --obfuscate / --split-debug-info bayraklarını ve SUPABASE_URL /
# SUPABASE_ANON_KEY --dart-define değerlerini zorunlu kılar.
#
# Kullanım:
#   $env:SUPABASE_URL = "https://xxxx.supabase.co"
#   $env:SUPABASE_ANON_KEY = "eyJ..."
#   ./build_release.ps1
#
# NOT: Bu değerleri asla bu script dosyasının içine hardcode etmeyin;
# CI/CD kullanıyorsanız (GitHub Actions vb.) bunları secret olarak tanımlayın.

$ErrorActionPreference = "Stop"

# Ortam değişkenleri yoksa (git'e girmeyen) dart_defines.json okunur.
$definesDosyasi = Join-Path $PSScriptRoot "dart_defines.json"
if ((-not $env:SUPABASE_URL -or -not $env:SUPABASE_ANON_KEY) -and (Test-Path $definesDosyasi)) {
    $defines = Get-Content $definesDosyasi -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $env:SUPABASE_URL) { $env:SUPABASE_URL = $defines.SUPABASE_URL }
    if (-not $env:SUPABASE_ANON_KEY) { $env:SUPABASE_ANON_KEY = $defines.SUPABASE_ANON_KEY }
}
if ($env:SUPABASE_URL -match 'PROJE-REF|xxxx') {
    Write-Error "SUPABASE_URL hâlâ yer tutucu: $env:SUPABASE_URL"
    exit 1
}

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_ANON_KEY) {
    Write-Error "SUPABASE_URL ve SUPABASE_ANON_KEY ortam değişkenleri tanımlı olmalı. Örnek:`n  `$env:SUPABASE_URL = 'https://xxxx.supabase.co'`n  `$env:SUPABASE_ANON_KEY = 'eyJ...'"
    exit 1
}

# Flutter'in AOT derleyicisi (gen_snapshot) Windows'ta ASCII disi karakter iceren
# yollari okuyamaz (ornek: "Masaustu" klasorunun Turkce yazimi). Boyle bir yolda
# proje gecici bir surucu harfine (subst) eslenip derleme oradan yapilir.
$kok = $PSScriptRoot
$geciciSurucu = $null
if ($kok -match '[^\x00-\x7F]') {
    $harf = @('L', 'Q', 'W', 'X', 'Y', 'Z') | Where-Object { -not (Test-Path "$($_):\") } | Select-Object -First 1
    if (-not $harf) { Write-Error "Gecici surucu harfi bulunamadi."; exit 1 }
    subst "$($harf):" "$kok"
    $geciciSurucu = "$($harf):"
    $kok = "$geciciSurucu\"
    Write-Host "Yol ASCII disi karakter iceriyor; derleme $geciciSurucu uzerinden yapilacak." -ForegroundColor Yellow
}

$symbolsDir = Join-Path $kok "symbols"
New-Item -ItemType Directory -Force -Path $symbolsDir | Out-Null

Write-Host "flutter build appbundle --release --obfuscate --split-debug-info=$symbolsDir ..." -ForegroundColor Cyan

Push-Location $kok
try {
    flutter build appbundle `
        --release `
        --obfuscate `
        --split-debug-info="$symbolsDir" `
        --dart-define=SUPABASE_URL="$env:SUPABASE_URL" `
        --dart-define=SUPABASE_ANON_KEY="$env:SUPABASE_ANON_KEY"
    $sonuc = $LASTEXITCODE
} finally {
    Pop-Location
    if ($geciciSurucu) { subst $geciciSurucu /d }
}
if ($sonuc -ne 0) { Write-Error "Derleme basarisiz (cikis kodu $sonuc)."; exit $sonuc }

Write-Host "Bitti. Debug sembolleri: $symbolsDir (Play Console'a crash sembolikleştirme için yüklenebilir, asla dağıtılmamalı/commit edilmemeli)." -ForegroundColor Green
