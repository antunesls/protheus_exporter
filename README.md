# 📊 Protheus Prometheus Exporter

> Sistema completo de monitoramento e métricas para Protheus ERP usando Prometheus e Grafana

[![Docker](https://img.shields.io/badge/docker-available-blue.svg)](https://hub.docker.com/r/antunesls/protheus_exporter)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.11+-blue.svg)](https://python.org)

## 🎯 Visão Geral

Solução profissional para coleta, processamento e visualização de métricas de uso do Protheus ERP, oferecendo insights valiosos sobre performance, utilização de funcionalidades e padrões de comportamento dos usuários.

### ✨ Principais Recursos

- 🔄 **Interceptação Automática**: Captura automática de execuções via CHKEXEC
- 📊 **Dashboard Rico**: Visualizações abrangentes no Grafana
- 🚨 **Sistema de Alertas**: Monitoramento proativo com Prometheus
- 🐳 **Deploy Simplificado**: Containerização completa com Docker
- 📈 **Métricas Detalhadas**: Análise por usuário, empresa, módulo e ambiente
- ⚡ **Alta Performance**: Otimizado para ambientes de produção

## 🚀 Início Rápido

### Método Recomendado (Docker)

```bash
# 1. Clone o repositório
git clone https://github.com/antunesls/protheus_exporter.git
cd protheus_exporter

# 2. Execute a stack completa
docker-compose -f deployments/docker/docker-compose-hub.yml up -d

# 3. Acesse as aplicações:
# - Exporter: http://localhost:8000
# - Prometheus: http://localhost:9090  
# - Grafana: http://localhost:3000 (admin/admin123)
```

### Apenas o Exporter

```bash
# Usando imagem do Docker Hub
docker run -d -p 8000:8000 --name protheus-exporter antunesls/protheus_exporter:0.2

# Verificar funcionamento
curl http://localhost:8000/health
```

## 📁 Estrutura do Projeto

```
protheus_exporter/
├── 📚 docs/                    # Documentação
│   └── grafana-dashboard.md    # Guia do dashboard Grafana
├── 🏗️ deployments/             # Configurações de deploy
│   └── docker/                 # Containers e orquestração
│       ├── Dockerfile          # Imagem do exporter
│       ├── docker-compose.yml  # Stack completa (build local)
│       └── docker-compose-hub.yml # Stack completa (Docker Hub)
├── ⚙️ configs/                 # Configurações dos serviços
│   ├── grafana/               # Configurações Grafana
│   │   ├── provisioning/      # Auto-configuração
│   │   └── dashboards/        # Dashboard JSON
│   └── prometheus/            # Configurações Prometheus
│       ├── prometheus.yml     # Configuração principal
│       ├── alert_rules.yml    # Regras de alertas
│       └── README-ALERTS.md   # Documentação alertas
├── 💻 src/                     # Código fonte
│   ├── python/                # Servidor Python Flask
│   │   ├── protheus_exporter.py # Servidor principal
│   │   └── requirements.txt   # Dependências
│   └── protheus/              # Código Protheus ADVPL
│       ├── CHKEXEC.PRW        # Hook de interceptação
│       └── zProtheusExporter.prw # Cliente HTTP
├── 📖 README.md               # Este arquivo
├── 🔒 .gitignore             # Arquivos ignorados pelo Git
└── 🐳 .dockerignore          # Arquivos ignorados pelo Docker
```

## ⚙️ Configuração

### 1. Protheus (ADVPL)

Compile e configure os arquivos Protheus:

**Arquivo obrigatório:**
- `src/protheus/CHKEXEC.PRW` - Hook para captura automática

**Arquivo para envio de métricas:**
- `src/protheus/zProtheusExporter.prw` - Cliente HTTP

**Configuração de URL no código:**

```advpl
// Para ambiente local
#define EXPORTER_URL "http://localhost:8000/track"

// Para Docker (Protheus no host)
#define EXPORTER_URL "http://host.docker.internal:8000/track"

// Para Docker (mesma rede)
#define EXPORTER_URL "http://protheus-exporter:8000/track"
```

**Uso manual (opcional):**
```advpl
// Rastreamento simples
u_PromTrackRoutine("MATA010")

// Rastreamento completo
u_PromTrackRoutine("MATA010", "PROD", "01", "0101", "EST", "ADMIN")
```

### 2. Ambiente Python (Desenvolvimento Local)

```bash
# Navegue para o código Python
cd src/python

# Crie ambiente virtual
python -m venv venv

# Ative o ambiente
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Instale dependências
pip install -r requirements.txt

# Execute o servidor
python protheus_exporter.py
```

## 📊 API Endpoints

| Endpoint | Método | Descrição | Exemplo |
|----------|--------|-------------|---------|
| `/health` | GET | Health check | `curl http://localhost:8000/health` |
| `/track` | POST | Recebe métricas do Protheus | Ver seção JSON |
| `/metrics` | GET | Métricas para Prometheus | Formato Prometheus |

### Formato JSON para `/track`

```json
{
  "routine": "MATA010",
  "environment": "PROD", 
  "user": "ADMIN",
  "company": "01",
  "branch": "0101",
  "module": "EST"
}
```

## 📈 Métricas Disponíveis

### `protheus_routine_calls_total`
- **Tipo:** Counter
- **Labels:** routine, environment, company, branch, module
- **Uso:** Análise agregada de uso de funcionalidades

### `protheus_routine_user_calls_total`  
- **Tipo:** Counter
- **Labels:** routine, environment, user, company, branch, module
- **Uso:** Análise detalhada por usuário

## 📊 Dashboard Grafana

### Funcionalidades Incluídas

🎯 **Visão Geral**
- Taxa de execução por minuto
- Total de rotinas e usuários ativos
- Contador total de execuções

🏆 **Rankings Top 5**
- Rotinas mais/menos utilizadas
- Usuários mais/menos ativos

📈 **Análises Distribucionais**
- Por empresa e filial (pizza charts)
- Por módulo do Protheus (donut + tabela)
- Por ambiente (bar chart)

⏰ **Análise Temporal**
- Taxa de execução ao longo do tempo
- Identificação de padrões e tendências

🎛️ **Filtros Dinâmicos**
- Ambiente (PROD, HML, DEV)
- Empresa (multi-seleção)
- Módulo (SIGAFIN, SIGAEST, etc.)

> 📖 **Documentação completa:** [docs/grafana-dashboard.md](docs/grafana-dashboard.md)

## 🚨 Sistema de Alertas

### Alertas Pré-configurados

| Alerta | Condição | Severidade | Descrição |
|--------|----------|------------|------------|
| **HighExecutionRate** | >100 exec/min | Warning | Rotina executando excessivamente |
| **RoutineNotExecuted** | >1h sem execução | Info | Rotina não utilizada |
| **VeryActiveUser** | >1000 exec/h | Info | Usuário muito ativo |
| **ExporterDown** | Serviço offline | Critical | Exporter indisponível |

> 📖 **Configuração completa:** [configs/prometheus/README-ALERTS.md](configs/prometheus/README-ALERTS.md)

## 🐳 Deployment

### Docker Compose (Recomendado)

**Produção (Docker Hub):**
```bash
cd deployments/docker
docker-compose -f docker-compose-hub.yml up -d
```

**Desenvolvimento (Build Local):**
```bash
cd deployments/docker  
docker-compose -f docker-compose.yml up -d
```

### Dockerfile Standalone

```bash
# Build da imagem
docker build -f deployments/docker/Dockerfile -t protheus-exporter .

# Executar container
docker run -p 8000:8000 protheus-exporter
```

## 🔧 Desenvolvimento

### Ambiente de Desenvolvimento

```bash
# Clone e setup
git clone <repo-url>
cd protheus_exporter/src/python

# Ambiente virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# Dependências e execução
pip install -r requirements.txt
export FLASK_DEBUG=1  # Modo debug
python protheus_exporter.py
```

### Stack de Desenvolvimento
- **Python 3.11+** - Runtime do exporter
- **Flask 3.0.0** - Framework web
- **prometheus-client 0.19.0** - Biblioteca de métricas
- **Docker & Docker Compose** - Containerização
- **Prometheus** - Coleta e storage de métricas  
- **Grafana** - Visualização e dashboards

## 🎯 Casos de Uso

### 1. 📊 Monitoramento de Performance
- Identifique rotinas com alto volume de execução
- Monitore padrões de uso durante o dia
- Detecte gargalos de performance

### 2. 👥 Gestão de Usuários  
- Analise comportamento de usuários
- Identifique usuários power users
- Otimize treinamentos e suporte

### 3. 🏢 Gestão Organizacional
- Compare uso entre empresas/filiais
- Planeje recursos por unidade de negócio
- Analise adoção de funcionalidades

### 4. 🔧 Otimização de Sistema
- Identifique funcionalidades subutilizadas
- Planeje descontinuação de features
- Otimize módulos mais utilizados

## 🛠️ Troubleshooting

### Problemas Comuns

**1. Conexão Protheus → Exporter**
```bash
# Verificar se exporter está rodando
curl http://localhost:8000/health

# Verificar logs do container
docker logs protheus-exporter
```

**2. Métricas não aparecem no Prometheus**
```bash
# Verificar endpoint de métricas
curl http://localhost:8000/metrics

# Verificar configuração do Prometheus
docker logs prometheus
```

**3. Dashboard vazio no Grafana**
```bash
# Verificar datasource
# Grafana → Configuration → Data Sources → Prometheus

# Verificar query no Explore
# Grafana → Explore → protheus_routine_user_calls_total
```

### Logs e Debug

**Python (modo debug):**
```bash
export FLASK_DEBUG=1
python src/python/protheus_exporter.py
```

**Docker Compose:**
```bash
# Logs de todos os serviços
docker-compose -f deployments/docker/docker-compose-hub.yml logs

# Logs específicos
docker-compose -f deployments/docker/docker-compose-hub.yml logs grafana
```

**Protheus:**
- Verifique console.log do AppServer
- Mensagens ConOut() aparecem nos logs

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

### Padrões de Código
- **Python:** PEP 8
- **ADVPL:** Padrões Protheus
- **Docker:** Multi-stage builds quando necessário
- **Documentação:** Markdown com emojis para clareza

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

## 📧 Suporte

- **Issues:** [GitHub Issues](https://github.com/antunesls/protheus_exporter/issues)
- **Discussões:** [GitHub Discussions](https://github.com/antunesls/protheus_exporter/discussions)
- **Email:** seu.email@exemplo.com

---

> **Desenvolvido com ❤️ para a comunidade Protheus**