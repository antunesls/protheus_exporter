# 📊 Dashboard Grafana - Protheus Metrics

Este dashboard fornece uma visão abrangente das métricas do Protheus, permitindo análise detalhada do uso do sistema.

## 🚀 Instalação Rápida

### Método 1: Docker Compose (Automático)
```bash
docker-compose -f docker/docker-compose-hub.yml up -d
```
Acesse: http://localhost:3000 (admin/admin123)

### Método 2: Importação Manual
1. Faça login no Grafana
2. Vá em **Dashboards → Import**
3. Cole o conteúdo de [`grafana-dashboard-protheus-metrics.json`](../grafana-dashboard-protheus-metrics.json)
4. Configure o datasource do Prometheus

## 📈 Visualizações

### 🎯 **Métricas de Visão Geral**
- **Execuções/min:** Taxa de execução em tempo real
- **Total de Rotinas:** Número de rotinas únicas no sistema
- **Usuários Ativos:** Quantidade de usuários únicos
- **Total Execuções:** Contador total acumulado

### 🏆 **Rankings Top 5**

#### Rotinas
- **Mais Usadas:** Identifica rotinas com maior volume
- **Menos Usadas:** Detecta funcionalidades subutilizadas

#### Usuários
- **Mais Ativos:** Usuários com maior atividade
- **Menos Ativos:** Usuários com baixa utilização

### 📊 **Análises Distribucionais**

#### Por Organização
- **Empresas:** Pizza chart com distribuição por empresa
- **Filiais:** Visualização por filial/unidade

#### Por Módulo
- **Pizza Chart:** Distribuição visual por módulo
- **Tabela Detalhada:** Números exatos por módulo

#### Por Ambiente
- **Bar Chart:** Comparação entre produção, homologação, desenvolvimento

### 📈 **Análise Temporal**
- **Taxa de Execução:** Gráfico de linhas mostrando evolução temporal
- **Tendências:** Identificação de padrões de uso

## 🎛️ Filtros Dinâmicos

O dashboard inclui três filtros no topo:

### 🌍 **Ambiente**
- Produção
- Homologação  
- Desenvolvimento
- Treinamento
- Teste

### 🏢 **Empresa**
- Filtro dinâmico baseado nos dados coletados
- Múltipla seleção permitida

### 🔧 **Módulo**
- SIGAFIN (Financeiro)
- SIGAEST (Estoque)
- SIGAFAT (Faturamento)
- SIGACOM (Compras)
- SIGAGPE (Gestão Pessoal)
- E outros módulos Protheus

## 📊 Casos de Uso

### 1. **Monitoramento de Performance**
```
Objetivo: Identificar gargalos de performance
Métricas: Execuções/min, Top rotinas mais usadas
Ação: Otimizar rotinas com alto volume
```

### 2. **Análise de Adoção de Funcionalidades**
```
Objetivo: Verificar uso de novas funcionalidades
Métricas: Rotinas menos usadas, distribuição por módulo
Ação: Treinamento ou descontinuação de features
```

### 3. **Gestão de Licenças**
```
Objetivo: Otimizar número de licenças
Métricas: Usuários ativos, distribuição por empresa
Ação: Realocação ou aquisição de licenças
```

### 4. **Planejamento de Capacidade**
```
Objetivo: Planejar recursos de infraestrutura
Métricas: Análise temporal, picos de uso
Ação: Dimensionamento de hardware/cloud
```

### 5. **Auditoria e Compliance**
```
Objetivo: Rastrear uso do sistema
Métricas: Todas as visualizações por período
Ação: Relatórios de compliance e auditoria
```

## ⚙️ Configurações Técnicas

### Refresh
- **Automático:** 30 segundos
- **Manual:** Disponível via botão refresh
- **Tempo padrão:** Última 1 hora

### Personalização
- **Período:** Ajustável no seletor de tempo
- **Zoom:** Clique e arraste nos gráficos
- **Drill-down:** Clique em elementos para filtrar

### Performance
- **Queries otimizadas:** TopK e BottomK para eficiência
- **Cache:** 30 segundos para reduzir carga no Prometheus
- **Agregações:** Pré-calculadas no Prometheus

## 🔧 Troubleshooting

### Dashboard em branco
```bash
# Verificar se o Prometheus está coletando métricas
curl http://localhost:9090/api/v1/query?query=protheus_routine_user_calls_total

# Verificar datasource no Grafana
# Configuration → Data Sources → Prometheus
```

### Dados não atualizando
```bash
# Verificar se o exporter está funcionando
curl http://localhost:8000/metrics

# Verificar configuração do Prometheus
docker-compose logs prometheus
```

### Filtros não funcionando
- Verifique se as labels estão sendo enviadas pelo exporter
- Confirme que os dados têm as dimensões esperadas
- Teste queries diretamente no Prometheus

## 📝 Customização

### Adicionando novos painéis
1. Edite o arquivo JSON do dashboard
2. Adicione novo painel na seção `"panels"`
3. Configure query Prometheus apropriada
4. Reimporte o dashboard

### Modificando queries
```promql
# Exemplo: Top 10 ao invés de Top 5
topk(10, sum by (routine) (protheus_routine_user_calls_total))

# Exemplo: Filtrar apenas produção
topk(5, sum by (routine) (protheus_routine_user_calls_total{environment="PROD"}))
```

## 📚 Referências

- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Query Language](https://prometheus.io/docs/prometheus/latest/querying/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/best-practices/)