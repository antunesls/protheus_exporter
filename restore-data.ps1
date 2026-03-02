# Script para restaurar dados de um backup
# Restaura os dados do Prometheus e Grafana de um arquivo ZIP

param(
    [string]$BackupFile,
    [switch]$Force
)

Write-Host "📥 Iniciando restauração de dados..." -ForegroundColor Cyan

# Verificar se o arquivo de backup foi especificado
if (-not $BackupFile) {
    Write-Host "📚 Backups disponíveis:" -ForegroundColor Yellow
    $backups = Get-ChildItem ".\backups" -Filter "protheus_exporter_backup_*.zip" -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending
    
    if (-not $backups) {
        Write-Host "❌ Nenhum backup encontrado em .\backups" -ForegroundColor Red
        Write-Host "💡 Use: .\restore-data.ps1 -BackupFile <caminho_do_backup.zip>" -ForegroundColor Cyan
        exit 1
    }
    
    $index = 1
    $backups | ForEach-Object {
        $size = [math]::Round($_.Length/1MB, 2)
        Write-Host "   [$index] $($_.Name) - $size MB - $($_.LastWriteTime)" -ForegroundColor White
        $index++
    }
    
    Write-Host "`n💡 Use: .\restore-data.ps1 -BackupFile `".\backups\<nome_do_arquivo>`"" -ForegroundColor Cyan
    exit 0
}

# Verificar se o arquivo existe
if (-not (Test-Path $BackupFile)) {
    Write-Host "❌ Arquivo de backup não encontrado: $BackupFile" -ForegroundColor Red
    exit 1
}

# Caminho dos dados
$dataPath = Join-Path $PSScriptRoot "data"

# Verificar se já existem dados
if ((Test-Path $dataPath) -and -not $Force) {
    Write-Host "⚠️  ATENÇÃO: Já existem dados em $dataPath" -ForegroundColor Yellow
    Write-Host "   A restauração irá SUBSTITUIR todos os dados atuais!" -ForegroundColor Yellow
    Write-Host ""
    $confirmation = Read-Host "   Deseja continuar? (S/N)"
    
    if ($confirmation -ne 'S' -and $confirmation -ne 's') {
        Write-Host "❌ Restauração cancelada" -ForegroundColor Red
        exit 0
    }
}

# Fazer backup dos dados atuais antes de restaurar
if (Test-Path $dataPath) {
    Write-Host "📦 Criando backup dos dados atuais..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $tempBackup = ".\backups\protheus_exporter_backup_pre_restore_$timestamp.zip"
    
    try {
        New-Item -ItemType Directory -Path ".\backups" -Force | Out-Null
        Compress-Archive -Path $dataPath -DestinationPath $tempBackup -Force
        Write-Host "✅ Backup de segurança criado: $tempBackup" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Não foi possível criar backup de segurança: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Remover dados atuais
    Write-Host "🗑️  Removendo dados atuais..." -ForegroundColor Yellow
    Remove-Item -Path $dataPath -Recurse -Force
}

# Restaurar dados
try {
    Write-Host "📂 Extraindo backup..." -ForegroundColor Yellow
    
    # Criar diretório temporário
    $tempPath = Join-Path $PSScriptRoot "temp_restore"
    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    
    # Extrair arquivo
    Expand-Archive -Path $BackupFile -DestinationPath $tempPath -Force
    
    # Mover dados para o local correto
    $extractedDataPath = Join-Path $tempPath "data"
    if (Test-Path $extractedDataPath) {
        Move-Item -Path $extractedDataPath -Destination $dataPath -Force
    } else {
        # Se o backup não contém a pasta "data", assume que o conteúdo está na raiz
        Move-Item -Path $tempPath -Destination $dataPath -Force
    }
    
    # Remover diretório temporário
    if (Test-Path $tempPath) {
        Remove-Item -Path $tempPath -Recurse -Force
    }
    
    Write-Host "✅ Dados restaurados com sucesso!" -ForegroundColor Green
    
    # Mostrar informações dos dados restaurados
    $prometheusPath = Join-Path $dataPath "prometheus"
    $grafanaPath = Join-Path $dataPath "grafana"
    
    if (Test-Path $prometheusPath) {
        $prometheusSize = (Get-ChildItem $prometheusPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Write-Host "   📊 Prometheus: $([math]::Round($prometheusSize/1MB, 2)) MB restaurados" -ForegroundColor White
    }
    
    if (Test-Path $grafanaPath) {
        $grafanaSize = (Get-ChildItem $grafanaPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Write-Host "   📈 Grafana: $([math]::Round($grafanaSize/1MB, 2)) MB restaurados" -ForegroundColor White
    }
    
    Write-Host "`n💡 Reinicie os containers para aplicar as mudanças:" -ForegroundColor Cyan
    Write-Host "   cd deployments\docker" -ForegroundColor White
    Write-Host "   docker-compose restart" -ForegroundColor White
    
} catch {
    Write-Host "❌ Erro ao restaurar dados: $($_.Exception.Message)" -ForegroundColor Red
    
    # Tentar restaurar o backup de segurança
    if (Test-Path $tempBackup) {
        Write-Host "🔄 Tentando restaurar backup de segurança..." -ForegroundColor Yellow
        try {
            Expand-Archive -Path $tempBackup -DestinationPath $PSScriptRoot -Force
            Write-Host "✅ Backup de segurança restaurado" -ForegroundColor Green
        } catch {
            Write-Host "❌ Falha ao restaurar backup de segurança: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    exit 1
}
