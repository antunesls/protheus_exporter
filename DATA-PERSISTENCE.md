# Persistência de Dados - Protheus Exporter

## 📝 Visão Geral

Este projeto foi configurado para garantir que **todos os dados sejam persistidos em arquivos locais** (não voláteis). Os dados do Prometheus e Grafana são armazenados no diretório `data/` e não serão perdidos em caso de reinicialização do sistema ou dos containers.

## 📂 Estrutura de Dados

```
protheus_exporter/
├── data/                    # Dados persistidos (NÃO comitados no Git)
│   ├── prometheus/          # Métricas e dados do Prometheus
│   └── grafana/             # Dashboards e configurações do Grafana
├── backups/                 # Backups dos dados (NÃO comitados no Git)
├── backup-data.ps1          # Script para criar backups
├── restore-data.ps1         # Script para restaurar backups
└── check-persistence.ps1    # Script para verificar persistência
```

## 🔧 Como Funciona

### Bind Mounts vs Named Volumes

**ANTES (Volátil):**
- Utilizava Docker named volumes (`prometheus_data`, `grafana_data`)
- Dados gerenciados internamente pelo Docker
- Difícil acesso e backup dos dados
- Poderia ser perdido ao remover volumes

**AGORA (Persistente):**
- Utiliza bind mounts para diretórios locais
- Dados em `./data/prometheus` e `./data/grafana`
- Acesso direto aos arquivos no sistema de arquivos
- Totalmente persistente e fácil de fazer backup

### Configuração do Docker Compose

```yaml
volumes:
  - ../../data/prometheus:/prometheus  # Bind mount local
  - ../../data/grafana:/var/lib/grafana  # Bind mount local
```

## 🚀 Uso

### Iniciar o Sistema

```powershell
cd deployments\docker
docker-compose up -d
```

Os dados serão automaticamente salvos em `data/`.

### Verificar Persistência

```powershell
.\check-persistence.ps1
```

Este script mostra:
- Tamanho dos dados em disco
- Número de arquivos
- Status dos containers
- Alertas sobre volumes Docker antigos

### Fazer Backup

```powershell
.\backup-data.ps1
```

Cria um arquivo ZIP em `backups/` com timestamp:
- `protheus_exporter_backup_20260302_143022.zip`

### Restaurar Backup

```powershell
# Listar backups disponíveis
.\restore-data.ps1

# Restaurar um backup específico
.\restore-data.ps1 -BackupFile ".\backups\protheus_exporter_backup_20260302_143022.zip"

# Restaurar sem confirmação (use com cuidado!)
.\restore-data.ps1 -BackupFile ".\backups\protheus_exporter_backup_20260302_143022.zip" -Force
```

## 📊 Retenção de Dados

### Prometheus
- Configurado para reter métricas por **200 horas** (≈8 dias)
- Configuração em `configs/prometheus/prometheus.yml`:
  ```yaml
  --storage.tsdb.retention.time=200h
  ```
- Para alterar: modifique o valor em `docker-compose.yml`

### Grafana
- Dashboards e configurações são persistidos permanentemente
- Datasources e provisioning são mantidos

## 🔒 Segurança

### O que NÃO é comitado no Git (.gitignore):
```
data/               # Dados do Prometheus e Grafana
backups/            # Arquivos de backup
temp_restore/       # Temporários da restauração
```

### Recomendações:
1. **Faça backups regulares** dos dados
2. **Armazene backups** em local seguro (externo ao projeto)
3. **Documente a senha do Grafana** (padrão: `admin123`)
4. **Monitore o espaço em disco** do diretório `data/`

## 📏 Tamanho dos Dados

Tamanhos típicos:
- **Prometheus**: 10-500 MB (depende do volume de métricas)
- **Grafana**: 1-10 MB (dashboards e configurações)
- **Total**: ~20-510 MB

O tamanho cresce com:
- Número de métricas coletadas
- Frequência de coleta (scrape_interval)
- Tempo de retenção (retention.time)
- Número de dashboards

## 🧪 Testar Persistência

1. **Envie algumas métricas** para o exporter
2. **Execute** `.\check-persistence.ps1` (anote os valores)
3. **Reinicie os containers**: `docker-compose restart`
4. **Execute** `.\check-persistence.ps1` novamente
5. **Verifique** que os valores foram mantidos

```powershell
# Teste completo
.\check-persistence.ps1
docker-compose restart
Start-Sleep -Seconds 10
.\check-persistence.ps1
```

## 🔄 Migração de Dados Antigos

Se você tinha dados em named volumes do Docker:

```powershell
# 1. Liste os volumes antigos
docker volume ls | Where-Object { $_ -match "prometheus|grafana" }

# 2. Se necessário, copie dados dos volumes antigos
docker run --rm -v docker_prometheus_data:/source -v ${PWD}/data/prometheus:/dest busybox cp -r /source/. /dest/

# 3. Após confirmar que os dados foram migrados, remova os volumes antigos
docker volume rm docker_prometheus_data docker_grafana_data docker_prometheus_config
```

## ⚙️ Configurações Avançadas

### Alterar Local dos Dados

Edite `deployments/docker/docker-compose.yml`:

```yaml
volumes:
  - /seu/caminho/personalizado/prometheus:/prometheus
  - /seu/caminho/personalizado/grafana:/var/lib/grafana
```

### Backup Automático

Crie uma tarefa agendada no Windows para executar `backup-data.ps1`:

```powershell
# Criar tarefa para backup diário às 2h AM
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Users\antunesls\projetos\protheus_exporter\backup-data.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Protheus Exporter Backup" -Description "Backup diário dos dados do Protheus Exporter"
```

## 🆘 Solução de Problemas

### Permissões

Se houver erros de permissão ao iniciar os containers:

```powershell
# Windows: garantir que o usuário tem controle total
icacls "data" /grant "${env:USERNAME}:(OI)(CI)F" /T

# Ou recriar os diretórios
Remove-Item data -Recurse -Force
New-Item -ItemType Directory -Path "data\prometheus"
New-Item -ItemType Directory -Path "data\grafana"
```

### Espaço em Disco

Se o disco estiver cheio:

1. Reduza `retention.time` em `docker-compose.yml`
2. Remova backups antigos de `backups/`
3. Execute `docker system prune -a` para limpar Docker

### Dados Corrompidos

Se os dados estiverem corrompidos:

```powershell
# 1. Pare os containers
docker-compose down

# 2. Remova dados corrompidos
Remove-Item data -Recurse -Force

# 3. Restaure último backup bom
.\restore-data.ps1

# 4. Ou inicie limpo
New-Item -ItemType Directory -Path "data\prometheus"
New-Item -ItemType Directory -Path "data\grafana"
docker-compose up -d
```

## 📚 Recursos Adicionais

- [Documentação do Prometheus - Storage](https://prometheus.io/docs/prometheus/latest/storage/)
- [Documentação do Grafana - Data Directory](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#data)
- [Docker Volumes vs Bind Mounts](https://docs.docker.com/storage/volumes/)

---

**Última atualização:** 02/03/2026
