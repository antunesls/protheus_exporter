from flask import Flask, request, jsonify
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
import threading
import os

app = Flask(__name__)

# URL de debug: /health
# URL para Protheus enviar eventos: /track
# URL para Prometheus coletar: /metrics

# -------------------------------------------------------------------
# Configurações básicas (pode virar env var)
# -------------------------------------------------------------------
DEFAULT_ENV = os.environ.get("PROTHEUS_ENV", "PROD")

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
    ["routine", "environment", "user", "company", "branch", "module"],
)

lock = threading.Lock()


# -------------------------------------------------------------------
# Healthcheck simples
# -------------------------------------------------------------------
@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


# -------------------------------------------------------------------
# Endpoint que o Protheus vai chamar
# -------------------------------------------------------------------
@app.route("/track", methods=["POST"])
def track():
    """
    Exemplo de JSON esperado do Protheus:

    {
      "routine": "MATA010",
      "environment": "PROD",
      "user": "LUCAS",
      "company": "01",
      "branch": "0101",
      "module": "FAT"
    }
    """
    data = request.get_json(silent=True) or {}

    routine     = (data.get("routine") or "").strip().upper()
    environment = (data.get("environment") or DEFAULT_ENV).strip().upper()
    user        = (data.get("user") or "UNKNOWN").strip().upper()
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
    data = generate_latest()
    return data, 200, {"Content-Type": CONTENT_TYPE_LATEST}


if __name__ == "__main__":
    # Pode ler host/port de env var também se quiser
    app.run(host="0.0.0.0", port=8000)
