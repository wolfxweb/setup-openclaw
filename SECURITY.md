# 🔒 Guia de Segurança - OpenClaw

## 📋 Índice
- [Segurança Implementada](#segurança-implementada)
- [Configurações Recomendadas](#configurações-recomendadas)
- [Proteção de Credenciais](#proteção-de-credenciais)
- [Hardening do Sistema](#hardening-do-sistema)
- [Checklist de Segurança](#checklist-de-segurança)

---

## 🛡️ Segurança Implementada

### 1. Tokens Criptograficamente Seguros
```bash
# Token gerado com 32 bytes (256 bits)
GATEWAY_TOKEN=$(openssl rand -hex 32)
```
✅ Impossível de adivinhar por força bruta

### 2. Permissões Restritas
```bash
# Arquivo .env
chmod 600 ~/.openclaw/.env          # Apenas dono pode ler/escrever

# Credenciais
chmod 600 ~/.openclaw-credentials.txt  # Apenas dono pode ler/escrever

# Diretórios
chmod 755 ~/.openclaw/*             # Outros não podem modificar
```

### 3. Isolamento por Docker
✅ OpenClaw roda em containers isolados  
✅ Não tem acesso direto ao sistema host  
✅ Volumes montados com permissões específicas

### 4. Separação de Credenciais
✅ `.env` dentro do projeto (usado pelo Docker)  
✅ `.openclaw-credentials.txt` na home (backup para usuário)  
✅ Nenhum arquivo commitado no Git

---

## ⚙️ Configurações Recomendadas

### 1. Firewall (UFW)

```bash
# Instalar UFW
sudo apt install ufw -y

# Regras básicas
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir SSH (IMPORTANTE: ajuste a porta se necessário!)
sudo ufw allow 22/tcp

# Se usar OpenClaw externamente, permitir porta
sudo ufw allow 1455/tcp

# Ativar firewall
sudo ufw --force enable

# Verificar status
sudo ufw status verbose
```

⚠️ **ATENÇÃO**: Configure SSH ANTES de ativar o firewall!

### 2. SSH Hardening

Edite `/etc/ssh/sshd_config`:

```bash
# Desabilitar login root
PermitRootLogin no

# Usar apenas autenticação por chave
PasswordAuthentication no
PubkeyAuthentication yes

# Desabilitar X11 Forwarding (se não usar)
X11Forwarding no

# Limite de tentativas
MaxAuthTries 3

# Timeout de login
LoginGraceTime 60
```

Depois reinicie SSH:
```bash
sudo systemctl restart sshd
```

### 3. Fail2Ban (Proteção contra Brute Force)

```bash
# Instalar
sudo apt install fail2ban -y

# Configurar
sudo cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
EOF

# Iniciar
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Verificar status
sudo fail2ban-client status sshd
```

### 4. Updates Automáticos

```bash
# Instalar unattended-upgrades
sudo apt install unattended-upgrades -y

# Ativar
sudo dpkg-reconfigure -plow unattended-upgrades

# Configurar updates de segurança
sudo cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF
```

---

## 🔐 Proteção de Credenciais

### ✅ O que FAZER:

1. **Backup Seguro**
```bash
# Copiar credenciais para máquina local via SCP
scp root@SEU_IP:~/.openclaw-credentials.txt ~/backup-openclaw.txt

# Guardar em gerenciador de senhas (1Password, Bitwarden, etc)
```

2. **Rotação de Token**
```bash
# Gerar novo token
NEW_TOKEN=$(openssl rand -hex 32)

# Atualizar .env
echo "OPENCLAW_GATEWAY_TOKEN=$NEW_TOKEN" > ~/.openclaw/.env

# Reiniciar containers
cd ~/.openclaw/openclaw
docker compose restart
```

3. **Verificar Permissões**
```bash
# Verificar arquivos sensíveis
ls -la ~/.openclaw/.env
ls -la ~/.openclaw-credentials.txt

# Devem mostrar: -rw------- (600)
```

### ❌ O que NÃO FAZER:

- ❌ **NUNCA** commit `.env` no Git
- ❌ **NUNCA** compartilhe tokens em chat/email
- ❌ **NUNCA** use tokens fracos ou previsíveis
- ❌ **NUNCA** reutilize tokens de outros serviços
- ❌ **NUNCA** exponha porta 1455 publicamente sem necessidade

---

## 🔧 Hardening do Sistema

### 1. Desabilitar Serviços Desnecessários

```bash
# Listar serviços ativos
systemctl list-units --type=service --state=running

# Desabilitar exemplos (ajuste conforme necessidade)
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable avahi-daemon
```

### 2. Configurar Limites de Recursos

Edite `/etc/security/limits.conf`:

```bash
# Limite de processos
* soft nproc 1024
* hard nproc 2048

# Limite de arquivos abertos
* soft nofile 4096
* hard nofile 8192
```

### 3. Auditoria de Logs

```bash
# Ver tentativas de login SSH
sudo grep "Failed password" /var/log/auth.log

# Ver comandos sudo executados
sudo grep "COMMAND" /var/log/auth.log

# Ver logs do Docker
sudo journalctl -u docker.service
```

### 4. Backup Regular

```bash
# Script de backup simples
cat > ~/backup-openclaw.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/openclaw/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup de configurações
cp -r ~/.openclaw/openclaw/docker-compose.yml "$BACKUP_DIR/"
cp ~/.openclaw/.env "$BACKUP_DIR/"
cp ~/.openclaw-credentials.txt "$BACKUP_DIR/"

# Backup de workspace (opcional - pode ser grande)
# tar -czf "$BACKUP_DIR/workspace.tar.gz" ~/.openclaw/workspace/

echo "Backup concluído: $BACKUP_DIR"
EOF

chmod +x ~/backup-openclaw.sh
```

---

## ✅ Checklist de Segurança

### Instalação Inicial
- [ ] Token gerado automaticamente (32 bytes)
- [ ] Arquivo `.env` com permissão 600
- [ ] Credenciais salvas em local separado
- [ ] `.env` adicionado ao `.gitignore`

### Configuração de Rede
- [ ] Firewall UFW ativo
- [ ] SSH configurado corretamente
- [ ] Portas desnecessárias fechadas
- [ ] Fail2Ban ativo

### Sistema
- [ ] Root login SSH desabilitado
- [ ] Autenticação por senha SSH desabilitada
- [ ] Updates automáticos configurados
- [ ] Serviços desnecessários desabilitados

### Monitoramento
- [ ] Logs sendo auditados regularmente
- [ ] Backup automático configurado
- [ ] Alertas de segurança configurados (opcional)

### Docker
- [ ] Containers rodando com usuário não-root
- [ ] Volumes montados com permissões corretas
- [ ] Rede Docker isolada
- [ ] Imagens atualizadas regularmente

---

## 🚨 Em Caso de Comprometimento

1. **Parar imediatamente**
```bash
cd ~/.openclaw/openclaw
docker compose down
```

2. **Rotacionar credenciais**
```bash
# Gerar novo token
openssl rand -hex 32 > ~/.openclaw/.env-new
# Atualizar manualmente o arquivo .env
```

3. **Investigar logs**
```bash
# Logs do Docker
docker compose logs > ~/incident-docker-logs.txt

# Logs do sistema
sudo journalctl -xe > ~/incident-system-logs.txt

# Logs de autenticação
sudo cat /var/log/auth.log > ~/incident-auth-logs.txt
```

4. **Bloquear acesso**
```bash
# Bloquear IP suspeito
sudo ufw deny from IP_SUSPEITO
```

5. **Reinstalar se necessário**
```bash
# Backup de dados importantes primeiro!
cd ~/.openclaw/openclaw
docker compose down -v
cd ~
rm -rf ~/.openclaw
# Executar instalador novamente
```

---

## 📚 Referências

- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [SSH Hardening Guide](https://www.ssh.com/academy/ssh/sshd_config)
- [UFW Firewall](https://help.ubuntu.com/community/UFW)
- [Fail2Ban Documentation](https://www.fail2ban.org/wiki/index.php/Main_Page)

---

## 💡 Dicas Extras

1. **Use VPN**: Considere acessar via VPN em vez de expor SSH publicamente
2. **2FA**: Configure autenticação de dois fatores quando possível
3. **Monitore**: Use ferramentas como Netdata ou Grafana para monitoramento
4. **Teste**: Simule ataques com ferramentas como `nmap` para verificar exposição

---

**Lembre-se**: Segurança é um processo contínuo, não uma configuração única! 🔐
