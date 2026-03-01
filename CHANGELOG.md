# Changelog

## v2.0.0 - Instalador Simplificado (2026-02-14)

### 🎯 Foco: Simplicidade e Essencial

#### ✅ Adicionado
- Instalador único e direto (`install.sh`)
- Geração automática de token seguro
- Configuração automática de permissões
- Instruções claras no terminal
- Documentação simplificada

#### ❌ Removido
- Sistema complexo de instalação modular
- Painel web administrativo
- Configuração de SSL/Traefik
- Configuração de firewall UFW
- Menus interativos (whiptail)
- Validação de DNS
- Interface X11
- Múltiplos arquivos de documentação

#### 🎨 Melhorado
- README.md completamente reescrito
- Foco apenas em Docker
- Processo de instalação linear
- Mensagens de erro mais claras

---

## v1.2.0 - Wizard Interativo + SSL Automático (2026-02-13)

### Removido na v2.0.0
- Wizard interativo com detecção de IP
- Configuração automática de domínio
- SSL com Let's Encrypt
- Painel web com autenticação
- Sistema modular de bibliotecas

---

## v1.1.0 - Segurança Aprimorada (2026-02-12)

### Removido na v2.0.0
- Rate limiting
- Validação de senha forte
- Proteção de sessão
- Logs de segurança
- Hardening SSH

---

## v1.0.0 - Lançamento Inicial (2026-02-11)

### Removido na v2.0.0
- Instalador modular com bibliotecas
- Painel web FastAPI + HTMX
- Configuração de proxy reverso
- Gerenciamento de firewall
