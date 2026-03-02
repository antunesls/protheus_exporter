# Changelog

Todas as mudanças notáveis deste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [2.0.0] - 2026-03-02

### 🎉 Adicionado
- **Persistência de dados não volátil**: Dados do Prometheus e Grafana agora são salvos em diretórios locais (`data/`)
- **Scripts de backup/restore**: 
  - `backup-data.ps1` - Cria backups ZIP com timestamp
  - `restore-data.ps1` - Restaura backups anteriores
  - `check-persistence.ps1` - Verifica estado da persistência (melhorado)
- **Documentação completa**:
  - `DATA-PERSISTENCE.md` - Guia completo sobre persistência de dados
  - `MIGRATION-GUIDE.md` - Guia de migração de volumes Docker para bind mounts
  - `data/README.md` - Instruções no diretório de dados

### 🔄 Modificado
- **Docker Compose**: Substituídos volumes Docker por bind mounts locais
  - `docker-compose.yml` - Build local
  - `docker-compose-hub.yml` - Imagem do Docker Hub
- **Estrutura do projeto**: Novo diretório `data/` para armazenamento persistente
- **README.md**: Adicionada seção sobre persistência de dados
- **`.gitignore`**: Excluídos diretórios `data/`, `backups/` e `temp_restore/`

### ✨ Melhorado
- Dados não são mais perdidos após reinicialização do sistema
- Backup e restore simplificados
- Acesso direto aos arquivos de dados
- Melhor documentação sobre gerenciamento de dados

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
