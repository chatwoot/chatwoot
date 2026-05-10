# Runbook Mestre — Release Synapseos

Single source of truth pra fazer um release oficial do ecossistema. Casa
chatwoot e synapseos-agentic numa janela única, com validações e rollback.

> **Quando usar:** sempre que houver mudanças acumuladas em
> `chatwoot/custom/initial-cleanup` OU `synapseos-agentic/main` que
> precisem ir pra produção. NÃO repetir hot-patch — usar este runbook.

## Estado atual de produção (referência)

| Service | Imagem | Origem | Atualização |
|---|---|---|---|
| `chatwoot_app`     | `ghcr.io/paraisolorrayne/synapseos-chatwoot:<TAG>` | GHCR remoto | `docker service update --image` |
| `chatwoot_sidekiq` | `ghcr.io/paraisolorrayne/synapseos-chatwoot:<TAG>` | GHCR remoto | mesmo flow |
| `synapseos_panel`  | `natalia-panel:latest` | Build local na VPS | `docker build` + `docker service update --force` |
| `chatwoot_redis`   | `redis:7-alpine` | upstream | n/a |
| `postgres_postgres`, `pgvector_pgvector`, `n8n_*`, `traefik_*` | upstream | upstream | fora do escopo |

## Próxima release planejada

- **chatwoot v0.1.3-synapseos** — ver `RELEASE_v0.1.3.md`
- **synapseos-agentic v0.2.0-agentic** — ver `../../synapseos-agentic/deploy/RELEASE_v0.2.0.md`

Ambos têm mudanças interligadas (UI do form chatwoot lê `status`/`title` do schema agentic). Deploy precisa ser nessa ordem.

## Sequência (ordem importa)

### Fase A — Pré-flight local (~5min)

```bash
# Verificar working trees limpas
cd ~/Documents/Dexi/Projetos/synapseos/chatwoot && git status
cd ~/Documents/Dexi/Projetos/synapseos/synapseos-agentic && git status

# Verificar que está nos commits/branches certos
cd ~/Documents/Dexi/Projetos/synapseos/chatwoot && git log --oneline -5
# HEAD esperado em b1bc9e1d2 (custom/initial-cleanup)

cd ~/Documents/Dexi/Projetos/synapseos/synapseos-agentic && git log --oneline -5
# HEAD esperado em 3d59ef1 (main)

# Login no GHCR (precisa GHCR_TOKEN com write:packages)
echo $GHCR_TOKEN | docker login ghcr.io -u paraisolorrayne --password-stdin

# Backup preventivo do Postgres (independente, roda na VPS)
ssh synapseos-vps 'bash ~/00-backup-postgres.sh' || echo "backup script ausente — segue mesmo assim"
```

### Fase B — Build chatwoot (~30min, deixa rodando)

```bash
cd ~/Documents/Dexi/Projetos/synapseos/chatwoot
git tag -a v0.1.3-synapseos -m "v0.1.3: super_admin 500 fix + quota mensal + UX form"
git push synapseos v0.1.3-synapseos

bash deploy/scripts/03-build-and-push.sh v0.1.3-synapseos
# Pede confirmação. Build linux/amd64 demora 20-40min em Apple Silicon.
```

### Fase C — Tag agentic (rápido)

```bash
cd ~/Documents/Dexi/Projetos/synapseos/synapseos-agentic
git tag -a v0.2.0-agentic -m "v0.2.0: AgentConfig.enabled default=False + persona titles"
git push origin v0.2.0-agentic
```

### Fase D — Subir scripts pra VPS (uma vez só, ~30s)

Os scripts novos (`05-rolling-update.sh` no chatwoot, `build-and-deploy.sh`
no agentic) precisam estar disponíveis na VPS. Caminho mais simples:

```bash
# Sobe o rolling-update do chatwoot pro home da VPS
scp ~/Documents/Dexi/Projetos/synapseos/chatwoot/deploy/scripts/05-rolling-update.sh \
    synapseos-vps:~/

# build-and-deploy do agentic já vem junto via git pull do ~/natalia
ssh synapseos-vps 'cd ~/natalia && git fetch --tags && git checkout main && git pull'
```

### Fase E — Deploy chatwoot (~2min, rolling)

```bash
ssh synapseos-vps 'bash ~/05-rolling-update.sh v0.1.3-synapseos'
```

Rolling: Swarm cria task novo → drena o velho → finaliza. Sem downtime
pra usuário (HTTP 502 brevíssimo se a request cair na transição, raro).

### Fase F — Deploy agentic (~5min, rolling)

```bash
ssh synapseos-vps 'bash ~/natalia/deploy/scripts/build-and-deploy.sh v0.2.0-agentic'
```

### Fase G — Validações pós-deploy (~3min)

```bash
# Imagens em produção
ssh synapseos-vps 'sudo docker service inspect chatwoot_app --format "{{.Spec.TaskTemplate.ContainerSpec.Image}}"'
ssh synapseos-vps 'sudo docker service inspect chatwoot_sidekiq --format "{{.Spec.TaskTemplate.ContainerSpec.Image}}"'
ssh synapseos-vps 'sudo docker service inspect synapseos_panel --format "{{.Spec.TaskTemplate.ContainerSpec.Image}}"'

# HTTP smoke tests
curl -I https://chat.dexidigital.com.br/                     # 200
curl -I https://chat.dexidigital.com.br/super_admin/sign_in  # 200
curl -fsS -u admin:$PANEL_PASS https://painel.dexidigital.com.br/api/health | jq .

# Schema do agentic deve refletir mudança
curl -fsS -u admin:$PANEL_PASS https://painel.dexidigital.com.br/api/schema \
  | jq '.["$defs"].AgentConfig.properties.enabled.default'  # false
```

Validação manual (browser):
- [ ] `/super_admin` carrega sem 500
- [ ] `/super_admin/synapseos/clients/new` → chips Pronto/Em desenvolvimento aparecem, agentes planned têm body bloqueado
- [ ] `AgentMetrics` em uma conta com AgentBot → bloco "Mensagens no mês" renderiza com barra de progresso
- [ ] Login normal de operador funciona

### Fase H — Rollback (se necessário)

Cada serviço tem rollback independente. Aplicar na ordem inversa:

```bash
ssh synapseos-vps
sudo docker service rollback synapseos_panel
sudo docker service rollback chatwoot_sidekiq
sudo docker service rollback chatwoot_app
```

Tempo: ~30s por serviço. Postgres/Redis intocados.

## Pós-release

1. Atualizar referência em `RELEASE_RUNBOOK.md` se houver script novo
2. Após 24-48h sem incidentes: limpar imagens antigas pra liberar disco
   ```bash
   ssh synapseos-vps 'sudo docker image rm ghcr.io/paraisolorrayne/synapseos-chatwoot:v0.1.0-synapseos ghcr.io/paraisolorrayne/synapseos-chatwoot:v0.1.1-synapseos'
   ```
   Manter `v0.1.2` como rollback target ainda por 1-2 semanas.

## Janela ideal

- **Day**: terça/quarta (sem fim de semana próximo, dá pra reagir)
- **Hora**: fora de pico do Chatwoot (≠ 08-12 e 14-18 BRT — confirmar com Sandro/Emerson o uso real)
- **Duração total**: ~50min (build 30min + deploy 5min + validação 15min)
