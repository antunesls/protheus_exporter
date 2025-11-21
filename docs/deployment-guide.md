# Protheus Exporter - Configurações de Ambiente

## 🏗️ Ambientes Suportados

### 🔧 Desenvolvimento Local
```bash
# Servidor Python standalone
cd src/python
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows
pip install -r requirements.txt
python protheus_exporter.py

# Configuração Protheus
#define EXPORTER_URL "http://localhost:8000/track"
```

### 🐳 Docker Local
```bash
# Stack completa
cd deployments/docker
docker-compose -f docker-compose.yml up -d

# Configuração Protheus
#define EXPORTER_URL "http://host.docker.internal:8000/track"
```

### 🚀 Produção (Docker Hub)
```bash
# Stack produção
cd deployments/docker
docker-compose -f docker-compose-hub.yml up -d

# Configuração Protheus
#define EXPORTER_URL "http://protheus-exporter:8000/track"
```

### ☁️ Cloud/Kubernetes
```yaml
# Exemplo para Kubernetes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: protheus-exporter
spec:
  replicas: 2
  selector:
    matchLabels:
      app: protheus-exporter
  template:
    metadata:
      labels:
        app: protheus-exporter
    spec:
      containers:
      - name: protheus-exporter
        image: antunesls/protheus_exporter:0.1
        ports:
        - containerPort: 8000
        env:
        - name: PROTHEUS_ENV
          value: "PROD"
---
apiVersion: v1
kind: Service
metadata:
  name: protheus-exporter-service
spec:
  selector:
    app: protheus-exporter
  ports:
  - port: 8000
    targetPort: 8000
  type: LoadBalancer
```

## ⚙️ Variáveis de Ambiente

### Python Flask Exporter
```bash
# Ambiente Protheus (padrão: PROD)
PROTHEUS_ENV=PROD

# Modo debug Flask (padrão: False)
FLASK_DEBUG=0

# Host de bind (padrão: 0.0.0.0)
FLASK_HOST=0.0.0.0

# Porta de bind (padrão: 8000)
FLASK_PORT=8000
```

### Prometheus
```bash
# Intervalo de coleta (padrão: 30s)
SCRAPE_INTERVAL=30s

# Retenção de dados (padrão: 200h)
RETENTION_TIME=200h

# Habilitar API admin (padrão: true)
ENABLE_ADMIN_API=true
```

### Grafana
```bash
# Senha do admin (padrão: admin123)
GF_SECURITY_ADMIN_PASSWORD=admin123

# Permitir signup (padrão: false)
GF_USERS_ALLOW_SIGN_UP=false

# Caminho de provisioning
GF_PATHS_PROVISIONING=/etc/grafana/provisioning
```

## 🔗 URLs por Ambiente

### Desenvolvimento Local
| Serviço | URL | Credenciais |
|---------|-----|-------------|
| Exporter | http://localhost:8000 | - |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3000 | admin/admin123 |

### Docker Compose
| Serviço | URL Externa | URL Interna |
|---------|-------------|-------------|
| Exporter | http://localhost:8000 | http://protheus-exporter:8000 |
| Prometheus | http://localhost:9090 | http://prometheus:9090 |
| Grafana | http://localhost:3000 | http://grafana:3000 |

### Kubernetes
```bash
# Obter URLs dos serviços
kubectl get services

# Port forward para acesso local
kubectl port-forward service/protheus-exporter-service 8000:8000
kubectl port-forward service/prometheus-service 9090:9090
kubectl port-forward service/grafana-service 3000:3000
```

## 📊 Configurações por Escala

### 🏠 Pequeno (< 100 usuários)
```yaml
# docker-compose.override.yml
version: '3.8'
services:
  protheus-exporter:
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
  
  prometheus:
    command:
      - '--storage.tsdb.retention.time=72h'
      
  grafana:
    environment:
      - GF_USERS_VIEWERS_CAN_EDIT=true
```

### 🏢 Médio (100-500 usuários)
```yaml
# docker-compose.override.yml
version: '3.8'
services:
  protheus-exporter:
    deploy:
      replicas: 2
      resources:
        limits:
          memory: 512M
          cpus: '1'
  
  prometheus:
    command:
      - '--storage.tsdb.retention.time=168h'  # 7 dias
```

### 🏭 Grande (500+ usuários)
```yaml
# docker-compose.override.yml
version: '3.8'
services:
  protheus-exporter:
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 1G
          cpus: '2'
  
  prometheus:
    command:
      - '--storage.tsdb.retention.time=720h'  # 30 dias
    volumes:
      - prometheus_data:/prometheus:Z
      
  grafana:
    environment:
      - GF_DATABASE_TYPE=postgres
      - GF_DATABASE_HOST=postgres:5432
      - GF_DATABASE_NAME=grafana
```

## 🔒 Configurações de Segurança

### Produção Básica
```yaml
# Adicionar ao docker-compose-hub.yml
services:
  protheus-exporter:
    environment:
      - PROTHEUS_ENV=PROD
    restart: unless-stopped
    
  grafana:
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_SECURITY_DISABLE_GRAVATAR=true
      - GF_ANALYTICS_REPORTING_ENABLED=false
```

### Produção Avançada
```yaml
# Com proxy reverso e HTTPS
services:
  nginx:
    image: nginx:alpine
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl/certs
    depends_on:
      - grafana
      - prometheus
```

## 🎯 Monitoramento do Monitor

### Health Checks
```bash
# Verificar status dos serviços
curl -f http://localhost:8000/health || exit 1
curl -f http://localhost:9090/-/healthy || exit 1
curl -f http://localhost:3000/api/health || exit 1
```

### Alertas para o Sistema de Monitoramento
```yaml
# configs/prometheus/alert_rules.yml
- alert: ExporterHighMemory
  expr: container_memory_usage_bytes{name="protheus-exporter"} > 500000000
  for: 5m
  
- alert: PrometheusHighDiskUsage
  expr: prometheus_tsdb_symbol_table_size_bytes > 1000000000
  for: 10m
```

## 📈 Otimização de Performance

### Configurações Prometheus
```yaml
# configs/prometheus/prometheus.yml
global:
  scrape_interval: 30s      # Aumentar para reduzir carga
  evaluation_interval: 60s  # Reduzir frequência de alertas
  
scrape_configs:
  - job_name: 'protheus-exporter'
    scrape_interval: 15s     # Intervalo específico por job
    scrape_timeout: 10s      # Timeout adequado
```

### Otimização Grafana
```bash
# Configurações de performance
GF_DATABASE_CACHE_MODE=private
GF_DATABASE_LOG_QUERIES=false
GF_METRICS_ENABLED=false
```