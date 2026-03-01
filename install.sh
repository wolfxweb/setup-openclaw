#!/bin/bash

#======================================
# OpenClaw - Instalador Simples
# Apenas instala OpenClaw no Docker
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
║   OpenClaw - Instalador Simples      ║
║   Docker Setup - Sem Complicações    ║
╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"

#======================================
# 1. Verificar Docker
#======================================
echo -e "${YELLOW}[1/7]${NC} Verificando Docker..."

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
echo -e "${YELLOW}[2/7]${NC} Limpando instalação anterior..."

if [ -d "$HOME/.openclaw" ]; then
    echo "Removendo containers anteriores..."
    cd "$HOME/.openclaw" 2>/dev/null && docker compose down -v 2>/dev/null || true
    cd "$HOME"
    rm -rf "$HOME/.openclaw"
    echo -e "${GREEN}✓ Limpeza concluída${NC}"
else
    echo -e "${GREEN}✓ Nenhuma instalação anterior encontrada${NC}"
fi

#======================================
# 3. Criar diretórios
#======================================
echo -e "${YELLOW}[3/7]${NC} Criando diretórios..."

mkdir -p "$HOME/.openclaw"
mkdir -p "$HOME/.openclaw/workspace"
mkdir -p "$HOME/.openclaw/agents"

# Permissões corretas para Docker (user node = UID 1000)
chown -R 1000:1000 "$HOME/.openclaw"
chmod -R 755 "$HOME/.openclaw"

echo -e "${GREEN}✓ Diretórios criados${NC}"

#======================================
# 4. Criar .env seguro
#======================================
echo -e "${YELLOW}[4/7]${NC} Gerando credenciais seguras..."

GATEWAY_TOKEN=$(openssl rand -hex 32)

cat > "$HOME/.openclaw/.env" << EOF
# OpenClaw Gateway Token (Gerado automaticamente)
OPENCLAW_GATEWAY_TOKEN=${GATEWAY_TOKEN}

# Não compartilhe este arquivo!
EOF

chmod 600 "$HOME/.openclaw/.env"
chown 1000:1000 "$HOME/.openclaw/.env"

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

Arquivo .env: $HOME/.openclaw/.env
EOF

chmod 600 "$HOME/.openclaw-credentials.txt"

echo -e "${GREEN}✓ Credenciais geradas${NC}"

#======================================
# 5. Clonar e instalar OpenClaw
#======================================
echo -e "${YELLOW}[5/7]${NC} Baixando OpenClaw..."

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
# 6. Limpar cache do Docker (se necessário)
#======================================
echo -e "${YELLOW}[6/7]${NC} Verificando cache do Docker..."

# Verificar se há problemas com o cache
if docker builder ls 2>&1 | grep -q "default"; then
    echo -e "${YELLOW}⚠ Limpando cache do Docker para evitar erros...${NC}"
    docker builder prune -af --filter "until=1h" 2>/dev/null || true
    echo -e "${GREEN}✓ Cache limpo${NC}"
else
    echo -e "${GREEN}✓ Cache OK${NC}"
fi

#======================================
# 7. Executar setup do OpenClaw
#======================================
echo -e "${YELLOW}[7/7]${NC} Iniciando setup do OpenClaw..."
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}⚠️  ATENÇÃO - Siga as instruções:${NC}"
echo ""
echo "1. O wizard do OpenClaw vai abrir"
echo "2. Quando pedir URL de callback OAuth:"
echo "   ${GREEN}Use o IP desta VPS${NC}"
echo "   Exemplo: http://SEU_IP:1455"
echo ""
echo "3. Após autorizar na OpenAI:"
echo "   ${GREEN}Copie a URL completa do navegador${NC}"
echo "   ${GREEN}Cole no terminal quando solicitado${NC}"
echo ""
echo "4. Se o build falhar com erro de snapshot:"
echo "   ${YELLOW}Execute: docker builder prune -af${NC}"
echo "   ${YELLOW}E rode o instalador novamente${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -p "Pressione ENTER para continuar..."

# Garantir permissões antes do setup
chown -R 1000:1000 "$HOME/.openclaw"
chmod -R 755 "$HOME/.openclaw"

echo ""
echo -e "${GREEN}✓ Iniciando instalação do OpenClaw${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📋 INSTRUÇÕES IMPORTANTES:${NC}"
echo ""
echo -e "${GREEN}1. Confirmação de Segurança:${NC}"
echo "   → Responda: ${GREEN}Yes${NC} (Y)"
echo ""
echo -e "${GREEN}2. Modo de Configuração:${NC}"
echo "   → Escolha: ${GREEN}QuickStart${NC} (use setas ↑↓ + ENTER)"
echo ""
echo -e "${GREEN}3. Callback OAuth:${NC}"
echo "   → Digite o IP público desta VPS"
echo "   → Exemplo: ${BLUE}http://203.0.113.45:1455${NC}"
echo ""
echo -e "${GREEN}4. Após autorizar OpenAI:${NC}"
echo "   → Copie a URL do navegador"
echo "   → Cole no terminal"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
sleep 2

# Executar o setup oficial do OpenClaw
# Nota: O wizard requer interação manual com setas do teclado
bash docker-setup.sh || {
    echo ""
    echo -e "${RED}✗ Erro durante a instalação${NC}"
    echo -e "${YELLOW}Tente executar manualmente:${NC}"
    echo -e "${BLUE}cd ~/.openclaw/openclaw && bash docker-setup.sh${NC}"
    exit 1
}

#======================================
# Finalização
#======================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Instalação concluída!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📋 Informações importantes:${NC}"
echo ""
echo "Gateway Token salvo em:"
echo "  → $HOME/.openclaw-credentials.txt"
echo ""
echo "Verificar status:"
echo "  → cd ~/.openclaw/openclaw && docker compose ps"
echo ""
echo "Ver logs:"
echo "  → cd ~/.openclaw/openclaw && docker compose logs -f"
echo ""
echo "Parar:"
echo "  → cd ~/.openclaw/openclaw && docker compose down"
echo ""
echo "Iniciar:"
echo "  → cd ~/.openclaw/openclaw && docker compose up -d"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
