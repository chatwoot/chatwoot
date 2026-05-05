# Playbook: instalar Synapseos em VPS já com n8n

Cenário: cliente já tem VPS rodando com n8n + agentes funcionando (geralmente
n8n + Supabase como storage). Queremos subir o ecossistema Synapseos
(Chatwoot fork, painel Agentic, Postgres + pgvector) **sem quebrar o n8n
existente** e migrar gradualmente as tabelas dos agentes para o Postgres
local.

Este playbook é a referência manual. Quando estabilizado, vira o modo
`synapseos-install --adopt-n8n` do instalador.

---

## Fase 0 — Inventário (antes de qualquer ação)

Conecta na VPS do cliente e levanta:

### 0.1 — Como o n8n está instalado?

```bash
# tenta cada formato comum
docker ps | grep -i n8n                                # docker swarm/compose
docker compose ls 2>/dev/null | grep -i n8n            # compose v2
systemctl list-units --type=service | grep -i n8n      # systemd
snap list 2>/dev/null | grep -i n8n                    # snap
ls /opt/n8n /home/*/n8n 2>/dev/null                    # instalação manual
```

Anotar:
- **Tipo de instalação** (compose, swarm, systemd, snap, manual)
- **Path do data-dir** (onde ficam os workflows)
- **Versão** (`docker exec <ctr> n8n --version`)
- **Como inicia** (script, systemd unit, label do swarm)

### 0.2 — Onde o n8n armazena os workflows?

```bash
# inspeciona env do container/processo
docker inspect <n8n-container> | jq '.[0].Config.Env'
# OU
cat /etc/n8n.env  /home/*/n8n/.env  /opt/n8n/.env 2>/dev/null
```

Procurar:
- `DB_TYPE` — `sqlite` (default), `postgresdb`, `mysqldb`
- Se `postgresdb`: `DB_POSTGRESDB_HOST`, `_DATABASE`, `_USER`, `_PASSWORD`
- `N8N_HOST`, `WEBHOOK_URL` (precisamos preservar)

### 0.3 — Onde estão as tabelas dos agentes?

Geralmente Supabase, mas pode ser:
- Supabase remoto (`*.supabase.co`)
- Postgres self-hosted local
- Mesmo Postgres do n8n (se já é postgresdb)
- Airtable, Sheets, etc (não cobertos por este playbook)

Pedir ao cliente:
- Connection string Supabase (Project Settings → Database → Connection string)
- Lista de tabelas usadas pelos agentes
  ```sql
  SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
  ```

### 0.4 — O que ocupa as portas 80/443?

```bash
sudo ss -tlnp | grep -E ':(80|443) '
docker ps --format '{{.Names}} {{.Ports}}' | grep -E ':(80|443)->'
```

Anotar:
- **Reverse proxy ativo** (nginx, traefik, caddy, apache, none)
- **Domínios/certificados em uso** (`certbot certificates` ou `traefik api/http/routers`)

### 0.5 — Recursos disponíveis

```bash
free -h                # RAM
df -h /                # disco
nproc                  # CPU
```

Mínimo recomendado para o ecossistema completo: 4GB RAM livres, 20GB disco.

---

## Fase 1 — Matriz de decisão

Com o inventário, escolher o caminho:

| Situação encontrada | Caminho |
|---|---|
| Sem reverse proxy nas portas 80/443 | **A — Traefik novo** |
| Já tem Traefik rodando | **B — Reusar Traefik existente** |
| Tem nginx/caddy/apache | **C — Migrar ingress (mais trabalhoso)** |
| n8n em SQLite | Mantém SQLite (workflows locais) |
| n8n em Postgres self-hosted | Pode reusar como `postgres_postgres` ou subir um novo separado |
| n8n em Postgres remoto/Supabase | Sobe Postgres novo, mantém remoto pro n8n até migração completa |

**Regra geral**: nunca migrar 2 coisas no mesmo passo. Se vai trocar o ingress
E migrar tabelas, faz em janelas separadas.

---

## Fase 2 — Subir as stacks Synapseos sem tocar n8n

### 2.1 — Network overlay compartilhada

Se a instalação atual é Swarm: usa a network existente (provavelmente
`dexinet` ou similar — confirmar com `docker network ls`).

Se é Compose/manual: cria network nova e conecta o n8n existente nela:

```bash
docker network create -d overlay --attachable dexinet  # ou bridge se não-Swarm
docker network connect dexinet <n8n-container>
```

### 2.2 — Subir Postgres + pgvector novos

Sem mexer no Postgres do n8n. Manifestos em `deploy/`:

```bash
# Postgres principal (com pgvector embarcado para Chatwoot + tabelas de
# agentes migradas; pode ser o mesmo do n8n ou separado)
docker stack deploy -c deploy/postgres/docker-stack.yml postgres
docker stack deploy -c deploy/pgvector/docker-stack.yml pgvector
```

Cria role/db dedicado para Chatwoot (ver memória `project_production_deploy.md`).

### 2.3 — Subir Chatwoot fork + painel

