# load_env.ps1
# Load semua variable dari .env ke environment variable sesi terminal ini.
# Perlu dijalankan tiap buka terminal baru SEBELUM pakai command dbt,
# karena dbt tidak otomatis baca file .env (beda dengan script Python yang pakai load_dotenv()).
#
# Cara pakai (dari root project):
#   . .\load_env.ps1
# (perhatikan titik + spasi di depan — supaya env var ini "menempel" ke sesi terminal saat ini,
#  bukan cuma di dalam script)

Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        [System.Environment]::SetEnvironmentVariable($key, $value)
        Write-Host "[OK] $key set"
    }
}

Write-Host "`nSelesai. Environment variable dari .env sudah aktif di sesi terminal ini."