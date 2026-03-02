# Protheus Exporter - Python Application

Este diretório contém a aplicação Python do Protheus Exporter.

## 📁 Arquivos

- `protheus_exporter.py` - Aplicação Flask principal
- `protheus_exporter_service.py` - Wrapper para Serviço Windows
- `gunicorn.conf.py` - Configuração do Gunicorn (Linux)
- `service-config.ini` - Configuração do Serviço Windows
- `requirements.txt` - Dependências básicas (Docker/Linux)
- `requirements-windows.txt` - Dependências para Windows Service

## 🚀 Execução

### Desenvolvimento Local

```bash
# Instalar dependências
pip install -r requirements.txt

# Executar
python protheus_exporter.py

# Acessar
# - Health: http://localhost:8000/health
# - Metrics: http://localhost:8000/metrics
```

### Produção (Linux/Mac)

```bash
# Instalar dependências com Gunicorn
pip install -r requirements.txt

# Executar com Gunicorn
gunicorn -c gunicorn.conf.py protheus_exporter:app
```

### Produção (Windows)

**Opção 1: Como Serviço Windows (Recomendado)**
```powershell
# Ver documentação completa
..\..\..\WINDOWS-SERVICE.md
```

**Opção 2: Com Waitress**
```powershell
# Instalar Waitress
pip install waitress

# Executar
waitress-serve --host=0.0.0.0 --port=8000 protheus_exporter:app
```

## ⚙️ Configuração

### Variáveis de Ambiente

```bash
# Host de bind
export FLASK_HOST=0.0.0.0

# Porta
export FLASK_PORT=8000

# Ambiente Protheus
export PROTHEUS_ENV=PROD

# Debug (apenas desenvolvimento)
export FLASK_DEBUG=false
```

### Windows
```powershell
$env:FLASK_HOST = "0.0.0.0"
$env:FLASK_PORT = "8000"
$env:PROTHEUS_ENV = "PROD"
```

## 🧪 Testes

### Healthcheck
```bash
curl http://localhost:8000/health
```

### Enviar Métrica
```bash
curl -X POST http://localhost:8000/track \
  -H "Content-Type: application/json" \
  -d '{
    "routine": "MATA010",
    "environment": "PROD",
    "user": "TESTE",
    "user_name": "Usuario Teste",
    "company": "01",
    "branch": "0101",
    "module": "FAT"
  }'
```

### Ver Métricas
```bash
curl http://localhost:8000/metrics
```

## 📦 Dependências

### Core (requirements.txt)
- `flask` - Framework web
- `prometheus-client` - Cliente Prometheus
- `gunicorn` - Servidor WSGI (Linux/Mac)

### Windows Service (requirements-windows.txt)
- `flask` - Framework web
- `prometheus-client` - Cliente Prometheus
- `pywin32` - Integração com Windows
- `waitress` - Servidor WSGI (Windows)

## 🐍 Versão Python

Requer Python 3.11 ou superior.

```bash
# Verificar versão
python --version
```

## 📝 Logs

- **Desenvolvimento**: Console (stdout)
- **Produção (Gunicorn)**: Configurado em `gunicorn.conf.py`
- **Serviço Windows**: `logs/protheus_exporter_service.log`

## 🔧 Troubleshooting

### Porta já em uso
```bash
# Linux/Mac
lsof -i :8000

# Windows
netstat -ano | findstr :8000
```

### Módulo não encontrado
```bash
# Reinstalar dependências
pip install -r requirements.txt --force-reinstall
```

### Permissões negadas (Linux)
```bash
# Usar porta > 1024 ou executar com sudo
sudo python protheus_exporter.py
# ou
export FLASK_PORT=8080
python protheus_exporter.py
```

## 📚 Mais Informações

- [README Principal](../../README.md)
- [Documentação Windows Service](../../WINDOWS-SERVICE.md)
- [Opções de Deployment](../../DEPLOYMENT-OPTIONS.md)
