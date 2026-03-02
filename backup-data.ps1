# Script para backup dos dados persistidos
# Cria um arquivo ZIP com os dados do Prometheus e Grafana

param(
    [string]$BackupPath = ".\backups"
)

Write-Host "💾 Iniciando backup dos dados..." -ForegroundColor Cyan

# Criar diretório de backups se não existir
if (-not (Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath | Out-Null
    Write-Host "📁 Diretório de backups criado: $BackupPath" -ForegroundColor Green
}

# Gerar nome do arquivo com timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFileName = "protheus_exporter_backup_$timestamp.zip"
$backupFullPath = Join-Path (Resolve-Path $BackupPath).Path $backupFileName

# Caminho dos dados
$dataPath = Join-Path $PSScriptRoot "data"

# Verificar se o diretório de dados existe
if (-not (Test-Path $dataPath)) {
    Write-Host "❌ Diretório data/ não encontrado!" -ForegroundColor Red
    exit 1
}

# Criar backup
try {
    Write-Host "🗜️  Compactando dados..." -ForegroundColor Yellow
    Compress-Archive -Path $dataPath -DestinationPath $backupFullPath -Force
    
    $backupSize = (Get-Item $backupFullPath).Length
    Write-Host "✅ Backup criado com sucesso!" -ForegroundColor Green
    Write-Host "   📦 Arquivo: $backupFileName" -ForegroundColor White
    Write-Host "   📊 Tamanho: $([math]::Round($backupSize/1MB, 2)) MB" -ForegroundColor White
    Write-Host "   📁 Local: $backupFullPath" -ForegroundColor White
    
    # Listar backups existentes
    Write-Host "`n📚 Backups disponíveis:" -ForegroundColor Yellow
    Get-ChildItem $BackupPath -Filter "protheus_exporter_backup_*.zip" | 
        Sort-Object LastWriteTime -Descending | 
        ForEach-Object {
            $size = [math]::Round($_.Length/1MB, 2)
            Write-Host "   $($_.Name) - $size MB - $($_.LastWriteTime)" -ForegroundColor White
        }
    
    # Sugestão de limpeza
    $oldBackups = Get-ChildItem $BackupPath -Filter "protheus_exporter_backup_*.zip" | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -Skip 5
    
    if ($oldBackups) {
        Write-Host "`n💡 Sugestão: Existem $($oldBackups.Count) backups antigos. Considere removê-los:" -ForegroundColor Cyan
        Write-Host "   Get-ChildItem `"$BackupPath`" -Filter `"protheus_exporter_backup_*.zip`" | Sort-Object LastWriteTime | Select-Object -First $($oldBackups.Count) | Remove-Item" -ForegroundColor DarkGray
    }
    
} catch {
    Write-Host "❌ Erro ao criar backup: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
