# Script para verificar persistência dos dados
# Executar antes e depois do restart do exporter

Write-Host "🔍 Verificando persistência de dados..." -ForegroundColor Cyan

# Verificar diretórios locais de dados
Write-Host "`n📁 Diretórios de dados persistidos:" -ForegroundColor Yellow
$dataPath = Join-Path $PSScriptRoot "data"
if (Test-Path $dataPath) {
    Write-Host "✅ Diretório data/ encontrado" -ForegroundColor Green
    
    # Verificar Prometheus
    $prometheusPath = Join-Path $dataPath "prometheus"
    if (Test-Path $prometheusPath) {
        $prometheusSize = (Get-ChildItem $prometheusPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $prometheusFiles = (Get-ChildItem $prometheusPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host "   📊 Prometheus: $prometheusFiles arquivos, $([math]::Round($prometheusSize/1MB, 2)) MB" -ForegroundColor White
    } else {
        Write-Host "   ⚠️  Prometheus: Diretório não encontrado" -ForegroundColor Yellow
    }
    
    # Verificar Grafana
    $grafanaPath = Join-Path $dataPath "grafana"
    if (Test-Path $grafanaPath) {
        $grafanaSize = (Get-ChildItem $grafanaPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $grafanaFiles = (Get-ChildItem $grafanaPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host "   📈 Grafana: $grafanaFiles arquivos, $([math]::Round($grafanaSize/1MB, 2)) MB" -ForegroundColor White
    } else {
        Write-Host "   ⚠️  Grafana: Diretório não encontrado" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Diretório data/ não encontrado" -ForegroundColor Red
}

# Verificar volumes do Docker (não devem mais existir)
Write-Host "`n📦 Volumes Docker:" -ForegroundColor Yellow
$volumes = docker volume ls | Where-Object { $_ -match "prometheus|grafana" }
if ($volumes) {
    Write-Host "⚠️  Volumes antigos encontrados (podem ser removidos):" -ForegroundColor Yellow
    Write-Host $volumes -ForegroundColor White
} else {
    Write-Host "✅ Nenhum volume Docker encontrado (usando bind mounts)" -ForegroundColor Green
}

# Verificar dados no Prometheus
Write-Host "`n📊 Consultando métricas no Prometheus:" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod "http://localhost:9090/api/v1/query?query=sum(protheus_routine_user_calls_total)"
    if ($response.status -eq "success") {
        Write-Host "✅ Total de métricas armazenadas: $($response.data.result.Count)" -ForegroundColor Green
        $response.data.result | ForEach-Object {
            Write-Host "   Valor: $($_.value[1])" -ForegroundColor White
        }
    } else {
        Write-Host "❌ Erro na consulta" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Prometheus não acessível: $($_.Exception.Message)" -ForegroundColor Red
}

# Verificar status dos containers
Write-Host "`n🐳 Status dos containers:" -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Where-Object { $_ -match "prometheus|grafana|protheus" }

Write-Host "`n💡 Para testar persistência:" -ForegroundColor Cyan
Write-Host "   1. Anote os valores atuais" -ForegroundColor White
Write-Host "   2. Reinicie o exporter: docker-compose restart protheus-exporter" -ForegroundColor White
Write-Host "   3. Execute este script novamente" -ForegroundColor White
Write-Host "   4. Os valores devem ser mantidos" -ForegroundColor White