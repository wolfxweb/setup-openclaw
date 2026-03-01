# 🚀 OpenClaw - Instalador Docker Simples

Instalador minimalista para OpenClaw rodando 100% em Docker.

## ✨ O que este instalador faz

- ✅ Instala Docker (se necessário)
- ✅ Configura OpenClaw em containers
- ✅ Gera credenciais seguras automaticamente
- ✅ Configura permissões corretas
- ❌ **SEM** configurações complicadas
- ❌ **SEM** painéis web
- ❌ **SEM** SSL/Traefik

---

## 📋 Requisitos

- **Sistema**: Ubuntu 20.04+ / Debian 11+
- **RAM**: Mínimo 4GB
- **Disco**: Mínimo 20GB livres
- **Acesso**: Root ou sudo

---

## 🎯 Instalação Rápida

### Método 1: Download direto (recomendado)

```bash
curl -fsSL https://raw.githubusercontent.com/wolfxweb/setup-openclaw/main/install.sh | bash
```

### Método 2: Clone o repositório

```bash
git clone https://github.com/wolfxweb/setup-openclaw.git
cd setup-openclaw
bash install.sh
```

---

## 🔑 Após a Instalação

### Suas credenciais estão salvas em:

```bash
cat ~/.openclaw-credentials.txt
```

### Verificar status dos containers:

```bash
cd ~/.openclaw/openclaw
docker compose ps
```

### Ver logs em tempo real:

```bash
cd ~/.openclaw/openclaw
docker compose logs -f
```

### Parar OpenClaw:

```bash
cd ~/.openclaw/openclaw
docker compose down
```

### Iniciar OpenClaw:

```bash
cd ~/.openclaw/openclaw
docker compose up -d
```

---

## ⚠️ Importante durante a instalação

Quando o wizard do OpenClaw pedir a **URL de callback OAuth**:

1. **Use o IP público da sua VPS**
   - Exemplo: `http://203.0.113.45:1455`
   - **NÃO use** `localhost` ou `127.0.0.1`

2. **Após autorizar na OpenAI:**
   - Copie a URL completa que aparece no navegador
   - Cole no terminal quando solicitado
   - A URL começa com `http://localhost:1455/auth/callback?code=...`

---

## 🗑️ Desinstalar

```bash
cd ~/.openclaw/openclaw
docker compose down -v
cd ~
rm -rf ~/.openclaw
rm -f ~/.openclaw-credentials.txt
```

---

## 📚 Estrutura de Arquivos

```
~/.openclaw/
├── openclaw/              # Repositório oficial clonado
│   ├── docker-compose.yml # Configuração Docker
│   └── ...
├── workspace/             # Área de trabalho dos agentes
├── agents/                # Agentes instalados
└── .env                   # Credenciais (NÃO COMPARTILHAR!)

~/.openclaw-credentials.txt # Suas credenciais de acesso
```

---

## 🆘 Problemas Comuns

### Erro de permissão Docker

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Containers não iniciam

```bash
cd ~/.openclaw/openclaw
docker compose logs
```

### Erro EACCES ao criar agentes

```bash
sudo chown -R 1000:1000 ~/.openclaw
sudo chmod -R 755 ~/.openclaw
```

---

## 🔒 Segurança

### Implementado Automaticamente:
- ✅ Token gateway gerado automaticamente com 32 bytes (256 bits)
- ✅ Arquivo `.env` com permissões `600` (somente leitura do dono)
- ✅ Credenciais salvas em arquivo separado
- ✅ Containers isolados (sem acesso root ao host)
- ✅ `.env` no `.gitignore` (nunca será commitado)

### Recomendações Importantes:

**⚠️ Configure o Firewall:**
```bash
sudo apt install ufw -y
sudo ufw allow 22/tcp          # SSH
sudo ufw allow 1455/tcp        # OpenClaw (se usar externamente)
sudo ufw --force enable
```

**⚠️ Proteja o SSH:**
```bash
# Desabilite login root em /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
```

**⚠️ Instale Fail2Ban:**
```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
```

### Guia Completo:
📖 Veja [SECURITY.md](SECURITY.md) para guia completo de segurança

### Regras de Ouro:
- ❌ **NUNCA** compartilhe seu `OPENCLAW_GATEWAY_TOKEN`
- ❌ **NUNCA** exponha porta 1455 sem firewall
- ❌ **NUNCA** use senha fraca no SSH
- ✅ **SEMPRE** faça backup das credenciais
- ✅ **SEMPRE** mantenha o sistema atualizado

---

## 📖 Documentação Oficial

- [OpenClaw GitHub](https://github.com/OpenClaw/openclaw)
- [Documentação OpenClaw](https://docs.openclaw.com)

---

## 🐛 Suporte

- **Issues**: [GitHub Issues](https://github.com/wolfxweb/setup-openclaw/issues)
- **OpenClaw**: [Documentação Oficial](https://docs.openclaw.com)

---

## 📝 Licença

MIT License - Veja [LICENSE](LICENSE) para detalhes.

---

## ⭐ Sobre

Este é um instalador não-oficial simplificado para OpenClaw.  
OpenClaw é desenvolvido por [OpenClaw Team](https://github.com/OpenClaw/openclaw).

**Versão**: 2.0.0 - Instalador Simplificado  
**Autor**: wolfxweb  
**Repositório**: https://github.com/wolfxweb/setup-openclaw
