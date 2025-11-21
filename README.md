# Protheus Prometheus Exporter

Solução completa para exportar métricas do Protheus para o Prometheus, incluindo duas abordagens:

1. **Exporter Python (Flask)** - Servidor HTTP externo que recebe eventos via REST API
2. **Exporter Nativo Protheus** - Implementação direta no Protheus usando SharedTable

## 🚀 Recursos

- **Coleta de Métricas**: Rastreamento automático de execuções de rotinas
- **Múltiplas Abordagens**: Python Flask + Implementação nativa Protheus
- **Formato Prometheus**: Métricas compatíveis com Prometheus/Grafana
- **Baixa Latência**: Operações otimizadas via SQL
- **Ambiente Containerizado**: Docker support para deploy fácil
- **Interceptação Automática**: Hook em todas as rotinas via CHKEXEC

## 🚀 Início Rápido

### Método mais simples (Docker Hub):
```bash
# 1. Baixar e executar o exporter
docker run -d -p 8000:8000 --name protheus-exporter antunesls/protheus_exporter:0.1

# 2. Testar se está funcionando
curl http://localhost:8000/health

# 3. Ver métricas
curl http://localhost:8000/metrics
```

### Stack completa com Prometheus + Grafana:
```bash
# 1. Clone o repositório
git clone https://github.com/antunesls/protheus_exporter.git
cd protheus_exporter

# 2. Execute a stack completa
docker-compose -f docker/docker-compose-hub.yml up -d

# 3. Acesse as interfaces:
# - Exporter: http://localhost:8000
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3000 (admin/admin123)
# - Dashboard será automaticamente importado!
```

## 📁 Estrutura do Projeto

```
protheus_exporter/
├── 🐍 exporter/                 # Python Exporter
│   ├── protheus_exporter.py     # Servidor Flask
│   ├── requirements.txt         # Dependências Python
│   ├── venv/                    # Ambiente virtual
│   ├── activate_env.bat        # Script para ativar ambiente (Windows)
│   └── run_server.bat          # Script para executar servidor (Windows)
├── 🐳 docker/                   # Configurações Docker
│   ├── Dockerfile              # Container do exporter
│   ├── docker-compose.yml      # Stack completa (build local)
│   └── docker-compose-hub.yml  # Stack completa (Docker Hub)
├── 📊 prometheus.yml            # Configuração do Prometheus
├── 🎯 grafana-dashboard-protheus-metrics.json  # Dashboard Grafana
├── 📖 GRAFANA-DASHBOARD.md      # Documentação do dashboard
├── 📜 protheus/                 # Código Protheus
│   ├── CHKEXEC.PRW            # Hook de interceptação
│   ├── zproexpo.prw           # Exporter nativo Protheus
│   └── zProtheusExporter.prw  # Cliente HTTP para Python
└── 📖 README.md               # Este arquivo
```

## ⚙️ Configuração do Ambiente Python

### 1. Clone o repositório
```bash
git clone <repository-url>
cd protheus_exporter
```

### 2. Navegue para a pasta do exporter
```bash
cd exporter
```

### 3. Crie o ambiente virtual
```bash
python -m venv venv
```

### 4. Ative o ambiente virtual

**Windows:**
```bash
venv\Scripts\activate
# ou
activate_env.bat
```

**Linux/Mac:**
```bash
source venv/bin/activate
```

### 5. Instale as dependências
```bash
pip install -r requirements.txt
```

### 6. Execute o servidor
```bash
python protheus_exporter.py
# ou
run_server.bat
```

## 🐳 Docker

### Opção 1: Usar imagem do Docker Hub (Recomendado)
```bash
# Pull da imagem oficial
docker pull antunesls/protheus_exporter:0.1

# Executar container
docker run -p 8000:8000 antunesls/protheus_exporter:0.1
```

### Opção 2: Build local da imagem
```bash
# A partir da raiz do projeto
docker build -f docker/Dockerfile -t protheus-exporter .

# Executar container
docker run -p 8000:8000 protheus-exporter
```

### Docker Compose (stack completa)

**Usando imagem do Docker Hub (Mais rápido):**
```bash
# A partir da pasta docker
cd docker
docker-compose -f docker-compose-hub.yml up -d

# Ou da raiz do projeto
docker-compose -f docker/docker-compose-hub.yml up -d
```

