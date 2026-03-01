# SetupOpenClaw

Sistema profissional de instalação automatizada do **OpenClaw** via Docker, com painel web administrativo e **segurança aprimorada**.

[![Security](https://img.shields.io/badge/security-8.5%2F10-green.svg)](SECURITY.md)
[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/wolfxweb/setup-openclaw)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://www.docker.com/)

## 🎯 Características

- ✅ **Instalação 100% Docker** - Segue exatamente o fluxo oficial do repositório OpenClaw
- ✅ **Wizard Interativo** - Não automatiza respostas, mantém a experiência original
- ✅ **Proxy Traefik + SSL** - HTTPS automático com Let's Encrypt
- ✅ **Painel Web** - Interface FastAPI + HTMX para gerenciar remotamente
- ✅ **🔒 Segurança Aprimorada v1.1.0** - Rate limiting, validação de senha forte, logs de segurança
- ✅ **Firewall UFW** - Configuração restritiva com bloqueio inteligente
- ✅ **Idempotente** - Pode ser executado múltiplas vezes sem problemas

## 🆕 Novidades v1.1.0 - Security Hardening

### Melhorias de Segurança
- 🛡️ **Rate Limiting**: 5 tentativas de login, 10 ações/minuto
- 🔑 **Senhas Fortes**: Mínimo 12 caracteres com complexidade obrigatória
- 📊 **Logs de Segurança**: `/var/log/setup-openclaw/security.log`
- 🚪 **Porta 8080 Bloqueada**: Acesso apenas via SSH tunnel (recomendado)
- 🔒 **Proteção de Sessão**: Detecção de IP hijacking
- 🛡️ **Firewall Hardening**: Default deny + SSH rate limiting
- 🔐 **Fail2Ban Support**: Proteção contra brute force

**Score de Segurança:** 6.8/10 → **8.5/10** ✅

📖 **[Leia o Guia de Segurança Completo](SECURITY.md)**

## 📋 Requisitos

- **OS**: Ubuntu 22.04/24.04 ou Debian 12
- **RAM**: Mínimo 2GB (recomendado 4GB+)
- **Disco**: Mínimo 20GB livre
- **Acesso**: Root (sudo)
- **Internet**: Conexão estável

## 🚀 Instalação Rápida

### Opção 1: Script Direto (curl)

```bash
# Clone do GitHub
git clone https://github.com/wolfxweb/setup-openclaw.git /root/setup-openclaw
cd /root/setup-openclaw/installer
sudo ./install.sh
```

### Opção 2: Via Git

```bash
git clone https://github.com/wolfxweb/setup-openclaw.git /root/setup-openclaw
cd /root/setup-openclaw/installer
sudo ./install.sh
```

## 📦 Instalação do Painel Web

O painel web permite gerenciar a instalação remotamente via navegador.

```bash
cd /root/setup-openclaw/panel

# Configure credenciais FORTES (v1.1.0 requer senha complexa)
export PANEL_USER=admin
export PANEL_PASSWORD=$(openssl rand -base64 24)  # Gera senha forte
export SECRET_KEY=$(openssl rand -base64 32)

# Inicie o painel
docker compose up -d
```

**🔒 Acesso Seguro (RECOMENDADO):**

```bash
# No seu computador local, crie SSH tunnel:
ssh -L 8080:localhost:8080 root@SEU_SERVIDOR_IP

# Depois acesse: http://localhost:8080
```

**Credenciais padrão**: `admin` / `changeme` (⚠️ Mude imediatamente!)

## 🏗️ Arquitetura

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
│                          └───────┬──────┘                      │
│                                  │                              │
│                                  ▼                              │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                    DOCKER ENGINE                         │ │
│  │                                                          │ │
│  │  ┌────────────────────────────────────────────────────┐ │ │
│  │  │         CONTAINERS DOCKER                          │ │ │
│  │  │  ┌──────────────┐      ┌────────────────────┐    │ │ │
│  │  │  │   Traefik    │      │  OpenClaw Gateway  │    │ │ │
│  │  │  │   (Proxy)    │◄────►│   (Container)      │    │ │ │
│  │  │  │  Port 80/443 │      │   Internal :18789  │    │ │ │
│  │  │  └──────────────┘      └────────────────────┘    │ │ │
│  │  └────────────────────────────────────────────────────┘ │ │
│  └──────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

**📖 [Diagrama Completo da Arquitetura](ARCHITECTURE.md)**

## 📚 Funcionalidades do Instalador

### Menu Interativo

1. **Instalar/Reinstalar OpenClaw**
   - Verifica requisitos do sistema
   - Instala dependências base
   - Instala Docker oficial
   - Clona repositório OpenClaw
   - Executa `./docker-setup.sh` (wizard interativo)

2. **Atualizar OpenClaw**
   - Git pull da última versão
   - Rebuild da imagem Docker
   - Restart dos containers

3. **Configurar Proxy + SSL**
   - Solicita domínio
   - Valida DNS (A/AAAA record)
   - Gera `docker-compose.proxy.yml` com Traefik
   - Certificado SSL automático (Let's Encrypt)
   - Expõe apenas portas 80/443

4. **Configurar Autenticação Web**
   - Solicita usuário/senha
   - Valida força da senha (v1.1.0)
   - Gera hash BCrypt
   - Configura BasicAuth no Traefik

5. **Configurar Firewall (UFW)** 🆕 **Enhanced**
   - Libera porta SSH (personalizável)
   - Libera portas 80/443 (se proxy ativo)
   - **Bloqueia porta 8080 externamente (padrão)**
   - SSH rate limiting
   - Fail2Ban integration
   - SSH hardening opcional

6. **Status & Logs**
   - Status dos containers
   - Test de conectividade (curl)
   - Últimos 50 logs do gateway
   - **Logs de segurança** 🆕

7. **Desinstalar**
   - Confirmação com "EXCLUIR"
   - Para e remove containers
   - Opção de remover diretório
   - Opção de remover Docker

### Modo Não-Interativo (para Painel)

```bash
sudo ./install.sh --action install
sudo ./install.sh --action update
sudo ./install.sh --action proxy
sudo ./install.sh --action webauth
sudo ./install.sh --action ufw
sudo ./install.sh --action status
sudo ./install.sh --action uninstall
```

## 🔒 Segurança

### ⚠️ IMPORTANTE - Leia Antes de Usar em Produção

O SetupOpenClaw v1.1.0 inclui melhorias significativas de segurança, mas requer configuração adequada:

**✅ Configuração Mínima Segura:**

```bash
# 1. Firewall restritivo
sudo /root/setup-openclaw/installer/install.sh
# Escolha opção 5: Configurar Firewall
# - Bloquear porta 8080 externamente: SIM

# 2. Acesso ao painel via SSH tunnel APENAS
ssh -L 8080:localhost:8080 root@seu-servidor

# 3. Senha forte (auto-gerada recomendado)
export PANEL_PASSWORD=$(openssl rand -base64 24)

# 4. Monitorar logs de segurança
tail -f /var/log/setup-openclaw/security.log
```

**🛡️ Proteções Ativas (v1.1.0):**
- Rate limiting automático (5 tentativas login)
- Validação de senha forte (min 12 chars)
- Logs de segurança com auditoria
- Proteção contra session hijacking
- Firewall com default deny

**📖 [Guia Completo de Segurança](SECURITY.md)**

### Sudoers (Produção)

Para executar o painel sem root completo:

```bash
# Criar usuário específico
useradd -m -s /bin/bash setup-panel

# Configurar sudoers
cat << 'EOF' > /etc/sudoers.d/setup-openclaw
setup-panel ALL=(ALL) NOPASSWD: /root/setup-openclaw/installer/install.sh --action *
