# 🪟 Deployment como Serviço Windows

Guia completo para instalar e executar o Protheus Exporter como um serviço nativo do Windows Server.

## 📋 Índice

- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [Gerenciamento](#gerenciamento)
- [Logs](#logs)
- [Troubleshooting](#troubleshooting)
- [Desinstalação](#desinstalação)

## 🎯 Visão Geral

O Protheus Exporter pode ser executado como um serviço Windows nativo, oferecendo:

- ✅ **Inicialização automática** com o Windows
- ✅ **Execução em background** sem janela de console
- ✅ **Integração com Service Control Manager** do Windows
- ✅ **Logs persistentes** em arquivo
- ✅ **Gestão via PowerShell** ou interface gráfica
- ✅ **Recuperação automática** em caso de falha

## 🔧 Pré-requisitos

### Software Necessário

1. **Python 3.11+**
   ```powershell
   # Verificar instalação
   python --version
   ```

2. **Windows Server 2016+** ou Windows 10/11

3. **Privilégios de Administrador**

### Dependências Python

As dependências serão instaladas automaticamente pelo script de instalação:
- `flask` - Framework web
- `prometheus-client` - Cliente Prometheus
- `pywin32` - Integração com Windows Services
- `waitress` - Servidor WSGI (mais adequado que Gunicorn para Windows)

## 🚀 Instalação

### Método 1: Script Automatizado (Recomendado)

```powershell
# 1. Abrir PowerShell como Administrador
# Botão direito no PowerShell > "Executar como Administrador"

# 2. Navegar até o diretório do projeto
cd C:\caminho\para\protheus_exporter

# 3. Executar script de instalação
.\install-service.ps1

# 4. (Opcional) Instalar com inicialização automática
.\install-service.ps1 -AutoStart
```

O script irá:
1. ✅ Verificar se Python está instalado
2. ✅ Instalar dependências necessárias
3. ✅ Registrar o serviço no Windows
4. ✅ Iniciar o serviço
5. ✅ Testar os endpoints

### Método 2: Manual

```powershell
# 1. Instalar dependências
cd src\python
pip install -r requirements-windows.txt

# 2. Instalar serviço
python protheus_exporter_service.py install

# 3. Iniciar serviço
python protheus_exporter_service.py start
```

## ⚙️ Configuração

### Arquivo de Configuração

Edite o arquivo `src/python/service-config.ini`:

```ini
[service]
# Endereço de bind (0.0.0.0 = todas as interfaces)
host = 0.0.0.0

# Porta do servidor
port = 8000

# Número de workers/threads
workers = 4

# Ambiente do Protheus (PROD, HML, DEV)
environment = PROD

[logging]
# Nível de log (DEBUG, INFO, WARNING, ERROR, CRITICAL)
level = INFO

# Diretório de logs
log_dir = logs

# Rotação de logs
max_bytes = 10485760
backup_count = 5
```

### Variáveis de Ambiente (Opcional)

Você também pode usar variáveis de ambiente que sobrescrevem as configurações do arquivo:

```powershell
# Configurar variáveis de ambiente do sistema
[Environment]::SetEnvironmentVariable("FLASK_HOST", "0.0.0.0", "Machine")
[Environment]::SetEnvironmentVariable("FLASK_PORT", "8000", "Machine")
[Environment]::SetEnvironmentVariable("PROTHEUS_ENV", "PROD", "Machine")
```

### Alterar Porta

```powershell
# Parar serviço
Stop-Service ProtheusExporter

# Editar configuração
notepad src\python\service-config.ini
# Alterar: port = 9000

# Iniciar serviço
Start-Service ProtheusExporter
```

## 🎮 Gerenciamento

### Usando PowerShell (Recomendado)

```powershell
# Ver status
.\manage-service.ps1 status

# Iniciar serviço
.\manage-service.ps1 start

# Parar serviço
.\manage-service.ps1 stop

# Reiniciar serviço
.\manage-service.ps1 restart

# Ver logs
.\manage-service.ps1 logs

# Ver logs em tempo real
.\manage-service.ps1 logs -Follow

# Testar endpoints
.\manage-service.ps1 test
```

### Usando Comandos Nativos do Windows

```powershell
# Ver status
Get-Service ProtheusExporter

# Iniciar
Start-Service ProtheusExporter

# Parar
Stop-Service ProtheusExporter

# Reiniciar
Restart-Service ProtheusExporter

# Ver detalhes
Get-Service ProtheusExporter | Format-List *

# Configurar inicialização automática
Set-Service ProtheusExporter -StartupType Automatic

# Configurar inicialização manual
Set-Service ProtheusExporter -StartupType Manual

# Desabilitar
Set-Service ProtheusExporter -StartupType Disabled
```

### Interface Gráfica (services.msc)

1. Pressione `Win + R`
2. Digite `services.msc`
3. Procure por "Protheus Prometheus Exporter"
4. Clique com botão direito para gerenciar

## 📝 Logs

### Localização

Os logs são armazenados em:
```
src\python\logs\protheus_exporter_service.log
```

### Visualizar Logs

```powershell
# Últimas 50 linhas
Get-Content src\python\logs\protheus_exporter_service.log -Tail 50

# Acompanhar em tempo real
Get-Content src\python\logs\protheus_exporter_service.log -Tail 50 -Wait

# Buscar por erro
Get-Content src\python\logs\protheus_exporter_service.log | Select-String "ERROR"

# Logs de hoje
Get-Content src\python\logs\protheus_exporter_service.log | Select-String (Get-Date -Format "yyyy-MM-dd")
```

### Event Viewer

O serviço também registra eventos no Event Viewer do Windows:

1. Abra Event Viewer (`eventvwr.msc`)
2. Navegue: Windows Logs > Application
3. Filtre por Source: "ProtheusExporter"

## 🧪 Testes

### Verificar se está Rodando

```powershell
# Status do serviço
Get-Service ProtheusExporter

# Testar healthcheck
Invoke-WebRequest http://localhost:8000/health

# Testar métricas
Invoke-WebRequest http://localhost:8000/metrics

# Enviar métrica de teste
$body = @{
    routine = "MATA010"
    environment = "PROD"
    user = "TESTE"
    user_name = "Usuario Teste"
    company = "01"
    branch = "0101"
    module = "FAT"
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:8000/track -Method POST -Body $body -ContentType "application/json"
```

### Monitoramento

```powershell
# Uso de CPU e memória
Get-Process | Where-Object {$_.ProcessName -like "*python*"} | Format-Table ProcessName, CPU, WorkingSet

# Portas em uso
netstat -ano | findstr :8000
```

## 🆘 Troubleshooting

### Serviço não inicia

**Problema:** Erro ao iniciar o serviço

**Soluções:**

1. Verificar logs:
   ```powershell
   Get-Content src\python\logs\protheus_exporter_service.log -Tail 100
   ```

2. Verificar dependências:
   ```powershell
   python -m pip list | findstr "flask prometheus pywin32 waitress"
   ```

3. Testar manualmente:
   ```powershell
   cd src\python
   python protheus_exporter.py
   ```

### Porta já em uso

**Problema:** Porta 8000 já está sendo usada

**Solução:**

```powershell
# Encontrar processo usando a porta
netstat -ano | findstr :8000

# Matar processo (substitua PID)
Stop-Process -Id <PID> -Force

# Ou alterar porta no service-config.ini
```

### Permissões negadas

**Problema:** Access Denied ao instalar/gerenciar serviço

**Solução:**

1. Execute PowerShell como Administrador
2. Verifique UAC não está bloqueando
3. Verifique antivírus não está interferindo

### Erro "pywin32 not found"

**Problema:** Módulo pywin32 não encontrado

**Solução:**

```powershell
# Instalar pywin32
pip install pywin32

# Executar configuração pós-instalação
python Scripts\pywin32_postinstall.py -install
```

### Serviço instalado mas não aparece

**Problema:** Serviço não aparece em services.msc

**Solução:**

```powershell
# Atualizar lista de serviços
sc query ProtheusExporter

# Reinstalar
.\uninstall-service.ps1 -Force
.\install-service.ps1
```

### Logs não são gerados

**Problema:** Arquivo de log vazio ou não existe

**Solução:**

```powershell
# Criar diretório de logs
New-Item -ItemType Directory -Path "src\python\logs" -Force

# Dar permissões
icacls "src\python\logs" /grant "NT AUTHORITY\LOCAL SERVICE:(OI)(CI)F"

# Reiniciar serviço
Restart-Service ProtheusExporter
```

## 🗑️ Desinstalação

### Método 1: Script (Recomendado)

```powershell
# Executar como Administrador
.\uninstall-service.ps1

# Forçar desinstalação sem confirmação
.\uninstall-service.ps1 -Force
```

### Método 2: Manual

```powershell
# Parar serviço
Stop-Service ProtheusExporter

# Remover serviço
cd src\python
python protheus_exporter_service.py remove

# Ou usando sc.exe
sc delete ProtheusExporter
```

### Limpeza Completa

```powershell
# Remover logs
Remove-Item src\python\logs -Recurse -Force

# Desinstalar dependências Python (opcional)
pip uninstall pywin32 waitress -y
```

## 🔄 Atualização

Para atualizar o exporter para uma nova versão:

```powershell
# 1. Parar serviço
Stop-Service ProtheusExporter

# 2. Fazer backup dos logs e configurações
Copy-Item src\python\logs logs_backup -Recurse
Copy-Item src\python\service-config.ini service-config.ini.bak

# 3. Atualizar código (git pull ou substituir arquivos)
git pull

# 4. Atualizar dependências
pip install -r src\python\requirements-windows.txt --upgrade

# 5. Iniciar serviço
Start-Service ProtheusExporter

# 6. Verificar
.\manage-service.ps1 test
```

## 🔒 Segurança

### Executar com Usuário Específico

Por padrão, o serviço roda como "Local System". Para usar outro usuário:

```powershell
# Alterar usuário do serviço
$credential = Get-Credential
sc config ProtheusExporter obj= "$($credential.UserName)" password= "$($credential.GetNetworkCredential().Password)"

# Reiniciar
Restart-Service ProtheusExporter
```

### Firewall

```powershell
# Abrir porta no firewall
New-NetFirewallRule -DisplayName "Protheus Exporter" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow

# Verificar regra
Get-NetFirewallRule -DisplayName "Protheus Exporter"
```

### HTTPS (Opcional)

Para habilitar HTTPS, você precisará usar um proxy reverso como IIS ou nginx.

## 📊 Performance

### Ajustar Workers

No `service-config.ini`, ajuste o número de workers baseado em:
- **CPU cores**: workers = cores * 2
- **Carga esperada**: mais workers = mais requisições simultâneas
- **Memória disponível**: cada worker consome ~50-100MB

```ini
[service]
workers = 8  # Para servidor com 4 cores
```

### Monitoramento de Recursos

```powershell
# CPU e memória do processo
Get-Counter "\Process(python*)\% Processor Time", "\Process(python*)\Working Set"

# Criar tarefa de monitoramento
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "Get-Service ProtheusExporter | Export-Csv C:\logs\service_status.csv -Append"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
Register-ScheduledTask -TaskName "Monitor ProtheusExporter" -Action $action -Trigger $trigger
```

## 🎯 Comparação com Outras Opções

| Característica | Serviço Windows | Docker | Python Standalone |
|----------------|----------------|--------|-------------------|
| Inicialização automática | ✅ Nativa | ✅ Com restart policy | ❌ Requer agendador |
| Isolamento | ⚠️ Processo | ✅ Container | ❌ Nenhum |
| Facilidade de uso | ✅ GUI Windows | ⚠️ CLI | ✅ Simples |
| Logs | ✅ Event Viewer + arquivo | ✅ Docker logs | ⚠️ Apenas arquivo |
| Performance | ✅ Nativa | ⚠️ Overhead mínimo | ✅ Nativa |
| Portabilidade | ❌ Apenas Windows | ✅ Multiplataforma | ⚠️ Requer Python |
| Requisitos | Python + pywin32 | Docker Desktop | Apenas Python |

## 📚 Recursos Adicionais

- [Documentação pywin32](https://github.com/mhammond/pywin32)
- [Windows Services Overview](https://docs.microsoft.com/en-us/windows/win32/services/services)
- [Waitress Documentation](https://docs.pylonsproject.org/projects/waitress/)

---

**Última atualização:** 02/03/2026  
**Versão:** 2.0.0