**Usando build local:**
```bash
# A partir da pasta docker
cd docker
docker-compose up -d

# Ou da raiz do projeto
docker-compose -f docker/docker-compose.yml up -d
```

## 🔗 Endpoints da API

| Endpoint | Método | Descrição |
|----------|--------|-------------|
| `/health` | GET | Health check do serviço |
| `/track` | POST | Recebe eventos do Protheus |
| `/metrics` | GET | Métricas para Prometheus |

### Exemplo de requisição `/track`
```json
{
  "routine": "MATA010",
  "environment": "PROD",
  "user": "LUCAS", 
  "company": "01",
  "branch": "0101",
  "module": "FAT"
}
```

### URLs de acesso

**Desenvolvimento local (Python direto):**
- Exporter: `http://localhost:8000`

**Docker Compose:**
- Exporter: `http://localhost:8000` (mapeado do container)
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`

**Dentro da rede Docker:**
- Exporter: `http://protheus-exporter:8000`
- Prometheus: `http://prometheus:9090`
- Grafana: `http://grafana:3000`

### Exemplo de resposta `/metrics`
```
# HELP protheus_routine_calls_total Total de chamadas de rotinas no Protheus (agregado)
# TYPE protheus_routine_calls_total counter
protheus_routine_calls_total{routine="MATA010",environment="PROD",company="01",branch="0101",module="FAT"} 125

# HELP protheus_routine_user_calls_total Total de chamadas de rotinas no Protheus por usuário
# TYPE protheus_routine_user_calls_total counter
protheus_routine_user_calls_total{routine="MATA010",environment="PROD",user="LUCAS",company="01",branch="0101",module="FAT"} 45
```

## 💻 Configuração no Protheus

### 1. Abordagem Python (Recomendada para ambientes distribuídos)

**Compile os arquivos:**
- `protheus/zProtheusExporter.prw` - Cliente HTTP para enviar métricas
- `protheus/CHKEXEC.PRW` - Hook para interceptar execuções

**Configuração de URL:**

Para **desenvolvimento local**:
```advpl
#define EXPORTER_URL "http://localhost:8000/track"
```

Para **Docker Compose** (se Protheus roda no host):
```advpl
#define EXPORTER_URL "http://host.docker.internal:8000/track"
```

Para **Docker Compose** (se Protheus roda em container na mesma rede):
```advpl
#define EXPORTER_URL "http://protheus-exporter:8000/track"
```

**Uso manual:**
```advpl
// Chamada simples
u_PromTrackRoutine("MATA010")

// Chamada completa
u_PromTrackRoutine("MATA010", "PROD", "01", "0101", "FAT", "LUCAS")
```

### 2. Abordagem Nativa (Recomendada para ambientes locais)

**Compile o arquivo:**
- `protheus/zproexpo.prw` - Exporter nativo com SharedTable

**Acesse o endpoint:**
```
http://seu-servidor-protheus:porta/rest/protheus_exporter/
```

**Uso manual:**
```advpl
// Incrementa contador
u_PromIncRoutine("MATA010", "PROD", "01", "0101", "FAT", "LUCAS")

// Obtém métricas
cMetrics := u_PromExportMetrics()
```

## 📊 Configuração do Prometheus

### prometheus.yml
```yaml
scrape_configs:
  - job_name: 'protheus-python'
    static_configs:
      - targets: ['localhost:8000']
    metrics_path: '/metrics'
    scrape_interval: 30s
    
  - job_name: 'protheus-native'
    static_configs:
      - targets: ['seu-servidor-protheus:porta']
    metrics_path: '/rest/protheus_exporter/'
    scrape_interval: 30s
```

## 📈 Métricas Disponíveis

### protheus_routine_calls_total
- **Tipo:** Counter
- **Labels:** routine, environment, company, branch, module
- **Descrição:** Total agregado de chamadas por rotina

### protheus_routine_user_calls_total
- **Tipo:** Counter  
- **Labels:** routine, environment, user, company, branch, module
- **Descrição:** Total de chamadas por usuário (alta cardinalidade)

## 📊 Dashboard do Grafana

### Importando o Dashboard

1. **Via arquivo JSON:**
   - Baixe o arquivo [`grafana-dashboard-protheus-metrics.json`](./grafana-dashboard-protheus-metrics.json)
   - No Grafana, vá em **Dashboards > Import**
   - Cole o conteúdo do JSON ou faça upload do arquivo

