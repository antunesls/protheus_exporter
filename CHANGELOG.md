# Changelog

Todas as mudanças notáveis deste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [2.0.0] - 2026-03-02

### 🎉 Adicionado
- **Persistência de dados não volátil**: Dados do Prometheus e Grafana agora são salvos em diretórios locais (`data/`)
- **Deployment como Serviço Windows**: Executar como serviço nativo do Windows Server
  - `protheus_exporter_service.py` - Wrapper do serviço Windows usando pywin32
  - `install-service.ps1` - Script de instalação automatizada
  - `uninstall-service.ps1` - Script de desinstalação
  - `manage-service.ps1` - Gerenciamento do serviço (start/stop/restart/logs)
  - `service-config.ini` - Arquivo de configuração do serviço
  - `requirements-windows.txt` - Dependências para Windows Service
- **Scripts de backup/restore**: 
  - `backup-data.ps1` - Cria backups ZIP com timestamp
  - `restore-data.ps1` - Restaura backups anteriores
  - `check-persistence.ps1` - Verifica estado da persistência (melhorado)
- **Documentação completa**:
  - `DATA-PERSISTENCE.md` - Guia completo sobre persistência de dados
  - `MIGRATION-GUIDE.md` - Guia de migração de volumes Docker para bind mounts
  - `WINDOWS-SERVICE.md` - Guia completo de deployment como serviço Windows
  - `data/README.md` - Instruções no diretório de dados
  - `RELEASE-2.0.md` - Guia de release e publicação
  - `publish-docker.ps1` - Script para publicar no Docker Hub

### 🔄 Modificado
- **Docker Compose**: Substituídos volumes Docker por bind mounts locais
  - `docker-compose.yml` - Build local
  - `docker-compose-hub.yml` - Imagem do Docker Hub (versão 2.0)
- **Estrutura do projeto**: Novo diretório `data/` para armazenamento persistente
- **README.md**: Adicionadas seções sobre persistência de dados e serviço Windows
- **`.gitignore`**: Excluídos diretórios `data/`, `backups/` e `temp_restore/`

### ✨ Melhorado
- **Três opções de deployment**: Docker, Python standalone, ou Serviço Windows nativo
- **Windows Server ready**: Execução como serviço nativo com inicialização automática
- Dados não são mais perdidos após reinicialização do sistema
- Backup e restore simplificados com scripts PowerShell
- Acesso direto aos arquivos de dados
- Logs estruturados com rotação automática
- Melhor documentação sobre gerenciamento de dados e deployment
- Integração nativa com Event Viewer do Windows

### 🔒 Segurança
- Dados sensíveis não são mais comitados no Git

## [0.2] - 2026-02-XX

### Adicionado
- Suporte a Gunicorn para produção
- Healthcheck configurado
- Dashboard Grafana completo

## [0.1] - 2026-01-XX

### Adicionado
- Versão inicial do Protheus Exporter
- Integração com Prometheus
- Docker e Docker Compose
- Métricas básicas de rotinas do Protheus
