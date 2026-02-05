# 🚀 Auto-Deploy Chatwoot HeyCommerce

Sistema completo de CI/CD para deploy automático do Chatwoot HeyCommerce em VPS com Docker Swarm.

## 📁 Arquivos Criados

| Arquivo | Descrição |
|---------|-----------|
| `.github/workflows/deploy_vps_heycommerce.yml` | Workflow GitHub Actions para auto-deploy |
| `docker-compose.production.yaml` | Stack Docker Swarm para produção |
| `.env.production.example` | Template de variáveis de ambiente |
| `DEPLOY_VPS_SETUP.md` | 📚 Documentação completa e detalhada |
| `QUICK_START_DEPLOY.md` | ⚡ Guia rápido de início |
| `deploy-helper.sh` | 🛠️ Script helper para operações comuns |
| `disable_unnecessary_workflows.sh` | Script para desativar workflows não usados |
| `validate_deploy_config.sh` | Script de validação de configuração |

## 🎯 Início Rápido

### 1. Configure os Secrets no GitHub

Acesse: `https://github.com/OshanKHZ/chatwoot/settings/secrets/actions`

**Secrets obrigatórios:**
- `SSH_HOST`, `SSH_USER`, `SSH_PORT`, `SSH_PRIVATE_KEY`
- `SECRET_KEY_BASE`, `FRONTEND_URL`, `CRM_URL`
- `POSTGRES_PASSWORD`
- `MAILER_SENDER_EMAIL`, `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_DOMAIN`
- `SSO_ENABLED`, `SSO_PROVIDER`, `SSO_SECRET_KEY`

### 2. Prepare a VPS

```bash
ssh usuario@vps-ip
mkdir -p ~/chatwoot-heycommerce
cd ~/chatwoot-heycommerce

# Criar arquivo .env (use .env.production.example como base)
nano .env
chmod 600 .env
```

### 3. Faça o Deploy

**Opção A: Push automático**
```bash
git push origin cliente-heycommerce
```

**Opção B: Manual via GitHub Actions**
1. Vá em Actions → Deploy HeyCommerce Chatwoot to VPS
2. Run workflow → cliente-heycommerce

## 📚 Documentação

- **[QUICK_START_DEPLOY.md](QUICK_START_DEPLOY.md)** - Comece por aqui! ⚡
- **[DEPLOY_VPS_SETUP.md](DEPLOY_VPS_SETUP.md)** - Documentação completa 📖

## 🛠️ Ferramentas

### Deploy Helper

Script interativo para operações comuns:

```bash
# Ver status
SSH_HOST=vps-ip bash deploy-helper.sh status

# Ver logs
SSH_HOST=vps-ip bash deploy-helper.sh logs

# Rails console
SSH_HOST=vps-ip bash deploy-helper.sh console

# Rollback
SSH_HOST=vps-ip bash deploy-helper.sh rollback

# Ver todos os comandos
bash deploy-helper.sh help
```

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Repository                       │
│                    OshanKHZ/chatwoot                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Push to cliente-heycommerce
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Actions                            │
│  1. Build Docker Image                                       │
│  2. Push to GHCR (ghcr.io/oshankHz/chatwoot-heycommerce)   │
│  3. Deploy via SSH                                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ SSH Connection
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         VPS                                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Docker Swarm Stack                        │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │  Traefik (SSL + Routing)                         │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │  chatwoot_app (Rails)                            │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │  chatwoot_worker (Sidekiq)                       │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │  chatwoot_rails_migrations                       │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  External Services (já existentes)                     │ │
│  │  - PostgreSQL (postgres)                               │ │
│  │  - Redis (redis)                                       │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Volumes                                               │ │
│  │  - chatwoot_storage (arquivos)                         │ │
│  │  - chatwoot_public (assets)                            │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Fluxo de Deploy

1. **Desenvolvedor** faz push para `cliente-heycommerce`
2. **GitHub Actions** detecta o push
3. **Build** da imagem Docker
4. **Push** para GitHub Container Registry
5. **SSH** para VPS
6. **Pull** da nova imagem
7. **Limpeza** do volume `chatwoot_public`
8. **Deploy** da stack no Swarm
9. **Update** forçado dos serviços
10. **Verificação** de status

## 🎛️ Comandos Úteis

### Na VPS

```bash
# Status
docker stack ps chatwoot
docker service ls | grep chatwoot

# Logs
docker service logs chatwoot_chatwoot_app -f --tail 100

# Rollback
docker service rollback chatwoot_chatwoot_app

# Console Rails
CONTAINER_ID=$(docker ps -q -f name=chatwoot_chatwoot_app)
docker exec -it $CONTAINER_ID bundle exec rails console

# Ver imagem em uso
docker service inspect chatwoot_chatwoot_app --format='{{.Spec.TaskTemplate.ContainerSpec.Image}}'
```

## 🔐 Segurança

- ✅ Secrets gerenciados pelo GitHub
- ✅ Arquivo `.env` protegido (chmod 600)
- ✅ SSL automático via Traefik/Let's Encrypt
- ✅ Chave SSH dedicada para deploy
- ✅ Registry privado (GHCR)

## 📊 Monitoramento

### GitHub Actions
- Logs de build e deploy
- Histórico de execuções
- Notificações de falha

### VPS
- Logs dos serviços via `docker service logs`
- Status via `docker stack ps`
- Métricas via `docker stats`

## 🆘 Troubleshooting

### Deploy falhou?
1. Verifique logs no GitHub Actions
2. Verifique se todos os secrets estão configurados
3. Verifique conectividade SSH
4. Consulte `DEPLOY_VPS_SETUP.md` seção Troubleshooting

### Serviço não inicia?
```bash
docker service ps chatwoot_chatwoot_app --no-trunc
docker service logs chatwoot_chatwoot_app --tail 200
```

### Fazer rollback?
```bash
docker service rollback chatwoot_chatwoot_app
docker service rollback chatwoot_chatwoot_worker
```

## 📝 Próximos Passos

1. ✅ Configurar secrets no GitHub
2. ✅ Preparar VPS
3. ✅ Testar primeiro deploy
4. ✅ Configurar monitoramento
5. ⬜ Configurar backups automáticos
6. ⬜ Configurar alertas
7. ⬜ Documentar procedimentos de emergência

## 🤝 Contribuindo

Para fazer alterações no workflow de deploy:

1. Edite `.github/workflows/deploy_vps_heycommerce.yml`
2. Teste em branch separada primeiro
3. Verifique logs do GitHub Actions
4. Documente mudanças

## 📞 Suporte

- **Documentação completa**: `DEPLOY_VPS_SETUP.md`
- **Guia rápido**: `QUICK_START_DEPLOY.md`
- **GitHub Actions**: https://github.com/OshanKHZ/chatwoot/actions

---

**Desenvolvido para HeyCommerce** 🚀
