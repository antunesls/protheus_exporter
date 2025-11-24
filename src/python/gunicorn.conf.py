# Configuração do Gunicorn para produção
# Arquivo: gunicorn.conf.py

import os

# Configurações básicas
bind = f"0.0.0.0:{os.environ.get('PORT', '8000')}"
# IMPORTANTE: 1 worker para métricas Prometheus consistentes
# Múltiplos workers causam contadores separados por processo
# Usamos threads para concorrência sem perder estado
workers = 1
worker_class = "gthread"
threads = 4
worker_connections = 1000
timeout = 120
keepalive = 5
graceful_timeout = 30

# Logging
accesslog = "-"  # stdout
errorlog = "-"   # stderr
loglevel = "info"
access_log_format = '%(h)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "protheus_exporter"

# Restart workers desabilitado para manter estado das métricas
# Com 1 worker, o restart causaria perda de contadores
max_requests = 0
max_requests_jitter = 0

# Pre-load da aplicação
preload_app = False

# Configurações de segurança
limit_request_line = 4096
limit_request_fields = 100
limit_request_field_size = 8190

print(f"🚀 Configurando Gunicorn:")
print(f"   Workers: {workers}")
print(f"   Threads por worker: {threads}")
print(f"   Worker class: {worker_class}")
print(f"   Bind: {bind}")
print(f"   Timeout: {timeout}s")
print(f"   Graceful Timeout: {graceful_timeout}s")