2. **Configuração automática (Docker):**
   ```bash
   docker-compose -f docker/docker-compose-hub.yml up -d
   ```
   O dashboard será automaticamente importado quando usar o docker-compose.

### 📈 Visualizações Incluídas

#### 📊 **Visão Geral**
- **Execuções/min:** Taxa atual de execuções por minuto
- **Total de Rotinas:** Número de rotinas distintas
- **Usuários Ativos:** Usuários únicos que executaram rotinas
- **Total Execuções:** Contador total acumulado

#### 🔝 **Top 5 Rankings**
- **Top 5 Rotinas Mais Usadas:** Ranking das rotinas com mais execuções
- **Top 5 Rotinas Menos Usadas:** Rotinas com menor utilização
- **Top 5 Usuários Mais Ativos:** Usuários com mais execuções
- **Top 5 Usuários Menos Ativos:** Usuários com menor atividade

#### 📈 **Análise Temporal**
- **Taxa de Execução por Minuto:** Gráfico de linhas mostrando execuções/min ao longo do tempo

#### 🏢 **Análise Organizacional**
- **Distribuição por Empresa:** Pizza chart com execuções por empresa
- **Distribuição por Filial:** Pizza chart com execuções por filial

#### 🔧 **Análise por Módulo**
- **Uso por Módulo:** Pizza chart com distribuição por módulo do Protheus
- **Detalhamento por Módulo:** Tabela com totais por módulo

#### 🌍 **Análise por Ambiente**
- **Execuções por Ambiente:** Bar chart comparando produção, homologação, etc.

### 🎛️ **Controles Dinâmicos**

O dashboard inclui filtros para segmentação dos dados:
- **Ambiente:** Filtre por produção, homologação, desenvolvimento
- **Empresa:** Selecione empresas específicas
- **Módulo:** Filtre por módulos do Protheus (SIGAFIN, SIGAEST, etc.)

### 🔄 **Configurações**
- **Atualização automática:** 30 segundos
- **Período padrão:** Última 1 hora
- **Tema:** Dark mode otimizado para dashboards

### 🎯 **Casos de Uso**

1. **Monitoramento de Performance:**
   - Identifique rotinas com alto volume de execuções
   - Monitore padrões de uso ao longo do dia

2. **Análise de Usuários:**
   - Identifique usuários mais ativos
   - Analise padrões de comportamento

3. **Gestão de Recursos:**
   - Identifique módulos mais utilizados
   - Planeje recursos por empresa/filial

4. **Troubleshooting:**
   - Correlacione problemas com picos de execução
   - Identifique rotinas problemáticas

📖 **Para documentação completa do dashboard, veja:** [GRAFANA-DASHBOARD.md](./GRAFANA-DASHBOARD.md)

### 🔧 Desenvolvimento

### Estrutura de desenvolvimento
```bash
# Clone e navegue para exporter
git clone <repo>
cd protheus_exporter/exporter

# Ativar ambiente
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# Instalar dependências de desenvolvimento
pip install -r requirements.txt

# Executar com debug
export FLASK_DEBUG=1      # Linux/Mac
set FLASK_DEBUG=1         # Windows
python protheus_exporter.py
```

### Dependências
- **Flask 3.0.0** - Framework web
- **prometheus-client 0.19.0** - Biblioteca de métricas Prometheus

## 🛠️ Troubleshooting

### Problemas comuns

**1. Erro de conexão do Protheus:**
- Verifique se o servidor Python está rodando na porta 8000
- Confirme se a URL no `#define EXPORTER_URL` está correta

**2. Métricas não aparecem no Prometheus:**
- Verifique se o endpoint `/metrics` retorna dados
- Confirme a configuração do `prometheus.yml`

**3. Erro de dependências Python:**
- Certifique-se de que o ambiente virtual está ativo
- Execute `pip install -r requirements.txt` novamente

### Logs

**Python:**
```bash
# Com debug
export FLASK_DEBUG=1
python protheus_exporter.py
```

**Protheus:**
- Verifique o console.log do AppServer
- Mensagens `ConOut()` aparecem no log

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`) 
5. Abra um Pull Request

## 📝 Licença

Distribuído sob a licença MIT. Veja `LICENSE` para mais informações.

## 📧 Contato

Seu Nome - seu.email@exemplo.com

Link do Projeto: [https://github.com/seuusuario/protheus_exporter](https://github.com/seuusuario/protheus_exporter)