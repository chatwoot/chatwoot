# Instalação de Dependências - Chatwoot-FazerAI

Este documento fornece instruções específicas para instalar as dependências do projeto no seu sistema operacional.

## ✅ Status do Seu Sistema

Verificamos sua máquina e encontramos:

| Ferramenta | Versão      | Status      |
| ---------- | ----------- | ----------- |
| Ruby       | 3.4.4       | ✅ OK       |
| Node.js    | v24.13.0    | ✅ OK       |
| pnpm       | 10.2.0      | ✅ OK       |
| PostgreSQL | 16.13       | ✅ OK       |
| Redis      | NOT FOUND   | ❌ INSTALAR |
| Docker     | Not checked | -           |

---

## 🔴 Instalar Redis

### No Ubuntu/Debian (Recomendado)

```bash
# Atualizar lista de pacotes
sudo apt-get update

# Instalar Redis server
sudo apt-get install -y redis-server redis-tools

# Iniciar o serviço
sudo systemctl start redis-server

# Ativar para iniciar automaticamente
sudo systemctl enable redis-server

# Verificar se está rodando
redis-cli ping
# Saída esperada: PONG
```

### No macOS (Homebrew)

```bash
# Instalar Redis
brew install redis

# Iniciar o serviço
brew services start redis

# Verificar se está rodando
redis-cli ping
# Saída esperada: PONG
```

### Via Docker (Alternativa)

Se preferir usar Docker (recomendado para evitar instalação local):

```bash
# Usar docker-compose para iniciar apenas Redis
docker-compose -f docker-compose.dev.yaml up -d redis

# Verificar
redis-cli ping
```

---

## 📥 Instalar Docker (Opcional, mas Recomendado)

### No Ubuntu/Debian

```bash
# Instalação rápida (oficial Docker)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adicionar seu usuário ao grupo docker
sudo usermod -aG docker $USER

# Ativar grupo sem fazer logout
newgrp docker

# Verificar
docker --version
docker-compose --version
```

### No macOS

```bash
# Com Homebrew
brew install docker docker-compose

# Ou baixar Docker Desktop
# https://www.docker.com/products/docker-desktop
```

---

## 🚀 Próximos Passos

Após instalar Redis (e opcionalmente Docker):

### A. Via Setup Script (Automático)

```bash
cd /home/lvkdev/Documentos/GitHub/chatwoot-fazerai
chmod +x setup-dev.sh
./setup-dev.sh
pnpm dev
```

### B. Via Docker Compose (Recomendado)

```bash
cd /home/lvkdev/Documentos/GitHub/chatwoot-fazerai
docker-compose -f docker-compose.dev.yaml up -d
bundle install && pnpm install
bundle exec rails db:create db:migrate
pnpm dev
```

### C. Via Make

```bash
cd /home/lvkdev/Documentos/GitHub/chatwoot-fazerai
make setup-local
make dev
```

---

## ✅ Verificação Final

Após instalar Redis, execute:

```bash
redis-cli ping
# Esperado: PONG

psql -U postgres -c "SELECT version();"
# Esperado: PostgreSQL 16.x

ruby -v
# Esperado: ruby 3.4.4

node -v
# Esperado: v24.13.0
```

Se todos os comandos retornarem OK, você está pronto para:

```bash
./setup-dev.sh
# ou
make setup-local
```

---

## 🆘 Problemas?

### Redis: "redis-cli: command not found"

```bash
# Instalar apenas redis-tools
sudo apt-get install redis-tools
```

### PostgreSQL: "psql: command not found"

```bash
# Instalar cliente PostgreSQL
sudo apt-get install postgresql-client-16
```

### Docker: "Permission denied"

```bash
sudo usermod -aG docker $USER
newgrp docker
docker ps  # Testar
```

### Port já em uso

```bash
# Encontrar processo usando porta
lsof -i :6379  # Redis
lsof -i :5432  # PostgreSQL

# Matar processo (se necessário)
kill -9 <PID>
```

---

## 📞 Suporte

- Veja [README_SETUP_LOCAL.md](README_SETUP_LOCAL.md) para setup detalhado
- Veja [QUICKSTART.md](QUICKSTART.md) para começar rápido
- Veja [DOCKER_DEV.md](DOCKER_DEV.md) para usar Docker

---

## 🎯 Decisão: Redis Local vs Docker

| Opção            | Vantagens            | Desvantagens        |
| ---------------- | -------------------- | ------------------- |
| **Redis Local**  | Simples, rápido      | Instalar no sistema |
| **Redis Docker** | Isolado, fácil reset | Precisa Docker      |

**Recomendação**: Se você já tem Docker, use Docker. Senão, instale Redis localmente.

---

**Status**: Pronto para setup!

Depois de instalar Redis, execute:

```bash
./setup-dev.sh && pnpm dev
```

Seu ambiente estará pronto em minutos! 🚀
