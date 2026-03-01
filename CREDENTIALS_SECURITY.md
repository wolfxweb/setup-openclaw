# Gestão Segura de Credenciais (.env)

## 🔐 Arquivo .env

O SetupOpenClaw gera automaticamente um arquivo `.env` seguro durante a instalação do OpenClaw.

### Localização
```
/opt/openclaw/.env
```

### O que contém

```bash
# Gateway Token (64 caracteres hex)
OPENCLAW_GATEWAY_TOKEN=abc123...

# Configurações
OPENCLAW_CONFIG_DIR=/root/.openclaw
OPENCLAW_WORKSPACE_DIR=/root/.openclaw/workspace
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_BRIDGE_PORT=18790
OPENCLAW_GATEWAY_BIND=lan
```

---

## ⚠️ SEGURANÇA CRÍTICA

### ✅ Boas Práticas

1. **Permissões Corretas**
   ```bash
   chmod 600 /opt/openclaw/.env
   ```
   - Somente o dono (root) pode ler/escrever
   - Ninguém mais tem acesso

2. **Não Commitar no Git**
   - `.env` está automaticamente no `.gitignore`
   - Nunca faça `git add .env`

3. **Não Compartilhar**
   - Gateway token é como uma senha
   - Quem tem o token tem acesso total ao OpenClaw

4. **Backup Seguro**
   ```bash
   cp /opt/openclaw/.env /root/backup/.env.$(date +%Y%m%d)
   chmod 600 /root/backup/.env.*
   ```

### ❌ NÃO Faça

- ❌ Não exponha o `.env` publicamente
- ❌ Não cole o token em logs ou chat
- ❌ Não commit no GitHub/GitLab
- ❌ Não deixe permissões 644 ou 777

---

## 🔄 Regenerar Token

Se o token foi exposto:

```bash
cd /opt/openclaw

# Backup do .env atual
cp .env .env.backup

# Gerar novo token
NEW_TOKEN=$(openssl rand -hex 32)

# Atualizar .env
sed -i "s/OPENCLAW_GATEWAY_TOKEN=.*/OPENCLAW_GATEWAY_TOKEN=$NEW_TOKEN/" .env

# Reiniciar gateway
docker compose restart openclaw-gateway

# Atualizar no Control UI
echo "Novo token: $NEW_TOKEN"
```

**⚠️ Após regenerar, você precisa:**
1. Acessar Control UI
2. Settings → Gateway Token
3. Inserir o novo token

---

## 📁 Arquivos de Credenciais

O instalador cria dois arquivos com credenciais:

### 1. OpenClaw Gateway Token
```
/root/.openclaw-gateway-token.txt
```

Contém:
- Gateway token
- Instance URL
- Instruções de uso

### 2. Web Panel Credentials (se instalado)
```
/root/.setup-openclaw-credentials.txt
```

Contém:
- Username: admin
- Password: (gerado automaticamente)
- SSH tunnel command

**Ambos têm permissões 600 (seguro)**

---

## 🔍 Verificar Segurança

```bash
# Verificar permissões do .env
ls -l /opt/openclaw/.env
# Deve mostrar: -rw------- (600)

# Verificar se está no .gitignore
grep "^\.env$" /opt/openclaw/.gitignore
# Deve retornar: .env

# Verificar se não está trackeado no git
cd /opt/openclaw
git status
# .env NÃO deve aparecer em "Untracked files"
```

---

## 🚨 Token Exposto?

Se você acidentalmente expôs o token:

### Ação Imediata

1. **Regenerar token** (ver seção acima)
2. **Reiniciar gateway**
3. **Atualizar Control UI**
4. **Verificar logs** para acessos suspeitos:
   ```bash
   docker logs openclaw-gateway | grep "auth\|token"
   ```

### Prevenção Futura

- Use SSH tunnel para acessar Control UI (não exponha porta 18789)
- Configure firewall:
  ```bash
  sudo ufw deny 18789/tcp  # Bloquear acesso externo
  sudo ufw allow from 127.0.0.1 to any port 18789  # Apenas localhost
  ```
- Use autenticação adicional (BasicAuth via Traefik)

---

## 🔐 Backup Seguro

### Script de Backup

```bash
#!/bin/bash
# backup-openclaw.sh

BACKUP_DIR="/root/openclaw-backups"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup .env
cp /opt/openclaw/.env "$BACKUP_DIR/.env.$DATE"

# Backup config
tar czf "$BACKUP_DIR/config.$DATE.tar.gz" /root/.openclaw/

# Backup credentials
cp /root/.openclaw-gateway-token.txt "$BACKUP_DIR/token.$DATE.txt"
cp /root/.setup-openclaw-credentials.txt "$BACKUP_DIR/panel.$DATE.txt" 2>/dev/null

# Secure permissions
chmod 600 "$BACKUP_DIR"/*

echo "Backup completo: $BACKUP_DIR"
ls -lh "$BACKUP_DIR" | tail -5
```

### Restaurar Backup

```bash
# Parar gateway
cd /opt/openclaw
docker compose down

# Restaurar .env
cp /root/openclaw-backups/.env.YYYYMMDD-HHMMSS /opt/openclaw/.env
chmod 600 /opt/openclaw/.env

# Restaurar config
cd /
tar xzf /root/openclaw-backups/config.YYYYMMDD-HHMMSS.tar.gz

# Reiniciar
cd /opt/openclaw
docker compose up -d
```

---

## 📖 Referências

- [SECURITY.md](SECURITY.md) - Guia completo de segurança
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Problemas comuns
- [OpenClaw Docs](https://docs.openclaw.ai) - Documentação oficial

---

## ✅ Checklist de Segurança

- [ ] `.env` tem permissões 600
- [ ] `.env` está no `.gitignore`
- [ ] Token salvo em local seguro
- [ ] Backup configurado
- [ ] Firewall bloqueia porta 18789 externamente
- [ ] SSH tunnel configurado para acesso
- [ ] Logs de acesso monitorados

---

**SetupOpenClaw v1.2.0** | Gestão Segura de Credenciais
