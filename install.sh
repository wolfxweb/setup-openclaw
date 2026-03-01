#!/bin/bash

#======================================
# OpenClaw - Instalador Simplificado v3
# 100% Automatizado - Zero Interação
#======================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════╗
║   OpenClaw - Instalador Automático   ║
║   Docker Setup - Zero Interação      ║
╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"

#======================================
# 1. Verificar Docker
#======================================
echo -e "${YELLOW}[1/8]${NC} Verificando Docker..."

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker não encontrado!${NC}"
    echo ""
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}✓ Docker instalado${NC}"
else
    echo -e "${GREEN}✓ Docker já instalado${NC}"
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose não encontrado!${NC}"
    echo "Instalando Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✓ Docker Compose instalado${NC}"
else
    echo -e "${GREEN}✓ Docker Compose já instalado${NC}"
fi

#======================================
# 2. Limpar instalação anterior
#======================================
echo -e "${YELLOW}[2/8]${NC} Limpando instalação anterior..."

if [ -d "$HOME/.openclaw" ]; then
    echo "Removendo containers anteriores..."
    cd "$HOME/.openclaw/openclaw" 2>/dev/null && docker compose down -v 2>/dev/null || true
    cd "$HOME"
    rm -rf "$HOME/.openclaw"
    echo -e "${GREEN}✓ Limpeza concluída${NC}"
else
    echo -e "${GREEN}✓ Nenhuma instalação anterior encontrada${NC}"
fi

#======================================
# 3. Criar diretórios
#======================================
echo -e "${YELLOW}[3/8]${NC} Criando diretórios..."

mkdir -p "$HOME/.openclaw"
mkdir -p "$HOME/.openclaw/workspace"
mkdir -p "$HOME/.openclaw/agents"

# Permissões corretas para Docker (user node = UID 1000)
chown -R 1000:1000 "$HOME/.openclaw"
chmod -R 755 "$HOME/.openclaw"

echo -e "${GREEN}✓ Diretórios criados${NC}"

#======================================
# 4. Gerar token seguro
#======================================
echo -e "${YELLOW}[4/8]${NC} Gerando credenciais seguras..."

GATEWAY_TOKEN=$(openssl rand -hex 32)

# Salvar token em local separado para usuário
cat > "$HOME/.openclaw-credentials.txt" << EOF
╔════════════════════════════════════════════╗
║  OpenClaw - Credenciais de Acesso         ║
╚════════════════════════════════════════════╝

Gateway Token: ${GATEWAY_TOKEN}

⚠️  IMPORTANTE:
- Guarde este token em local seguro
- Você precisará dele para conectar agentes
- Não compartilhe com ninguém

Configuração: $HOME/.openclaw/openclaw.json
EOF

chmod 600 "$HOME/.openclaw-credentials.txt"

echo -e "${GREEN}✓ Credenciais geradas${NC}"

#======================================
# 5. Clonar OpenClaw oficial
#======================================
echo -e "${YELLOW}[5/8]${NC} Baixando OpenClaw..."

cd "$HOME/.openclaw"

if [ ! -d "openclaw" ]; then
    git clone https://github.com/OpenClaw/openclaw.git
    cd openclaw
else
    cd openclaw
    git pull
fi

echo -e "${GREEN}✓ OpenClaw baixado${NC}"

#======================================
# 6. Limpar cache do Docker
#======================================
echo -e "${YELLOW}[6/8]${NC} Verificando cache do Docker..."

if docker builder ls 2>&1 | grep -q "default"; then
    echo -e "${YELLOW}⚠ Limpando cache do Docker para evitar erros...${NC}"
    docker builder prune -af --filter "until=1h" 2>/dev/null || true
    echo -e "${GREEN}✓ Cache limpo${NC}"
else
    echo -e "${GREEN}✓ Cache OK${NC}"
fi

#======================================
# 7. Build da imagem Docker
#======================================
echo -e "${YELLOW}[7/8]${NC} Compilando OpenClaw..."

