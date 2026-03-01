# Troubleshooting - SetupOpenClaw

## ❌ EACCES: permission denied (Docker)

### Problema
```
Error: EACCES: permission denied, mkdir '/home/node/.openclaw/agents/main/agent'
```

### Causa
O container Docker roda como usuário `node` (uid 1000), mas os diretórios montados pertencem a `root`.

### Solução

```bash
# Corrigir permissões do diretório OpenClaw
sudo chown -R 1000:1000 ~/.openclaw
sudo chmod -R 755 ~/.openclaw

# Reiniciar container
cd /opt/openclaw
docker compose restart openclaw-gateway

# Verificar logs
docker compose logs openclaw-gateway | tail -20
```

### Verificar se corrigiu

```bash
# Ver proprietário dos diretórios
ls -la ~/.openclaw
# Deve mostrar: drwxr-xr-x ... 1000 1000 ...

# Testar criação de arquivo
sudo -u "#1000" touch ~/.openclaw/test.txt
# Se não der erro, permissões estão corretas
rm ~/.openclaw/test.txt
```

### Prevenção
O instalador v1.2.0+ corrige automaticamente as permissões. Se instalou manualmente, rode:

```bash
sudo chown -R 1000:1000 ~/.openclaw
```

---

## ❌ OAuth Callback Error (localhost:1455)

### Problema
Ao tentar fazer login com OpenAI/outros providers OAuth, você vê um erro de redirect para `http://localhost:1455/auth/callback`.

### Causa
O OpenClaw foi configurado com URL incorreta durante a instalação (provavelmente usou `localhost` ou `127.0.0.1`).

### Solução

#### Opção 1: Reinstalar com IP correto

```bash
# 1. Parar e remover instalação atual
cd /opt/openclaw
docker compose down -v

# 2. Reinstalar
cd /root/setup-openclaw/installer
sudo ./install.sh

# 3. Escolher opção 1: Install/Reinstall OpenClaw
# 4. Quando perguntar "What is the URL of this instance?", usar:
#    http://SEU_IP_PUBLICO:18789
#    (O instalador mostrará seu IP automaticamente)
```

#### Opção 2: Configurar manualmente no OpenClaw

1. Acesse o OpenClaw: `http://SEU_IP:18789`
2. Vá em **Settings** → **Instance Settings**
3. Altere **Base URL** para: `http://SEU_IP_PUBLICO:18789`
4. Salve e reinicie o container

#### Opção 3: Usar domínio com HTTPS (Recomendado)

```bash
# 1. Configure DNS do seu domínio apontando para o IP da VPS
# 2. Configure proxy SSL
cd /root/setup-openclaw/installer
sudo ./install.sh
# Escolher opção 3: Configure Proxy + SSL

# 3. Reinstalar OpenClaw usando:
#    https://seudominio.com
```

### Como descobrir seu IP público

```bash
curl -4 ifconfig.me  # IPv4
curl -6 ifconfig.me  # IPv6
```

---

## ❌ Containers não iniciam

### Verificar logs

```bash
cd /opt/openclaw
docker compose logs openclaw-gateway
```

### Reiniciar containers

```bash
cd /opt/openclaw
docker compose restart
```

---

## ❌ Porta 18789 não acessível

### Verificar firewall

```bash
# Liberar porta
sudo ufw allow 18789/tcp
sudo ufw reload

# Verificar status
sudo ufw status
```

### Verificar se porta está em uso

```bash
ss -tuln | grep 18789
```

---

## ❌ SSL não provisiona (Traefik)

### Verificar DNS

```bash
dig +short seudominio.com
# Deve retornar o IP da VPS
```

### Aguardar propagação

- Let's Encrypt precisa validar o domínio
- Aguarde 1-2 minutos após configurar DNS
- Verifique logs: `docker logs openclaw-traefik`

### Requisitos para SSL

- ✅ Domínio configurado corretamente
- ✅ DNS apontando para o IP da VPS
- ✅ Portas 80 e 443 abertas
- ✅ Firewall liberado

---

## ❌ Painel web não carrega

### Verificar se está rodando

```bash
cd /root/setup-openclaw/panel
docker compose ps
```

### Ver logs

```bash
cd /root/setup-openclaw/panel
docker compose logs -f
```

### Acessar via SSH tunnel (recomendado)

```bash
# No seu computador local:
ssh -L 8080:localhost:8080 root@SEU_IP
# Depois acesse: http://localhost:8080
```

---

## ❌ Rate limiting bloqueando

### Verificar logs de segurança

```bash
tail -50 /var/log/setup-openclaw/security.log
```

### Resetar (reiniciar painel)

```bash
cd /root/setup-openclaw/panel
docker compose restart
```

---

## ❌ Git pull/push não funciona

### Verificar remote

```bash
cd /root/setup-openclaw
git remote -v
```

### Trocar para SSH

```bash
git remote set-url origin git@github.com:wolfxweb/setup-openclaw.git
```

---

## 📞 Precisa de mais ajuda?

- **Issues**: https://github.com/wolfxweb/setup-openclaw/issues
- **OpenClaw Docs**: https://docs.openclaw.ai
- **Discord**: https://discord.gg/openclaw

---

## 🔍 Comandos úteis para debug

```bash
# Verificar todos os containers
docker ps -a

# Verificar logs do instalador
tail -f /var/log/setup-openclaw/install.log

# Verificar logs de segurança
tail -f /var/log/setup-openclaw/security.log

# Ver IP público
curl ifconfig.me

# Testar porta aberta
nc -zv SEU_IP 18789

# Verificar firewall
sudo ufw status numbered

# Verificar DNS
dig +short seudominio.com
nslookup seudominio.com
```
