# SetupOpenClaw

Sistema profissional de instalação automatizada do **OpenClaw** via Docker, com painel web administrativo.

## 🎯 Características

- ✅ **Instalação 100% Docker** - Segue exatamente o fluxo oficial do repositório OpenClaw
- ✅ **Wizard Interativo** - Não automatiza respostas, mantém a experiência original
- ✅ **Proxy Traefik + SSL** - HTTPS automático com Let's Encrypt
- ✅ **Painel Web** - Interface FastAPI + HTMX para gerenciar remotamente
- ✅ **Seguro** - BasicAuth, firewall UFW, execução controlada
- ✅ **Idempotente** - Pode ser executado múltiplas vezes sem problemas

## 📋 Requisitos

- **OS**: Ubuntu 22.04/24.04 ou Debian 12
- **RAM**: Mínimo 2GB (recomendado 4GB+)
- **Disco**: Mínimo 20GB livre
- **Acesso**: Root (sudo)
- **Internet**: Conexão estável

## 🚀 Instalação Rápida

### Opção 1: Script Direto (curl)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/seu-repo/setup-openclaw/main/installer/install.sh)
```

### Opção 2: Clone Manual

```bash
# Clone o repositório
git clone https://github.com/seu-repo/setup-openclaw.git /root/setup-openclaw

# Execute o instalador
cd /root/setup-openclaw/installer
sudo ./install.sh
```

## 📦 Instalação do Painel Web

O painel web permite gerenciar a instalação remotamente via navegador.

```bash
cd /root/setup-openclaw/panel

# Configure credenciais (opcional)
export PANEL_USER=admin
export PANEL_PASSWORD=suasenha123

# Inicie o painel
docker compose up -d
```

Acesse: `http://SEU_IP:8080`

**Credenciais padrão**: `admin` / `changeme`

## 🏗️ Arquitetura

```
┌─────────────┐         ┌──────────────┐
│   Usuário   │ ◄────── │  Painel Web  │
│             │         │  (Port 8080) │
└─────────────┘         └───────┬──────┘
                                │
                                ▼
                        ┌──────────────┐
                        │  install.sh  │
                        └───────┬──────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐      ┌──────────────┐      ┌─────────────┐
│   Docker      │      │   OpenClaw   │      │   Traefik   │
│  Installation │      │  (Gateway)   │      │  (Proxy)    │
└───────────────┘      └──────────────┘      └─────────────┘
                              │
                              ▼
                       ┌──────────────┐
                       │   Port 18789 │
                       └──────────────┘
```

## 📚 Funcionalidades do Instalador

### Menu Interativo

1. **Instalar/Reinstalar OpenClaw**
   - Verifica requisitos do sistema
   - Instala dependências base
   - Instala Docker oficial
   - Clona repositório OpenClaw
   - Executa `./docker-setup.sh` (wizard interativo)

2. **Atualizar OpenClaw**
   - Git pull da última versão
   - Rebuild da imagem Docker
   - Restart dos containers

