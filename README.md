# 🚀 OpenClaw - Instalador Oficial Simplificado

Instalador wrapper que facilita o uso do instalador oficial do OpenClaw.

## ✨ O que este instalador faz

- ✅ Verifica e instala Docker automaticamente
- ✅ Limpa instalações anteriores
- ✅ Prepara o ambiente (diretórios e permissões)
- ✅ Clona o repositório oficial do OpenClaw
- ✅ **Executa o instalador oficial** (`docker-setup.sh`)
- ✅ Fornece instruções claras durante o processo

## ⚠️ Importante

Este instalador **usa o instalador oficial do OpenClaw** sem modificações.  
Você precisará **interagir manualmente** com o wizard para configurar OAuth.

---

## 🎯 Instalação Rápida

### Método 1: Download direto (recomendado)

```bash
curl -fsSL https://raw.githubusercontent.com/wolfxweb/setup-openclaw/main/install.sh | bash
```

### Método 2: Clone o repositório

```bash
git clone https://github.com/wolfxweb/setup-openclaw.git
cd setup-openclaw
bash install.sh
```

---

## 📋 Durante a Instalação

O wizard oficial do OpenClaw vai pedir:

1. **Confirmação de Segurança**
   - Responda: `Yes` (Y)

2. **Modo de Configuração**
   - Escolha: `QuickStart` (use setas ↑↓ + ENTER)

3. **AI Providers**
   - Selecione: `OpenAI` (use ESPAÇO para marcar, ENTER para continuar)

4. **OAuth**
   - Autorize no navegador
   - Cole a URL de callback no terminal

---

## 🔑 Após a Instalação

### Verificar status:

```bash
cd ~/.openclaw/openclaw
docker compose ps
```

### Ver logs:

```bash
cd ~/.openclaw/openclaw
docker compose logs -f
```

### Parar OpenClaw:

```bash
cd ~/.openclaw/openclaw
docker compose down
```

### Iniciar OpenClaw:

```bash
cd ~/.openclaw/openclaw
docker compose up -d
```

### Acessar Dashboard:

```bash
cd ~/.openclaw/openclaw
docker compose run --rm openclaw-cli openclaw dashboard
```

---

## 🗑️ Desinstalar

```bash
cd ~/.openclaw/openclaw
docker compose down -v
cd ~
rm -rf ~/.openclaw
```

---

## 📚 Documentação

### 🏗️ Como Funciona Este Instalador?
📘 **Leia**: [COMO_FUNCIONA.md](COMO_FUNCIONA.md) - Explica a arquitetura completa

**TL;DR**: Este instalador:
1. Prepara o ambiente (Docker, diretórios, permissões)
2. Clona o repositório oficial do OpenClaw
3. Executa o `docker-setup.sh` oficial
4. **Não modifica nada** do código oficial!

### OpenClaw Oficial
- [OpenClaw GitHub](https://github.com/OpenClaw/openclaw)
- [Documentação OpenClaw](https://docs.openclaw.ai)
- [Instalação Docker Oficial](https://docs.openclaw.ai/install/docker)

---

## 🔒 Segurança

### Implementado pelo OpenClaw Oficial:
- ✅ Token gateway gerado automaticamente
- ✅ Arquivo de configuração com permissões corretas
- ✅ Containers isolados
- ✅ Autenticação por token

### Guia Completo:
📖 Veja [SECURITY.md](SECURITY.md) para guia completo de segurança

### Recomendações:

**⚠️ Configure o Firewall:**
```bash
sudo apt install ufw -y
sudo ufw allow 22/tcp
sudo ufw --force enable
```

---

## 🆘 Problemas Comuns

### Erro de permissão Docker

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Containers não iniciam

```bash
cd ~/.openclaw/openclaw
docker compose logs
```

### Reinstalar

```bash
curl -fsSL https://raw.githubusercontent.com/wolfxweb/setup-openclaw/main/install.sh | bash
```

---

## 💡 Por Que Usar Este Instalador?

### Vantagens

✅ **Simplicidade**: Prepara tudo automaticamente  
✅ **Oficial**: Usa o instalador oficial do OpenClaw  
✅ **Sem Modificações**: Não altera o código original  
✅ **Instruções Claras**: Guia passo a passo  
✅ **Limpeza Automática**: Remove instalações anteriores  

---

## 📝 Licença

MIT License - Veja [LICENSE](LICENSE) para detalhes.

---

## ⭐ Sobre

Este é um wrapper não-oficial que facilita o uso do instalador oficial do OpenClaw.  
OpenClaw é desenvolvido por [OpenClaw Team](https://github.com/OpenClaw/openclaw).

**Versão**: 4.0.0 - Wrapper do Instalador Oficial  
**Autor**: wolfxweb  
**Repositório**: https://github.com/wolfxweb/setup-openclaw
