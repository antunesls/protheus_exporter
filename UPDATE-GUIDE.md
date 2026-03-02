# Guia de Atualização do Protheus Exporter

Este guia explica como atualizar o Protheus Exporter Service para uma nova versão.

## 🔄 Métodos de Atualização

### Método 1: Script Automatizado (Recomendado)

Execute o script de atualização como **Administrador**:

```powershell
# Atualização completa com backup
.\update-service.ps1

# Atualização sem backup (mais rápido)
.\update-service.ps1 -SkipBackup

# Atualização preservando dados e configurações
.\update-service.ps1 -KeepData
```

O script automaticamente:
1. ✅ Para o serviço
2. ✅ Cria backup dos arquivos atuais
3. ✅ Atualiza os arquivos Python
4. ✅ Atualiza as dependências
5. ✅ Reinicia o serviço
6. ✅ Testa se está funcionando

### Método 2: Manual

Se preferir fazer manualmente:

#### 1. Parar o Serviço
```powershell
Stop-Service ProtheusExporter
```

#### 2. Fazer Backup (Opcional mas Recomendado)
```powershell
# Criar pasta de backup
$backup = "C:\backup\protheus_exporter_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backup

# Copiar arquivos
Copy-Item "C:\...\protheus_exporter\src\python\*" $backup -Recurse
```

#### 3. Substituir Arquivos
Copie os novos arquivos sobre os antigos:

```powershell
# Copiar novos arquivos Python
Copy-Item ".\src\python\*.py" "C:\caminho_instalacao\src\python\" -Force

# NÃO sobrescrever configurações e dados
Copy-Item ".\src\python\requirements*.txt" "C:\caminho_instalacao\src\python\" -Force
```

#### 4. Atualizar Dependências
```powershell
python -m pip install -r "C:\caminho_instalacao\src\python\requirements-windows.txt" --upgrade
```

#### 5. Reiniciar Serviço
```powershell
Start-Service ProtheusExporter
```

#### 6. Verificar
```powershell
# Ver status
Get-Service ProtheusExporter

# Testar endpoint
Invoke-WebRequest http://localhost:8000/health
```

## 📋 Checklist de Atualização

- [ ] Serviço parado
- [ ] Backup criado (se necessário)
- [ ] Arquivos `.py` atualizados
- [ ] Dependências atualizadas
- [ ] Configurações preservadas
- [ ] Dados preservados (se usar persistência)
- [ ] Serviço reiniciado
- [ ] Serviço testado e funcionando

## 🔐 Arquivos Importantes para Preservar

### ✅ SEMPRE preservar:
- `service-config.ini` - Configurações customizadas
- `data/` - Dados de métricas persistidas
- `logs/` - Logs históricos (opcional)

### ✅ Sempre SUBSTITUIR:
- `protheus_exporter.py` - Código principal
- `protheus_exporter_service.py` - Serviço Windows
- `metrics_persistence.py` - Módulo de persistência
- `requirements*.txt` - Dependências

### ⚠️ Verificar antes:
- `gunicorn.conf.py` - Se você customizou, mesclar mudanças

## 📦 Atualização de Dependências

### Verificar versões atuais:
```powershell
python -m pip list | Select-String "flask|prometheus|pywin32|waitress"
```

### Atualizar apenas pacotes específicos:
```powershell
python -m pip install --upgrade flask prometheus-client pywin32 waitress
```

### Atualizar todas (requirements):
```powershell
python -m pip install -r .\src\python\requirements-windows.txt --upgrade
```

## 🔍 Verificar Versão Atual

Não há um comando de versão ainda, mas você pode verificar:

```powershell
# Ver data de modificação dos arquivos
Get-Item "C:\...\src\python\protheus_exporter.py" | Select-Object Name, LastWriteTime

# Ver logs para mensagens de versão
Get-Content "C:\...\src\python\logs\protheus_exporter_service.log" -Tail 20
```

## 🆕 Novas Funcionalidades (v2.1)

Se você está atualizando para a versão com persistência de métricas:

### O que muda:
- ✅ Métricas preservadas entre reinicializações
- ✅ Novo arquivo `metrics_persistence.py`
- ✅ Nova seção `[persistence]` no `service-config.ini`
- ✅ Endpoint `/health` retorna estatísticas

### Migração:
A persistência é **opcional** e vem **habilitada** por padrão. Se quiser desabilitar:

```ini
# service-config.ini
[persistence]
enabled = false
```

## 🚨 Troubleshooting

### Serviço não inicia após atualização

1. Verificar logs:
```powershell
Get-Content "C:\...\logs\protheus_exporter_service.log" -Tail 50
```

2. Testar execução manual:
```powershell
python "C:\...\protheus_exporter.py"
```

3. Verificar dependências:
```powershell
python -m pip check
```

### Erro de import após atualização

Reinstalar dependências:
```powershell
python -m pip install -r requirements-windows.txt --force-reinstall
```

### Perdi as métricas

Se você não tinha persistência habilitada, as métricas foram perdidas na reinicialização (comportamento normal).

**Solução:** Habilitar persistência para evitar no futuro:
```ini
[persistence]
enabled = true
```

### Configurações resetadas

Se você sobrescreveu o `service-config.ini`, restaure do backup:
```powershell
Copy-Item "C:\backup\...\service-config.ini" "C:\...\src\python\" -Force
Restart-Service ProtheusExporter
```

## 🔄 Rollback (Reverter Atualização)

Se algo der errado, reverta para a versão anterior:

### 1. Parar o serviço:
```powershell
Stop-Service ProtheusExporter
```

### 2. Restaurar do backup:
```powershell
Copy-Item "C:\backup\...\*" "C:\...\src\python\" -Recurse -Force
```

### 3. Reiniciar:
```powershell
Start-Service ProtheusExporter
```

## 📅 Frequência de Atualização

### Recomendações:
- **Atualizações de segurança**: Imediatamente
- **Novas funcionalidades**: A cada 3-6 meses
- **Bug fixes**: Quando necessário
- **Dependências Python**: Mensalmente (pip outdated)

### Verificar atualizações disponíveis:
```powershell
# No diretório do projeto
git pull origin main

# Ver mudanças
git log --oneline -10
```

## 💾 Backup Automático

Agende backups regulares:

```powershell
# Criar script de backup agendado
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\...\backup-service.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Backup Protheus Exporter" -Description "Backup diário do serviço"
```

## 📚 Recursos Adicionais

- [README.md](README.md) - Documentação geral
- [WINDOWS-SERVICE.md](WINDOWS-SERVICE.md) - Documentação do serviço
- [METRICS-PERSISTENCE.md](METRICS-PERSISTENCE.md) - Persistência de métricas
- [CHANGELOG.md](CHANGELOG.md) - Histórico de mudanças

## 💡 Dicas

1. **Sempre faça backup** antes de atualizar em produção
2. **Teste em ambiente de homologação** primeiro
3. **Agende atualizações** para horários de baixo uso
4. **Documente customizações** feitas no código
5. **Mantenha logs** de atualizações anteriores

## 🔐 Segurança

Ao atualizar, revise:
- [ ] Permissões de arquivos mantidas
- [ ] Firewall configurado para porta 8000
- [ ] Serviço rodando com usuário apropriado
- [ ] Logs não expostos publicamente
- [ ] Dados de métricas protegidos