```bash
docker stack deploy -c deploy/chatwoot/docker-stack.yml chatwoot --with-registry-auth
docker stack deploy -c deploy/synapseos-panel/docker-stack.yml synapseos
```

### 2.4 — Conferir que n8n existente continua intacto

```bash
docker ps | grep n8n         # ainda rodando, sem restart
curl -I https://n8n.<dominio-cliente>.com.br   # ainda responde
```

Se quebrar aqui, parar e investigar. **Não prossegue para Fase 3.**

---

## Fase 3 — Migrar tabelas dos agentes (Supabase → Postgres local)

### 3.1 — Criar DB e role para os dados dos agentes

```sql
-- como superuser no postgres_postgres
CREATE USER agentes WITH PASSWORD 'gerar';
CREATE DATABASE agentes_data OWNER agentes;
\c agentes_data
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector;     -- embeddings
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- fuzzy search
```

### 3.2 — Dump+restore por tabela

Script `deploy/scripts/migrate-supabase-tables.sh` (a criar):

```bash
#!/bin/bash
set -euo pipefail

SUPABASE_URL="${SUPABASE_URL:?defina}"
LOCAL_URL="postgresql://agentes:${LOCAL_PASS}@127.0.0.1:5432/agentes_data"
TABLES=("${@:?passe nomes das tabelas}")

for t in "${TABLES[@]}"; do
  echo "==> $t"
  pg_dump "$SUPABASE_URL" \
    --table="public.$t" \
    --no-owner --no-privileges \
    --schema=public \
  | psql "$LOCAL_URL"
done

# Reseta sequences (Postgres dump preserva valores, mas IDs futuros
# precisam continuar do MAX)
psql "$LOCAL_URL" <<'SQL'
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT s.relname AS seq, t.relname AS tbl, a.attname AS col
    FROM pg_class s
    JOIN pg_depend d ON d.objid = s.oid
    JOIN pg_class t ON d.refobjid = t.oid
    JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = d.refobjsubid
    WHERE s.relkind = 'S'
  LOOP
    EXECUTE format('SELECT setval(%L, COALESCE((SELECT MAX(%I) FROM %I), 1))',
                   r.seq, r.col, r.tbl);
  END LOOP;
END $$;
SQL

echo "OK"
```

Uso:

```bash
SUPABASE_URL='postgresql://postgres.xxx:senha@aws-0-...supabase.com:5432/postgres' \
LOCAL_PASS='senha-do-user-agentes' \
bash deploy/scripts/migrate-supabase-tables.sh \
  n8n_chat_histories agent_memory leads_pipeline knowledge_base
```

### 3.3 — Validação dos dados

```sql
-- contar linhas em cada lado e comparar
\c agentes_data
SELECT 'n8n_chat_histories' AS tabela, COUNT(*) FROM n8n_chat_histories
UNION ALL
SELECT 'agent_memory', COUNT(*) FROM agent_memory;
-- ... etc

-- comparar com mesma query no Supabase, números têm que bater
```

---

## Fase 4 — Reapontar n8n para o Postgres local

### 4.1 — Criar credentials nova no n8n (mantendo a antiga)

Via UI:
- Settings → Credentials → New → Postgres
- Host: `postgres_postgres` (se na mesma network) ou IP/hostname acessível
- Database: `agentes_data`
- User: `agentes` (criado em 3.1)
- Password: a definida
- SSL: disable (rede interna) — confirmar política do cliente
- **Nome da credential**: `Postgres Local — agentes` (deixa claro)

Via API (pra automatizar no instalador):

```bash
curl -X POST https://n8n.<cliente>/rest/credentials \
  -H "Cookie: n8n-auth=..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Postgres Local — agentes",
    "type": "postgres",
    "data": {"host":"postgres_postgres","database":"agentes_data","user":"agentes","password":"...","port":5432,"ssl":"disable"}
  }'
```

### 4.2 — Trocar credentials nos workflows um por um

Para cada workflow que usa as tabelas migradas:
1. Abrir workflow no editor
2. Em cada node Postgres/Supabase, trocar a credential pra `Postgres Local — agentes`
3. Executar manualmente (Test workflow) — confere que funciona
4. Deactivate + Activate (força reload)

**Não apaga a credential antiga ainda** — precisa pra rollback.

### 4.3 — Janela de validação

Roda o ambiente em **dual-write não é necessário** porque os agentes leem
contexto, não escrevem em ambos. Mas:
- Espera 24-48h
- Acompanha errors do n8n (`docker service logs n8n_n8n_worker`)
- Se algum workflow ainda apontava pra Supabase, vai falhar e você sabe que precisa migrar

---

## Fase 5 — Cleanup e cutover final

Após validação OK:

### 5.1 — Apaga credentials antigas no n8n

```bash
# UI: Settings → Credentials → seleciona "Supabase ..." → Delete
```

### 5.2 — Encerra instância Supabase (se for cobrança)

Apenas se cliente confirmar — alguns mantém pra histórico/auditoria.

### 5.3 — Atualiza DNS/SSL se mudou ingress

