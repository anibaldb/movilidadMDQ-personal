# Trae los backups de la base de MovilidadMDQ desde el server (por Tailscale)
# y los guarda en backup-db\dumps. Lo ejecuta una tarea programada de Windows.

$Server  = "anibal@covacha"
$Remote  = "/var/backups/movilidad-mdq/*.sql.gz"
$Dest    = Join-Path $PSScriptRoot "dumps"
$Log     = Join-Path $PSScriptRoot "log.txt"
$DiasLocal = 30   # cuantos dias de backups conservar en la notebook

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

# -p conserva la fecha original del archivo; BatchMode evita que se quede esperando una password
$salida = & scp -p -o BatchMode=yes -o ConnectTimeout=20 "${Server}:${Remote}" "$Dest" 2>&1
if ($LASTEXITCODE -eq 0) {
    "$(Get-Date -Format s) OK - $((Get-ChildItem $Dest -Filter *.sql.gz).Count) backups en la notebook" | Out-File -Append -Encoding utf8 $Log
} else {
    "$(Get-Date -Format s) ERROR ($LASTEXITCODE): $salida" | Out-File -Append -Encoding utf8 $Log
}

# Limpieza: borra backups locales con mas de $DiasLocal dias
Get-ChildItem $Dest -Filter *.sql.gz |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DiasLocal) } |
    Remove-Item -Force
