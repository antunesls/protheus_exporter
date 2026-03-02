from flask import Flask, request, jsonify
from prometheus_client import Counter, Gauge, generate_latest, CONTENT_TYPE_LATEST
import threading
import os
import time
import atexit
from pathlib import Path

# Importar módulo de persistência
try:
    from metrics_persistence import get_persistence
    PERSISTENCE_AVAILABLE = True
except ImportError:
    PERSISTENCE_AVAILABLE = False
    print("⚠️  Módulo de persistência não disponível")

app = Flask(__name__)

# URL de debug: /health
# URL para Protheus enviar eventos: /track
# URL para Prometheus coletar: /metrics

# -------------------------------------------------------------------
# Configurações básicas (pode virar env var)
# -------------------------------------------------------------------
DEFAULT_ENV = os.environ.get("PROTHEUS_ENV", "PROD")

# Configurar persistência
PERSISTENCE_ENABLED = os.environ.get("METRICS_PERSISTENCE", "true").lower() == "true"
DATA_DIR = Path(__file__).parent / "data"

if PERSISTENCE_AVAILABLE and PERSISTENCE_ENABLED:
    persistence = get_persistence(data_dir=str(DATA_DIR), enabled=True)
    persistence.load_from_disk()
    print(f"✅ Persistência de métricas habilitada: {DATA_DIR / 'metrics_data.json'}")
    print(f"   Estatísticas: {persistence.get_stats()}")
else:
    persistence = None
    if PERSISTENCE_ENABLED:
        print("⚠️  Persistência desabilitada (módulo não disponível)")
    else:
        print("ℹ️  Persistência desabilitada por configuração")

# -------------------------------------------------------------------
# Métricas
# -------------------------------------------------------------------

# Métrica agregada por rotina / ambiente / empresa / filial / módulo
ROUTINE_CALLS = Counter(
    "protheus_routine_calls_total",
    "Total de chamadas de rotinas no Protheus (agregado)",
    ["routine", "environment", "company", "branch", "module"],
)

# Métrica por usuário (use com cuidado – cardinalidade!)
ROUTINE_USER_CALLS = Counter(
    "protheus_routine_user_calls_total",
    "Total de chamadas de rotinas no Protheus por usuário",
    ["routine", "environment", "user", "user_name", "company", "branch", "module"],
)

# Métrica de uptime do exporter
EXPORTER_START_TIME = time.time()
EXPORTER_UPTIME = Gauge(
    "protheus_exporter_uptime_seconds",
    "Tempo em segundos desde que o exporter foi iniciado"
)

lock = threading.Lock()


# -------------------------------------------------------------------
# Funções auxiliares para persistência
# -------------------------------------------------------------------
def restore_counter_from_persistence(counter, metric_name):
    """Restaura valores de um contador a partir da persistência"""
    if not persistence:
        return
    
    saved_counters = persistence.get_all_counters(metric_name)
    for label_key, data in saved_counters.items():
        labels = data["labels"]
        value = data["value"]
        
        # Incrementar o contador para o valor salvo
        if value > 0:
            counter.labels(**labels).inc(value)


def save_metrics_to_disk():
    """Salva todas as métricas em disco"""
    if not persistence:
        return
    
    try:
        # Aqui seria ideal iterar sobre todas as métricas e salvá-las
        # Por simplicidade, vamos salvar periodicamente via timer
        persistence.persist_to_disk()
    except Exception as e:
        print(f"Erro ao salvar métricas: {e}")


# Timer para salvar métricas periodicamente (a cada 60 segundos)
def periodic_save():
    """Salva métricas periodicamente em background"""
    if persistence:
        save_metrics_to_disk()
    threading.Timer(60.0, periodic_save).start()


# Registrar salvamento ao encerrar
if persistence:
    atexit.register(save_metrics_to_disk)
    periodic_save()


# -------------------------------------------------------------------
# Healthcheck simples
# -------------------------------------------------------------------
@app.route("/health", methods=["GET"])
def health():
    response = {"status": "ok"}
    
    # Adicionar informações de persistência se habilitada
    if persistence:
        response["persistence"] = persistence.get_stats()
    
    return jsonify(response), 200


# -------------------------------------------------------------------
# Endpoint que o Protheus vai chamar
# -------------------------------------------------------------------
@app.route("/track", methods=["POST"])
def track():
    """
        
        # Salvar na persistência se habilitada
        if persistence:
            # Obter valores atuais dos contadores (simplificado)
            # Em produção, seria melhor manter um contador interno
            persistence.save_counter(
                "protheus_routine_calls_total",
                {
                    "routine": routine,
                    "environment": environment,
                    "company": company,
                    "branch": branch,
                    "module": module,
                },
                1  # Incremento
            )
    Exemplo de JSON esperado do Protheus:

    {
      "routine": "MATA010",
      "environment": "PROD",
      "user": "LUCAS",
      "user_name": "Lucas Silva",
      "company": "01",
      "branch": "0101",
      "module": "FAT"
    }
    """
    data = request.get_json(silent=True) or {}

    routine     = (data.get("routine") or "").strip().upper()
    environment = (data.get("environment") or DEFAULT_ENV).strip().upper()
    user        = (data.get("user") or "UNKNOWN").strip().upper()
    user_name   = (data.get("user_name") or "UNKNOWN").strip()
    company     = (data.get("company") or "00").strip()
    branch      = (data.get("branch") or "0000").strip()
    module      = (data.get("module") or "UNKNOWN").strip().upper()

    if not routine:
        return jsonify({"error": "Campo 'routine' é obrigatório"}), 400

    with lock:
        # Agregado
        ROUTINE_CALLS.labels(
            routine=routine,
            environment=environment,
            company=company,
            branch=branch,
            module=module,
        ).inc()

        # Por usuário
        ROUTINE_USER_CALLS.labels(
            routine=routine,
            environment=environment,
            user=user,
            user_name=user_name,
            company=company,
            branch=branch,
            module=module,
        ).inc()

    return jsonify({"status": "ok"}), 200


# -------------------------------------------------------------------
# Endpoint /metrics para o Prometheus
# -------------------------------------------------------------------
@app.route("/metrics", methods=["GET"])
def metrics():
    # Atualizar uptime antes de gerar métricas
    EXPORTER_UPTIME.set(time.time() - EXPORTER_START_TIME)
    data = generate_latest()
    return data, 200, {"Content-Type": CONTENT_TYPE_LATEST}


if __name__ == "__main__":
    # Configurações do servidor
    host = os.environ.get("FLASK_HOST", "0.0.0.0")
    port = int(os.environ.get("FLASK_PORT", "8000"))
    debug = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
    
    print(f"🚀 Iniciando Protheus Exporter em {host}:{port}")
    print("⚠️  AVISO: Este é o servidor de desenvolvimento do Flask.")
    print("📝 Para produção, use: gunicorn -w 4 -b 0.0.0.0:8000 protheus_exporter:app")
    
    app.run(host=host, port=port, debug=debug)
