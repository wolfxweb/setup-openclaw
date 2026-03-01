# 🔧 Troubleshooting - Problemas Comuns

## ❌ Erro: EACCES: permission denied

### Descrição do erro:
```
Error: EACCES: permission denied, open '/home/node/.openclaw/workspace/AGENTS.md'
```

### Causa:
O wizard oficial do OpenClaw tenta criar arquivos no diretório `~/.openclaw/workspace/`, mas ele não existe ou não tem as permissões corretas para o usuário do container (UID 1000).

### ✅ Solução automática (v4.2+):
O instalador agora cria automaticamente os diretórios com permissões corretas **ANTES** do wizard. Se você estiver usando a versão mais recente:

```bash
curl -fsSL https://raw.githubusercontent.com/wolfxweb/setup-openclaw/main/install.sh | bash
```

### 🔧 Solução manual (instalações antigas):

Se você já tem uma instalação e está com este erro, execute:

```bash
# 1. Parar o OpenClaw
cd ~/.openclaw/openclaw && docker compose down

# 2. Criar diretórios e permissões
mkdir -p ~/.openclaw/workspace
mkdir -p ~/.openclaw/workspace/.agents
chown -R 1000:1000 ~/.openclaw
chmod -R 755 ~/.openclaw

# 3. Executar o wizard novamente
bash docker-setup.sh
```

### Por que UID 1000?
O container OpenClaw roda com o usuário `node` (UID 1000). Os arquivos precisam pertencer a este usuário para que o processo dentro do container possa criar/modificar arquivos.

---

---

## ❌ Erro: device signature expired

### Descrição do erro:
```
device signature expired
```

ou no log do gateway:

```
closed before connect ... reason=device signature expired
```

### Causa:
O OpenClaw usa assinatura de dispositivo para segurança. A assinatura pode expirar por:
- Cache/cookies antigos do navegador
- Sessão antiga armazenada no LocalStorage
- Gateway reiniciado mas navegador com sessão antiga
- Conflito entre HTTP e HTTPS

### ✅ Solução 1: Limpar cache do navegador (Recomendada)

**Chrome/Edge:**
1. Pressione `F12` (abrir DevTools)
2. Vá em **Application** (ou **Aplicativo**)
3. Clique em **Storage** > **Clear site data**
4. Ou use `Ctrl+Shift+Delete`:
   - ✅ Cookies e outros dados do site
   - ✅ Imagens e arquivos em cache
   - ✅ Dados hospedados de apps
5. Recarregue com `Ctrl+F5`

**Firefox:**
1. `Ctrl+Shift+Delete`
2. Marque:
   - ✅ Cookies
   - ✅ Cache
3. Clique em **Limpar agora**

**Safari:**
1. `Cmd+Option+E` (limpar cache)
2. Ou **Safari** > **Limpar Histórico**

---

### ✅ Solução 2: Modo anônimo/privado

Teste em uma janela anônima (sem cache):

- **Chrome/Edge:** `Ctrl+Shift+N`
- **Firefox:** `Ctrl+Shift+P`
- **Safari:** `Cmd+Shift+N`

Depois acesse:
```
https://seu-dominio.com.br
```

---

### ✅ Solução 3: Reiniciar o gateway

O gateway pode precisar ser reiniciado para gerar novas assinaturas:

```bash
cd ~/.openclaw/openclaw
docker compose restart openclaw-gateway
```

Aguarde 5-10 segundos e tente novamente.

---

### ✅ Solução 4: Túnel SSH (100% garantido)

Se nada funcionar, use túnel SSH que sempre funciona:

No seu computador local:
```bash
ssh -L 18789:localhost:18789 root@SEU_SERVIDOR
```

Acesse:
```
http://localhost:18789
```

---

### ✅ Solução 5: Verificar configuração

Confirme que o domínio está em `allowedOrigins`:

```bash
cat ~/.openclaw/openclaw.json | grep -A 10 '"allowedOrigins"'
```

Deve incluir seu domínio com HTTPS:
```json
{
  "allowedOrigins": [
    "http://127.0.0.1:18789",
    "http://localhost:18789",
    "https://seu-dominio.com.br"
  ]
}
```

---

## ❌ Erro: origin not allowed

### Descrição do erro:
```
origin not allowed (open the Control UI from the gateway host or allow it in gateway.controlUi.allowedOrigins)
```

### Causa:
O OpenClaw está configurado com `bind: "loopback"` por padrão, aceitando apenas conexões de `127.0.0.1`. Quando você tenta acessar remotamente, o gateway bloqueia.

### ✅ Solução automática (v4.1+):
O instalador detecta seu IP público e configura automaticamente após o wizard.

### 🔧 Solução manual:

```bash
# 1. Detectar seu IP público
PUBLIC_IP=$(curl -s https://ifconfig.me)
echo "Seu IP: $PUBLIC_IP"

# 2. Editar configuração
nano ~/.openclaw/openclaw.json
```

Modifique:
```json
{
  "gateway": {
    "bind": "all",
    "controlUi": {
      "allowedOrigins": [
        "http://127.0.0.1:18789",
        "http://SEU_IP_AQUI:18789"
      ]
    }
  }
}
```

```bash
# 3. Reiniciar gateway
cd ~/.openclaw/openclaw
docker compose restart openclaw-gateway
```

---

## ❌ Erro: port already in use

### Descrição do erro:
```
Error response from daemon: failed to bind host port 127.0.0.1:18789/tcp: address already in use
```

### Causa:
Existe outro processo (provavelmente uma instalação anterior do OpenClaw) usando a porta 18789.

