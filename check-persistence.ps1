# Script para verificar persistência dos dados
# Executar antes e depois do restart do exporter

Write-Host "🔍 Verificando persistência de dados..." -ForegroundColor Cyan

# Verificar volumes do Docker
Write-Host "`n📦 Volumes Docker:" -ForegroundColor Yellow
docker volume ls | Where-Object { $_ -match "prometheus|grafana" }

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