3. **Configurar Proxy + SSL**
   - Solicita domínio
   - Valida DNS (A/AAAA record)
   - Gera `docker-compose.proxy.yml` com Traefik
   - Certificado SSL automático (Let's Encrypt)
   - Expõe apenas portas 80/443

4. **Configurar Autenticação Web**
   - Solicita usuário/senha
   - Gera hash BCrypt
   - Configura BasicAuth no Traefik

5. **Configurar Firewall (UFW)**
   - Libera porta SSH
   - Libera portas 80/443 (se proxy ativo)
   - Opção de liberar porta 18789 (acesso direto)

6. **Status & Logs**
   - Status dos containers
   - Test de conectividade (curl)
   - Últimos 50 logs do gateway

7. **Desinstalar**
   - Confirmação com "EXCLUIR"
   - Para e remove containers
   - Opção de remover diretório
   - Opção de remover Docker

### Modo Não-Interativo (para Painel)

```bash
sudo ./install.sh --action install
sudo ./install.sh --action update
sudo ./install.sh --action proxy
sudo ./install.sh --action webauth
sudo ./install.sh --action ufw
sudo ./install.sh --action status
sudo ./install.sh --action uninstall
```

## 🔒 Segurança

### Painel Web

- Autenticação por sessão
- Whitelist estrita de comandos
- `subprocess.run()` sem `shell=True`
- Timeout de 10 minutos por comando

### Sudoers (Produção)

Para executar o painel sem root completo:

```bash
# Criar usuário específico
useradd -m -s /bin/bash setup-panel

# Configurar sudoers
cat << 'EOF' > /etc/sudoers.d/setup-openclaw
setup-panel ALL=(ALL) NOPASSWD: /root/setup-openclaw/installer/install.sh --action *
EOF

chmod 440 /etc/sudoers.d/setup-openclaw

# Ajustar docker-compose.yml do painel
# Mudar volumes de /root/setup-openclaw para /opt/setup-openclaw
```

### Firewall

```bash
# Liberar apenas o necessário
ufw allow 22/tcp      # SSH
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS
ufw allow 8080/tcp    # Painel (opcional, use VPN/Tailscale)
ufw enable
```

### Proxy com BasicAuth

```bash
# Proteger acesso ao OpenClaw
./install.sh
# Escolha opção 4: Configurar Web Authentication
```

## 🔧 Configuração Avançada

### Variáveis de Ambiente (Painel)

Crie `.env` em `/root/setup-openclaw/panel/`:

```bash
PANEL_USER=admin
PANEL_PASSWORD=senhasegura123
SECRET_KEY=chave-secreta-aleatoria-aqui
```

### Template Traefik Customizado

Edite `installer/templates/docker-compose.proxy.yml.tpl`:

```yaml
# Adicionar middlewares, rate limiting, etc.
```

### DNS Wildcard

Para subdomínios automáticos:

```
*.openclaw.example.com → IP_VPS
```

## 📊 Logs

- **Instalador**: `/var/log/setup-openclaw/install.log`
- **Gateway**: `cd /opt/openclaw && docker compose logs`
- **Traefik**: `docker logs openclaw-traefik`

## 🔄 Atualização

### Atualizar SetupOpenClaw

```bash
cd /root/setup-openclaw
git pull origin main

# Reconstruir painel
cd panel
docker compose build
docker compose up -d
```

### Atualizar OpenClaw

Via painel ou:

```bash
sudo ./install.sh --action update
```

## 🗑️ Desinstalação

### Remover OpenClaw

```bash
sudo ./install.sh --action uninstall
```

### Remover Painel

```bash
cd /root/setup-openclaw/panel
docker compose down -v
```

### Remover Tudo

```bash
# Desinstalar OpenClaw
sudo /root/setup-openclaw/installer/install.sh --action uninstall

# Parar painel
cd /root/setup-openclaw/panel && docker compose down -v

# Remover diretórios
rm -rf /root/setup-openclaw
rm -rf /opt/openclaw

# Opcional: remover Docker
apt-get remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

## 🐛 Troubleshooting

### Gateway não inicia

```bash
cd /opt/openclaw
docker compose logs openclaw-gateway
```

### SSL não provisiona

- Verifique DNS: `dig +short seudominio.com`
- Aguarde 1-2 minutos
- Veja logs: `docker logs openclaw-traefik`

### Painel não conecta

```bash
# Verificar se está rodando
docker ps | grep panel

# Ver logs
cd /root/setup-openclaw/panel
docker compose logs -f
```

### Porta 18789 em uso

```bash
# Ver o que está usando
ss -tlnp | grep 18789

# Se for OpenClaw antigo
docker ps -a | grep openclaw
docker rm -f $(docker ps -aq -f name=openclaw)
```

## 📞 Suporte

- **Repositório OpenClaw**: https://github.com/openclaw/openclaw
- **Documentação**: https://docs.openclaw.ai
- **Issues**: https://github.com/seu-repo/setup-openclaw/issues

## 📄 Licença

MIT License - veja `LICENSE`

## 🙏 Créditos

- **OpenClaw**: https://openclaw.ai
- **Traefik**: https://traefik.io
- **FastAPI**: https://fastapi.tiangolo.com
- **HTMX**: https://htmx.org

---

**SetupOpenClaw v1.0.0** | Sistema profissional de instalação Docker para OpenClaw
