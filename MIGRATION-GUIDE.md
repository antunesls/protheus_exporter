# 🔄 Guia de Migração para Dados Persistentes

Este guia ajuda a migrar de volumes Docker (named volumes) para bind mounts locais.

## 📋 Pré-requisitos

- Docker instalado e rodando
- PowerShell (Windows)
- Acesso ao diretório do projeto

## 🚀 Passo a Passo

### 1. Verificar Volumes Antigos

```powershell
# Liste os volumes Docker existentes
docker volume ls | Where-Object { $_ -match "prometheus|grafana" }
```

Se você vê volumes como:
- `docker_prometheus_data`
- `docker_grafana_data`
- `docker_prometheus_config`

Você tem dados antigos que podem ser migrados.

### 2. Parar os Containers

```powershell
cd deployments\docker
docker-compose down
```

### 3. Criar Estrutura de Diretórios

```powershell
# Voltar para a raiz do projeto
cd ..\..

# Criar diretórios (já devem existir se você puxou as alterações)
New-Item -ItemType Directory -Path "data\prometheus" -Force
New-Item -ItemType Directory -Path "data\grafana" -Force
```

### 4. Migrar Dados do Prometheus

```powershell
# Migrar dados do volume Docker para o diretório local
docker run --rm `
  -v docker_prometheus_data:/source `
  -v ${PWD}\data\prometheus:/dest `
  busybox sh -c "cp -r /source/* /dest/"

# Verificar se os dados foram copiados
Get-ChildItem "data\prometheus" -Recurse | Measure-Object -Property Length -Sum
```

### 5. Migrar Dados do Grafana

```powershell
# Migrar dados do Grafana
docker run --rm `
  -v docker_grafana_data:/source `
  -v ${PWD}\data\grafana:/dest `
  busybox sh -c "cp -r /source/* /dest/"

# Verificar se os dados foram copiados
Get-ChildItem "data\grafana" -Recurse | Measure-Object -Property Length -Sum
```

### 6. Iniciar com Nova Configuração

```powershell
cd deployments\docker
docker-compose up -d
```

### 7. Verificar Persistência

```powershell
# Voltar para raiz do projeto
cd ..\..

# Executar script de verificação
.\check-persistence.ps1
```

Você deve ver:
- ✅ Prometheus e Grafana acessíveis
- ✅ Métricas antigas preservadas
- ✅ Dashboards mantidos

### 8. Limpar Volumes Antigos (Opcional)

⚠️ **CUIDADO**: Só faça isso após confirmar que tudo está funcionando!

```powershell
# Listar volumes para confirmar
docker volume ls

# Remover volumes antigos SOMENTE após confirmar migração bem-sucedida
docker volume rm docker_prometheus_data docker_grafana_data docker_prometheus_config
```

## 🔍 Verificações Importantes

### Verificar Métricas no Prometheus

1. Acesse http://localhost:9090
2. Execute uma query: `protheus_routine_calls_total`
3. Verifique se há dados históricos

### Verificar Dashboards no Grafana

1. Acesse http://localhost:3000
2. Login: `admin` / `admin123`
3. Verifique se os dashboards estão presentes
4. Confirme se os dados aparecem nos gráficos

## 🆘 Solução de Problemas

### Problema: Permissões Negadas

**Solução (Windows):**
```powershell
# Dar permissões totais ao diretório data
icacls "data" /grant "${env:USERNAME}:(OI)(CI)F" /T
```

**Solução (Linux):**
```bash
# Ajustar proprietário (usuário 65534 = nobody, usado pelo Prometheus)
sudo chown -R 65534:65534 data/prometheus
sudo chown -R 472:472 data/grafana  # UID do Grafana
```

### Problema: Containers Não Iniciam

```powershell
# Ver logs dos containers
docker-compose logs prometheus
docker-compose logs grafana

# Recriar containers
docker-compose down -v
docker-compose up -d
```

### Problema: Dados Não Aparecem

```powershell
# Verificar se os diretórios estão montados corretamente
docker inspect protheus_exporter_prometheus_1 | Select-String "Mounts" -Context 20

# Verificar conteúdo dentro do container
docker exec -it protheus_exporter_prometheus_1 ls -la /prometheus
docker exec -it protheus_exporter_grafana_1 ls -la /var/lib/grafana
```

### Problema: Volumes Antigos Ainda Existem

Volumes antigos não afetam o funcionamento, mas ocupam espaço:

```powershell
# Ver tamanho dos volumes
docker system df -v | Select-String "VOLUME NAME|prometheus|grafana" -Context 1

# Remover apenas após confirmar que tudo funciona
docker volume rm $(docker volume ls -q | Where-Object { $_ -match "prometheus|grafana" })
```

## 📦 Backup Antes da Migração

Recomendado fazer backup antes de migrar:

```powershell
# Backup dos volumes Docker antigos
docker run --rm `
  -v docker_prometheus_data:/data `
  -v ${PWD}\backups:/backup `
  busybox tar czf /backup/prometheus_old_volume_backup.tar.gz -C /data .

docker run --rm `
  -v docker_grafana_data:/data `
  -v ${PWD}\backups:/backup `
  busybox tar czf /backup/grafana_old_volume_backup.tar.gz -C /data .
```

## ✅ Checklist Final

- [ ] Volumes antigos identificados
- [ ] Containers parados
- [ ] Diretórios criados
- [ ] Dados do Prometheus migrados
- [ ] Dados do Grafana migrados
- [ ] Containers reiniciados com sucesso
- [ ] Prometheus acessível (http://localhost:9090)
- [ ] Grafana acessível (http://localhost:3000)
- [ ] Métricas históricas preservadas
- [ ] Dashboards funcionando
- [ ] Script check-persistence.ps1 executado
- [ ] Backup criado (opcional mas recomendado)
- [ ] Volumes antigos removidos (após confirmação)

## 🎉 Migração Concluída!

Agora seus dados estão persistidos em arquivos locais e não serão perdidos em reinicializações.

**Próximos passos:**
1. Configure backups automáticos (veja [DATA-PERSISTENCE.md](DATA-PERSISTENCE.md))
2. Monitore o espaço em disco usado por `data/`
3. Ajuste a retenção de dados conforme necessário

---

**Dúvidas?** Consulte [DATA-PERSISTENCE.md](DATA-PERSISTENCE.md) para mais informações.
