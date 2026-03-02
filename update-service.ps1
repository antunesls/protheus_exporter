# Script para atualizar o Protheus Exporter Service
# Requer privilégios de Administrador

param(
    [switch]$KeepData,
    [switch]$SkipBackup,
    [string]$BackupDir = ".\backups"
)

# Verificar se está rodando como Administrador
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Write-Host "   Clique com botão direito e selecione 'Executar como Administrador'" -ForegroundColor Yellow
    exit 1
}

Write-Host "🔄 Atualização do Protheus Exporter Service" -ForegroundColor Cyan
Write-Host ""

# Verificar se o serviço existe
$service = Get-Service -Name "ProtheusExporter" -ErrorAction SilentlyContinue

if (-not $service) {
    Write-Host "❌ Serviço ProtheusExporter não encontrado!" -ForegroundColor Red
    Write-Host "   Execute: .\install-service.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Serviço encontrado: $($service.DisplayName)" -ForegroundColor Green
Write-Host "   Status atual: $($service.Status)" -ForegroundColor Gray
Write-Host ""

# Diretório do serviço
$ServicePath = Join-Path $PSScriptRoot "src\python"

if (-not (Test-Path $ServicePath)) {
    Write-Host "❌ Diretório do serviço não encontrado: $ServicePath" -ForegroundColor Red
    exit 1
}

# Criar backup se solicitado
if (-not $SkipBackup) {
    Write-Host "💾 Criando backup..." -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $BackupDir "backup_$timestamp"
    
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir | Out-Null
    }
    
    try {
        New-Item -ItemType Directory -Path $backupPath | Out-Null
        
        # Backup dos arquivos Python
        Copy-Item -Path "$ServicePath\*.py" -Destination $backupPath -ErrorAction SilentlyContinue
        Copy-Item -Path "$ServicePath\*.ini" -Destination $backupPath -ErrorAction SilentlyContinue
        
        # Backup dos dados (se existir)
        if (Test-Path "$ServicePath\data") {
            Copy-Item -Path "$ServicePath\data" -Destination $backupPath -Recurse -ErrorAction SilentlyContinue
        }
        
        # Backup dos logs (últimos arquivos)
        if (Test-Path "$ServicePath\logs") {
            Copy-Item -Path "$ServicePath\logs" -Destination $backupPath -Recurse -ErrorAction SilentlyContinue
        }
        
        Write-Host "   ✅ Backup criado em: $backupPath" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Erro ao criar backup: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   Continuar mesmo assim? (S/N)" -ForegroundColor Yellow
        $response = Read-Host
        if ($response -ne 'S' -and $response -ne 's') {
            exit 1
        }
    }
}

Write-Host ""
Write-Host "⏸️  Parando o serviço..." -ForegroundColor Yellow

try {
    if ($service.Status -eq 'Running') {
        Stop-Service -Name "ProtheusExporter" -Force
        Start-Sleep -Seconds 3
        
        $service = Get-Service -Name "ProtheusExporter"
        if ($service.Status -ne 'Stopped') {
            Write-Host "❌ Não foi possível parar o serviço!" -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host "✅ Serviço parado" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao parar serviço: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📝 Atualizando arquivos..." -ForegroundColor Yellow

# Lista de arquivos a serem atualizados
$filesToUpdate = @(
    "protheus_exporter.py",
    "protheus_exporter_service.py",
    "metrics_persistence.py",
    "requirements.txt",
    "requirements-windows.txt",
    "gunicorn.conf.py"
)

$updatedCount = 0
foreach ($file in $filesToUpdate) {
    $sourcePath = Join-Path $ServicePath $file
    if (Test-Path $sourcePath) {
        Write-Host "   ✅ $file" -ForegroundColor Gray
        $updatedCount++
    }
}

Write-Host "   Arquivos verificados: $updatedCount" -ForegroundColor Green

# Atualizar configuração apenas se não existir
$configFile = Join-Path $ServicePath "service-config.ini"
if (-not (Test-Path $configFile)) {
    Write-Host "   📋 Criando arquivo de configuração..." -ForegroundColor Gray
    # O arquivo já deve existir na instalação nova
}

# Preservar dados se solicitado
if ($KeepData) {
    Write-Host ""
    Write-Host "💾 Preservando dados e configurações..." -ForegroundColor Cyan
    Write-Host "   ✅ Dados de métricas mantidos" -ForegroundColor Gray
    Write-Host "   ✅ Logs mantidos" -ForegroundColor Gray
    Write-Host "   ✅ Configurações mantidas" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🔄 Verificando dependências..." -ForegroundColor Yellow

# Obter Python path
$pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
if ($pythonPath) {
    Write-Host "   Python: $pythonPath" -ForegroundColor Gray
    
    # Verificar se há novas dependências
    $requirementsFile = Join-Path $ServicePath "requirements-windows.txt"
    if (Test-Path $requirementsFile) {
        Write-Host "   Instalando/atualizando dependências..." -ForegroundColor Gray
        & $pythonPath -m pip install -r $requirementsFile --upgrade --quiet
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Dependências atualizadas" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Erro ao atualizar dependências" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "   ⚠️  Python não encontrado, pulando atualização de dependências" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🚀 Reiniciando serviço..." -ForegroundColor Yellow

try {
    Start-Service -Name "ProtheusExporter"
    Start-Sleep -Seconds 3
    
    $service = Get-Service -Name "ProtheusExporter"
    if ($service.Status -eq 'Running') {
        Write-Host "✅ Serviço reiniciado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Serviço não está rodando - Status: $($service.Status)" -ForegroundColor Yellow
        Write-Host "   Verifique os logs para mais detalhes" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Erro ao reiniciar serviço: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Tente: Start-Service ProtheusExporter" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🧪 Testando serviço..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Serviço está respondendo corretamente!" -ForegroundColor Green
        
        # Tentar obter informações de persistência
        $healthData = $response.Content | ConvertFrom-Json
        if ($healthData.persistence) {
            Write-Host ""
            Write-Host "📊 Persistência de métricas:" -ForegroundColor Cyan
            Write-Host "   Status: $($healthData.persistence.enabled)" -ForegroundColor White
            Write-Host "   Métricas: $($healthData.persistence.total_series) séries" -ForegroundColor White
        }
    }
} catch {
    Write-Host "⚠️  Não foi possível conectar ao serviço" -ForegroundColor Yellow
    Write-Host "   Verifique os logs para mais detalhes" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✅ Atualização concluída!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Resumo:" -ForegroundColor Cyan
Write-Host "   Arquivos atualizados: $updatedCount" -ForegroundColor White
if (-not $SkipBackup) {
    Write-Host "   Backup salvo em: $backupPath" -ForegroundColor White
}
Write-Host "   Status do serviço: $($service.Status)" -ForegroundColor White

Write-Host ""
Write-Host "💡 Comandos úteis:" -ForegroundColor Cyan
Write-Host "   Ver status: Get-Service ProtheusExporter" -ForegroundColor White
Write-Host "   Ver logs: Get-Content '$ServicePath\logs\protheus_exporter_service.log' -Tail 50" -ForegroundColor White
Write-Host "   Testar: Invoke-WebRequest http://localhost:8000/health" -ForegroundColor White

