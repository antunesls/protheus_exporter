# 🚀 Guia de Deployment - Protheus Exporter

Escolha a melhor opção de deployment para seu ambiente.

## 📊 Comparação das Opções

| Característica | Docker 🐳 | Serviço Windows 🪟 | Python Standalone 🐍 |
|----------------|-----------|-------------------|---------------------|
| **Facilidade de instalação** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Gerenciamento** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Isolamento** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐ |
| **Performance** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Portabilidade** | ⭐⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐ |
| **Integração Windows** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Inicialização automática** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ |
| **Monitoramento** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |

## 🐳 Opção 1: Docker (Recomendado para DevOps)

### ✅ Quando Usar
- Ambiente com Docker instalado
- Equipe familiarizada com containers
- Necessidade de rodar stack completa (Exporter + Prometheus + Grafana)
- Ambientes de desenvolvimento/staging
- Deploy em cloud (AWS, Azure, GCP)

### ⚡ Prós
- Setup mais rápido
- Isolamento completo
- Stack completa em um comando
- Fácil rollback de versões
- Portável entre ambientes

### ⚠️ Contras
- Requer Docker instalado
- Overhead de containerização (mínimo)
- Pode ter restrições corporativas

### 🚀 Início Rápido

```bash
# Stack completa
docker-compose -f deployments/docker/docker-compose-hub.yml up -d

# Apenas exporter
docker run -d -p 8000:8000 antunesls/protheus_exporter:2.0
```

### 📚 Documentação
- [README.md](README.md#-início-rápido)
- [Docker Hub](https://hub.docker.com/r/antunesls/protheus_exporter)

---

## 🪟 Opção 2: Serviço Windows (Recomendado para Windows Server)

### ✅ Quando Usar
- **Windows Server em produção**
- Ambientes corporativos sem Docker
- Necessidade de integração com Event Viewer
- Gerenciamento via GUI (services.msc)
- Inicialização automática com o Windows
- IT tradicional (não-DevOps)

### ⚡ Prós
- Integração nativa com Windows
- Event Viewer logs
- GUI de gerenciamento (services.msc)
- Inicialização automática configurável
- Sem overhead de containerização
- Execução em background
- Recuperação automática de falhas

### ⚠️ Contras
- Específico para Windows
- Requer instalação de dependências Python
- Setup um pouco mais complexo

### 🚀 Início Rápido

```powershell
# Instalação automatizada (executar como Administrador)
.\install-service.ps1 -AutoStart

# Gerenciamento
.\manage-service.ps1 status
.\manage-service.ps1 start
.\manage-service.ps1 logs
```

### 📚 Documentação
- [WINDOWS-SERVICE.md](WINDOWS-SERVICE.md) - **Guia completo**

---

## 🐍 Opção 3: Python Standalone (Para Desenvolvimento)

### ✅ Quando Usar
- Desenvolvimento local
- Testes rápidos
- Ambientes onde Docker não é permitido
- Servidores Linux simples
- Necessidade de debugar código

### ⚡ Prós
- Setup mais simples
- Ideal para desenvolvimento
- Fácil debug
- Controle total do ambiente

### ⚠️ Contras
- Não inicia automaticamente
- Requer gerenciamento manual
- Sem isolamento
- Logs apenas em console/arquivo

### 🚀 Início Rápido

```bash
# Instalar dependências
cd src/python
pip install -r requirements.txt

# Executar (desenvolvimento)
python protheus_exporter.py

# Executar (produção com Gunicorn - Linux)
gunicorn -w 4 -b 0.0.0.0:8000 protheus_exporter:app

# Executar (produção com Waitress - Windows)
pip install waitress
waitress-serve --host=0.0.0.0 --port=8000 protheus_exporter:app
```

### 📚 Documentação
- [README.md](README.md#-configuração)

---

## 🎯 Matriz de Decisão

### Cenário: Produção em Windows Server

```
Tem Docker? 
├─ Sim → Docker 🐳
└─ Não → Serviço Windows 🪟
```

### Cenário: Produção em Linux

```
Tem Docker?
├─ Sim → Docker 🐳
└─ Não → Python + systemd (similar ao Windows Service)
```

### Cenário: Desenvolvimento Local

```
Qualquer OS → Python Standalone 🐍 (mais rápido para testar)
```

### Cenário: Stack Completa (Exporter + Prometheus + Grafana)

```
Sempre use Docker 🐳 (mais fácil de gerenciar)
```

## 📊 Requisitos por Opção

### Docker
- **Software**: Docker Desktop ou Docker Engine
- **Memória**: 2GB+ (stack completa), 256MB (só exporter)
- **Disco**: 1GB+ (imagens)
- **CPU**: 1+ core

### Serviço Windows
- **SO**: Windows Server 2016+ ou Windows 10/11
- **Software**: Python 3.11+
- **Memória**: 256MB+
- **Disco**: 500MB+ (Python + dependências)
- **CPU**: 1+ core
- **Privilégios**: Administrador (para instalação)

### Python Standalone
- **Software**: Python 3.11+
- **Memória**: 128MB+
- **Disco**: 100MB+ (dependências)
- **CPU**: 1+ core

## 🔄 Migração Entre Opções

### Docker → Serviço Windows
```powershell
# 1. Exportar dados do Docker
docker cp protheus-exporter:/app/data ./data_backup

# 2. Parar Docker
docker-compose down

# 3. Instalar como serviço
.\install-service.ps1

# 4. Restaurar dados (se necessário)
```

### Serviço Windows → Docker
```powershell
# 1. Fazer backup
.\backup-data.ps1

# 2. Parar serviço
.\uninstall-service.ps1

# 3. Iniciar com Docker
docker-compose -f deployments/docker/docker-compose-hub.yml up -d

# 4. Restaurar dados se necessário
```

## 🆘 Troubleshooting por Opção

| Problema | Docker | Serviço Windows | Python Standalone |
|----------|--------|----------------|-------------------|
| Não inicia | `docker logs` | Event Viewer + logs | Ver console |
| Porta ocupada | Mudar porta no compose | Mudar no config.ini | Mudar variável env |
| Alto uso de memória | Limitar via Docker | Reduzir workers | Reduzir workers |
| Logs não aparecem | `docker logs -f` | `manage-service.ps1 logs` | Redirecionar output |

## 📞 Suporte

- **Issues**: [GitHub Issues](https://github.com/antunesls/protheus_exporter/issues)
- **Documentação**: Veja arquivos específicos de cada opção
- **Comunidade**: Contribuições são bem-vindas!

---

## 🎓 Recomendações Finais

### Para Produção
1. **Primeira escolha**: **Docker** (se disponível)
2. **Segunda escolha**: **Serviço Windows** (Windows Server sem Docker)
3. **Última opção**: Python Standalone (apenas se necessário)

### Para Desenvolvimento
1. **Python Standalone** - mais rápido para iterar
2. **Docker** - se quiser testar em ambiente próximo à produção

### Para Stack Completa
1. **Sempre Docker** - gerenciar Exporter + Prometheus + Grafana separadamente é complexo

---

**Última atualização:** 02/03/2026  
**Versão:** 2.0.0
