# Script para fazer build e publicar a imagem Docker no Docker Hub
# Versão 2.0

Write-Host "🐳 Build e Publicação do Protheus Exporter v2.0" -ForegroundColor Cyan
Write-Host ""

# Verificar se o Docker está rodando
Write-Host "🔍 Verificando Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker não está rodando"
    }
    Write-Host "✅ Docker está rodando (versão: $dockerVersion)" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker não está rodando ou não está instalado!" -ForegroundColor Red
    Write-Host "   Por favor, inicie o Docker Desktop e tente novamente." -ForegroundColor Yellow
    exit 1
}

# Navegar para o diretório correto
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host ""
Write-Host "📦 Fazendo build da imagem..." -ForegroundColor Yellow
Write-Host "   Diretório: $projectRoot" -ForegroundColor Gray

# Build da imagem com múltiplas tags
docker build `
    -t antunesls/protheus_exporter:2.0 `
    -t antunesls/protheus_exporter:latest `
    -f deployments/docker/Dockerfile `
    .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao fazer build da imagem!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build concluído com sucesso!" -ForegroundColor Green
Write-Host ""

# Verificar se está logado no Docker Hub
Write-Host "🔐 Verificando login no Docker Hub..." -ForegroundColor Yellow
$dockerInfo = docker info 2>$null | Select-String "Username:"
if (-not $dockerInfo) {
    Write-Host "⚠️  Você não está logado no Docker Hub!" -ForegroundColor Yellow
    Write-Host "   Execute: docker login" -ForegroundColor White
    Write-Host ""
    $response = Read-Host "   Deseja fazer login agora? (S/N)"
    if ($response -eq 'S' -or $response -eq 's') {
        docker login
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Falha ao fazer login!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "❌ É necessário estar logado para publicar a imagem!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Logado no Docker Hub" -ForegroundColor Green
Write-Host ""

# Fazer push da imagem
Write-Host "📤 Publicando imagem no Docker Hub..." -ForegroundColor Yellow
Write-Host "   Tag: antunesls/protheus_exporter:2.0" -ForegroundColor Gray

docker push antunesls/protheus_exporter:2.0

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao fazer push da versão 2.0!" -ForegroundColor Red
    exit 1
}

Write-Host "   Tag: antunesls/protheus_exporter:latest" -ForegroundColor Gray
docker push antunesls/protheus_exporter:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao fazer push da versão latest!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Imagem publicada com sucesso no Docker Hub!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Resumo:" -ForegroundColor Cyan
Write-Host "   🏷️  Versão: 2.0" -ForegroundColor White
Write-Host "   📦 Imagem: antunesls/protheus_exporter:2.0" -ForegroundColor White
Write-Host "   📦 Imagem: antunesls/protheus_exporter:latest" -ForegroundColor White
Write-Host "   🔗 URL: https://hub.docker.com/r/antunesls/protheus_exporter" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Para usar a nova versão:" -ForegroundColor Cyan
Write-Host "   docker pull antunesls/protheus_exporter:2.0" -ForegroundColor White
Write-Host "   docker run -d -p 8000:8000 antunesls/protheus_exporter:2.0" -ForegroundColor White
Write-Host ""
Write-Host "📝 Ou usando docker-compose:" -ForegroundColor Cyan
Write-Host "   cd deployments\docker" -ForegroundColor White
Write-Host "   docker-compose -f docker-compose-hub.yml up -d" -ForegroundColor White
Write-Host ""
