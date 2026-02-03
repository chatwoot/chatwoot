# 🚀 Configuração de Auto-Deploy VPS - HeyCommerce Chatwoot

## 📋 Visão Geral

Este documento descreve a configuração do workflow de auto-deploy para a VPS do Chatwoot HeyCommerce.

## 🔐 Secrets Necessários no GitHub

Configure os seguintes secrets no repositório GitHub (`Settings` → `Secrets and variables` → `Actions` → `New repository secret`):

### SSH e Servidor
- **`SSH_HOST`**: IP ou domínio da VPS (ex: `192.168.1.100` ou `chatwoot.heycommerce.com`)
- **`SSH_USER`**: Usuário SSH da VPS (ex: `ubuntu`, `root`, etc.)
- **`SSH_PORT`**: Porta SSH (padrão: `22`)
- **`SSH_PRIVATE_KEY`**: Chave privada SSH para acesso à VPS

### Aplicação
- **`SECRET_KEY_BASE`**: Chave secreta do Rails (gerar com `rake secret`)
- **`FRONTEND_URL`**: URL pública do Chatwoot (ex: `https://chat.heycommerce.com`)

### Banco de Dados
- **`POSTGRES_PASSWORD`**: Senha do PostgreSQL

### Redis
- **`REDIS_PASSWORD`**: Senha do Redis (pode ser vazia para desenvolvimento)

### Email (SMTP)
- **`MAILER_SENDER_EMAIL`**: Email remetente (ex: `HeyCommerce <noreply@heycommerce.com>`)
- **`SMTP_ADDRESS`**: Endereço do servidor SMTP (ex: `smtp.gmail.com`)
- **`SMTP_PORT`**: Porta SMTP (ex: `587`)
- **`SMTP_USERNAME`**: Usuário SMTP
- **`SMTP_PASSWORD`**: Senha SMTP
- **`SMTP_DOMAIN`**: Domínio SMTP (ex: `heycommerce.com`)

## 🔑 Como Gerar a Chave SSH

### 1. Na sua máquina local:
```bash
# Gerar nova chave SSH (se não tiver uma)
ssh-keygen -t ed25519 -C "deploy@heycommerce" -f ~/.ssh/deploy_heycommerce

# Copiar chave pública para a VPS
ssh-copy-id -i ~/.ssh/deploy_heycommerce.pub usuario@ip-da-vps
```

### 2. Copiar a chave privada:
```bash
# Windows (Git Bash)
cat ~/.ssh/deploy_heycommerce | clip

# Linux/Mac
cat ~/.ssh/deploy_heycommerce | pbcopy  # Mac
cat ~/.ssh/deploy_heycommerce | xclip   # Linux
```

### 3. Adicionar no GitHub:
- Vá em `Settings` → `Secrets and variables` → `Actions`
- Clique em `New repository secret`
- Nome: `SSH_PRIVATE_KEY`
- Valor: Cole a chave privada completa (incluindo `-----BEGIN` e `-----END`)

## 🔑 Como Gerar SECRET_KEY_BASE

### Opção 1: Usando Rails (se tiver Ruby instalado)
```bash
cd c:\Users\LUCAS OSHAN\Repos\01_customers\heycommerce\chatwoot
bundle exec rake secret
```

### Opção 2: Usando OpenSSL
```bash
openssl rand -hex 64
```

### Opção 3: Online (use com cuidado)
- Acesse: https://www.random.org/strings/
- Configure: 128 caracteres, alfanuméricos

## 📦 Preparação da VPS

### ⚠️ Ambiente Atual: Docker Swarm + Traefik

Sua VPS já está configurada com:
- ✅ **Docker Swarm** (modo cluster)
- ✅ **Traefik** (reverse proxy com SSL automático)
- ✅ **Network externa**: `network_public`
- ✅ **Volumes externos**: `chatwoot_storage`, `chatwoot_public`

### 1. Verificar configuração existente:
```bash
# Conectar na VPS
ssh usuario@ip-da-vps

# Verificar se Swarm está ativo
docker info | grep Swarm

# Listar networks
docker network ls | grep network_public

# Listar volumes
docker volume ls | grep chatwoot

# Verificar stack atual
docker stack ls
docker stack ps chatwoot
```

### 2. Criar/Atualizar diretório de deploy:
```bash
mkdir -p ~/chatwoot-heycommerce
cd ~/chatwoot-heycommerce
```

