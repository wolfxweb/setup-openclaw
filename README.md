# SetupOpenClaw

Sistema profissional de instalação automatizada do **OpenClaw** via Docker com segurança aprimorada.

[![Security](https://img.shields.io/badge/security-8.5%2F10-green.svg)](SECURITY.md)
[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/wolfxweb/setup-openclaw)

## 🆕 v1.2.0 - Wizard Interativo + SSL Automático

### Novo Wizard de Instalação:
- 🤖 **Detecção automática de IP** público
- 💬 **Perguntas interativas**: domínio, SSL, painel web
- 🔒 **SSL automático** com Let's Encrypt (renovação automática)
- 🔑 **Senhas fortes** geradas automaticamente
- ⚙️ **Configuração zero**: tudo é feito para você

### v1.1.0 - Security Hardening:
- 🛡️ Rate limiting (5 tentativas login)
- 🔑 Senhas fortes obrigatórias (12+ chars)
- 📊 Logs de segurança completos
- 🚪 Porta 8080 bloqueada por padrão
- 🔒 Proteção anti-hijacking
- 🛡️ Firewall hardening
- 🔐 Fail2Ban support

**Score:** 6.8/10 → **8.5/10** → **9.0/10** ✅

📖 [**Guia Completo de Segurança**](SECURITY.md)

## 🚀 Instalação Rápida

⚠️ **IMPORTANTE**: Durante a instalação, o wizard perguntará pela URL da instância. **NÃO use `localhost`**! Use o IP público da sua VPS (exemplo: `http://203.0.113.50:18789`) ou seu domínio (exemplo: `https://openclaw.seudominio.com`).

### Método 1: Clone Manual (Recomendado)

```bash
git clone https://github.com/wolfxweb/setup-openclaw.git /root/setup-openclaw
cd /root/setup-openclaw/installer
sudo ./install.sh
```

### Método 2: Comando Único

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wolfxweb/setup-openclaw/main/installer/install.sh)
```

## 📦 Painel Web

```bash
cd /root/setup-openclaw/panel

# Configure senha forte (obrigatório v1.1.0)
export PANEL_PASSWORD=$(openssl rand -base64 24)
echo "Sua senha: $PANEL_PASSWORD"  # Guarde esta senha!

docker compose up -d
```

**🔒 Acesso Seguro (SSH Tunnel):**
```bash
# No seu computador local:
ssh -L 8080:localhost:8080 root@SEU_SERVIDOR_IP

# Acesse: http://localhost:8080
# Login: admin
# Senha: a que você gerou acima
```

## 🎯 Funcionalidades

- ✅ Instalação 100% Docker (fluxo oficial OpenClaw)
- ✅ Wizard interativo preservado
- ✅ Proxy Traefik + SSL automático
- ✅ Painel FastAPI + HTMX
- ✅ Rate limiting automático
- ✅ Validação senha forte
- ✅ Logs de auditoria
- ✅ Firewall UFW hardening

## 📚 Documentação

- 📖 [CREDENTIALS_SECURITY.md](CREDENTIALS_SECURITY.md) - **Gestão segura de credenciais (.env)**
- 📖 [SSL_AUTO_RENEWAL.md](SSL_AUTO_RENEWAL.md) - **SSL automático com Let's Encrypt**
- 📖 [SECURITY.md](SECURITY.md) - **Guia de segurança completo** (leitura obrigatória!)
- 📖 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - **Soluções para problemas comuns**
- 📖 [ARCHITECTURE.md](ARCHITECTURE.md) - Arquitetura do sistema
- 📖 [QUICKSTART.md](QUICKSTART.md) - Guia rápido
- 📖 [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Resumo técnico

## 🔒 Segurança

**v1.1.0** implementa proteções profissionais:
- Rate limiting contra brute force
- Senhas fortes obrigatórias (min 12 chars)
- Logs de segurança com auditoria
- Firewall com default deny
- SSH hardening automático
- Session hijacking protection

⚠️ **IMPORTANTE:** Leia [SECURITY.md](SECURITY.md) antes de usar em produção!

**Acesso ao painel:**
- ✅ **RECOMENDADO**: Via SSH tunnel (porta 8080 bloqueada externamente)
- ⚠️ **NÃO RECOMENDADO**: Expor porta 8080 publicamente

## 📊 Logs

- **Instalador**: `/var/log/setup-openclaw/install.log`
- **Segurança**: `/var/log/setup-openclaw/security.log`
- **Gateway**: `cd /opt/openclaw && docker compose logs`

## 🔄 Atualizar

```bash
cd /root/setup-openclaw
git pull origin main
cd panel && docker compose down && docker compose build && docker compose up -d
```

## 🔑 Para Desenvolvedores

### Clonar o Repositório

**SSH (Recomendado):**
```bash
git clone git@github.com:wolfxweb/setup-openclaw.git
```

**HTTPS:**
```bash
git clone https://github.com/wolfxweb/setup-openclaw.git
```

### Configurar SSH para Git

Se você já tem uma chave SSH no GitHub:
```bash
cd /root/setup-openclaw
git remote set-url origin git@github.com:wolfxweb/setup-openclaw.git
git pull origin main
```

Se você precisa criar uma chave SSH:
```bash
ssh-keygen -t ed25519 -C "seu@email.com"
cat ~/.ssh/id_ed25519.pub  # Adicione esta chave no GitHub
```

**Adicionar chave no GitHub**: https://github.com/settings/keys

## 📞 Suporte

- **Repositório**: https://github.com/wolfxweb/setup-openclaw
- **OpenClaw Oficial**: https://github.com/openclaw/openclaw
- **Issues**: https://github.com/wolfxweb/setup-openclaw/issues

## 📝 Changelog

### v1.1.0 (2024-03-01) - Security Hardening
- 🔒 Rate limiting (5 login attempts, 10 actions/min)
- 🔑 Senha forte obrigatória (12+ chars, uppercase, lowercase, number, special)
- 📊 Logs de segurança completos com auditoria
- 🛡️ Firewall hardening (default deny, SSH rate limit)
- 🚪 Porta 8080 bloqueada externamente por padrão
- 🔐 Session hijacking protection
- 📖 Guia de segurança completo (SECURITY.md)

### v1.0.0 (2024-02-14) - Release Inicial
- ✅ Instalador Bash modular
- ✅ Painel web FastAPI + HTMX
- ✅ Proxy Traefik com SSL automático
- ✅ Firewall UFW
- ✅ Documentação completa

## 🙏 Créditos

- **OpenClaw**: https://openclaw.ai
- **Traefik**: https://traefik.io
- **FastAPI**: https://fastapi.tiangolo.com
- **HTMX**: https://htmx.org

---

**SetupOpenClaw v1.1.0** | Instalação profissional com segurança aprimorada

⭐ **Dê uma estrela no GitHub se este projeto foi útil!**

**Desenvolvido por:** [wolfxweb](https://github.com/wolfxweb)
