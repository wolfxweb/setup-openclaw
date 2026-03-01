#!/bin/bash

#======================================
# OpenClaw - Instalador Oficial v4
# Baseado 100% na documentação oficial
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
║   OpenClaw - Instalador Oficial      ║
║   Configuração Automática Completa   ║
╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${YELLOW}⚠️  Este instalador:${NC}"
echo "1. Usa o instalador oficial do OpenClaw (docker-setup.sh)"
echo "2. Requer interação manual para configuração OAuth"
echo "3. É a forma oficial e recomendada de instalar"
echo ""
read -p "Pressione ENTER para continuar..."

#======================================
# 1. Verificar Docker
#======================================
echo ""
echo -e "${YELLOW}[1/5]${NC} Verificando Docker..."

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker não encontrado!${NC}"
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}✓ Docker instalado${NC}"
else
    echo -e "${GREEN}✓ Docker já instalado${NC}"
fi

#======================================
# 2. Limpar instalação anterior
#======================================
echo -e "${YELLOW}[2/5]${NC} Limpando instalação anterior..."

# Parar todos containers OpenClaw
docker ps -a | grep openclaw | awk '{print $1}' | xargs -r docker stop 2>/dev/null || true
docker ps -a | grep openclaw | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

if [ -d "$HOME/.openclaw" ]; then
    rm -rf "$HOME/.openclaw"
fi

echo -e "${GREEN}✓ Limpeza concluída${NC}"

#======================================
# 3. Criar diretórios e permissões
#======================================
echo -e "${YELLOW}[3/5]${NC} Preparando ambiente..."

mkdir -p "$HOME/.openclaw"
chown -R 1000:1000 "$HOME/.openclaw"
chmod -R 755 "$HOME/.openclaw"

echo -e "${GREEN}✓ Ambiente preparado${NC}"

#======================================
# 4. Clonar OpenClaw oficial
#======================================
echo -e "${YELLOW}[4/5]${NC} Baixando OpenClaw oficial..."

cd "$HOME/.openclaw"
git clone --depth 1 https://github.com/OpenClaw/openclaw.git
cd openclaw

echo -e "${GREEN}✓ OpenClaw baixado${NC}"

#======================================
# 5. Executar instalador oficial
#======================================
echo -e "${YELLOW}[5/5]${NC} Executando instalador oficial do OpenClaw..."
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📋 INSTRUÇÕES:${NC}"
echo ""
echo "1. ${GREEN}Confirme o aviso de segurança${NC} (Yes)"
echo "2. ${GREEN}Escolha 'QuickStart'${NC} (use setas + ENTER)"
echo "3. ${GREEN}Selecione 'OpenAI'${NC} como provider"
echo "4. ${GREEN}Autorize no navegador${NC}"
echo "5. ${GREEN}Cole a URL de callback${NC} no terminal"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
sleep 3

# Executar o instalador oficial
bash docker-setup.sh

#======================================
# Finalização
#======================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Instalação concluída!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📋 Comandos úteis:${NC}"
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
echo "Dashboard:"
echo "  → openclaw dashboard"
echo ""
echo "Configurar:"
echo "  → docker compose run --rm openclaw-cli openclaw configure"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}💡 Documentação completa:${NC}"
echo "   https://docs.openclaw.ai"
echo ""
