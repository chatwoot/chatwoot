# Release v0.1.3-synapseos — Chatwoot Synapseos

Consolida 3 hot-patches aplicados em produção desde `v0.1.2-synapseos` em
uma imagem oficial. Substitui o estado atual da VPS (que tem código modificado
direto no container, volátil em qualquer redeploy) por um deploy reproduzível.

## Changelog

| Commit | Tipo | Descrição |
|---|---|---|
| `3b7fd8f1f` | fix | super_admin retornava 500 em qualquer GET — Administrate iterava sobre `synapseos/clients` (controller custom sem Dashboard class) e estourava `NameError`. Adiciona ao skip-list em `_navigation.html.erb`. |
| `8f82e29fc` | feat | Card "Mensagens no mês" por agente cadastrado em `AgentMetrics`. Backend `AgentMetricsQuery#usage_payload` + endpoint `GET /api/v1/accounts/:id/synapseos/agent_metrics/:slug/usage`. Quota fixa em 300 (`MONTHLY_MESSAGE_QUOTA`). Frontend `SynapseQuotaBar.vue` com barra colorida + chip de excedente. |
| `b1bc9e1d2` | fix | UX form do super_admin/synapseos/clients distingue agentes prontos (chip verde "Pronto") vs planejados (chip âmbar "Em desenvolvimento"). Body de planned não renderiza form — mostra banner. Impede operador de ativar agente sem workflows e quebrar deploy. |

## Pré-requisitos

1. **Localmente** (Mac):
   - Docker Desktop ou colima rodando com buildx
   - Login no GHCR:
     ```bash
     echo $GHCR_TOKEN | docker login ghcr.io -u paraisolorrayne --password-stdin
     ```
   - Working tree limpa em `custom/initial-cleanup` no commit `b1bc9e1d2`

2. **Na VPS** (`synapseos-vps`):
   - Acesso sudo (já tem)
   - Stack `chatwoot` rodando (já está)
   - Volume `chatwoot_storage` preservado (será mantido pelo rolling update)

## Sequência de comandos

### 1. Local — tag + build + push

```bash
cd ~/Documents/Dexi/Projetos/synapseos/chatwoot
git checkout custom/initial-cleanup
git pull synapseos custom/initial-cleanup
git tag -a v0.1.3-synapseos -m "v0.1.3: super_admin 500 fix + quota mensal + UX form"
git push synapseos v0.1.3-synapseos

bash deploy/scripts/03-build-and-push.sh v0.1.3-synapseos
# build leva 20-40min em M1/M2 (linux/amd64 cross-build)
```

### 2. VPS — rolling update

```bash
ssh synapseos-vps
# se ~/deploy/scripts/05-rolling-update.sh não existir, faça:
#   git -C ~/natalia pull   # se o repo chatwoot estiver clonado lá
# OU baixe o script via scp do Mac:
#   scp ./deploy/scripts/05-rolling-update.sh synapseos-vps:~/

bash ~/05-rolling-update.sh v0.1.3-synapseos
```

O script faz `docker pull` da nova tag, mostra a imagem atual, pede confirmação,
e roda `docker service update --image` em `chatwoot_app` e `chatwoot_sidekiq`
sequencialmente. Volumes e Postgres ficam intactos.

### 3. Validações pós-deploy

```bash
# Status HTTP
curl -I https://chat.dexidigital.com.br/                       # 200
curl -I https://chat.dexidigital.com.br/super_admin/sign_in    # 200

# Confirmar a nova imagem está rodando
ssh synapseos-vps 'sudo docker service inspect chatwoot_app --format "{{.Spec.TaskTemplate.ContainerSpec.Image}}"'
# Deve printar: ghcr.io/paraisolorrayne/synapseos-chatwoot:v0.1.3-synapseos
```

Manualmente no browser:
- `/super_admin` → carrega dashboard sem 500 ✓
- `/super_admin/synapseos/clients/new` → form mostra chips Pronto/Em desenvolvimento ✓
- AgentMetrics em qualquer conta com AgentBot → cards aparecem com bloco "Mensagens no mês" ✓

### 4. Rollback (se algo der errado)

Swarm guarda o spec anterior automaticamente:

```bash
ssh synapseos-vps
sudo docker service rollback chatwoot_app
sudo docker service rollback chatwoot_sidekiq
```

Volta pra `v0.1.2-synapseos` em ~30s. Os hot-patches do super_admin perdidos
no rollback (porque o container é recriado a partir da imagem) — **mas** esse
release oficial inclui o fix, então rollback só faz sentido se a v0.1.3 tiver
introduzido outra regressão.

## Limpeza pós-release

Após validar v0.1.3 em produção por 24h:

```bash
ssh synapseos-vps
# Remover imagens antigas pra liberar disco (cada uma ~706MB instalada)
sudo docker image rm ghcr.io/paraisolorrayne/synapseos-chatwoot:v0.1.0-synapseos
sudo docker image rm ghcr.io/paraisolorrayne/synapseos-chatwoot:v0.1.1-synapseos
# Manter v0.1.2 como rollback target durante 1-2 semanas
```
