# Release Process

Este documento descreve o processo de release do **Protheus Prometheus Exporter**.

## Visão Geral

O pipeline de release é automatizado via **GitHub Actions** e publicado em:

| Canal | URL |
|-------|-----|
| **GitHub Releases** | https://github.com/antunesls/protheus_exporter/releases |
| **PyPI** | https://pypi.org/project/protheus-exporter/ |
| **Docker Hub** | https://hub.docker.com/r/antunesls/protheus_exporter |

## Fluxo de Release

### 1. Preparação

Antes de criar uma nova release:

```bash
# Verificar estado do repositório
git status
git log --oneline -10

# Certificar-se de que está na branch main
git checkout main
git pull origin main
```

### 2. Atualizar Versão

```bash
# Editar arquivo VERSION com a nova versão
echo "2.1" > VERSION

# Atualizar CHANGELOG.md com as mudanças da nova versão
# Seguir o formato Keep a Changelog
```

### 3. Commit da Preparação

```bash
git add VERSION CHANGELOG.md
git commit -m "chore: prepare release v2.1"
git push origin main
```

### 4. Criar Tag e Publicar

```bash
# Criar tag (dispara o CI/CD automaticamente)
git tag -a v2.1 -m "Release v2.1 - Descrição breve"

# Push da tag (ativa o GitHub Actions)
git push origin v2.1
```

O GitHub Actions executa automaticamente:

| Job | Descrição | Gatilho |
|-----|-----------|---------|
| **build-package** | Build do pacote Python (sdist + wheel) | Tag v* |
| **publish-pypi** | Publica pacote no PyPI | build-package |
| **github-release** | Cria GitHub Release com changelog | publish-pypi |
| **docker** | Build multi-arch e push Docker Hub | build-package |

### 5. Verificar Publicação

Após o pipeline concluir (5-10 minutos):

```bash
# Verificar GitHub Release
# https://github.com/antunesls/protheus_exporter/releases

# Verificar Docker Hub
# https://hub.docker.com/r/antunesls/protheus_exporter/tags

# Verificar PyPI
# https://pypi.org/project/protheus-exporter/
```

### 6. Testar a Nova Versão

```bash
# Testar Docker
docker pull antunesls/protheus_exporter:2.1
docker run -d -p 8000:8000 antunesls/protheus_exporter:2.1
curl http://localhost:8000/health

# Testar PyPI (opcional)
pip install protheus-exporter==2.1
protheus-exporter
```

## Publicação Manual (workflow_dispatch)

Se precisar publicar sem criar tag:

1. Acesse https://github.com/antunesls/protheus_exporter/actions
2. Selecione o workflow **Release**
3. Clique **Run workflow**
4. Informe a versão (ex: `v2.1`)
5. Confirme

## Pré-requisitos

### Secrets do GitHub (configurados no repositório)

| Secret | Descrição | Obrigatório |
|--------|-----------|-------------|
| `DOCKER_USERNAME` | Usuário do Docker Hub | Sim |
| `DOCKER_TOKEN` | Access Token do Docker Hub (Read & Write) | Sim |
| `PYPI_TOKEN` | API Token do PyPI | Sim |

## Troubleshooting

### Pipeline falhou no Docker push
- Verificar se `DOCKER_USERNAME` e `DOCKER_TOKEN` estão configurados
- Token do Docker Hub pode ter expirado

### Pipeline falhou no PyPI
- Verificar se `PYPI_TOKEN` está configurado
- Verificar se o nome do pacote já existe

### GitHub Release não foi criada
- Verificar permissões do `GITHUB_TOKEN`
- Release notes podem conter caracteres especiais não escapados

## Histórico de Releases

| Versão | Data | Destaques |
|--------|------|-----------|
| v2.0 | 2026-03-02 | Persistência de dados, Serviço Windows, CI/CD, PyPI |
| v0.2 | 2026-02 | Gunicorn, Healthcheck, Dashboard Grafana |
| v0.1 | 2026-01 | Versão inicial |
