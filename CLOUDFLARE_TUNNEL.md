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

#### **Opção A: Via comando (Recomendado)**

```bash
cloudflared tunnel route dns openclaw-gateway openclaw.seu-dominio.com.br
```

**Se o registro já existir:**

```bash
cloudflared tunnel route dns --overwrite-dns openclaw-gateway openclaw.seu-dominio.com.br
```

#### **Opção B: Manual no painel Cloudflare**

Se você já tem um registro A ou CNAME antigo:

1. **Acesse:** https://dash.cloudflare.com
2. **Selecione** seu domínio
3. **Vá em:** DNS > Records
4. **Delete** o registro antigo (se existir)
5. **Clique em:** "Add record"
6. **Preencha:**
   - **Type:** `CNAME`
   - **Name:** `openclaw` (ou seu subdomínio)
   - **Target:** `SEU_TUNNEL_ID.cfargotunnel.com`
     - Exemplo: `e7751658-8754-4352-ac1a-4da9504d0223.cfargotunnel.com`
   - **Proxy status:** ✅ **Proxied** (nuvem laranja)
   - **TTL:** `Auto`
7. **Salve**

⚠️ **IMPORTANTE:** 
- Não use IP no campo "Target" de um registro CNAME
- Se aparecer erro "invalid", delete o registro antigo primeiro
- Use o Tunnel ID completo seguido de `.cfargotunnel.com`

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

**Causa:** O registro DNS já existe (geralmente um A record apontando para o IP do servidor).

**Solução 1 - Via comando (Mais fácil):**

```bash
cloudflared tunnel route dns --overwrite-dns openclaw-gateway openclaw.seu-dominio.com.br
```

Este comando vai sobrescrever o registro antigo automaticamente.

**Solução 2 - Manual:**

1. Acesse https://dash.cloudflare.com
2. Vá em **DNS** > **Records**
3. **Delete** o registro antigo
4. **Adicione** um novo CNAME:
   - **Type:** `CNAME`
   - **Name:** Seu subdomínio (ex: `openclaw`)
   - **Target:** `SEU_TUNNEL_ID.cfargotunnel.com`
   - **Proxy:** ✅ Proxied

**Verificar se funcionou:**

```bash
nslookup seu-dominio.com.br 8.8.8.8
```

Deve mostrar IPs do Cloudflare (104.x.x.x ou 172.x.x.x) em vez do seu IP do servidor.

### Erro: device signature expired

**Causa:** Cache/cookies antigos ou sessão expirada no navegador.

**Solução:**

1. **Limpar cache do navegador:**
   - Chrome: `F12` > `Application` > `Storage` > `Clear site data`
   - Ou `Ctrl+Shift+Delete` e limpar cookies + cache

2. **Modo anônimo:**
   - Chrome/Edge: `Ctrl+Shift+N`
   - Firefox: `Ctrl+Shift+P`
   - Teste em janela anônima

3. **Reiniciar gateway:**
   ```bash
   cd ~/.openclaw/openclaw
   docker compose restart openclaw-gateway
   ```

4. **Se nada funcionar, use túnel SSH:**
   ```bash
   ssh -L 18789:localhost:18789 root@SEU_SERVIDOR
   ```
   Acesse: `http://localhost:18789`

---

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

### Gateway não aceita origem (origin not allowed)

**Causa:** O domínio não está na lista de origens permitidas do OpenClaw.

**Solução:**

1. Verifique se o domínio está em `allowedOrigins`:

```bash
cat ~/.openclaw/openclaw.json | grep -A 10 '"allowedOrigins"'
```

2. Se estiver faltando, adicione:

```bash
cd ~/.openclaw && python3 << 'PYTHONEOF'
import json

DOMINIO = "https://seu-dominio.com.br"

with open('openclaw.json', 'r') as f:
    config = json.load(f)

origins = config['gateway']['controlUi']['allowedOrigins']
if DOMINIO not in origins:
    origins.append(DOMINIO)
    
with open('openclaw.json', 'w') as f:
    json.dump(config, f, indent=2)
    
print(f"✓ {DOMINIO} adicionado!")
PYTHONEOF
```

