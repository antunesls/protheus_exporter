# Script PowerShell de inicialização do Protheus Exporter
# Uso: .\start.ps1 [dev|prod]

param(
    [ValidateSet("dev", "development", "prod", "production")]
    [string]$Mode = "prod"
)

$Host_Address = if ($env:FLASK_HOST) { $env:FLASK_HOST } else { "0.0.0.0" }
$Port = if ($env:FLASK_PORT) { $env:FLASK_PORT } else { "8000" }
$Workers = if ($env:WORKERS) { $env:WORKERS } else { "4" }

Write-Host "🚀 Iniciando Protheus Exporter..." -ForegroundColor Cyan
Write-Host "📦 Modo: $Mode" -ForegroundColor Yellow
Write-Host "🌐 Host: ${Host_Address}:${Port}" -ForegroundColor Green

# Navegar para o diretório do código Python
Set-Location "src\python"

switch ($Mode.ToLower()) {
    { $_ -in @("dev", "development") } {
        Write-Host "⚠️  Modo de desenvolvimento (não use em produção!)" -ForegroundColor Yellow
        Write-Host "🔧 Executando com Flask dev server..." -ForegroundColor Cyan
        $env:FLASK_DEBUG = "true"
        python protheus_exporter.py
    }
    { $_ -in @("prod", "production") } {
        Write-Host "🏭 Modo de produção" -ForegroundColor Green
        Write-Host "👷 Workers: $Workers" -ForegroundColor White
        Write-Host "🔧 Executando com Gunicorn..." -ForegroundColor Cyan
        
        # Verificar se gunicorn está instalado
        try {
            gunicorn --version | Out-Null
            gunicorn -c gunicorn.conf.py protheus_exporter:app
        }
        catch {
            Write-Host "❌ Gunicorn não encontrado. Instalando..." -ForegroundColor Red
            pip install gunicorn
            gunicorn -c gunicorn.conf.py protheus_exporter:app
        }
    }
    default {
        Write-Host "❌ Modo inválido: $Mode" -ForegroundColor Red
        Write-Host "💡 Use: .\start.ps1 [dev|prod]" -ForegroundColor Yellow
        exit 1
    }
}