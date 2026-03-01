# 🏗️ Como Funciona

Este documento explica a arquitetura do instalador e como ele interage com o OpenClaw oficial.

## 📋 Índice
- [Visão Geral](#visão-geral)
- [Fluxo de Instalação](#fluxo-de-instalação)
- [Estrutura de Diretórios](#estrutura-de-diretórios)
- [O que o Instalador Faz](#o-que-o-instalador-faz)
- [O que o OpenClaw Oficial Faz](#o-que-o-openclaw-oficial-faz)

---

## 🎯 Visão Geral

Este é um **wrapper** (envoltório) simplificado que prepara o ambiente e depois executa o instalador oficial do OpenClaw.

```
┌──────────────────────────────────────────────────────┐
│           setup-openclaw (Este Repositório)          │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │  install.sh (Nosso Wrapper)                │    │
│  │  ────────────────────────────────────────  │    │
│  │  1. Verifica/instala Docker                │    │
│  │  2. Cria diretórios (~/.openclaw)          │    │
│  │  3. Gera token seguro (.env)               │    │
│  │  4. Clona OpenClaw oficial                 │    │
│  │  5. Executa: bash docker-setup.sh ─────────┼────┼──┐
│  └────────────────────────────────────────────┘    │  │
└──────────────────────────────────────────────────────┘  │
                                                          │
                           ┌──────────────────────────────▼───────┐
                           │  OpenClaw Oficial                    │
                           │  github.com/OpenClaw/openclaw        │
                           │                                      │
                           │  ┌────────────────────────────────┐ │
                           │  │  docker-setup.sh (Oficial)     │ │
                           │  │  ────────────────────────────  │ │
                           │  │  1. Build da imagem Docker     │ │
                           │  │  2. Wizard de configuração     │ │
                           │  │  3. OAuth com OpenAI           │ │
                           │  │  4. Inicia containers          │ │
                           │  └────────────────────────────────┘ │
                           └──────────────────────────────────────┘
```

---

## 🔄 Fluxo de Instalação

### Etapa 1: Nosso Instalador (`install.sh`)

```bash
curl -fsSL https://raw.githubusercontent.com/wolfxweb/setup-openclaw/main/install.sh | bash
```

**O que acontece:**

1. **Verificação de Dependências**
   ```bash
   # Verifica se Docker está instalado
   # Se não, instala automaticamente
   curl -fsSL https://get.docker.com | sh
   ```

2. **Preparação do Ambiente**
   ```bash
   # Cria estrutura de diretórios
   mkdir -p ~/.openclaw/{workspace,agents}
   
   # Define permissões corretas para Docker
   chown -R 1000:1000 ~/.openclaw
   chmod -R 755 ~/.openclaw
   ```

3. **Geração de Credenciais Seguras**
   ```bash
   # Gera token criptograficamente seguro
   GATEWAY_TOKEN=$(openssl rand -hex 32)
   
   # Cria arquivo .env
   echo "OPENCLAW_GATEWAY_TOKEN=${GATEWAY_TOKEN}" > ~/.openclaw/.env
   chmod 600 ~/.openclaw/.env
   ```

4. **Clone do Repositório Oficial**
   ```bash
   cd ~/.openclaw
   git clone https://github.com/OpenClaw/openclaw.git
   cd openclaw
   ```

5. **Limpeza de Cache (Prevenção de Erros)**
   ```bash
   # Limpa cache corrompido do Docker BuildKit
   docker builder prune -af --filter "until=1h"
   ```

6. **Execução do Instalador Oficial**
   ```bash
   # ⚠️ AQUI CHAMAMOS O INSTALADOR OFICIAL DO OPENCLAW
   bash docker-setup.sh
   ```

### Etapa 2: Instalador Oficial (`docker-setup.sh`)

**O que o OpenClaw oficial faz:**

1. **Build da Imagem Docker**
   - Compila o código TypeScript
   - Instala dependências (pnpm)
   - Cria imagem `openclaw:local`

2. **Wizard Interativo**
   - Configuração de rede (lan/tailscale)
   - Autenticação (token/none)
   - Configuração de gateway

3. **OAuth com Providers**
   - OpenAI
   - Anthropic
   - Outros providers

4. **Inicialização**
   - Sobe containers via Docker Compose
   - Configura volumes e redes
   - Inicia o gateway

---

## 📁 Estrutura de Diretórios

### Durante a Instalação

```
/root/
└── .openclaw/                    ← Criado pelo nosso instalador
    ├── .env                      ← Token gerado por nós
    ├── workspace/                ← Diretório de trabalho
    ├── agents/                   ← Agentes instalados
    └── openclaw/                 ← Clone do repositório oficial
        ├── docker-setup.sh       ← Instalador oficial
        ├── docker-compose.yml    ← Configuração Docker oficial
        ├── Dockerfile            ← Build oficial
        └── src/                  ← Código-fonte oficial
```

### Após a Instalação

```
~/.openclaw/
├── .env                          ← Suas credenciais (NÃO compartilhar!)
├── workspace/                    ← Arquivos de trabalho dos agentes
├── agents/                       ← Agentes instalados
└── openclaw/                     ← OpenClaw oficial rodando
    ├── docker-compose.yml        ← Containers ativos
    └── ...

~/.openclaw-credentials.txt       ← Backup das credenciais
```

---

## 🔧 O que o Nosso Instalador Faz

### ✅ Responsabilidades

| Tarefa | Descrição |
|--------|-----------|
| **Verificação de Sistema** | Checa se Docker está instalado |
| **Instalação de Docker** | Instala Docker se necessário |
| **Criação de Diretórios** | Cria `~/.openclaw` com estrutura correta |
| **Permissões** | Define `chown 1000:1000` (usuário Docker) |
| **Geração de Token** | Cria token seguro de 32 bytes |
| **Arquivo .env** | Salva credenciais com permissões `600` |
| **Clone do Oficial** | Baixa repositório oficial do OpenClaw |
| **Limpeza de Cache** | Previne erros de snapshot do Docker |
| **Chamada do Oficial** | Executa `bash docker-setup.sh` |
| **Instruções Finais** | Mostra comandos para gerenciar OpenClaw |

### ❌ O que NÃO fazemos

- ❌ Não modificamos o código do OpenClaw
- ❌ Não alteramos o `docker-setup.sh` oficial
- ❌ Não fazemos build personalizado
- ❌ Não modificamos containers oficiais
- ❌ Não interferimos no wizard oficial

---

## 🎯 O que o OpenClaw Oficial Faz

### ✅ Responsabilidades do `docker-setup.sh`

| Tarefa | Descrição |
|--------|-----------|
| **Build Docker** | Compila código TypeScript e cria imagem |
| **Wizard Interativo** | Interface de configuração oficial |
| **OAuth Setup** | Configuração de providers (OpenAI, etc) |
| **Network Config** | Configuração de rede (lan/tailscale) |
| **Gateway Config** | Configuração do gateway e autenticação |
| **Container Start** | Inicia serviços via Docker Compose |
| **Health Checks** | Verifica se tudo está funcionando |

### 📦 Containers Criados (pelo oficial)

```yaml
# docker-compose.yml (do OpenClaw oficial)
services:
  openclaw-gateway:
    image: openclaw:local
    ports:
      - "1455:1455"     # Gateway HTTP
    volumes:
      - ~/.openclaw:/home/node/.openclaw
    environment:
      - OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}
```

---

## 🔐 Segurança

### O que Garantimos

1. **Token Forte**
   ```bash
   # 32 bytes = 256 bits de entropia
   openssl rand -hex 32
   ```

2. **Permissões Restritas**
   ```bash
   chmod 600 ~/.openclaw/.env           # Somente dono lê
   chmod 600 ~/.openclaw-credentials.txt # Somente dono lê
   ```

3. **Isolamento Docker**
   - Containers não rodam como root
   - User `node` (UID 1000)
   - Volumes com permissões específicas

4. **Sem Modificações**
   - Usamos o código oficial sem alterações
   - Não injetamos código
   - Não modificamos comportamento

---

## 🆚 Comparação

| Aspecto | Nosso Instalador | OpenClaw Oficial |
|---------|------------------|------------------|
| **Repositório** | `wolfxweb/setup-openclaw` | `OpenClaw/openclaw` |
| **Arquivo** | `install.sh` | `docker-setup.sh` |
| **Função** | Preparar ambiente | Instalar OpenClaw |
| **Docker** | Instala se necessário | Assume já instalado |
| **Diretórios** | Cria `~/.openclaw` | Usa diretórios existentes |
| **Credenciais** | Gera token seguro | Solicita no wizard |
| **Permissões** | Ajusta para UID 1000 | Assume corretas |
| **Build** | Não faz | Faz build da imagem |
| **Wizard** | Não tem | Wizard completo |
| **Modificações** | Nenhuma | N/A (é o oficial) |

---

## 🤔 Por que Usar Este Instalador?

### Vantagens

✅ **Simplicidade**: Um comando único  
✅ **Segurança**: Token gerado automaticamente  
✅ **Permissões**: Configuradas corretamente desde o início  
✅ **Previne Erros**: Limpa cache do Docker  
✅ **Instruções Claras**: Guia completo ao final  
✅ **Backup**: Salva credenciais em arquivo separado  

### Alternativa (Manual)

Se preferir fazer manualmente:

```bash
# 1. Instalar Docker
curl -fsSL https://get.docker.com | sh

# 2. Criar diretórios
mkdir -p ~/.openclaw/{workspace,agents}
chown -R 1000:1000 ~/.openclaw
chmod -R 755 ~/.openclaw

# 3. Gerar token
echo "OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)" > ~/.openclaw/.env
chmod 600 ~/.openclaw/.env

# 4. Clonar e instalar
cd ~/.openclaw
git clone https://github.com/OpenClaw/openclaw.git
cd openclaw
bash docker-setup.sh  # ← Instalador oficial
```

---

## 📚 Links

- **OpenClaw Oficial**: https://github.com/OpenClaw/openclaw
- **Documentação OpenClaw**: https://docs.openclaw.ai
- **Nosso Repositório**: https://github.com/wolfxweb/setup-openclaw
- **Issues**: https://github.com/wolfxweb/setup-openclaw/issues

---

## 💡 Resumo TL;DR

```
Nosso instalador = Preparação do ambiente
         ↓
bash docker-setup.sh = Instalação oficial do OpenClaw
         ↓
OpenClaw rodando 100% oficial em Docker
```

**Não modificamos nada do OpenClaw. Apenas facilitamos a preparação inicial!** 🎯
