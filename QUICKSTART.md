# SetupOpenClaw - Quick Start Guide

## 🚀 Instalação em 3 Passos

### Passo 1: Execute o Instalador

```bash
cd /root/setup-openclaw/installer
sudo ./install.sh
```

**O que acontece:**
- Menu interativo aparece
- Escolha opção `1` (Instalar OpenClaw)
- O sistema verifica requisitos
- Instala Docker automaticamente
- Clona OpenClaw em `/opt/openclaw`
- Executa `./docker-setup.sh` (wizard interativo)
- **IMPORTANTE**: Siga as perguntas do wizard OpenClaw

### Passo 2: Configure HTTPS (Opcional mas Recomendado)

Após instalação bem-sucedida:

1. No menu, escolha opção `3` (Configurar Proxy + SSL)
2. Digite seu domínio: `openclaw.seudominio.com`
3. Digite email para Let's Encrypt: `seu@email.com`
4. Aguarde validação DNS
5. Certificado SSL será provisionado automaticamente

**Acesso:** `https://openclaw.seudominio.com`

### Passo 3: Inicie o Painel Web

```bash
cd /root/setup-openclaw/panel

# Configure credenciais (opcional)
export PANEL_USER=admin
export PANEL_PASSWORD=minhasenha123

# Inicie
docker compose up -d
```

**Acesso:** `http://SEU_IP:8080`

---

## 📱 Usando o Painel Web

1. Acesse `http://SEU_IP:8080`
2. Login: `admin` / `changeme` (ou suas credenciais)
3. Dashboard mostra:
   - Status do Gateway (atualizado a cada 5s)
   - Botões para todas as ações
   - Saída dos comandos em tempo real

### Ações Disponíveis:

| Botão | Função |
|-------|--------|
| 🚀 Instalar | Instalação completa do OpenClaw |
| 🔄 Atualizar | Atualizar para última versão |
| 🔒 Proxy + SSL | Configurar Traefik + HTTPS |
| 🔐 Autenticação | Proteger com login/senha |
| 🛡️ Firewall | Configurar regras UFW |
| 📊 Status | Ver status e logs |
| 🗑️ Desinstalar | Remover completamente |

---

## 🔧 Comandos Úteis

### Verificar Status

```bash
# Via instalador
sudo /root/setup-openclaw/installer/install.sh --action status

# Direto
cd /opt/openclaw
docker compose ps
docker compose logs openclaw-gateway
```

### Ver Logs

```bash
# Instalador
tail -f /var/log/setup-openclaw/install.log

# OpenClaw Gateway
cd /opt/openclaw && docker compose logs -f openclaw-gateway

# Painel Web
cd /root/setup-openclaw/panel && docker compose logs -f
```

### Acessar Control UI

```bash
# Local (no servidor)
curl http://127.0.0.1:18789

# Com proxy configurado
curl https://seudominio.com

# Ver token do gateway
cd /opt/openclaw
cat .env | grep OPENCLAW_GATEWAY_TOKEN
```

### Reiniciar Serviços

```bash
# OpenClaw Gateway
cd /opt/openclaw
docker compose restart openclaw-gateway

# Painel
cd /root/setup-openclaw/panel
docker compose restart panel
```

---

## 🐛 Troubleshooting Rápido

### "Gateway offline" no painel

```bash
cd /opt/openclaw
docker compose up -d openclaw-gateway
docker compose logs openclaw-gateway
```

### "Cannot connect to Docker daemon"

```bash
systemctl start docker
systemctl status docker
```

### SSL não funciona

```bash
# Verificar DNS
dig +short seudominio.com

# Ver logs Traefik
docker logs openclaw-traefik

# Aguardar 1-2 minutos para provisionamento
```

### Porta 8080 já em uso

```bash
# Ver o que está usando
ss -tlnp | grep 8080

# Mudar porta do painel
cd /root/setup-openclaw/panel
# Editar docker-compose.yml: "8081:8080"
docker compose up -d
```

---

## 🎯 Próximos Passos

1. **Configure canais** (WhatsApp, Telegram, etc):
   ```bash
   cd /opt/openclaw
   docker compose run --rm openclaw-cli channels login
   ```

2. **Configure modelos de IA**:
   - Acesse Control UI em `https://seudominio.com`
   - Vá em Settings → Models
   - Configure OpenAI, Anthropic, etc.

3. **Proteja o acesso**:
   ```bash
   sudo /root/setup-openclaw/installer/install.sh
   # Escolha opção 4: Configurar Autenticação Web
   ```

4. **Configure firewall**:
   ```bash
   sudo /root/setup-openclaw/installer/install.sh
   # Escolha opção 5: Configurar Firewall
   ```

---

## 📚 Documentação Completa

- **SetupOpenClaw**: `/root/setup-openclaw/README.md`
- **OpenClaw Oficial**: https://docs.openclaw.ai
- **Repositório**: https://github.com/openclaw/openclaw

---

**Dúvidas?** Consulte o README.md completo ou a documentação oficial do OpenClaw.
