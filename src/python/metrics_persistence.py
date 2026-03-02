"""
Módulo de persistência para métricas do Protheus Exporter

Este módulo permite salvar e restaurar contadores de métricas
entre reinicializações do serviço.
"""

import json
import logging
from pathlib import Path
from typing import Dict, Any
import threading

logger = logging.getLogger(__name__)


class MetricsPersistence:
    """Gerencia persistência de métricas em arquivo JSON"""
    
    def __init__(self, data_file: str = "metrics_data.json", enabled: bool = True):
        """
        Inicializa o gerenciador de persistência
        
        Args:
            data_file: Caminho do arquivo JSON para armazenar métricas
            enabled: Se True, habilita persistência automática
        """
        self.enabled = enabled
        self.data_file = Path(data_file)
        self.lock = threading.Lock()
        self.metrics_cache: Dict[str, Dict[str, Any]] = {}
        
        if self.enabled:
            self._ensure_data_dir()
            logger.info(f"Persistência de métricas habilitada: {self.data_file}")
        else:
            logger.info("Persistência de métricas desabilitada")
    
    def _ensure_data_dir(self):
        """Garante que o diretório de dados existe"""
        self.data_file.parent.mkdir(parents=True, exist_ok=True)
    
    def save_counter(self, metric_name: str, labels: Dict[str, str], value: float):
        """
        Salva o valor de um contador
        
        Args:
            metric_name: Nome da métrica
            labels: Dicionário com labels da métrica
            value: Valor atual do contador
        """
        if not self.enabled:
            return
        
        with self.lock:
            if metric_name not in self.metrics_cache:
                self.metrics_cache[metric_name] = {}
            
            # Criar chave única baseada nas labels
            label_key = self._labels_to_key(labels)
            
            if label_key not in self.metrics_cache[metric_name]:
                self.metrics_cache[metric_name][label_key] = {
                    "labels": labels,
                    "value": 0
                }
            
            self.metrics_cache[metric_name][label_key]["value"] = value
    
    def get_counter_value(self, metric_name: str, labels: Dict[str, str]) -> float:
        """
        Obtém o valor salvo de um contador
        
        Args:
            metric_name: Nome da métrica
            labels: Dicionário com labels da métrica
            
        Returns:
            Valor do contador ou 0 se não existir
        """
        if not self.enabled:
            return 0
        
        with self.lock:
            if metric_name not in self.metrics_cache:
                return 0
            
            label_key = self._labels_to_key(labels)
            
            if label_key not in self.metrics_cache[metric_name]:
                return 0
            
            return self.metrics_cache[metric_name][label_key]["value"]
    
    def _labels_to_key(self, labels: Dict[str, str]) -> str:
        """Converte dicionário de labels em string única"""
        sorted_items = sorted(labels.items())
        return json.dumps(sorted_items, sort_keys=True)
    
    def persist_to_disk(self):
        """Salva todas as métricas em cache para o disco"""
        if not self.enabled:
            return
        
        try:
            with self.lock:
                with open(self.data_file, 'w', encoding='utf-8') as f:
                    json.dump(self.metrics_cache, f, indent=2, ensure_ascii=False)
                logger.info(f"Métricas salvas em {self.data_file}")
        except Exception as e:
            logger.error(f"Erro ao salvar métricas: {e}")
    
    def load_from_disk(self):
        """Carrega métricas salvas do disco"""
        if not self.enabled:
            return
        
        if not self.data_file.exists():
            logger.info("Arquivo de métricas não encontrado, iniciando do zero")
            return
        
        try:
            with self.lock:
                with open(self.data_file, 'r', encoding='utf-8') as f:
                    self.metrics_cache = json.load(f)
                
                total_metrics = sum(len(labels) for labels in self.metrics_cache.values())
                logger.info(f"Métricas carregadas de {self.data_file}: {total_metrics} séries")
        except Exception as e:
            logger.error(f"Erro ao carregar métricas: {e}")
            self.metrics_cache = {}
    
    def get_all_counters(self, metric_name: str) -> Dict[str, Any]:
        """
        Retorna todos os contadores de uma métrica
        
        Args:
            metric_name: Nome da métrica
            
        Returns:
            Dicionário com todos os valores da métrica
        """
        if not self.enabled:
            return {}
        
        with self.lock:
            return self.metrics_cache.get(metric_name, {}).copy()
    
    def clear(self):
        """Limpa todas as métricas em cache"""
        with self.lock:
            self.metrics_cache = {}
        logger.info("Cache de métricas limpo")
    
    def get_stats(self) -> Dict[str, Any]:
        """Retorna estatísticas sobre as métricas armazenadas"""
        with self.lock:
            stats = {
                "enabled": self.enabled,
                "data_file": str(self.data_file),
                "metrics_count": len(self.metrics_cache),
                "total_series": sum(len(labels) for labels in self.metrics_cache.values())
            }
            
            if self.data_file.exists():
                stats["file_size_bytes"] = self.data_file.stat().st_size
            
            return stats


# Singleton global
_persistence_instance = None


def get_persistence(data_dir: str = None, enabled: bool = None) -> MetricsPersistence:
    """
    Obtém a instância singleton de MetricsPersistence
    
    Args:
        data_dir: Diretório para armazenar dados (usado apenas na primeira chamada)
        enabled: Habilitar/desabilitar persistência (usado apenas na primeira chamada)
    
    Returns:
        Instância de MetricsPersistence
    """
    global _persistence_instance
    
    if _persistence_instance is None:
        if data_dir is None:
            data_dir = Path(__file__).parent / "data"
        else:
            data_dir = Path(data_dir)
        
        if enabled is None:
            import os
            enabled = os.environ.get("METRICS_PERSISTENCE", "true").lower() == "true"
        
        data_file = data_dir / "metrics_data.json"
        _persistence_instance = MetricsPersistence(str(data_file), enabled=enabled)
    
    return _persistence_instance
