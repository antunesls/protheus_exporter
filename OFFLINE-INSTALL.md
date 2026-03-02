# Instalação Offline - Protheus Exporter

Este guia explica como instalar o Protheus Exporter em ambientes sem conexão com a internet.

## 📋 Pré-requisitos

- Python 3.8 ou superior instalado
- Windows com privilégios de Administrador

## 🔄 Processo em 2 Etapas

### Etapa 1: Baixar Dependências (Máquina com Internet)

Em uma máquina **com acesso à internet**:

```powershell
# Baixar todos os pacotes necessários
.\download-dependencies.ps1
```

Isso criará uma pasta `python-packages` com todos os arquivos `.whl` necessários.

**Arquivos gerados:**
- `python-packages/` - Pasta com todos os pacotes Python (.whl)

### Etapa 2: Copiar e Instalar (Máquina Offline)

1. **Copie** os seguintes itens para a máquina offline:
   - Pasta completa do projeto `protheus_exporter`
   - A pasta `python-packages` com todos os arquivos baixados

2. **Instale o serviço** na máquina offline:

```powershell
# Executar como Administrador
.\install-service.ps1 -Offline
```

## 📝 Opções do Script de Download

```powershell
# Sintaxe completa
.\download-dependencies.ps1 [-PythonPath <caminho>] [-OutputDir <diretório>]

# Exemplos:
.\download-dependencies.ps1
.\download-dependencies.ps1 -OutputDir "C:\temp\packages"
.\download-dependencies.ps1 -PythonPath "C:\Python311\python.exe"
```

**Parâmetros:**
- `-PythonPath`: Caminho customizado do Python (opcional)
- `-OutputDir`: Diretório de saída para os pacotes (padrão: `.\python-packages`)

## 📝 Opções do Script de Instalação Offline

```powershell
# Sintaxe completa
.\install-service.ps1 -Offline [-PackagesDir <diretório>] [-AutoStart]

# Exemplos:
.\install-service.ps1 -Offline
.\install-service.ps1 -Offline -AutoStart
.\install-service.ps1 -Offline -PackagesDir "C:\temp\packages"
```

**Parâmetros:**
- `-Offline`: Ativa o modo de instalação offline (obrigatório)
- `-PackagesDir`: Diretório onde estão os pacotes (padrão: `.\python-packages`)
- `-AutoStart`: Configura inicialização automática do serviço
- `-PythonPath`: Caminho customizado do Python (opcional)

## 🔍 Verificação dos Pacotes

Para ver quais pacotes foram baixados:

```powershell
Get-ChildItem .\python-packages\*.whl | Select-Object Name, Length
```

## 📦 Pacotes Incluídos

Os seguintes pacotes serão baixados (com suas dependências):
- Flask 3.0.0
- prometheus-client 0.19.0
- pywin32 311
- waitress 3.0.0
- colorlog 6.8.0

## ⚠️ Troubleshooting

### Erro: "Diretório de pacotes não encontrado"

Se receber este erro durante a instalação offline:

```
❌ Diretório de pacotes não encontrado: .\python-packages
```

**Solução:** Certifique-se de que:
1. A pasta `python-packages` está no mesmo diretório do script
2. Ou especifique o caminho: `.\install-service.ps1 -Offline -PackagesDir "C:\caminho\completo\python-packages"`

### Arquitetura Incompatível

Os pacotes `.whl` dependem da arquitetura (32-bit vs 64-bit) e versão do Python.

**Certifique-se de:**
- Usar a mesma versão do Python nas duas máquinas
- Usar a mesma arquitetura (x86 ou x64)

Para verificar:
```powershell
python --version
python -c "import platform; print(platform.architecture())"
```

### Instalação Manual (se necessário)

Se preferir instalar manualmente:

```powershell
# Navegar até a pasta do projeto
cd C:\caminho\protheus_exporter

# Instalar dependências do cache local
python -m pip install --no-index --find-links=.\python-packages -r .\src\python\requirements-windows.txt

# Instalar o serviço
python .\src\python\protheus_exporter_service.py install

# Iniciar o serviço
Start-Service ProtheusExporter
```

## 🌐 Instalação Online (para comparação)

Para ambientes **com internet**, use o método padrão:

```powershell
.\install-service.ps1
```

## 📚 Recursos Adicionais

- [WINDOWS-SERVICE.md](WINDOWS-SERVICE.md) - Documentação completa do serviço Windows
- [README.md](README.md) - Documentação geral do projeto

## 💡 Dicas

1. **Mantenha os pacotes atualizados**: Execute `.\download-dependencies.ps1` periodicamente para ter os pacotes mais recentes
2. **Backup**: Mantenha uma cópia da pasta `python-packages` para reinstalações futuras
3. **Transferência**: Use ferramentas como zip para facilitar a transferência dos arquivos
