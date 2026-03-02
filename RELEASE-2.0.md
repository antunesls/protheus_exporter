# Publicação da Versão 2.0 no Docker Hub

## 📋 Alterações da Versão 2.0

✅ **Versão atualizada para 2.0** nos arquivos:
- `VERSION` (novo arquivo)
- `README.md`
- `docker-compose-hub.yml`
- `CHANGELOG.md` (novo arquivo)

✅ **Persistência de dados** implementada em ambos os docker-compose:
- `docker-compose.yml` - Build local
- `docker-compose-hub.yml` - Imagem do Docker Hub

✅ **Documentação criada/atualizada**:
- `DATA-PERSISTENCE.md` - Guia completo
- `MIGRATION-GUIDE.md` - Como migrar
- `CHANGELOG.md` - Histórico de versões

## 🚀 Publicar no Docker Hub

### Opção 1: Usar o Script Automatizado (Recomendado)

```powershell
.\publish-docker.ps1
```

O script irá:
1. ✅ Verificar se o Docker está rodando
2. ✅ Fazer build da imagem com tags `2.0` e `latest`
3. ✅ Verificar login no Docker Hub
4. ✅ Fazer push das imagens
5. ✅ Mostrar resumo e instruções de uso

### Opção 2: Comandos Manuais

```powershell
# 1. Fazer build da imagem
cd c:\Users\antunesls\projetos\protheus_exporter
docker build -t antunesls/protheus_exporter:2.0 -t antunesls/protheus_exporter:latest -f deployments/docker/Dockerfile .

# 2. Login no Docker Hub (se necessário)
docker login

# 3. Fazer push das imagens
docker push antunesls/protheus_exporter:2.0
docker push antunesls/protheus_exporter:latest

# 4. Verificar publicação
docker pull antunesls/protheus_exporter:2.0
```

### Opção 3: PowerShell Inline

```powershell
# Comando único (copie e cole)
docker build -t antunesls/protheus_exporter:2.0 -t antunesls/protheus_exporter:latest -f deployments/docker/Dockerfile .; docker push antunesls/protheus_exporter:2.0; docker push antunesls/protheus_exporter:latest
```

## 🧪 Testar a Nova Versão

```powershell
# Pull da nova versão
docker pull antunesls/protheus_exporter:2.0

# Rodar container de teste
docker run -d -p 8000:8000 --name protheus-exporter-test antunesls/protheus_exporter:2.0

# Verificar se está rodando
curl http://localhost:8000/health

# Ver logs
docker logs protheus-exporter-test

# Limpar teste
docker stop protheus-exporter-test
docker rm protheus-exporter-test
```

## 📦 Usar a Stack Completa

```powershell
cd deployments\docker

# Parar versão antiga (se estiver rodando)
docker-compose -f docker-compose-hub.yml down

# Iniciar versão 2.0
docker-compose -f docker-compose-hub.yml up -d

# Verificar serviços
docker-compose -f docker-compose-hub.yml ps

# Ver logs
docker-compose -f docker-compose-hub.yml logs -f protheus-exporter
```

## 🏷️ Tags Disponíveis

Após a publicação, estas tags estarão disponíveis no Docker Hub:

- `antunesls/protheus_exporter:2.0` - Versão específica 2.0
- `antunesls/protheus_exporter:latest` - Sempre aponta para a versão mais recente
- `antunesls/protheus_exporter:0.2` - Versão anterior (ainda disponível)

## 📝 Verificar no Docker Hub

Após publicar, acesse:
- https://hub.docker.com/r/antunesls/protheus_exporter/tags

Você deve ver:
- Tag `2.0` com data de hoje
- Tag `latest` atualizada para hoje

## 🔍 Troubleshooting

### Erro: "docker: command not found"
**Solução:** Certifique-se que o Docker Desktop está:
1. Instalado
2. Iniciado
3. Disponível no PATH

```powershell
# Adicionar Docker ao PATH (temporário)
$env:Path += ";C:\Program Files\Docker\Docker\resources\bin"
```

### Erro: "denied: requested access to the resource is denied"
**Solução:** Faça login no Docker Hub:
```powershell
docker login
```

### Erro: "no space left on device"
**Solução:** Limpe imagens antigas:
```powershell
docker system prune -a
```

### Build muito lento
**Solução:** Verifique se o WSL2 está configurado corretamente (Windows):
```powershell
wsl --set-default-version 2
```

## 📊 Estatísticas Esperadas

Após build:
- **Tamanho da imagem**: ~200-300 MB
- **Layers**: ~10-15 layers
- **Tempo de build**: 2-5 minutos (primeira vez), 10-30s (rebuild)
- **Tempo de push**: 1-3 minutos (depende da conexão)

## ✅ Checklist de Publicação

- [x] Versão atualizada nos arquivos
- [x] CHANGELOG.md criado
- [x] Persistência implementada
- [x] Documentação atualizada
- [ ] Docker build executado com sucesso
- [ ] Login no Docker Hub confirmado
- [ ] Push da tag 2.0 concluído
- [ ] Push da tag latest concluído
- [ ] Imagem testada (pull + run)
- [ ] Verificado no Docker Hub (web)
- [ ] Stack completa testada
- [ ] Persistência testada após restart

## 🎉 Pós-Publicação

Após publicar com sucesso:

1. **Tag Git** (opcional mas recomendado):
```powershell
git tag -a v2.0.0 -m "Release 2.0.0 - Persistência de dados"
git push origin v2.0.0
```

2. **Atualizar README** do Docker Hub:
   - Acesse https://hub.docker.com/r/antunesls/protheus_exporter
   - Edite a descrição
   - Adicione informações sobre a versão 2.0

3. **Comunicar aos usuários**:
   - Criar release notes
   - Notificar sobre breaking changes (se houver)
   - Documentar processo de migração

---

**Data de preparação**: 02/03/2026  
**Versão**: 2.0.0  
**Status**: Pronto para publicação ✅