### 3. Criar arquivo .env de produção:
```bash
# Criar arquivo .env baseado no template
cat > .env << 'EOF'
POSTGRES_PASSWORD=yO3y7nc1F3P7
REDIS_PASSWORD=
SECRET_KEY_BASE=a7b4c9e8f1d2a5b8c3e6f9a2d5b8c1e4f7a0d3b6c9e2f5a8b1d4c7e0f3a6b9c2
FRONTEND_URL=https://chat.crm-heycommerce.com
CRM_URL=https://app.crm-heycommerce.com
MAILER_SENDER_EMAIL=crm.heycommerce@gmail.com
SMTP_DOMAIN=gmail.com
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=crm.heycommerce@gmail.com
SMTP_PASSWORD=rhwn qnbi cxwr xrmi
SSO_ENABLED=true
SSO_PROVIDER=custom
SSO_SECRET_KEY=650104abea44f187db645f220a030c84a11c92a1cb574ee3848463a9c88ac413
EOF

# Proteger o arquivo
chmod 600 .env
```

### 4. Verificar volumes externos (se não existirem, criar):
```bash
# Criar volumes se não existirem
docker volume create chatwoot_storage
docker volume create chatwoot_public

# Verificar
docker volume ls | grep chatwoot
```

## 🚀 Como Funciona o Deploy

### Fluxo Automático:
1. **Push para `cliente-heycommerce`** → Trigger do workflow
2. **Build da imagem Docker** → Enviada para GitHub Container Registry (GHCR)
3. **Deploy via SSH no Docker Swarm**:
   - Copia `docker-compose.production.yaml` para VPS
   - Copia arquivo `.env` com secrets para VPS
   - Faz login no GHCR na VPS
   - Pull da nova imagem
   - Limpa volume `chatwoot_public` (assets antigos)
   - Faz deploy da stack com `docker stack deploy`
   - Força update dos serviços `chatwoot_app` e `chatwoot_worker`
   - Aguarda convergência dos serviços
   - Verifica status final

### Deploy Manual:
Você também pode disparar o deploy manualmente:
1. Vá em `Actions` no GitHub
2. Selecione `Deploy HeyCommerce Chatwoot to VPS`
3. Clique em `Run workflow`
4. Escolha a branch `cliente-heycommerce`

### Comandos Úteis na VPS:

```bash
# Ver status da stack
docker stack ps chatwoot

# Ver logs dos serviços
docker service logs chatwoot_chatwoot_app -f
docker service logs chatwoot_chatwoot_worker -f

# Forçar update manual de um serviço
docker service update --force chatwoot_chatwoot_app

# Escalar serviços (se necessário)
docker service scale chatwoot_chatwoot_worker=2

# Remover stack (cuidado!)
docker stack rm chatwoot
```

## 🌐 Traefik (Reverse Proxy)

Sua VPS já está configurada com **Traefik** para gerenciar SSL e roteamento.

### Configuração Atual (via labels no docker-compose):
- ✅ SSL automático via Let's Encrypt
- ✅ Domínio: `chat.crm-heycommerce.com`
- ✅ Headers de proxy configurados
- ✅ HTTPS forçado

### Verificar configuração do Traefik:
```bash
# Ver serviços Traefik
docker service ls | grep traefik

# Ver logs do Traefik
docker service logs traefik -f

# Verificar certificados SSL
docker exec $(docker ps -q -f name=traefik) ls -la /letsencrypt/acme.json
```

### Se precisar atualizar o domínio:
Edite as labels no `docker-compose.production.yaml`:
```yaml
labels:
  - traefik.http.routers.chatwoot_app.rule=Host(`novo-dominio.com`)
```

## 🛑 Desativar Workflows Desnecessários

Para evitar execuções desnecessárias e economizar minutos do GitHub Actions:

### Opção 1: Renomear arquivos (Recomendado)
```bash
cd .github/workflows
mv publish_foss_docker.yml publish_foss_docker.yml.disabled
mv publish_ee_docker.yml publish_ee_docker.yml.disabled
mv nightly_installer.yml nightly_installer.yml.disabled
```

### Opção 2: Adicionar condição nos workflows
Edite cada arquivo `.yml` e adicione no início:
```yaml
on:
  push:
    branches:
      - never-run-this  # Branch que não existe
```

### Workflows Sugeridos para Desativar:
- ✅ `publish_foss_docker.yml` - Não precisamos publicar imagem FOSS oficial
- ✅ `publish_ee_docker.yml` - Não precisamos publicar imagem Enterprise
- ✅ `nightly_installer.yml` - Não precisamos de builds noturnos
- ✅ `publish_codespace_image.yml` - Não usamos Codespaces
- ⚠️ `run_foss_spec.yml` - Manter se quiser testes automáticos
- ⚠️ `test_docker_build.yml` - Manter para validar builds

## 📊 Monitoramento

### Verificar status dos serviços:
```bash
ssh usuario@ip-da-vps

# Ver status geral da stack
docker stack ps chatwoot

# Ver serviços da stack
docker stack services chatwoot

# Ver detalhes de um serviço específico
docker service ps chatwoot_chatwoot_app --no-trunc
docker service ps chatwoot_chatwoot_worker --no-trunc
docker service ps chatwoot_chatwoot_rails_migrations --no-trunc

# Ver réplicas e recursos
docker service ls | grep chatwoot
```

