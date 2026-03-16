# Synapsea / Connect — Runbook completo para implantação em VPS (homologação)

Este documento é um guia operacional para um agente de IA (ou time técnico) implantar o sistema em ambiente de **homologação** com segurança, validar ponta a ponta e decidir **GO / NO-GO**.

> Escopo: aplicação principal (Rails + Sidekiq + Vite + Postgres + Redis), recursos de UX/branding/context help, e scaffold `services/synapsea-analytics` para experimentação controlada.

---

## 1) Visão geral do sistema

### 1.1 Componentes principais

- **App Web (Rails)**: API + servidor principal da aplicação.
- **Sidekiq**: processamento assíncrono (jobs).
- **PostgreSQL (pgvector)**: persistência.
- **Redis**: cache, filas e recursos em tempo real.
- **Vite**: assets/frontend em desenvolvimento.
- **Mailhog**: inspeção de e-mails em homologação.
- **Synapsea Analytics (scaffold)**: serviço Node/Fastify para protótipos de eventos, relatórios, automações e módulos operacionais.

### 1.2 Artefatos de apoio já no repositório

- Compose de instalação/teste: `docker-compose.install-test.yaml`.
- Guia rápido docker: `docs/docker-install-test.md`.
- Arquitetura Synapsea: `docs/synapsea-connect-architecture.md`.
- Checklist de QA/homologação: `docs/synapsea-connect-qa-homologation.md`.
- Validação por stacks: `docs/synapsea-validation-stacks.md`.

---

## 2) Pré-requisitos da VPS (homologação)

## 2.1 Infra mínima recomendada

- CPU: 4 vCPU
- RAM: 8 GB (mínimo funcional), ideal 16 GB
- Disco: 80 GB SSD
- SO: Ubuntu 22.04+ (ou equivalente Linux com Docker)

## 2.2 Software obrigatório

- Docker Engine 24+
- Docker Compose Plugin v2+
- Git
- Acesso HTTPS (Nginx/Traefik/Caddy) para ambiente exposto

## 2.3 Portas e rede

- Internas para stack: `3000`, `3036`, `4010`, `5432`, `6379`, `8025`, `1025`
- Externamente, em homologação pública, exponha preferencialmente apenas:
  - `80/443` (proxy reverso)
- Mantenha `5432`, `6379`, `8025`, `1025` bloqueadas externamente.

---

## 3) Estratégia de implantação (segura para homologação)

## 3.1 Branch/release

1. Fazer deploy por commit SHA (imutável).
2. Registrar no relatório: SHA, data/hora, operador/agente.
3. Nunca homologar “working tree sujo”.

## 3.2 Segredos e variáveis

- Criar `.env` com base no `.env.example`.
- Preencher obrigatórios (mínimo):
  - `REDIS_PASSWORD`
  - variáveis de banco
  - chaves da aplicação necessárias ao boot
- Não commitar `.env`.

## 3.3 Persistência

Garantir volumes persistentes para:

- Postgres
- Redis
- Bundler/node cache (quando apropriado)

---

## 4) Passo a passo de implantação na VPS

## 4.1 Clonar e preparar

```bash
git clone <repo-url> sentiia
cd sentiia
cp .env.example .env
# editar .env com segredos de homologação
```

## 4.2 Build e setup inicial

```bash
docker compose -f docker-compose.install-test.yaml run --rm setup
```

Esse passo instala dependências e prepara banco/seed.

## 4.3 Subir serviços

```bash
docker compose -f docker-compose.install-test.yaml up -d
```

## 4.4 Validar serviços vivos

```bash
docker compose -f docker-compose.install-test.yaml ps
```

Endpoints esperados (interno/VPS):

- App: `http://localhost:3000`
- Vite: `http://localhost:3036`
- Mailhog: `http://localhost:8025`
- Synapsea analytics scaffold: `http://localhost:4010`

## 4.5 Logs de estabilização

```bash
docker compose -f docker-compose.install-test.yaml logs -f rails sidekiq redis postgres
```

Aguardar estabilização sem erro fatal recorrente.

---

## 5) Validação técnica mínima antes da validação funcional

Executar no host do repositório (ou container apropriado):

