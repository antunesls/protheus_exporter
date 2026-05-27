# Script PowerShell de inicialização do Protheus Exporter
# Uso: .\start.ps1 [dev|prod]

param(
    [ValidateSet("dev", "development", "prod", "production")]
    [string]$Mode = "prod"
)

$Host_Address = if ($env:FLASK_HOST) { $env:FLASK_HOST } else { "0.0.0.0" }
$Port = if ($env:FLASK_PORT) { $env:FLASK_PORT } else { "8000" }
$Workers = if ($env:WORKERS) { $env:WORKERS } else { "4" }

Write-Host "Iniciando Protheus Exporter..." -ForegroundColor Cyan
Write-Host "Modo: $Mode" -ForegroundColor Yellow
Write-Host "Host: ${Host_Address}:${Port}" -ForegroundColor Green

# Navegar para o diretório do código Python
Set-Location "src\python"

switch ($Mode.ToLower()) {
    { $_ -in @("dev", "development") } {
        Write-Host "[AVISO] Modo de desenvolvimento (nao use em producao!)" -ForegroundColor Yellow
        Write-Host "[INFO] Executando com Flask dev server..." -ForegroundColor Cyan
        $env:FLASK_DEBUG = "true"
        python protheus_exporter.py
    }
    { $_ -in @("prod", "production") } {
        Write-Host "[INFO] Modo de producao" -ForegroundColor Green
        Write-Host "[INFO] Threads: $Workers" -ForegroundColor White
        Write-Host "[INFO] Executando com Waitress..." -ForegroundColor Cyan

        # Instalar dependencias necessarias para o ambiente Windows
        Write-Host "[INFO] Verificando dependencias..." -ForegroundColor Yellow
        pip install -r requirements-windows.txt | Out-Null

        python -m waitress --host=$Host_Address --port=$Port --threads=$Workers protheus_exporter:app
    }
    default {
        Write-Host "[ERRO] Modo invalido: $Mode" -ForegroundColor Red
        Write-Host "[INFO] Use: .\start.ps1 [dev|prod]" -ForegroundColor Yellow
        exit 1
    }
}