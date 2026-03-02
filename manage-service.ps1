# Script para gerenciar o Protheus Exporter Service
# Comandos: status, start, stop, restart, logs

param(
    [Parameter(Mandatory=$false, Position=0)]
    [ValidateSet('status', 'start', 'stop', 'restart', 'logs', 'test')]
    [string]$Action = 'status',
    
    [switch]$Follow
)

$ServiceName = "ProtheusExporter"

function Show-ServiceStatus {
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    
    if (-not $service) {
        Write-Host "❌ Serviço não está instalado" -ForegroundColor Red
        Write-Host "   Execute: .\install-service.ps1" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "📋 Status do Serviço:" -ForegroundColor Cyan
    Write-Host "   Nome: $($service.Name)" -ForegroundColor White
    Write-Host "   Nome de exibição: $($service.DisplayName)" -ForegroundColor White
    
    $statusColor = switch ($service.Status) {
        'Running' { 'Green' }
        'Stopped' { 'Red' }
        default { 'Yellow' }
    }
    
    Write-Host "   Status: $($service.Status)" -ForegroundColor $statusColor
    Write-Host "   Tipo de início: $($service.StartType)" -ForegroundColor White
    
    return $true
}

function Start-ProtheusService {
    Write-Host "🚀 Iniciando serviço..." -ForegroundColor Yellow
    
    try {
        Start-Service -Name $ServiceName
        Start-Sleep -Seconds 3
        
        $service = Get-Service -Name $ServiceName
        if ($service.Status -eq 'Running') {
            Write-Host "✅ Serviço iniciado com sucesso!" -ForegroundColor Green
            Test-ServiceEndpoint
        } else {
            Write-Host "⚠️  Serviço não está rodando. Status: $($service.Status)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Erro ao iniciar serviço: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Stop-ProtheusService {
    Write-Host "⏸️  Parando serviço..." -ForegroundColor Yellow
    
    try {
        Stop-Service -Name $ServiceName -Force
        Start-Sleep -Seconds 2
        
        $service = Get-Service -Name $ServiceName
        if ($service.Status -eq 'Stopped') {
            Write-Host "✅ Serviço parado com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Serviço ainda está rodando. Status: $($service.Status)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Erro ao parar serviço: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Restart-ProtheusService {
    Write-Host "🔄 Reiniciando serviço..." -ForegroundColor Yellow
    
    Stop-ProtheusService
    Start-Sleep -Seconds 2
    Start-ProtheusService
}

function Show-ServiceLogs {
    $logPath = Join-Path $PSScriptRoot "src\python\logs\protheus_exporter_service.log"
    
    if (-not (Test-Path $logPath)) {
        Write-Host "⚠️  Arquivo de log não encontrado: $logPath" -ForegroundColor Yellow
        return
    }
    
    Write-Host "📝 Logs do serviço:" -ForegroundColor Cyan
    Write-Host "   Arquivo: $logPath" -ForegroundColor Gray
    Write-Host ""
    
    if ($Follow) {
        Write-Host "   Acompanhando logs (Ctrl+C para sair)..." -ForegroundColor Yellow
        Get-Content $logPath -Tail 50 -Wait
    } else {
        Write-Host "   Últimas 50 linhas:" -ForegroundColor Yellow
        Get-Content $logPath -Tail 50
    }
}

function Test-ServiceEndpoint {
    Write-Host ""
    Write-Host "🧪 Testando endpoints..." -ForegroundColor Yellow
    
    # Teste de healthcheck
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "   ✅ Health: http://localhost:8000/health" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ❌ Health: Não acessível" -ForegroundColor Red
    }
    
    # Teste de métricas
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/metrics" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "   ✅ Metrics: http://localhost:8000/metrics" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ❌ Metrics: Não acessível" -ForegroundColor Red
    }
}

# Verificar se está rodando como Administrador (necessário para start/stop/restart)
if ($Action -in @('start', 'stop', 'restart')) {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "❌ Esta operação requer privilégios de Administrador!" -ForegroundColor Red
        Write-Host "   Execute o PowerShell como Administrador" -ForegroundColor Yellow
        exit 1
    }
}

# Executar ação
Write-Host "🔧 Protheus Exporter Service Manager" -ForegroundColor Cyan
Write-Host ""

switch ($Action) {
    'status' {
        if (Show-ServiceStatus) {
            Write-Host ""
            Test-ServiceEndpoint
        }
    }
    'start' {
        Start-ProtheusService
    }
    'stop' {
        Stop-ProtheusService
    }
    'restart' {
        Restart-ProtheusService
    }
    'logs' {
        Show-ServiceLogs
    }
    'test' {
        Test-ServiceEndpoint
    }
}

Write-Host ""
