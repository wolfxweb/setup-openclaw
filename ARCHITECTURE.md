# SetupOpenClaw - Arquitetura do Sistema

## Diagrama Correto da Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                         HOST VPS (Ubuntu/Debian)                │
│                                                                 │
│  ┌─────────────┐         ┌──────────────┐                     │
│  │   Usuário   │ ◄────── │  Painel Web  │                     │
│  │  (Browser)  │         │  (Port 8080) │                     │
│  └─────────────┘         └───────┬──────┘                     │
│                                  │                              │
│                                  ▼                              │
│                          ┌──────────────┐                      │
│                          │  install.sh  │                      │
│                          │  (Bash)      │                      │
│                          └───────┬──────┘                      │
│                                  │                              │
│                                  │ instala/configura            │
│                                  ▼                              │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                    DOCKER ENGINE                         │ │
│  │                                                          │ │
│  │  ┌────────────────────────────────────────────────────┐ │ │
│  │  │         CONTAINERS DOCKER                          │ │ │
│  │  │                                                     │ │ │
│  │  │  ┌──────────────┐      ┌────────────────────┐    │ │ │
│  │  │  │   Traefik    │      │  OpenClaw Gateway  │    │ │ │
│  │  │  │   (Proxy)    │◄────►│   (Container)      │    │ │ │
│  │  │  │  Port 80/443 │      │   Internal :18789  │    │ │ │
│  │  │  └──────┬───────┘      └─────────┬──────────┘    │ │ │
│  │  │         │                        │                │ │ │
│  │  │         │ HTTPS                  │ Docker         │ │ │
│  │  │         │ with SSL               │ Network        │ │ │
│  │  │         │                        │                │ │ │
│  │  └─────────┼────────────────────────┼────────────────┘ │ │
│  └────────────┼────────────────────────┼──────────────────┘ │
│               │                        │                     │
│               │ expõe                  │ executa             │
│               ▼                        ▼                     │
│         Port 80/443              /opt/openclaw               │
│    (acesso externo)          (docker-compose.yml)            │
└─────────────────────────────────────────────────────────────────┘
```

## Detalhamento dos Componentes

### 1. Host VPS (Bare Metal)
- Sistema Operacional: Ubuntu 22/24 ou Debian 12
- Docker Engine instalado
- Arquivos do projeto em `/root/setup-openclaw`
- OpenClaw clonado em `/opt/openclaw`

### 2. Instalador (Bash - Roda no Host)
- **Local:** `/root/setup-openclaw/installer/install.sh`
- **Função:** Automatizar instalação
- **Executa:**
  - Instala Docker no host
  - Clona repositório OpenClaw
  - Executa `docker-setup.sh` oficial
  - Configura Traefik (se solicitado)

### 3. Docker Engine (Roda no Host)
- Gerencia todos os containers
- Fornece rede isolada para containers
- Volumes persistentes para dados

### 4. Container OpenClaw Gateway (Dentro do Docker)
- **Imagem:** Buildada pelo `docker-setup.sh` oficial
- **Porta Interna:** 18789 (não exposta diretamente)
- **Network:** Rede Docker interna
- **Função:** Gateway do OpenClaw
- **Comando:** Definido pelo OpenClaw oficial
- **Dados:** Volume `/opt/openclaw` no host

### 5. Container Traefik (Dentro do Docker - Opcional)
- **Imagem:** traefik:v3.0
- **Portas Expostas:** 80, 443 (para o mundo)
- **Função:** 
  - Reverse proxy
  - SSL automático (Let's Encrypt)
  - Roteia HTTPS → OpenClaw Gateway :18789
- **Network:** Compartilha rede com OpenClaw

### 6. Painel Web (Python FastAPI - Roda no Host ou Container)
- **Local:** `/root/setup-openclaw/panel`
- **Porta:** 8080
- **Função:** Interface web para gerenciar instalador
- **Executa:** Comandos do `install.sh` via subprocess

## Fluxo de Dados

### Instalação
```
Usuário → Painel Web (8080) → install.sh → Docker Engine
                                              ↓
                                    Cria Containers OpenClaw
                                              ↓
                                    OpenClaw rodando em :18789
```

### Acesso ao OpenClaw (SEM Proxy)
```
Usuário → http://IP_VPS:18789 → Container OpenClaw
```

### Acesso ao OpenClaw (COM Proxy)
```
Usuário → https://dominio.com:443 → Container Traefik → Container OpenClaw :18789
```

## Componentes que rodam DENTRO do Docker

✅ **OpenClaw Gateway** (container)
✅ **Traefik Proxy** (container - se configurado)

## Componentes que rodam FORA do Docker (no Host)

✅ **Instalador Bash** (`install.sh`)
✅ **Painel Web** (FastAPI - pode ser containerizado)
✅ **Docker Engine** (o daemon)

## Resumo

O OpenClaw **SEMPRE** roda dentro de containers Docker, conforme o repositório oficial. Nosso instalador:

1. Prepara o ambiente (instala Docker)
2. Clona o repositório oficial
3. Executa o script oficial `docker-setup.sh`
4. Opcionalmente adiciona Traefik como proxy

**Nada do OpenClaw roda fora do Docker!**
