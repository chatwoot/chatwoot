# Deploy Synapseos / Chatwoot na VPS Interlivre

Manifestos e scripts para colocar o **fork do Chatwoot** (com branding, painel
Agentic e demais customizações) em produção em `chat.dexidigital.com.br`,
substituindo a imagem oficial que o DevOps subiu inicialmente.

VPS: `158.69.63.140` (Ubuntu, Docker Swarm + Traefik).

## Estrutura

```
deploy/
├── README.md                              ← este arquivo
├── adopt-n8n-playbook.md                  ← instalar Synapseos em VPS já com n8n
├── registry/
│   └── docker-stack.yml                   ← registry self-hosted (OBSOLETO — usamos GHCR)
├── chatwoot/
│   └── docker-stack.yml                   ← stack do Chatwoot do fork
├── synapseos-panel/
│   └── traefik-labels.md                  ← como colocar o painel atrás do Traefik
└── scripts/
    ├── 00-backup-postgres.sh              ← dump pré-execução
    ├── 01-cleanup-nginx.sh                ← remover Nginx residual
    ├── 02-deploy-registry.sh              ← OBSOLETO (registry self-hosted descartado)
    ├── 03-build-and-push.sh               ← LOCAL — build + push da imagem
    └── 04-redeploy-chatwoot.sh            ← substituir Chatwoot pelo fork
```

## Pré-requisitos (você precisa fazer)

1. **DNS** — criar A records apontando para `158.69.63.140`:
   - `registry.dexidigital.com.br`
   - `painel.dexidigital.com.br`
   - (`chat.dexidigital.com.br` já existe ✓)

2. **SSH key-based** — adicionar sua pubkey ao `~/.ssh/authorized_keys` do
   `ubuntu@158.69.63.140` para parar de digitar senha. Depois, **rotacionar a
   senha** que vazou no chat.

3. **Mergear PR** `custom/initial-cleanup` → `synapseos/main` no GitHub e criar
   tag `v0.1.0-synapseos`. (Bloqueado agora por `.git/index.lock` antigo —
   resolver com `rm .git/index.lock`.)

4. **Decidir senhas/secrets**:
   - htpasswd do registry (usuário `synapseos`)
   - `SECRET_KEY_BASE` do Chatwoot (gerar com `openssl rand -hex 64`)
   - SMTP

## Ordem de execução

### Fase 1 — Local (no Mac)

| Passo | Comando |
|---|---|
| Conferir build | `docker buildx build --platform=linux/amd64 -f docker/Dockerfile -t local-test .` |
| Tag git | `git tag v0.1.0-synapseos && git push synapseos v0.1.0-synapseos` |

### Fase 2 — Na VPS (preparação, não-destrutiva)

```bash
ssh ubuntu@158.69.63.140
mkdir -p ~/deploy && exit

# Do Mac, copiar manifestos:
scp -r deploy/ ubuntu@158.69.63.140:~/deploy-synapseos
```

| Passo | Script |
|---|---|
| Backup completo | `bash 00-backup-postgres.sh` |
| Cleanup Nginx | `bash 01-cleanup-nginx.sh` |
| Subir registry | (criar htpasswd primeiro) → `bash 02-deploy-registry.sh` |

### Fase 3 — Local (build da imagem do fork)

```bash
docker login registry.dexidigital.com.br -u synapseos
bash deploy/scripts/03-build-and-push.sh v0.1.0-synapseos
```

### Fase 4 — Na VPS (destrutivo — descarta dados existentes)

```bash
# Configurar secrets:
printf '%s' "$(openssl rand -hex 64)" | sudo docker secret create chatwoot_secret_key_base -
# ... outros secrets

# Substituir
bash 04-redeploy-chatwoot.sh v0.1.0-synapseos

# Painel atrás do Traefik (ver synapseos-panel/traefik-labels.md)
```

### Fase 5 — Validação

- `https://chat.dexidigital.com.br` carrega com branding Synapseos
- `https://painel.dexidigital.com.br` responde com HTTPS
- Super admin → link "Synapseos Agentic Panel" funcional
- Login + criar inbox + mensagem de teste

## Pontos de atenção

- **Network compartilhada com Postgres**: o manifesto assume que existe uma
  network overlay `app` que conecta os services do Chatwoot aos containers
  `postgres_postgres` e `pgvector_pgvector` (que estão em stacks separadas).
  Se não existir, o `app` não vai conseguir conectar no banco. Validar com:
  ```
  sudo docker network inspect $(sudo docker network ls -q | head -20) \
    --format '{{.Name}}: {{range .Containers}}{{.Name}} {{end}}' \
    | grep -E 'postgres|pgvector'
  ```

- **Cert resolver**: o YAML usa `letsencrypt`. Confirmar nome real do resolver
  do Traefik antes de fazer deploy.

- **Migrations**: rodar `rails db:chatwoot_prepare` após subir o app (script
  04 lembra disso no final).

- **R2/S3 storage**: handoff `068e7fb27` menciona R2 — não está configurado
  ainda neste manifesto. Iteração futura.
