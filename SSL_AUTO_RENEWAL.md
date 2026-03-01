# SSL Automático com Renovação (Let's Encrypt)

## 🔒 Como Funciona

O SetupOpenClaw usa **Traefik v3.0** com **Let's Encrypt** para gerenciar certificados SSL automaticamente.

### Características

- ✅ **Emissão Automática**: Certificado gerado na primeira vez que você acessa o domínio
- ✅ **Renovação Automática**: Traefik renova automaticamente antes do vencimento (90 dias)
- ✅ **HTTP → HTTPS**: Redirect automático de HTTP para HTTPS
- ✅ **Sem Configuração Manual**: Tudo gerenciado pelo Traefik

---

## 📋 Requisitos

Para SSL funcionar, você precisa:

1. **Domínio próprio** (ex: `openclaw.example.com`)
2. **DNS configurado** corretamente:
   ```
   A Record: openclaw.example.com → SEU_IP_PUBLICO
   ```
3. **Portas abertas**:
   - Porta 80 (HTTP) - Para validação ACME
   - Porta 443 (HTTPS) - Para tráfego SSL

---

## 🚀 Instalação Automática

Durante a instalação do SetupOpenClaw, o sistema perguntará:

```
Do you have a domain for this installation? (y/n)
→ y

Enter your domain (e.g., openclaw.example.com):
→ openclaw.example.com

Enter email for Let's Encrypt notifications:
→ seu@email.com
```

**Pronto!** O sistema irá:
1. Validar o DNS
2. Configurar Traefik com Let's Encrypt
3. Iniciar os containers
4. Obter certificado SSL (1-2 minutos)
5. Configurar renovação automática

---

## 🔄 Renovação Automática

### Como Funciona

O Traefik verifica os certificados **diariamente** e renova automaticamente quando faltam **30 dias** para expirar.

### Onde São Armazenados

```bash
/opt/openclaw/letsencrypt/acme.json
```

**⚠️ IMPORTANTE:** Este arquivo contém suas chaves privadas!
- Permissões: `600` (somente root)
- Backup recomendado

### Verificar Status

```bash
# Ver certificados ativos
docker exec openclaw-traefik cat /letsencrypt/acme.json | jq '.letsencrypt.Certificates'

# Logs do Traefik
docker logs openclaw-traefik | grep -i "cert\|acme"
```

---

## 🔧 Configuração Manual (se necessário)

Se você pulou a configuração durante a instalação:

```bash
cd /root/setup-openclaw/installer
sudo ./install.sh

# Escolha opção 3: Configure Proxy + SSL
```

---

## 🐛 Troubleshooting

### Certificado não emite

**Causa**: DNS não configurado ou portas bloqueadas

**Solução**:
```bash
# 1. Verificar DNS
dig +short openclaw.example.com
# Deve retornar seu IP público

# 2. Testar porta 80
curl -I http://openclaw.example.com
# Deve retornar resposta HTTP

# 3. Ver logs
docker logs openclaw-traefik
```

### Erro: "too many failed authorizations"

**Causa**: Muitas tentativas falhadas (limite do Let's Encrypt)

**Solução**:
1. Aguardar 1 hora
2. Corrigir DNS/firewall
3. Reiniciar Traefik:
   ```bash
   cd /opt/openclaw
   docker compose restart traefik
   ```

### Certificado expirou

**Causa**: Traefik não conseguiu renovar automaticamente

**Solução**:
```bash
# 1. Ver logs de erro
docker logs openclaw-traefik | grep -i error

# 2. Forçar renovação
docker compose restart traefik

# 3. Verificar após 2 minutos
docker logs openclaw-traefik | tail -50
```

---

## 📊 Monitoramento

### Dashboard Traefik

Acesse: `https://openclaw.example.com/dashboard/`

Mostra:
- Certificados ativos
- Data de expiração
- Status de renovação
- Rotas configuradas

### Logs

```bash
# Logs em tempo real
docker logs -f openclaw-traefik

# Últimos 100 logs
docker logs openclaw-traefik --tail 100

# Buscar por certificado
docker logs openclaw-traefik | grep "certificate"
```

### Alertas por Email

Let's Encrypt envia emails para o endereço configurado quando:
- Certificado vai expirar em 20 dias
- Certificado vai expirar em 10 dias
- Certificado vai expirar em 1 dia

**⚠️ Se receber esses emails, algo está errado com a renovação!**

---

## 🔐 Segurança

### Arquivo acme.json

```bash
# Verificar permissões
ls -l /opt/openclaw/letsencrypt/acme.json
# Deve ser: -rw------- (600)

# Corrigir se necessário
chmod 600 /opt/openclaw/letsencrypt/acme.json
```

### Backup

```bash
# Backup do certificado
sudo cp /opt/openclaw/letsencrypt/acme.json \
       /root/backup-acme-$(date +%Y%m%d).json

# Restaurar backup
sudo cp /root/backup-acme-YYYYMMDD.json \
       /opt/openclaw/letsencrypt/acme.json
sudo chmod 600 /opt/openclaw/letsencrypt/acme.json
docker compose restart traefik
```

---

## 📖 Referências

- **Traefik Docs**: https://doc.traefik.io/traefik/https/acme/
- **Let's Encrypt**: https://letsencrypt.org/how-it-works/
- **Rate Limits**: https://letsencrypt.org/docs/rate-limits/

---

## ❓ FAQ

**Q: Posso usar certificado próprio?**  
A: Sim, mas não recomendado. Let's Encrypt é grátis e automático.

**Q: Quanto tempo dura um certificado?**  
A: 90 dias. Renovação automática ocorre aos 60 dias.

**Q: Posso usar múltiplos domínios?**  
A: Sim, basta adicionar mais rotas no Traefik.

**Q: Funciona com subdomínios?**  
A: Sim! Ex: `api.openclaw.example.com`

**Q: Funciona offline?**  
A: Não. Let's Encrypt precisa validar o domínio online.

**Q: Há custo?**  
A: Não! Let's Encrypt é 100% gratuito.

---

**SetupOpenClaw v1.2.0** | SSL Automático com Let's Encrypt
