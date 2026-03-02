r"""
Protheus Exporter - Windows Service Wrapper

Este módulo permite executar o Protheus Exporter como um serviço Windows nativo.
Usa pywin32 para integração com o Service Control Manager do Windows.

Instalação:
    python protheus_exporter_service.py install

Iniciar:
    python protheus_exporter_service.py start
    
Parar:
    python protheus_exporter_service.py stop
    
Desinstalar:
    python protheus_exporter_service.py remove

Ou use os scripts PowerShell:
    .\install-service.ps1
    .\uninstall-service.ps1
"""

import sys
import os
import time
import socket
import logging
from pathlib import Path

# Adicionar o diretório atual ao path para importar o exporter
sys.path.insert(0, str(Path(__file__).parent))

import win32serviceutil
import win32service
import win32event
import servicemanager

# Configurar logging
LOG_DIR = Path(__file__).parent / "logs"
LOG_DIR.mkdir(exist_ok=True)
LOG_FILE = LOG_DIR / "protheus_exporter_service.log"

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger('ProtheusExporterService')


class ProtheusExporterService(win32serviceutil.ServiceFramework):
    """Serviço Windows para o Protheus Exporter"""
    
    _svc_name_ = "ProtheusExporter"
    _svc_display_name_ = "Protheus Prometheus Exporter"
    _svc_description_ = "Exportador de métricas do Protheus ERP para Prometheus"
    
    def __init__(self, args):
        win32serviceutil.ServiceFramework.__init__(self, args)
        self.stop_event = win32event.CreateEvent(None, 0, 0, None)
        self.is_running = True
        self.server_thread = None
        
        # Carregar configurações
        self.load_config()
        
        logger.info("Serviço ProtheusExporter inicializado")
        
    def load_config(self):
        """Carrega configurações do arquivo ini ou variáveis de ambiente"""
        config_file = Path(__file__).parent / "service-config.ini"
        
        # Valores padrão
        self.host = "0.0.0.0"
        self.port = 8000
        self.workers = 4
        self.environment = "PROD"
        
        # Tentar carregar do arquivo de configuração
        if config_file.exists():
            try:
                import configparser
                config = configparser.ConfigParser()
                config.read(config_file)
                
                if 'service' in config:
                    self.host = config['service'].get('host', self.host)
                    self.port = config['service'].getint('port', self.port)
                    self.workers = config['service'].getint('workers', self.workers)
                    self.environment = config['service'].get('environment', self.environment)
                    
                logger.info(f"Configuração carregada de {config_file}")
            except Exception as e:
                logger.warning(f"Erro ao carregar configuração: {e}. Usando valores padrão.")
        
        # Sobrescrever com variáveis de ambiente se existirem
        self.host = os.environ.get('FLASK_HOST', self.host)
        self.port = int(os.environ.get('FLASK_PORT', self.port))
        self.environment = os.environ.get('PROTHEUS_ENV', self.environment)
        
        logger.info(f"Configuração: host={self.host}, port={self.port}, workers={self.workers}, env={self.environment}")
    
    def SvcStop(self):
        """Chamado quando o serviço é solicitado a parar"""
        logger.info("Requisição de parada recebida")
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        win32event.SetEvent(self.stop_event)
        self.is_running = False
        
    def SvcDoRun(self):
        """Chamado quando o serviço é iniciado"""
        logger.info("Iniciando serviço ProtheusExporter")
        servicemanager.LogMsg(
            servicemanager.EVENTLOG_INFORMATION_TYPE,
            servicemanager.PYS_SERVICE_STARTED,
            (self._svc_name_, '')
        )
        
        try:
            self.main()
        except Exception as e:
            logger.error(f"Erro crítico no serviço: {e}", exc_info=True)
            servicemanager.LogErrorMsg(f"Erro no serviço ProtheusExporter: {str(e)}")
    
    def main(self):
        """Lógica principal do serviço"""
        logger.info(f"Iniciando Protheus Exporter em {self.host}:{self.port}")
        
        # Importar apenas quando necessário para evitar problemas de importação
        try:
            from waitress import serve
            import protheus_exporter
            
            # Definir variável de ambiente
            os.environ['PROTHEUS_ENV'] = self.environment
            
            # Log de inicialização
            logger.info(f"Servidor rodando em http://{self.host}:{self.port}")
            logger.info(f"Ambiente: {self.environment}")
            logger.info(f"Workers: {self.workers}")
            logger.info(f"Healthcheck: http://{self.host}:{self.port}/health")
            logger.info(f"Métricas: http://{self.host}:{self.port}/metrics")
            
            # Iniciar servidor usando waitress (mais adequado para Windows Service)
            serve(
                protheus_exporter.app,
                host=self.host,
                port=self.port,
                threads=self.workers,
                _quiet=False
            )
            
        except ImportError as e:
            logger.error(f"Erro ao importar dependências: {e}")
            logger.error("Certifique-se de que todas as dependências estão instaladas:")
            logger.error("pip install -r requirements-windows.txt")
            raise
        except Exception as e:
            logger.error(f"Erro ao iniciar servidor: {e}", exc_info=True)
            raise
        
        # Aguardar sinal de parada
        while self.is_running:
            rc = win32event.WaitForSingleObject(self.stop_event, 5000)
            if rc == win32event.WAIT_OBJECT_0:
                break
        
        logger.info("Serviço ProtheusExporter parado")
        servicemanager.LogMsg(
            servicemanager.EVENTLOG_INFORMATION_TYPE,
            servicemanager.PYS_SERVICE_STOPPED,
            (self._svc_name_, '')
        )


def main():
    """Ponto de entrada principal"""
    if len(sys.argv) == 1:
        # Executar como serviço
        servicemanager.Initialize()
        servicemanager.PrepareToHostSingle(ProtheusExporterService)
        servicemanager.StartServiceCtrlDispatcher()
    else:
        # Linha de comando (install, start, stop, remove, etc.)
        win32serviceutil.HandleCommandLine(ProtheusExporterService)


if __name__ == '__main__':
    main()
