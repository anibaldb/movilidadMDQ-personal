# Sincroniza este repo (docs, bitacora, gestion) con GitHub.
# Lo corre la tarea programada "movilidadMDQ-sync" en cada maquina.
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repo
$log = Join-Path $repo "sync.log"
$aviso = Join-Path $repo "SYNC-CONFLICTO.txt"
function Log($m) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m" | Add-Content $log }

# Si hay un Word abierto (archivo temporal ~$...), no tocar nada
$abiertos = Get-ChildItem $repo, "$repo\gestion" -Force -Filter '~$*' -ErrorAction SilentlyContinue
if ($abiertos) { Log "Word abierto, salteo"; exit 0 }

# Si quedo un conflicto sin resolver, no seguir
if (Test-Path $aviso) { Log "Hay un conflicto pendiente, salteo"; exit 1 }

# 1. Guardar cambios locales
git add -A
if (git status --porcelain) {
    git commit -q -m "auto-sync $env:COMPUTERNAME $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
}

# 2. Traer cambios de la otra maquina
git pull -q --rebase
if ($LASTEXITCODE -ne 0) {
    git rebase --abort 2>$null
    "Conflicto al sincronizar ($(Get-Date)). El mismo archivo se cambio en las dos maquinas.`r`nResolver a mano (git pull) y despues borrar este archivo." | Set-Content $aviso
    Log "CONFLICTO al hacer pull"
    exit 1
}

# 3. Subir
git push -q
if ($LASTEXITCODE -ne 0) { Log "Fallo el push (sin internet?)" } else { Log "ok" }