Se subiu Traefik novo (caminho A), aponta domínios:
- `chat.<cliente>.com.br` → IP da VPS (já apontava antes? confere)
- `painel.<cliente>.com.br` → IP da VPS (novo)
- `n8n.<cliente>.com.br` → IP da VPS (já existia)

---

## Plano de rollback

Em qualquer ponto, se algo crítico quebrar:

| Fase | Como reverter |
|---|---|
| 2 (subiu stacks novas) | `docker stack rm chatwoot synapseos pgvector` — n8n nem foi tocado |
| 3 (migrou tabelas) | DB local fica órfão, sem efeito; n8n continua lendo Supabase |
| 4 (trocou credentials) | Reabre workflow, troca a credential de volta pra Supabase, save+activate |
| 5 (apagou credential antiga) | `pg_restore` do dump da Supabase (manter dump por 30 dias!) |

**Sempre mantém um dump da Supabase original** em `~/backups/<cliente>/<data>/`
até a janela de validação fechar.

---

## Conflitos conhecidos e resoluções

### C1: Outro reverse proxy ocupando 80/443

**Sintoma**: `docker stack deploy traefik` falha com "port already in use".

**Resoluções** (por ordem de preferência):
1. **Cliente já usa Traefik**: pula nosso traefik, conecta nossas stacks ao Traefik existente. Ajustar labels/network nos manifestos pra apontar pro nome real da network do Traefik do cliente.
2. **Cliente usa nginx/caddy**: discute com cliente migrar pra Traefik (uma janela). Se rejeitar, configura nginx upstream apontando pra nossas portas internas. Mais frágil.
3. **Cliente usa apache**: idem nginx.

### C2: n8n em SQLite, queremos histórico de execuções persistente

**Não é problema imediato** — workflows continuam em SQLite. Tarefas de
migração de **dados de agentes** não tocam o SQLite do n8n. Só registrar como
tech-debt do cliente (Postgres seria mais robusto pra escala).

### C3: n8n usando o mesmo Postgres que vamos subir

Se descobrir no inventário que o n8n já usa um `postgres` rodando na VPS:
- **Reusar**: aponta nossas stacks (chatwoot) pro mesmo container, criando role/db dedicado. Economiza recursos, simplifica backup.
- **Não reusar**: sobe um Postgres novo separado se temos receio de impacto. 1.5GB RAM extra por instância.

Default: **reusar**. Cria DB+role isolados.

### C4: Domínios já usando Let's Encrypt em outro local

**Sintoma**: Traefik não consegue emitir cert porque outro processo já
respondeu o desafio HTTP-01.

**Resolução**: Confere que **só um** processo escuta na 80. Se cert antigo
está em `/etc/letsencrypt/live/`, copia pro Traefik ou deixa Traefik emitir
do zero (Let's Encrypt aceita renovação cruzada).

### C5: Cliente sem domínio configurado

**Resolução**: usa subdomínio temporário (`chat-cliente.dexidigital.com.br`)
até cliente apontar o próprio. DNS na nossa zona, A record pro IP da VPS.

---

## Checklist final (cole no ticket de onboarding)

**Pré-instalação**
- [ ] Inventário VPS completo (Fase 0)
- [ ] Caminho escolhido (A, B, C — Fase 1)
- [ ] Connection string Supabase do cliente
- [ ] Lista de tabelas dos agentes
- [ ] Domínios + DNS confirmados
- [ ] Janela de manutenção combinada com cliente

**Execução**
- [ ] Backup das credenciais e tabelas Supabase (`pg_dump --schema-only` + `--data-only`)
- [ ] Stacks Synapseos no ar (chat. e painel. respondendo HTTPS)
- [ ] n8n existente continua intacto (`docker ps`, login na UI)
- [ ] Tabelas migradas com counts validados
- [ ] Credentials novas no n8n
- [ ] Workflows reapontados (lista por nome)
- [ ] Janela de validação 24-48h sem erros nos logs

**Cutover**
- [ ] Credentials Supabase removidas do n8n
- [ ] Cliente notificado do cutover
- [ ] Backup final do dump da Supabase mantido por 30 dias
- [ ] DNS antigo desligado (se aplicável)
- [ ] Doc de operação entregue ao cliente

---

## Próximos passos para virar `--adopt-n8n`

Quando este playbook for executado em 2-3 clientes e estabilizar:

1. **Script de inventário** (`scripts/probe-vps.sh`): roda os comandos da Fase 0 e gera relatório JSON
2. **Script de migração de tabelas** (`scripts/migrate-supabase-tables.sh`): já esboçado em 3.2
3. **Script de update de credentials no n8n** (`scripts/n8n-credential-swap.sh`): API REST do n8n
4. **Wrapper `synapseos-install --adopt-n8n`**: lê inventário → escolhe caminho → executa scripts → valida → imprime checklist

A lógica de detecção (qual reverse proxy, onde n8n armazena, etc) deve ser
extensível: cada conflito da seção "Conflitos conhecidos" vira um detector +
resolutor plugável.
