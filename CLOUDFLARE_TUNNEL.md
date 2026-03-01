# 🌐 Acesso via HTTPS com Cloudflare Tunnel

Guia completo para configurar acesso seguro ao OpenClaw Control UI usando Cloudflare Tunnel.

## ✨ Por que usar Cloudflare Tunnel?

- ✅ **HTTPS automático** via Cloudflare
- ✅ **Sem abrir portas** no firewall
- ✅ **DDoS protection** gratuito
- ✅ **CDN global** para melhor performance
- ✅ **Zero Trust security**
- ✅ **Gratuito** para uso pessoal

---

## 📋 Pré-requisitos

1. Conta no Cloudflare (gratuita)
2. Um domínio gerenciado pelo Cloudflare
3. Servidor com OpenClaw instalado

---

## 🚀 Instalação Rápida

### 1. Instalar Cloudflared

```bash
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
cloudflared --version
```

### 2. Autenticar no Cloudflare

```bash
cloudflared tunnel login
```

- Abra o link fornecido no navegador
- Faça login na sua conta Cloudflare
- Autorize o acesso
- Aguarde a confirmação

### 3. Criar o Túnel

```bash
cloudflared tunnel create openclaw-gateway
```

Anote o **Tunnel ID** exibido (exemplo: `e7751658-8754-4352-ac1a-4da9504d0223`).

### 4. Configurar o Túnel

Crie o arquivo de configuração:

```bash
nano /root/.cloudflared/config.yml
```

Cole este conteúdo (substitua os valores):

```yaml
tunnel: SEU_TUNNEL_ID_AQUI
credentials-file: /root/.cloudflared/SEU_TUNNEL_ID_AQUI.json

ingress:
  - hostname: openclaw.seu-dominio.com.br
    service: http://localhost:18789
  - service: http_status:404
```

**Exemplo:**

```yaml
tunnel: e7751658-8754-4352-ac1a-4da9504d0223
credentials-file: /root/.cloudflared/e7751658-8754-4352-ac1a-4da9504d0223.json

ingress:
  - hostname: socx.celx.com.br
    service: http://localhost:18789
  - service: http_status:404
```

### 5. Criar Registro DNS

```bash
cloudflared tunnel route dns openclaw-gateway openclaw.seu-dominio.com.br
```

**Nota:** Se o registro DNS já existir, você pode atualizá-lo manualmente no painel do Cloudflare:

1. Acesse https://dash.cloudflare.com
2. Selecione seu domínio
3. Vá em **DNS** > **Records**
4. Adicione um registro **CNAME**:
   - **Name:** `openclaw` (ou seu subdomínio)
   - **Target:** `SEU_TUNNEL_ID.cfargotunnel.com`
   - **Proxy status:** ✅ Proxied (laranja)

### 6. Atualizar OpenClaw

Edite o arquivo de configuração do OpenClaw:

```bash
nano ~/.openclaw/openclaw.json
```

Adicione seu domínio em `allowedOrigins`:

```json
{
  "gateway": {
    "controlUi": {
      "allowedOrigins": [
        "http://127.0.0.1:18789",
        "http://localhost:18789",
        "https://openclaw.seu-dominio.com.br"
      ]
    }
  }
}
```

Reinicie o gateway:

```bash
cd ~/.openclaw/openclaw
docker compose restart openclaw-gateway
```

### 7. Instalar Cloudflared como Serviço

Para que o túnel inicie automaticamente:

```bash
cloudflared service install
systemctl start cloudflared
systemctl enable cloudflared
systemctl status cloudflared
```

### 8. Testar o Acesso

Abra seu navegador e acesse:

```
https://openclaw.seu-dominio.com.br
```

Use o token do OpenClaw para autenticar (encontre em `~/.openclaw/openclaw.json`):

```bash
cat ~/.openclaw/openclaw.json | grep '"token"'
```

---

## 🔧 Comandos Úteis

### Verificar Status do Túnel

```bash
systemctl status cloudflared
```

### Ver Logs do Túnel

```bash
journalctl -u cloudflared -f
```

### Reiniciar Túnel

```bash
systemctl restart cloudflared
```

### Parar Túnel

```bash
systemctl stop cloudflared
```

### Listar Túneis

```bash
cloudflared tunnel list
```

### Deletar Túnel

```bash
cloudflared tunnel delete openclaw-gateway
```

---

## 🛡️ Segurança Adicional

### Habilitar Cloudflare Access (Zero Trust)

Para adicionar autenticação extra:

1. Acesse https://one.dash.cloudflare.com
2. Vá em **Access** > **Applications**
3. Clique em **Add an application**
4. Configure:
   - **Application name:** OpenClaw
   - **Session Duration:** 24 hours
   - **Application domain:** `openclaw.seu-dominio.com.br`
5. Adicione uma política de acesso (email, IP, etc.)

### Logs de Acesso

Os logs do Cloudflare estão disponíveis em:
- https://dash.cloudflare.com → **Analytics** → **Traffic**

---

## 🆘 Troubleshooting

### Erro: "tunnel credentials file doesn't exist"

**Solução:**

```bash
ls -la /root/.cloudflared/
```

Verifique se o arquivo `.json` existe. O nome deve corresponder ao seu Tunnel ID.

### Erro: "Failed to create route: record already exists"

**Solução:**

O registro DNS já existe. Atualize manualmente no painel do Cloudflare ou remova o registro antigo:

```bash
cloudflared tunnel route dns --overwrite-dns openclaw-gateway openclaw.seu-dominio.com.br
```

### Túnel não conecta

**Verificar:**

1. Status do serviço:
   ```bash
   systemctl status cloudflared
   ```

2. Logs:
   ```bash
   journalctl -u cloudflared -n 50
   ```

3. Configuração:
   ```bash
   cat /root/.cloudflared/config.yml
   ```

### Gateway não aceita origem

**Solução:**

Verifique se o domínio está em `allowedOrigins`:

```bash
cat ~/.openclaw/openclaw.json | grep -A 10 '"allowedOrigins"'
```

Adicione seu domínio se estiver faltando.

---

## 📚 Links Úteis

- **Documentação Cloudflare Tunnel:** https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **Dashboard Cloudflare:** https://dash.cloudflare.com
- **Cloudflare Zero Trust:** https://one.dash.cloudflare.com
- **Status Cloudflare:** https://www.cloudflarestatus.com

---

## 💡 Dicas

### Múltiplos Subdomínios

Você pode expor múltiplos serviços no mesmo túnel:

```yaml
tunnel: e7751658-8754-4352-ac1a-4da9504d0223
credentials-file: /root/.cloudflared/e7751658-8754-4352-ac1a-4da9504d0223.json

ingress:
  - hostname: openclaw.seu-dominio.com.br
    service: http://localhost:18789
  - hostname: app.seu-dominio.com.br
    service: http://localhost:3000
  - service: http_status:404
```

### Backup da Configuração

```bash
# Backup
tar -czf cloudflared-backup.tar.gz /root/.cloudflared/

# Restaurar
tar -xzf cloudflared-backup.tar.gz -C /
```

### Migrar para Outro Servidor

1. Copie os arquivos:
   ```bash
   scp -r /root/.cloudflared/ root@novo-servidor:/root/
   ```

2. No novo servidor:
   ```bash
   cloudflared service install
   systemctl start cloudflared
   ```

---

**Pronto!** ✅ Agora você tem acesso seguro via HTTPS ao OpenClaw Control UI!
