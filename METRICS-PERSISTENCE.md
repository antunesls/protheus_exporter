# Persistência de Métricas

O Protheus Exporter agora suporta **persistência de métricas** entre reinicializações do serviço.

## 📊 Como Funciona

### Sem Persistência (padrão anterior):
```
Serviço inicia → Contador em 0
Recebe 100 eventos → Contador em 100
Serviço reinicia → Contador volta para 0 ❌
```

### Com Persistência (novo):
```
Serviço inicia → Contador em 0
Recebe 100 eventos → Contador em 100
Salva em arquivo JSON automaticamente
Serviço reinicia → Carrega do arquivo → Contador em 100 ✅
Recebe mais 50 eventos → Contador em 150
```

## ⚙️ Configuração

### Arquivo: `service-config.ini`

```ini
[persistence]
# Habilitar/desabilitar persistência
enabled = true

# Diretório para dados
data_dir = data

# Intervalo de salvamento (segundos)
save_interval = 60
```

### Variável de Ambiente

```powershell
# Habilitar
$env:METRICS_PERSISTENCE = "true"

# Desabilitar
$env:METRICS_PERSISTENCE = "false"
```

## 📁 Localização dos Dados

As métricas são salvas em:

```
C:\Users\antunesls\projetos\protheus_exporter\src\python\data\metrics_data.json
```

### Exemplo do arquivo JSON:

```json
{
  "protheus_routine_calls_total": {
    "[['branch', '0101'], ['company', '01'], ['environment', 'PROD'], ['module', 'FAT'], ['routine', 'MATA010']]": {
      "labels": {
        "routine": "MATA010",
        "environment": "PROD",
        "company": "01",
        "branch": "0101",
        "module": "FAT"
      },
      "value": 150
    }
  }
}
```

## 🔄 Funcionamento Automático

### Salvamento Automático:
- **A cada 60 segundos**: Salva automaticamente em background
- **Ao encerrar o serviço**: Salva antes de finalizar

### Carregamento:
- **Na inicialização**: Carrega automaticamente os valores salvos

## 💡 Quando Usar

### ✅ Recomendado para:
- **Ambientes de produção** onde reinicializações são raras
- **Servidores Windows** que podem reiniciar para updates
- **Desenvolvimento/testes** para manter histórico

### ⚠️ Considere desabilitar se:
- **Muito alto volume** de eventos (milhões por dia)
- **Pouca memória** disponível
- **Prometheus já faz o backup** completo dos dados

## 🎯 Vantagens

1. **Continuidade**: Métricas não são perdidas em reinicializações
2. **Confiabilidade**: Dados salvos mesmo em caso de falha
3. **Transparente**: Funciona automaticamente, sem ação necessária

## 📝 Comandos Úteis

### Ver métricas salvas:
```powershell
Get-Content "C:\Users\antunesls\projetos\protheus_exporter\src\python\data\metrics_data.json" | ConvertFrom-Json
```

### Ver tamanho do arquivo:
```powershell
Get-Item "C:\Users\antunesls\projetos\protheus_exporter\src\python\data\metrics_data.json" | Select-Object Name, Length
```

### Limpar métricas salvas (reset):
```powershell
Remove-Item "C:\Users\antunesls\projetos\protheus_exporter\src\python\data\metrics_data.json"
Restart-Service ProtheusExporter
```

### Backup das métricas:
```powershell
Copy-Item "C:\Users\antunesls\projetos\protheus_exporter\src\python\data\metrics_data.json" "C:\backup\metrics_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
```

## 🔍 Monitoramento

### Ver logs relacionados:
```powershell
Get-Content "C:\Users\antunesls\projetos\protheus_exporter\src\python\logs\protheus_exporter_service.log" | Select-String "persist"
```

Mensagens no log:
- `✅ Persistência de métricas habilitada`
- `Métricas carregadas: X séries`
- `Métricas salvas em metrics_data.json`

## 🚨 Troubleshooting

### Métricas não estão sendo salvas

1. Verificar se está habilitado:
```powershell
Get-Content "C:\Users\antunesls\projetos\protheus_exporter\src\python\service-config.ini" | Select-String "enabled"
```

2. Verificar permissões do diretório:
```powershell
Test-Path "C:\Users\antunesls\projetos\protheus_exporter\src\python\data" -PathType Container
```

3. Verificar logs:
```powershell
Get-Content "C:\Users\antunesls\projetos\protheus_exporter\src\python\logs\protheus_exporter_service.log" -Tail 50
```

### Arquivo corrompido

Se o arquivo JSON ficar corrompido:

```powershell
# Fazer backup do arquivo problemático
Move-Item "metrics_data.json" "metrics_data.json.backup"

# Reiniciar o serviço (criará novo arquivo)
Restart-Service ProtheusExporter
```

## 📊 Relação com Prometheus

**Importante:** A persistência do exporter é **complementar** ao Prometheus, não substitui:

| Componente | Armazena | Quando perde dados |
|------------|----------|-------------------|
| **Exporter** (este projeto) | Valores atuais dos contadores | Ao reiniciar (sem persistência) |
| **Prometheus** (servidor) | Histórico completo de todas as coletas | Ao apagar volume do Docker |

**Melhor configuração:** 
- ✅ Persistência habilitada no exporter
- ✅ Volume persistente no Prometheus
- ✅ Backups regulares dos dados do Prometheus

## 🔐 Segurança

O arquivo `metrics_data.json` pode conter informações sensíveis como:
- Nomes de usuários
- Empresas e filiais
- Rotinas acessadas

**Recomendações:**
- Proteger o diretório `data/` com permissões adequadas
- Incluir no `.gitignore` (já configurado)
- Considerar criptografia para ambientes críticos

## 🆕 Novos Recursos

Ver estatísticas da persistência via endpoint `/health`:

```powershell
Invoke-RestMethod -Uri "http://localhost:8000/health"
```

Retorna:
```json
{
  "status": "ok",
  "persistence": {
    "enabled": true,
    "metrics_count": 5,
    "total_series": 150,
    "file_size_bytes": 12456
  }
}
```
