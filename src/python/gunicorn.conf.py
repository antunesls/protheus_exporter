# Configuração do Gunicorn para produção
# Arquivo: gunicorn.conf.py

import os

# Configurações básicas
bind = f"0.0.0.0:{os.environ.get('PORT', '8000')}"
workers = int(os.environ.get('WORKERS', '2'))
worker_class = "sync"
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

# Restart workers depois de N requests (previne memory leaks)
max_requests = 1000
max_requests_jitter = 50

# Pre-load da aplicação
preload_app = True

# Configurações de segurança
limit_request_line = 4096
limit_request_fields = 100
limit_request_field_size = 8190

print(f"🚀 Configurando Gunicorn:")
print(f"   Workers: {workers}")
print(f"   Bind: {bind}")
print(f"   Timeout: {timeout}s")
print(f"   Graceful Timeout: {graceful_timeout}s")