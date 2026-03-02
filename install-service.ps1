# Script para instalar o Protheus Exporter como Serviço Windows
# Requer privilégios de Administrador

param(
    [string]$PythonPath = "",
    [string]$ServicePath = "",
    [switch]$AutoStart,
    [switch]$Offline,
    [string]$PackagesDir = ".\python-packages"
)

# Verificar se está rodando como Administrador
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Write-Host "   Clique com botão direito e selecione 'Executar como Administrador'" -ForegroundColor Yellow
    exit 1
}

Write-Host "🔧 Instalação do Protheus Exporter como Serviço Windows" -ForegroundColor Cyan
Write-Host ""

# Determinar caminho do Python
if (-not $PythonPath) {
    $PythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $PythonPath) {
        Write-Host "❌ Python não encontrado no PATH!" -ForegroundColor Red
        Write-Host "   Instale Python ou especifique o caminho: .\install-service.ps1 -PythonPath 'C:\Python311\python.exe'" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "✅ Python encontrado: $PythonPath" -ForegroundColor Green

# Verificar versão do Python
$pythonVersion = & $PythonPath --version 2>&1
Write-Host "   Versão: $pythonVersion" -ForegroundColor Gray
Write-Host ""

# Determinar caminho do serviço
Write-Host "🔍 Determinando caminho do serviço..." -ForegroundColor Yellow

# Garantir que ServicePath seja definido
if (-not $ServicePath -or $ServicePath -eq "") {
    $testPath = Join-Path $PSScriptRoot "src\python"
    Write-Host "   Testando: $testPath" -ForegroundColor Gray
    
    if (Test-Path $testPath) {
        $ServicePath = $testPath
        Write-Host "   ✅ Encontrado em: $ServicePath" -ForegroundColor Green
    } else {
        $ServicePath = $PSScriptRoot
        Write-Host "   ✅ Usando raiz do projeto: $ServicePath" -ForegroundColor Green
    }
}

$serviceScript = Join-Path $ServicePath "protheus_exporter_service.py"

if (-not (Test-Path $serviceScript)) {
    Write-Host "❌ Arquivo do serviço não encontrado: $serviceScript" -ForegroundColor Red
    Write-Host "   ServicePath atual: $ServicePath" -ForegroundColor Gray
    Write-Host "   PSScriptRoot: $PSScriptRoot" -ForegroundColor Gray
    exit 1
}

Write-Host "✅ Script do serviço: $serviceScript" -ForegroundColor Green
Write-Host ""

# Verificar se as dependências estão instaladas
Write-Host "📦 Verificando dependências..." -ForegroundColor Yellow

$requirementsFile = Join-Path $ServicePath "requirements-windows.txt"
if (Test-Path $requirementsFile) {
    if ($Offline) {
        # Modo offline - instalar de cache local
        if (-not (Test-Path $PackagesDir)) {
            Write-Host "❌ Diretório de pacotes não encontrado: $PackagesDir" -ForegroundColor Red
            Write-Host "   Execute primeiro: .\download-dependencies.ps1" -ForegroundColor Yellow
            exit 1
        }
        
        $PackagesDirFull = Resolve-Path $PackagesDir
        Write-Host "   Instalando dependências do cache local: $PackagesDirFull" -ForegroundColor Gray
        & $PythonPath -m pip install --no-index --find-links=$PackagesDirFull -r $requirementsFile
    } else {
        # Modo online - baixar da internet
        Write-Host "   Instalando dependências de $requirementsFile" -ForegroundColor Gray
        & $PythonPath -m pip install -r $requirementsFile --upgrade
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao instalar dependências!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "⚠️  Arquivo requirements-windows.txt não encontrado!" -ForegroundColor Yellow
    Write-Host "   Instalando dependências manualmente..." -ForegroundColor Gray
    & $PythonPath -m pip install flask prometheus-client pywin32 waitress
}

Write-Host "✅ Dependências instaladas" -ForegroundColor Green
Write-Host ""

# Verificar se o serviço já existe
$existingService = Get-Service -Name "ProtheusExporter" -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Host "⚠️  O serviço ProtheusExporter já existe!" -ForegroundColor Yellow
    $response = Read-Host "   Deseja reinstalá-lo? (S/N)"
    
    if ($response -eq 'S' -or $response -eq 's') {
        Write-Host "   Parando serviço..." -ForegroundColor Gray
        Stop-Service -Name "ProtheusExporter" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        Write-Host "   Removendo serviço..." -ForegroundColor Gray
        & $PythonPath $serviceScript remove
        Start-Sleep -Seconds 2
    } else {
        Write-Host "❌ Instalação cancelada" -ForegroundColor Red
        exit 0
    }
}

# Instalar o serviço
Write-Host "🔧 Instalando serviço..." -ForegroundColor Yellow

try {
    & $PythonPath $serviceScript install
    
    if ($LASTEXITCODE -ne 0) {
        throw "Erro ao instalar serviço"
    }
    
    Write-Host "✅ Serviço instalado com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao instalar serviço: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Configurar inicialização automática
if ($AutoStart) {
    Write-Host "⚙️  Configurando inicialização automática..." -ForegroundColor Yellow
    Set-Service -Name "ProtheusExporter" -StartupType Automatic
    Write-Host "✅ Inicialização automática configurada" -ForegroundColor Green
}

Write-Host ""
Write-Host "🚀 Iniciando serviço..." -ForegroundColor Yellow

try {
    Start-Service -Name "ProtheusExporter"
    Start-Sleep -Seconds 3
    
    $service = Get-Service -Name "ProtheusExporter"
    if ($service.Status -eq 'Running') {
        Write-Host "✅ Serviço iniciado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Serviço instalado mas não está rodando" -ForegroundColor Yellow
        Write-Host "   Status: $($service.Status)" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠️  Erro ao iniciar serviço: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   Você pode iniciá-lo manualmente: Start-Service ProtheusExporter" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📋 Informações do Serviço:" -ForegroundColor Cyan
Write-Host "   Nome: ProtheusExporter" -ForegroundColor White
Write-Host "   Nome de exibição: Protheus Prometheus Exporter" -ForegroundColor White
Write-Host "   Descrição: Exportador de métricas do Protheus ERP para Prometheus" -ForegroundColor White
Write-Host ""
Write-Host "🔗 URLs:" -ForegroundColor Cyan
Write-Host "   Healthcheck: http://localhost:8000/health" -ForegroundColor White
Write-Host "   Métricas: http://localhost:8000/metrics" -ForegroundColor White
Write-Host "   Track: http://localhost:8000/track [POST]" -ForegroundColor White
Write-Host ""
Write-Host "📝 Logs:" -ForegroundColor Cyan
Write-Host "   Diretório: $ServicePath\logs" -ForegroundColor White
Write-Host "   Arquivo: protheus_exporter_service.log" -ForegroundColor White
Write-Host ""
Write-Host "💡 Comandos úteis:" -ForegroundColor Cyan
Write-Host "   Ver status: Get-Service ProtheusExporter" -ForegroundColor White
Write-Host "   Iniciar: Start-Service ProtheusExporter" -ForegroundColor White
Write-Host "   Parar: Stop-Service ProtheusExporter" -ForegroundColor White
Write-Host "   Reiniciar: Restart-Service ProtheusExporter" -ForegroundColor White
Write-Host "   Ver logs: Get-Content `"$ServicePath\logs\protheus_exporter_service.log`" -Tail 50 -Wait" -ForegroundColor White
Write-Host "   Desinstalar: .\uninstall-service.ps1" -ForegroundColor White
Write-Host ""
Write-Host "✅ Instalação concluída!" -ForegroundColor Green
Write-Host ""

# Testar o serviço
Write-Host "🧪 Testando serviço..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Serviço está respondendo corretamente!" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Não foi possível conectar ao serviço" -ForegroundColor Yellow
    Write-Host "   Verifique os logs para mais detalhes" -ForegroundColor Gray
}

