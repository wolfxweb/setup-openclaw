#!/bin/bash

#======================================
# OpenClaw - Instalador Oficial v4.2
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
# 3. Criar diretórios e permissões (IMPORTANTE!)
#======================================
echo -e "${YELLOW}[3/5]${NC} Preparando ambiente..."

# Criar estrutura completa de diretórios
mkdir -p "$HOME/.openclaw/workspace"
mkdir -p "$HOME/.openclaw/workspace/.agents"

# Definir permissões ANTES do wizard
chown -R 1000:1000 "$HOME/.openclaw"
chmod -R 755 "$HOME/.openclaw"

echo -e "${GREEN}✓ Ambiente preparado (workspace + permissões)${NC}"

#======================================
# 4. Clonar OpenClaw oficial
#======================================
echo -e "${YELLOW}[4/5]${NC} Baixando OpenClaw oficial..."

cd "$HOME/.openclaw"
git clone --depth 1 https://github.com/OpenClaw/openclaw.git
cd openclaw

echo -e "${GREEN}✓ OpenClaw baixado${NC}"

#======================================
# 5. Build da imagem Docker (antes do wizard)
#======================================
echo -e "${YELLOW}[5/7]${NC} Compilando OpenClaw (isso pode demorar 3-5 minutos)..."

# Fazer build da imagem antes do wizard
docker build -t openclaw:local -f Dockerfile . || {
    echo -e "${RED}✗ Erro no build do Docker${NC}"
    exit 1
}

echo -e "${GREEN}✓ OpenClaw compilado${NC}"

#======================================
# 6. Configurar e iniciar (wizard interativo)
#======================================
echo -e "${YELLOW}[6/7]${NC} Configurando OpenClaw..."
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📋 INSTRUÇÕES DO WIZARD:${NC}"
echo ""
echo "1. ${GREEN}Confirme o aviso de segurança${NC} (Yes)"
echo "2. ${GREEN}Escolha 'QuickStart'${NC} (use setas + ENTER)"
echo "3. ${GREEN}Selecione 'OpenAI'${NC} como provider"
echo "4. ${GREEN}Autorize no navegador${NC}"
echo "5. ${GREEN}Cole a URL de callback${NC} no terminal"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verificar se está rodando via pipe (curl | bash)
if [ ! -t 0 ]; then
    # Rodando via pipe - não pode ser interativo
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  DETECTADO: Instalação via pipe (curl | bash)${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "✓ Build concluído! Agora precisa de terminal interativo."
    echo ""
    echo -e "${GREEN}Para completar, execute:${NC}"
    echo ""
    echo -e "${BLUE}  cd ~/.openclaw/openclaw && bash docker-setup.sh${NC}"
    echo ""
    echo "O wizard vai começar direto (build já foi feito!)"
    echo ""
    exit 0
fi

# Terminal interativo - pode rodar o wizard
# Como já fizemos o build, o docker-setup.sh vai pular essa etapa
export OPENCLAW_IMAGE=openclaw:local
bash docker-setup.sh

#======================================
# 7. Detectar IP e configurar acesso remoto
#======================================
echo ""
echo -e "${YELLOW}[7/7]${NC} Configurando acesso remoto..."

PUBLIC_IP=$(curl -s -4 https://ifconfig.me 2>/dev/null || curl -s -4 https://api.ipify.org 2>/dev/null || echo "")

if [ -n "$PUBLIC_IP" ]; then
    echo -e "${GREEN}✓ IP público detectado: $PUBLIC_IP${NC}"
    
    # Verificar se openclaw.json existe
    if [ -f "$HOME/.openclaw/openclaw.json" ]; then
        # Criar backup
        cp "$HOME/.openclaw/openclaw.json" "$HOME/.openclaw/openclaw.json.backup"
        
        # Adicionar allowedOrigins com o IP público
        python3 << PYTHONEOF
import json
import sys

try:
    with open('$HOME/.openclaw/openclaw.json', 'r') as f:
        config = json.load(f)
    
    # Garantir que a estrutura existe
    if 'gateway' not in config:
        config['gateway'] = {}
    if 'controlUi' not in config['gateway']:
        config['gateway']['controlUi'] = {}
    if 'allowedOrigins' not in config['gateway']['controlUi']:
        config['gateway']['controlUi']['allowedOrigins'] = []
    
    # Adicionar origens permitidas
    origins = config['gateway']['controlUi']['allowedOrigins']
    new_origins = [
        "http://$PUBLIC_IP:18789",
        "https://$PUBLIC_IP:18789",
        "http://127.0.0.1:18789"
    ]
    
    for origin in new_origins:
        if origin not in origins:
            origins.append(origin)
    
    # Mudar bind de loopback para all (para aceitar conexões externas)
    config['gateway']['bind'] = 'all'
    
    with open('$HOME/.openclaw/openclaw.json', 'w') as f:
        json.dump(config, f, indent=2)
    
    print("✓ Configuração atualizada")
    sys.exit(0)
except Exception as e:
    print(f"✗ Erro: {e}")
    sys.exit(1)
PYTHONEOF
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Acesso remoto configurado${NC}"
            
            # Reiniciar gateway para aplicar mudanças
            echo -e "${YELLOW}Reiniciando gateway...${NC}"
            cd "$HOME/.openclaw/openclaw"
            docker compose restart openclaw-gateway
            sleep 3
            echo -e "${GREEN}✓ Gateway reiniciado${NC}"
        else
            echo -e "${YELLOW}⚠ Não foi possível configurar automaticamente${NC}"
            echo -e "${YELLOW}Configure manualmente em ~/.openclaw/openclaw.json:${NC}"
            echo ""
            echo "  \"gateway\": {"
            echo "    \"bind\": \"all\","
            echo "    \"controlUi\": {"
            echo "      \"allowedOrigins\": ["
            echo "        \"http://$PUBLIC_IP:18789\","
            echo "        \"http://127.0.0.1:18789\""
            echo "      ]"
            echo "    }"
            echo "  }"
        fi
    else
        echo -e "${YELLOW}⚠ openclaw.json não encontrado${NC}"
        echo "Execute o wizard primeiro com: cd ~/.openclaw/openclaw && bash docker-setup.sh"
    fi
else
    echo -e "${YELLOW}⚠ Não foi possível detectar o IP público${NC}"
fi

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
