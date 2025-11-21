#!/bin/bash
# Script de inicialização do Protheus Exporter
# Uso: ./start.sh [dev|prod]

MODE=${1:-prod}
HOST=${FLASK_HOST:-0.0.0.0}
PORT=${FLASK_PORT:-8000}
WORKERS=${WORKERS:-4}

echo "🚀 Iniciando Protheus Exporter..."
echo "📦 Modo: $MODE"
echo "🌐 Host: $HOST:$PORT"

cd "$(dirname "$0")/src/python"

case $MODE in
    "dev"|"development")
        echo "⚠️  Modo de desenvolvimento (não use em produção!)"
        echo "🔧 Executando com Flask dev server..."
        export FLASK_DEBUG=true
        python protheus_exporter.py
        ;;
    "prod"|"production")
        echo "🏭 Modo de produção"
        echo "👷 Workers: $WORKERS"
        echo "🔧 Executando com Gunicorn..."
        gunicorn -c gunicorn.conf.py protheus_exporter:app
        ;;
    *)
        echo "❌ Modo inválido: $MODE"
        echo "💡 Use: $0 [dev|prod]"
        exit 1
        ;;
esac