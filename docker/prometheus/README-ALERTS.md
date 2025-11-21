# 🚨 Alertas Prometheus - Protheus Exporter

Este arquivo contém as regras de alerta configuradas para monitoramento do Protheus.

## 📋 Alertas Configurados

### 🔥 **HighExecutionRate**
- **Condição:** `rate(protheus_routine_user_calls_total[5m]) * 60 > 100`
- **Gatilho:** 2 minutos
- **Severidade:** Warning
- **Descrição:** Dispara quando uma rotina executa mais de 100 vezes por minuto

**Ações recomendadas:**
- Verificar se a rotina está em loop
- Analisar performance da rotina
- Verificar se há problema na aplicação

### 💤 **RoutineNotExecuted**
- **Condição:** `time() - protheus_routine_user_calls_total > 3600`
- **Gatilho:** 5 minutos
- **Severidade:** Info
- **Descrição:** Rotina não executada há mais de 1 hora

**Ações recomendadas:**
- Verificar se a funcionalidade está sendo usada
- Considerar descontinuação se não for crítica
- Verificar se há problemas de acesso

### 👤 **VeryActiveUser**
- **Condição:** `rate(protheus_routine_user_calls_total[1h]) * 3600 > 1000`
- **Gatilho:** 5 minutos
- **Severidade:** Info
- **Descrição:** Usuário executou mais de 1000 rotinas na última hora

**Ações recomendadas:**
- Verificar se é comportamento normal
- Verificar possível automação/script
- Analisar padrão de uso

### 💀 **ExporterDown**
- **Condição:** `up{job="protheus-exporter"} == 0`
- **Gatilho:** 1 minuto
- **Severidade:** Critical
- **Descrição:** Protheus Exporter não está respondendo

**Ações recomendadas:**
- Verificar se o container está rodando
- Verificar logs do exporter
- Reiniciar o serviço se necessário

## ⚙️ Configuração

### Habilitando Alertmanager
Para receber notificações, configure o Alertmanager:

```yaml
# docker-compose.yml
alertmanager:
  image: prom/alertmanager:latest
  ports:
    - "9093:9093"
  volumes:
    - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
```

### Exemplo de configuração Alertmanager:
```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'seu-email@gmail.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'email-alerts'

receivers:
- name: 'email-alerts'
  email_configs:
  - to: 'admin@empresa.com'
    subject: 'Alerta Protheus: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alerta: {{ .Annotations.summary }}
      Descrição: {{ .Annotations.description }}
      {{ end }}
```

## 🔧 Customização

### Adicionando novos alertas

Edite o arquivo `alert_rules.yml`:

```yaml
groups:
  - name: protheus.rules
    rules:
      # Novo alerta personalizado
      - alert: CustomAlert
        expr: sua_query_prometheus_aqui
        for: tempo_de_espera
        labels:
          severity: warning|critical|info
        annotations:
          summary: "Resumo do alerta"
          description: "Descrição detalhada"
```

### Exemplos de alertas úteis:

```yaml
# Alerta para empresa específica com alta atividade
- alert: HighCompanyActivity
  expr: rate(protheus_routine_user_calls_total{company="01"}[5m]) * 60 > 50
  for: 3m

# Alerta para módulo específico
- alert: FinanceModuleDown
  expr: absent(protheus_routine_user_calls_total{module="SIGAFIN"})
  for: 10m

# Alerta para ambiente de produção
- alert: ProductionIssue
  expr: rate(protheus_routine_user_calls_total{environment="PROD"}[10m]) == 0
  for: 5m
```

## 📊 Testando Alertas

### Via Prometheus Web UI:
1. Acesse http://localhost:9090
2. Vá em **Alerts**
3. Verifique se as regras estão carregadas
4. Monitore o status (Inactive/Pending/Firing)

### Via linha de comando:
```bash
# Verificar se as regras estão válidas
docker-compose exec prometheus promtool check rules /etc/prometheus/alert_rules.yml

# Recarregar configuração sem restart
curl -X POST http://localhost:9090/-/reload
```

## 🎯 Boas Práticas

1. **Defina severidades apropriadas:**
   - `critical`: Requer ação imediata
   - `warning`: Requer atenção
   - `info`: Informativo apenas

2. **Use períodos de espera adequados:**
   - Evite alertas em picos momentâneos
   - Balance entre velocidade e precisão

3. **Inclua contexto útil:**
   - Labels relevantes (empresa, módulo, usuário)
   - Descrições claras e acionáveis

4. **Teste regularmente:**
   - Simule condições de alerta
   - Verifique se as notificações chegam
   - Ajuste thresholds conforme necessário