3. Reinicie o gateway:

```bash
cd ~/.openclaw/openclaw
docker compose restart openclaw-gateway
```

### DNS não propaga

**Verificar DNS:**

```bash
# DNS local
nslookup seu-dominio.com.br

# DNS Google (mais atualizado)
nslookup seu-dominio.com.br 8.8.8.8

# DNS Cloudflare
nslookup seu-dominio.com.br 1.1.1.1
```

**Se ainda mostrar IP antigo:**

1. Limpe o cache DNS local:
   ```bash
   # Linux
   sudo systemd-resolve --flush-caches
   
   # Windows
   ipconfig /flushdns
   
   # Mac
   sudo dscacheutil -flushcache
   ```

2. Aguarde 5-10 minutos para propagação global

3. Teste em modo anônimo/privado do navegador

---

## 📚 Links Úteis

- **Documentação Cloudflare Tunnel:** https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **Dashboard Cloudflare:** https://dash.cloudflare.com
- **Cloudflare Zero Trust:** https://one.dash.cloudflare.com
- **Status Cloudflare:** https://www.cloudflarestatus.com

---

## 📝 Exemplo Prático Completo

Este é um exemplo real de configuração que foi testada e funcionou:

### Cenário:
- **Servidor:** VPS com IP `207.231.108.38`
- **Domínio:** `socx.celx.com.br`
- **Túnel ID:** `e7751658-8754-4352-ac1a-4da9504d0223`

### Passo a Passo:

**1. Instalação:**
```bash
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
```

**2. Autenticação:**
```bash
cloudflared tunnel login
# Abrir URL no navegador e autorizar
```

**3. Criar túnel:**
```bash
cloudflared tunnel create openclaw-gateway
# Output: Created tunnel openclaw-gateway with id e7751658-8754-4352-ac1a-4da9504d0223
```

**4. Configurar arquivo:**
```bash
cat > /root/.cloudflared/config.yml << 'EOF'
tunnel: e7751658-8754-4352-ac1a-4da9504d0223
credentials-file: /root/.cloudflared/e7751658-8754-4352-ac1a-4da9504d0223.json

ingress:
  - hostname: socx.celx.com.br
    service: http://localhost:18789
  - service: http_status:404
EOF
```

**5. Criar DNS (com overwrite porque já existia um A record):**
```bash
cloudflared tunnel route dns --overwrite-dns openclaw-gateway socx.celx.com.br
```

**6. Atualizar OpenClaw:**
```bash
cd ~/.openclaw
# Backup
cp openclaw.json openclaw.json.backup

# Atualizar allowedOrigins
python3 << 'PYTHONEOF'
import json

with open('openclaw.json', 'r') as f:
    config = json.load(f)

config['gateway']['controlUi']['allowedOrigins'] = [
    "http://127.0.0.1:18789",
    "http://localhost:18789",
    "https://socx.celx.com.br"
]

with open('openclaw.json', 'w') as f:
    json.dump(config, f, indent=2)

print("✓ Configurado!")
PYTHONEOF
```

**7. Reiniciar gateway:**
```bash
cd ~/.openclaw/openclaw
docker compose restart openclaw-gateway
```

**8. Instalar como serviço:**
```bash
cloudflared service install
systemctl start cloudflared
systemctl enable cloudflared
```

**9. Verificar:**
```bash
# Status do túnel
systemctl status cloudflared

# Verificar DNS
nslookup socx.celx.com.br 8.8.8.8
# Deve mostrar: 172.67.204.160 e 104.21.85.107 (IPs Cloudflare)
```

**10. Acessar:**
```
https://socx.celx.com.br
```

**Token:**
```
418021e09d3f22bb9096ea78980a2fb916f9c1f7ccb60e30
```

✅ **Funcionou!**

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