### ✅ Solução:

```bash
# 1. Verificar o que está usando a porta
lsof -i :18789

# 2. Parar containers OpenClaw anteriores
docker ps -a | grep openclaw | awk '{print $1}' | xargs docker stop
docker ps -a | grep openclaw | awk '{print $1}' | xargs docker rm -f

# 3. Se houver outro processo, matá-lo (substitua PID)
kill -9 PID

# 4. Verificar novamente
lsof -i :18789
```

---

## ❌ Build do Docker falha

### Descrição do erro:
```
ERROR [internal] load metadata for docker.io/library/node:20-alpine
failed to solve with frontend dockerfile.v0: failed to create LLB definition
```

### Causa:
Cache do Docker corrompido.

### ✅ Solução:

```bash
# Limpar cache do Docker
docker builder prune -af
docker system prune -af

# Reinstalar
curl -fsSL https://raw.githubusercontent.com/wolfxweb/setup-openclaw/main/install.sh | bash
```

---

## ❌ Wizard não responde / trava

### Causa:
Você está executando via `curl | bash` (não interativo).

### ✅ Solução:

O instalador detecta automaticamente e para antes do wizard. Execute manualmente:

```bash
cd ~/.openclaw/openclaw
bash docker-setup.sh
```

---

## ❌ Container reinicia constantemente

### Verificar logs:

```bash
cd ~/.openclaw/openclaw
docker compose logs -f openclaw-gateway
```

### Causas comuns:
1. **Erro no openclaw.json**: Verifique a sintaxe JSON
2. **Token inválido**: Regenere em `~/.openclaw/openclaw.json`
3. **OAuth expirado**: Reconfigure com `openclaw configure`

---

## 🆘 Reinstalação completa

Se nada funcionar, reinstale do zero:

```bash
# 1. Parar tudo
cd ~/.openclaw/openclaw 2>/dev/null && docker compose down -v || true

# 2. Remover containers/imagens
docker ps -a | grep openclaw | awk '{print $1}' | xargs -r docker rm -f
docker images | grep openclaw | awk '{print $3}' | xargs -r docker rmi -f

# 3. Remover configuração
rm -rf ~/.openclaw

# 4. Limpar cache
docker system prune -af --volumes

# 5. Reinstalar
curl -fsSL https://raw.githubusercontent.com/wolfxweb/setup-openclaw/main/install.sh | bash
```

---

---

## ❌ Erro: control ui requires device identity (use HTTPS or localhost secure context)

### Descrição do erro:
```
control ui requires device identity (use HTTPS or localhost secure context)
```

### Causa:
O OpenClaw Control UI requer contexto seguro (HTTPS ou localhost) para funcionar. Acessar via IP público HTTP não é permitido por questões de segurança.

### ✅ Soluções:

#### **Opção 1: Túnel SSH (Recomendada - Simples e Segura)**

No seu computador local:

```bash
ssh -L 18789:localhost:18789 root@SEU_IP_SERVIDOR
```

Depois acesse no navegador:
```
http://localhost:18789
```

**Vantagens:**
- ✅ Criptografia via SSH
- ✅ Sem configuração adicional
- ✅ Porta não exposta publicamente

---

#### **Opção 2: Cloudflare Tunnel (Recomendada - HTTPS Automático)**

**1. Instalar Cloudflared:**

```bash
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
```

**2. Autenticar no Cloudflare:**

```bash
cloudflared tunnel login
```

Abra o link fornecido no navegador e autorize.

**3. Criar túnel:**

```bash
cloudflared tunnel create openclaw-gateway
```

**4. Configurar túnel:**

Crie `/root/.cloudflared/config.yml`:

```yaml
tunnel: SEU_TUNNEL_ID
credentials-file: /root/.cloudflared/SEU_TUNNEL_ID.json

ingress:
  - hostname: seu-dominio.com.br
    service: http://localhost:18789
  - service: http_status:404
```

**5. Criar DNS:**

```bash
cloudflared tunnel route dns openclaw-gateway seu-dominio.com.br
```

**6. Atualizar `openclaw.json`:**

Adicione seu domínio em `allowedOrigins`:

```json
{
  "gateway": {
    "controlUi": {
      "allowedOrigins": [
        "http://127.0.0.1:18789",
        "http://localhost:18789",
        "https://seu-dominio.com.br"
      ]
    }
  }
}
```

**7. Instalar como serviço:**

```bash
cloudflared service install
systemctl start cloudflared
systemctl enable cloudflared
```

**8. Reiniciar gateway:**

```bash
cd ~/.openclaw/openclaw
docker compose restart openclaw-gateway
```

**9. Acessar:**

```
https://seu-dominio.com.br
```

**Vantagens:**
- ✅ HTTPS automático (Let's Encrypt via Cloudflare)
- ✅ Sem necessidade de abrir portas no firewall
- ✅ DDoS protection gratuito
- ✅ CDN global
- ✅ Zero Trust security

---

#### **Opção 3: Caddy + Domínio próprio**

Se você tem um domínio, pode usar Caddy para HTTPS automático:

```bash
# Instalar Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

# Configurar Caddy
cat > /etc/caddy/Caddyfile << 'EOF'
seu-dominio.com.br {
    reverse_proxy localhost:18789
}
EOF

# Reiniciar Caddy
systemctl restart caddy
```

---

## 📚 Mais ajuda

- **Documentação oficial**: https://docs.openclaw.ai
- **GitHub Issues**: https://github.com/wolfxweb/setup-openclaw/issues
- **OpenClaw Discord**: https://discord.gg/openclaw
- **Cloudflare Tunnel**: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
