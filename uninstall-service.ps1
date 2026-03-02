# Script para desinstalar o Protheus Exporter Service
# Requer privilégios de Administrador

param(
    [switch]$Force
)

# Verificar se está rodando como Administrador
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Write-Host "   Clique com botão direito e selecione 'Executar como Administrador'" -ForegroundColor Yellow
    exit 1
}

Write-Host "🗑️  Desinstalação do Protheus Exporter Service" -ForegroundColor Cyan
Write-Host ""

# Verificar se o serviço existe
$service = Get-Service -Name "ProtheusExporter" -ErrorAction SilentlyContinue

if (-not $service) {
    Write-Host "⚠️  O serviço ProtheusExporter não está instalado" -ForegroundColor Yellow
    exit 0
}

Write-Host "📋 Serviço encontrado:" -ForegroundColor Yellow
Write-Host "   Nome: $($service.Name)" -ForegroundColor White
Write-Host "   Status: $($service.Status)" -ForegroundColor White
Write-Host "   Nome de exibição: $($service.DisplayName)" -ForegroundColor White
Write-Host ""

# Confirmar desinstalação
if (-not $Force) {
    $response = Read-Host "   Deseja realmente desinstalar o serviço? (S/N)"
    if ($response -ne 'S' -and $response -ne 's') {
        Write-Host "❌ Desinstalação cancelada" -ForegroundColor Red
        exit 0
    }
}

# Parar o serviço se estiver rodando
if ($service.Status -eq 'Running') {
    Write-Host "⏸️  Parando serviço..." -ForegroundColor Yellow
    try {
        Stop-Service -Name "ProtheusExporter" -Force
        Start-Sleep -Seconds 2
        Write-Host "✅ Serviço parado" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Erro ao parar serviço: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Determinar caminho do Python e script
$PythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source

if (-not $PythonPath) {
    Write-Host "⚠️  Python não encontrado no PATH" -ForegroundColor Yellow
    Write-Host "   Tentando remover serviço diretamente com sc.exe..." -ForegroundColor Gray
    
    sc.exe delete ProtheusExporter
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Serviço removido com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "❌ Erro ao remover serviço com sc.exe" -ForegroundColor Red
        exit 1
    }
} else {
    # Determinar caminho do script
    $ServicePath = Join-Path $PSScriptRoot "src\python"
    if (-not (Test-Path $ServicePath)) {
        $ServicePath = $PSScriptRoot
    }
    
    $serviceScript = Join-Path $ServicePath "protheus_exporter_service.py"
    
    if (-not (Test-Path $serviceScript)) {
        Write-Host "⚠️  Script do serviço não encontrado: $serviceScript" -ForegroundColor Yellow
        Write-Host "   Tentando remover serviço diretamente com sc.exe..." -ForegroundColor Gray
        
        sc.exe delete ProtheusExporter
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Serviço removido com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "❌ Erro ao remover serviço" -ForegroundColor Red
            exit 1
        }
    } else {
        # Remover usando o script Python
        Write-Host "🗑️  Removendo serviço..." -ForegroundColor Yellow
        
        try {
            & $PythonPath $serviceScript remove
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Serviço removido com sucesso!" -ForegroundColor Green
            } else {
                Write-Host "❌ Erro ao remover serviço" -ForegroundColor Red
                exit 1
            }
        } catch {
            Write-Host "❌ Erro ao remover serviço: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
}

# Verificar se realmente foi removido
Start-Sleep -Seconds 2
$serviceCheck = Get-Service -Name "ProtheusExporter" -ErrorAction SilentlyContinue

if ($serviceCheck) {
    Write-Host "⚠️  O serviço ainda aparece no sistema" -ForegroundColor Yellow
    Write-Host "   Pode ser necessário reiniciar o sistema" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "✅ Serviço completamente removido!" -ForegroundColor Green
}

Write-Host ""
Write-Host "📁 Arquivos do projeto mantidos em:" -ForegroundColor Cyan
Write-Host "   $PSScriptRoot" -ForegroundColor White
Write-Host ""
Write-Host "💡 Para reinstalar o serviço:" -ForegroundColor Cyan
Write-Host "   .\install-service.ps1" -ForegroundColor White
Write-Host ""
