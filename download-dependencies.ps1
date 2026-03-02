# Script para baixar dependências Python para instalação offline
# Uso: .\download-dependencies.ps1
# Uso com versão específica: .\download-dependencies.ps1 -TargetPython "3.11" -Platform "win_amd64"

param(
    [string]$PythonPath = "",
    [string]$OutputDir = ".\python-packages",
    [string]$TargetPython = "",
    [ValidateSet("win_amd64", "win32", "")]
    [string]$Platform = ""
)

Write-Host "📦 Download de Dependências para Instalação Offline" -ForegroundColor Cyan
Write-Host ""

# Determinar caminho do Python
if (-not $PythonPath) {
    $PythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $PythonPath) {
        Write-Host "❌ Python não encontrado no PATH!" -ForegroundColor Red
        Write-Host "   Especifique o caminho: .\download-dependencies.ps1 -PythonPath 'C:\Python311\python.exe'" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "✅ Python encontrado: $PythonPath" -ForegroundColor Green

# Verificar versão e arquitetura
$pythonVersion = & $PythonPath --version 2>&1
$pythonArch = & $PythonPath -c "import platform; print(platform.architecture()[0])" 2>&1
Write-Host "   Versão: $pythonVersion" -ForegroundColor Gray
Write-Host "   Arquitetura: $pythonArch" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠️  IMPORTANTE: Os pacotes serão baixados para esta versão do Python!" -ForegroundColor Yellow
Write-Host "   Se o servidor tiver versão diferente, os pacotes NÃO funcionarão." -ForegroundColor Yellow
Write-Host ""

# Verificar pip
$pipVersion = & $PythonPath -m pip --version 2>&1
Write-Host "   pip: $pipVersion" -ForegroundColor Gray
Write-Host ""

# Criar diretório de saída
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host "📁 Criado diretório: $OutputDir" -ForegroundColor Green
} else {
    Write-Host "📁 Usando diretório existente: $OutputDir" -ForegroundColor Gray
}

$OutputDirFull = Resolve-Path $OutputDir
Write-Host ""

# Baixar dependências do requirements-windows.txt
$requirementsFile = ".\src\python\requirements-windows.txt"

if (-not (Test-Path $requirementsFile)) {
    Write-Host "❌ Arquivo não encontrado: $requirementsFile" -ForegroundColor Red
    exit 1
}

Write-Host "⬇️  Baixando dependências de $requirementsFile..." -ForegroundColor Yellow

if ($TargetPython -or $Platform) {
    Write-Host "🎯 Download para versão específica:" -ForegroundColor Cyan
    if ($TargetPython) { Write-Host "   Python: $TargetPython" -ForegroundColor Gray }
    if ($Platform) { Write-Host "   Plataforma: $Platform" -ForegroundColor Gray }
}

Write-Host ""

try {
    # Construir comando com parâmetros opcionais
    $pipArgs = @("-m", "pip", "download", "-r", $requirementsFile, "-d", $OutputDirFull)
    
    if ($TargetPython) {
        $pipArgs += "--python-version=$TargetPython"
        $pipArgs += "--only-binary=:all:"
    }
    
    if ($Platform) {
        $pipArgs += "--platform=$Platform"
        $pipArgs += "--only-binary=:all:"
    }
    
    & $PythonPath $pipArgs
    
    if ($LASTEXITCODE -ne 0) {
        throw "Erro ao baixar dependências"
    }
    
    Write-Host ""
    Write-Host "✅ Dependências baixadas com sucesso!" -ForegroundColor Green
    Write-Host ""
    
    # Listar arquivos baixados
    $packages = Get-ChildItem -Path $OutputDirFull -Filter "*.whl"
    Write-Host "📋 Pacotes baixados ($($packages.Count) arquivos):" -ForegroundColor Cyan
    $packages | ForEach-Object {
        Write-Host "   - $($_.Name)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "💡 Para instalar offline, use:" -ForegroundColor Cyan
    Write-Host "   .\install-service.ps1 -Offline" -ForegroundColor White
    Write-Host ""
    Write-Host "   Ou manualmente:" -ForegroundColor Gray
    Write-Host "   python -m pip install --no-index --find-links=$OutputDirFull -r $requirementsFile" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  COMPATIBILIDADE:" -ForegroundColor Yellow
    if ($TargetPython -or $Platform) {
        Write-Host "   Estes pacotes são para: Python $TargetPython ($Platform)" -ForegroundColor Yellow
    } else {
        Write-Host "   Estes pacotes são para: $pythonVersion ($pythonArch)" -ForegroundColor Yellow
    }
    Write-Host "   O servidor de destino DEVE ter a mesma versão e arquitetura!" -ForegroundColor Yellow
    
} catch {
    Write-Host ""
    Write-Host "❌ Erro ao baixar dependências: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

