# SetupOpenClaw - Guia de Segurança

## 🔒 Visão Geral de Segurança

Este guia detalha todas as medidas de segurança implementadas e recomendações para uso em produção.

## ✅ Melhorias de Segurança Implementadas (v1.1.0)

### 1. **Rate Limiting**
- ✅ Limite de 5 tentativas de login por IP (bloqueio de 5 minutos)
- ✅ Limite de 10 ações por minuto por usuário
- ✅ Proteção contra brute force automático
- ✅ Logs de tentativas bloqueadas

### 2. **Validação de Senha Forte**
- ✅ Mínimo 12 caracteres
- ✅ Pelo menos 1 maiúscula
- ✅ Pelo menos 1 minúscula
- ✅ Pelo menos 1 número
- ✅ Pelo menos 1 caractere especial

### 3. **Proteção de Sessão**
- ✅ Verificação de mudança de IP
- ✅ Timeout de sessão (1 hora)
- ✅ Secret key auto-gerada se não configurada
- ✅ Tokens de sessão seguros

### 4. **Logs de Segurança**
- ✅ Log de todas tentativas de login
- ✅ Log de ações executadas
- ✅ Log de bloqueios por rate limit
- ✅ Hashing de IPs nos logs (privacidade)
- ✅ Arquivo: `/var/log/setup-openclaw/security.log`

### 5. **Firewall Aprimorado**
- ✅ Configuração default deny
- ✅ Rate limiting no SSH
- ✅ Opção de bloquear porta 8080 externamente
- ✅ Suporte a Fail2Ban
- ✅ SSH hardening automático

### 6. **Sanitização de Entrada**
- ✅ Remoção de caracteres de controle
- ✅ Limite de comprimento de inputs
- ✅ Validação de tokens de sessão

## 🛡️ Configuração Recomendada para Produção

### Passo 1: Firewall Restritivo

```bash
# Executar instalador
sudo /root/setup-openclaw/installer/install.sh

# Escolher opção 5: Configurar Firewall
# - SSH: escolha porta não-padrão (ex: 2222)
# - Bloquear porta 8080 externamente: SIM
# - Não permitir porta 18789 direta

# Instalar Fail2Ban (proteção brute force)
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Passo 2: SSH Hardening

```bash
# Editar /etc/ssh/sshd_config
sudo nano /etc/ssh/sshd_config

# Aplicar estas configurações:
Port 2222                          # Mudar porta SSH
PermitRootLogin prohibit-password  # Apenas chaves SSH
PasswordAuthentication no          # Desabilitar senhas
MaxAuthTries 3                     # Limitar tentativas
AllowUsers seu-usuario             # Apenas usuários específicos

# Reiniciar SSH
sudo systemctl restart sshd
```

### Passo 3: Acesso ao Painel Apenas via SSH Tunnel

```bash
# No seu computador local:
ssh -L 8080:localhost:8080 -p 2222 usuario@SEU_SERVIDOR

# Acesse o painel em:
http://localhost:8080

# Nunca exponha porta 8080 publicamente!
```

### Passo 4: Credenciais Fortes

```bash
# Configurar credenciais fortes para o painel
cd /root/setup-openclaw/panel

# Criar arquivo .env com senha forte
cat > .env << 'ENVFILE'
PANEL_USER=admin_$(openssl rand -hex 4)
PANEL_PASSWORD=$(openssl rand -base64 24)
SECRET_KEY=$(openssl rand -base64 32)
ENVFILE

# Aplicar
docker compose down
docker compose up -d
```

### Passo 5: HTTPS Obrigatório (Traefik)

```bash
# Configurar proxy SSL
sudo /root/setup-openclaw/installer/install.sh
# Opção 3: Configurar Proxy + SSL

# Depois, configurar autenticação
# Opção 4: Configurar Web Authentication
```

### Passo 6: Monitoramento

```bash
# Monitorar logs de segurança
tail -f /var/log/setup-openclaw/security.log

# Monitorar firewall
tail -f /var/log/ufw.log

# Monitorar Fail2Ban
fail2ban-client status sshd
```

## 🚨 Checklist de Segurança

### Antes de Colocar em Produção

- [ ] Firewall UFW configurado (default deny)
- [ ] Porta 8080 bloqueada externamente
- [ ] SSH em porta não-padrão
- [ ] SSH com chaves (senha desabilitada)
- [ ] Fail2Ban instalado e ativo
- [ ] Painel acessível apenas via SSH tunnel
- [ ] Senha forte configurada (mín. 12 caracteres)
- [ ] HTTPS configurado via Traefik
- [ ] Logs de segurança habilitados
- [ ] Backups automáticos configurados
- [ ] Monitoramento de logs ativo

### Manutenção Regular

- [ ] Revisar logs de segurança semanalmente
- [ ] Atualizar sistema: `apt update && apt upgrade`
- [ ] Atualizar OpenClaw: via painel ou CLI
- [ ] Rotar logs: configurar logrotate
- [ ] Testar backups mensalmente
- [ ] Revogar acessos não utilizados

## 🔐 Gestão de Secrets

### Variáveis de Ambiente Seguras

```bash
# Nunca commite secrets!
# Use .env files com permissões restritas:

chmod 600 /root/setup-openclaw/panel/.env
chmod 600 /opt/openclaw/.env
chmod 600 /opt/openclaw/.setupopenclaw.env

# Exemplo .env seguro:
cat > .env << 'EOF'
PANEL_USER=admin_$(uuidgen | cut -d- -f1)
PANEL_PASSWORD=$(openssl rand -base64 32)
SECRET_KEY=$(openssl rand -base64 48)