```bash
pnpm exec eslint app/javascript/dashboard/components-next/sidebar/SidebarHelpCenter.vue app/javascript/dashboard/components-next/sidebar/Sidebar.vue app/javascript/dashboard/routes/dashboard/Dashboard.vue app/javascript/dashboard/helper/contextHelpContent.js
```

Se houver ambiente Ruby pronto e necessidade de verificação adicional:

```bash
bundle exec rails zeitwerk:check
```

Para scaffold de analytics:

```bash
cd services/synapsea-analytics
npm install
npm run typecheck
```

---

## 6) Plano de validação funcional (obrigatório)

Use o documento de stacks como fonte oficial de execução:

- `docs/synapsea-validation-stacks.md`

Ordem obrigatória:

1. Stack 0 — Base técnica
2. Stack 1 — Legado core
3. Stack 2 — Integrações existentes
4. Stack 3 — Filas/transferência
5. Stack 4 — Supervisor/realtime
6. Stack 5 — Automações
7. Stack 6 — Features Synapsea
8. Stack 7 — Permissões
9. Stack 8 — Analytics/IA
10. Stack 9 — Performance visual/responsividade/acessibilidade

### Regra de avanço

- Não avançar se existir falha P0/P1 em stack corrente.

### Formato de evidência

Para cada cenário testado, registrar:

- Stack
- Cenário
- Resultado (`OK`, `AJUSTE`, `ERRO`)
- Severidade (P0/P1/P2/P3)
- Evidência (print, vídeo curto, log)

---

## 7) Central de ajuda e auto treinamento (item crítico desta entrega)

A aplicação agora deve ser validada com foco em **autousabilidade**:

- Verificar botão de **Help center** no sidebar.
- Verificar painel lateral com busca e conteúdo por ação.
- Verificar recomendação por contexto (tela atual).
- Verificar ajuda contextual flutuante no dashboard/rotas suportadas.

Critério de aceite operacional:

- usuário novo consegue executar tarefas centrais sem suporte humano:
  - cadastrar contato
  - abrir conversa
  - responder
  - aplicar etiqueta
  - transferir

---

## 8) Critérios de GO / NO-GO para homologação

## GO

- Sem falhas P0/P1 nos stacks críticos (0 a 7).
- Permissões consistentes por perfil.
- Fluxos core estáveis sem erro crítico frontend/backend.
- Atualização em tempo real funcional nos fluxos de conversa/transferência.

## GO restrito

- Apenas P2/P3 sem impacto em operação principal.

## NO-GO

- Qualquer falha em login, conversa, transferência, permissão, automação core ou consistência operacional em tempo real.

---

## 9) Rollback seguro

## 9.1 Estratégia

- Rollback por commit/tag anterior estável.
- Preservar volumes de dados.
- Subir versão anterior e validar saúde mínima.

## 9.2 Comandos (exemplo)

```bash
git checkout <tag-ou-sha-estavel>
docker compose -f docker-compose.install-test.yaml up -d --build
```

Validar:

- login
- abrir conversa
- resposta
- transferências

---

## 10) Entregáveis obrigatórios do agente de implantação

Antes de declarar “pronto para homologação”, o agente deve publicar:

1. SHA implantado
2. Tabela de resultados por stack
3. Lista de falhas abertas com severidade
4. Evidências anexas (prints/logs)
5. Decisão final: `GO`, `GO RESTRITO` ou `NO-GO`

---

## 11) Modelo de relatório final (copiar/colar)

```md
# Relatório de implantação homologação

- Commit: <sha>
- Ambiente: <vps/hostname>
- Data/Hora: <UTC>
- Responsável: <agente/time>

## Resultado por stack

| Stack | Cenários OK | Ajustes | Erros | P0/P1? |
| ----- | ----------- | ------- | ----- | ------ |
| 0     | 8           | 0       | 0     | Não    |
| 1     | 15          | 1       | 0     | Não    |

...

## Falhas abertas

| ID  | Stack | Severidade | Descrição | Evidência | Dono |
| --- | ----- | ---------- | --------- | --------- | ---- |

## Decisão

- Status: GO | GO RESTRITO | NO-GO
- Justificativa: <resumo objetivo>
```

---

## 12) Observações finais

- Este runbook é para **homologação robusta**, não só smoke test.
- O objetivo é subir com base sólida para evitar retrabalho em produção.
- Sempre priorizar estabilidade de operação (atendimento, transferência, permissão e tempo real) antes de avançar em IA/estética.