export OPENCLAW_CONFIG_DIR="$HOME/.openclaw"
export OPENCLAW_WORKSPACE_DIR="$HOME/.openclaw/workspace"
export OPENCLAW_GATEWAY_PORT=18789
export OPENCLAW_GATEWAY_BIND=lan
export OPENCLAW_GATEWAY_TOKEN="$GATEWAY_TOKEN"
export OPENCLAW_IMAGE=openclaw:local

echo -e "${BLUE}Building Docker image: openclaw:local${NC}"
docker build -t openclaw:local -f Dockerfile . || {
    echo -e "${RED}✗ Erro no build do Docker${NC}"
    exit 1
}

echo -e "${GREEN}✓ Build concluído${NC}"

#======================================
# 8. Configurar OpenClaw (sem wizard)
#======================================
echo -e "${YELLOW}[8/8]${NC} Configurando OpenClaw automaticamente..."

# Criar arquivo de configuração diretamente
cat > "$HOME/.openclaw/openclaw.json" << JSONEOF
{
  "gateway": {
    "bind": "lan",
    "port": 18789,
    "auth": {
      "token": "$GATEWAY_TOKEN"
    },
    "controlUi": {
      "allowedOrigins": ["http://127.0.0.1:18789"]
    }
  },
  "workspace": {
    "root": "$HOME/.openclaw/workspace"
  },
  "agents": {
    "default": {
      "model": "openai:gpt-4"
    }
  }
}
JSONEOF

chmod 600 "$HOME/.openclaw/openclaw.json"
chown 1000:1000 "$HOME/.openclaw/openclaw.json"

echo -e "${GREEN}✓ Configuração criada${NC}"

# Criar arquivo .env para docker-compose
cat > .env << ENVEOF
OPENCLAW_CONFIG_DIR=$HOME/.openclaw
OPENCLAW_WORKSPACE_DIR=$HOME/.openclaw/workspace
OPENCLAW_GATEWAY_TOKEN=$GATEWAY_TOKEN
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_IMAGE=openclaw:local
ENVEOF

# Parar containers existentes
echo -e "${YELLOW}Limpando containers anteriores...${NC}"
docker compose down -v 2>/dev/null || true
docker stop openclaw-gateway 2>/dev/null || true
docker rm openclaw-gateway 2>/dev/null || true

# Criar docker-compose simplificado
cat > docker-compose.simple.yml << COMPOSEEOF
services:
  openclaw-gateway:
    image: openclaw:local
    container_name: openclaw-gateway
    restart: unless-stopped
    ports:
      - "127.0.0.1:18789:18789"
    volumes:
      - $HOME/.openclaw:/home/node/.openclaw:rw
    environment:
      OPENCLAW_CONFIG_DIR: /home/node/.openclaw
      OPENCLAW_WORKSPACE_DIR: /home/node/.openclaw/workspace
      OPENCLAW_GATEWAY_TOKEN: $GATEWAY_TOKEN
      OPENCLAW_GATEWAY_PORT: "18789"
      OPENCLAW_GATEWAY_BIND: lan
    user: "1000:1000"
    working_dir: /app
    command: ["node", "dist/index.js", "gateway", "--port", "18789", "--bind", "lan"]
COMPOSEEOF

echo -e "${BLUE}Iniciando gateway...${NC}"
docker compose -f docker-compose.simple.yml up -d

echo -e "${GREEN}✓ Gateway iniciado${NC}"

#======================================
# Finalização
#======================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Instalação concluída com sucesso!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📋 Informações importantes:${NC}"
echo ""
echo "Gateway Token salvo em:"
echo "  → $HOME/.openclaw-credentials.txt"
echo ""
echo "Verificar status:"
echo "  → docker ps | grep openclaw"
echo ""
echo "Ver logs:"
echo "  → docker logs -f openclaw-gateway"
echo ""
echo "Parar:"
echo "  → docker stop openclaw-gateway"
echo ""
echo "Iniciar:"
echo "  → docker start openclaw-gateway"
echo ""
echo "Acessar dashboard:"
echo "  → http://localhost:18789"
echo "  → Token: ${GATEWAY_TOKEN:0:16}..."
echo ""
echo -e "${YELLOW}⚠️  Próximos passos:${NC}"
echo "1. Configure providers (OpenAI, Anthropic, etc):"
echo "   → docker exec -it openclaw-gateway openclaw configure"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