### Ver logs:
```bash
# Logs do app (Rails)
docker service logs chatwoot_chatwoot_app -f --tail 100

# Logs do worker (Sidekiq)
docker service logs chatwoot_chatwoot_worker -f --tail 100

# Logs das migrations
docker service logs chatwoot_chatwoot_rails_migrations --tail 50

# Logs de todos os serviços da stack
docker service logs -f chatwoot_chatwoot_app chatwoot_chatwoot_worker
```

### Executar comandos no container:
```bash
# Obter ID do container do app
CONTAINER_ID=$(docker ps -q -f name=chatwoot_chatwoot_app)

# Console Rails
docker exec -it $CONTAINER_ID bundle exec rails console

# Bash no container
docker exec -it $CONTAINER_ID bash

# Executar comando único
docker exec $CONTAINER_ID bundle exec rails db:migrate:status
```

### Inspecionar serviço:
```bash
# Ver configuração completa do serviço
docker service inspect chatwoot_chatwoot_app --pretty

# Ver variáveis de ambiente
docker service inspect chatwoot_chatwoot_app --format='{{json .Spec.TaskTemplate.ContainerSpec.Env}}' | jq

# Ver imagem em uso
docker service inspect chatwoot_chatwoot_app --format='{{.Spec.TaskTemplate.ContainerSpec.Image}}'
```

## 🔄 Rollback

Se algo der errado no deploy, você pode fazer rollback de várias formas:

### Opção 1: Rollback Automático do Swarm (Recomendado)
```bash
ssh usuario@ip-da-vps

# Rollback do serviço app
docker service rollback chatwoot_chatwoot_app

# Rollback do serviço worker
docker service rollback chatwoot_chatwoot_worker

# Verificar status
docker service ps chatwoot_chatwoot_app
```

### Opção 2: Update para Versão Específica
```bash
ssh usuario@ip-da-vps

# Listar imagens disponíveis
docker images | grep chatwoot-heycommerce

# Update para tag específica
docker service update \
  --image ghcr.io/oshankHz/chatwoot-heycommerce:cliente-heycommerce-SHA_ANTERIOR \
  chatwoot_chatwoot_app

docker service update \
  --image ghcr.io/oshankHz/chatwoot-heycommerce:cliente-heycommerce-SHA_ANTERIOR \
  chatwoot_chatwoot_worker
```

### Opção 3: Redeploy da Stack Completa
```bash
ssh usuario@ip-da-vps
cd ~/chatwoot-heycommerce

# Editar docker-compose para usar tag anterior
nano docker-compose.production.yaml
# Alterar: ghcr.io/oshankHz/chatwoot-heycommerce:TAG_ANTERIOR

# Redeploy
docker stack deploy -c docker-compose.production.yaml chatwoot --with-registry-auth

# Verificar
docker stack ps chatwoot
```

### Verificar Histórico de Updates:
```bash
# Ver histórico de updates do serviço
docker service inspect chatwoot_chatwoot_app --format='{{json .PreviousSpec}}' | jq

# Ver tasks antigas (incluindo falhas)
docker service ps chatwoot_chatwoot_app --no-trunc
```

## 🐛 Troubleshooting

### Erro: "Permission denied (publickey)"
- Verifique se a chave SSH está correta no GitHub Secrets
- Verifique se a chave pública está no `~/.ssh/authorized_keys` da VPS

### Erro: "Cannot connect to Docker daemon"
- Verifique se o Docker está rodando: `sudo systemctl status docker`
- Reinicie o Docker: `sudo systemctl restart docker`

### Erro: "Port 3000 already in use"
- Verifique processos usando a porta: `sudo lsof -i :3000`
- Pare containers antigos: `docker-compose down`

### Containers não iniciam
- Verifique logs: `docker-compose logs`
- Verifique recursos: `docker stats`
- Verifique espaço em disco: `df -h`

## 📝 Checklist de Deploy

- [ ] Secrets configurados no GitHub
- [ ] SSH configurado na VPS
- [ ] Docker instalado na VPS
- [ ] Diretório `~/chatwoot-heycommerce` criado
- [ ] Nginx configurado (se aplicável)
- [ ] SSL configurado (se aplicável)
- [ ] Workflows desnecessários desativados
- [ ] Primeiro deploy manual testado
- [ ] Logs verificados
- [ ] Aplicação acessível via browser

## 🎯 Próximos Passos

1. Configure todos os secrets no GitHub
2. Prepare a VPS conforme documentado
3. Faça o primeiro deploy manual
4. Teste a aplicação
5. Configure monitoramento
6. Configure backups automáticos do PostgreSQL

## 📞 Suporte

Em caso de dúvidas ou problemas:
1. Verifique os logs do GitHub Actions
2. Verifique os logs dos containers na VPS
3. Consulte a documentação oficial do Chatwoot
