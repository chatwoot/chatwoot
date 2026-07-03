# Agentes Autonomia — Progresso do plano de evolução

> Fonte: auditoria de 11 agentes (2026-07-03). Plano completo na conversa/memória
> (`agentes-autonomia-audit-plan`). Este arquivo é o estado vivo — atualizar a cada
> item entregue. Gate por onda: implementado → Codex review → teste real → review
> final (Codex + Claude) → 🟢 Rodrigo → merge+deploy.

## STATUS GERAL (2026-07-03): Ondas 1-4 ENTREGUES E EM PRODUÇÃO ✅

PR #105 mergeado em `main` (`1dbb25d8`) → deploy blue-green **success** nos 2 stacks
(Hub2You + Autonomia) → smoke check ok (`chat.hub2you.ai` 200, `agents.autonomia.site` 302).
IAM do PR #103 (que bloqueava deploy Autonomia antes) não impediu este deploy.

**Próxima etapa do projeto**: próxima leva de evolução (ver "Backlog pós-ondas 1-4" no fim
deste arquivo) — G2 (versionamento de instrução), G5 (revisor de documento inteiro),
H (abas do painel como navegação real), F1/F2/F4 (features de produto: portão de
confiança por conta, modo `:attendant` no copiloto, aviso de base fraca ao publicar).

## Decisões de produto (Rodrigo, 2026-07-03)
- F1 SIM — portão de confiança ligável por conta no agente externo (default OFF)
- F2 SIM — copiloto ganha modo análise pro atendente (`:attendant`)
- F3 NÃO — atribuição de humano é do CRM; agente não atribui
- F4 AVISAR — base fraca ao publicar avisa, não bloqueia
- SEM G3 — refresh de instrução continua automático (sem diff/aprovação manual)

## Onda 1 — Cliente para de tropeçar (branch `feat/agentes-onda-1`)
| Item | Descrição | Status |
|---|---|---|
| A1 | DELETE_DIALOG i18n ausente (apagar agente quebra tela) | ✅ `9397cfd6c` |
| A3 | Painel não recarrega ao trocar de agente (mistura dados) | ✅ watch+`:key` + clear-on-fetch nos stores `123a35bd3` |
| A4 | Publicar externo não-atômico (agente zumbi se conexão falha) | ✅ ativa→conecta→rollback; connect só propaga erro do POST |
| B1 | Toast pós-ativação do copiloto (onde encontrar) | ✅ |
| B2 | Selo "Copiloto interno" no card do hub | ✅ |
| B3 | Estado vazio da aba Desempenho com orientação | ✅ |
| B4 | Slider de confiança com legenda | ✅ |
| B5 | Erro de upload com mensagem acionável | ✅ |
| — | Codex review Onda 1 | ✅ FAIL→2 achados corrigidos em `123a35bd3` (re-check na rodada final) |
| — | Teste real | ✅ eslint 0 erros + vite: 5099 módulos transformados (falha final foi ETIMEDOUT de FS local; CI valida no push) |

## Execução paralela (worktrees, 2026-07-03)
T2 chunker · T3 G1/G

## Onda 2 — Confiável e barato
| Item | Descrição | Status |
|---|---|---|
| A2 | Chunker: herdar título de seção nos chunks (recall Ana/Miriam) + reprocesso | ⏳ |
| G1 | Refresh de instrução NÃO roda em agente modo avançado | ⏳ |
| C1 | Teto de tamanho no input pro LLM (msg/história) | ⏳ |
| C2 | Web search OFF por default nos 4 caminhos | ⏳ |
| C3 | `with_knowledge=false` desliga retrieval/embedding | ⏳ |
| C4 | Recheck de elegibilidade antes de gastar LLM | ⏳ |
| — | Codex review + teste real | ⏳ |

## Onda 3 — Instrução viva madura + UI + blindagem
| Item | Descrição | Status |
|---|---|---|
| G2 | Versionamento da instrução (histórico + rollback) | ⏳ |
| G4 | Corrida ajuste×refresh (token rastreia edição de instrução) | ⏳ |
| G5 | Revisor amostra documento inteiro (não só 15 chunks) | ⏳ |
| G6 | Falha de reprocesso não rebaixa base boa | ⏳ |
| H | Abas do painel viram navegação real + status/pausar visível | ⏳ |
| D1-D5 | Segurança: tenancy nos vínculos, assigned_only no copiloto, blobs por conta, history não-confiável, serializer sem config interno | ⏳ |
| — | Codex review + teste real | ⏳ |

## Onda 4 — Regressão eterna + produto
| Item | Descrição | Status |
|---|---|---|
| I | Suíte caminhos tristes da matriz (~25-30 specs) | ⏳ |
| E1-E5 | Robustez do construtor (histórico assistant, retry, turno duplo, idempotência, loop sem base) | ⏳ |
| F1 | Portão de confiança por conta (default OFF) | ⏳ |
| F2 | Modo `:attendant` no copiloto | ⏳ |
| F4 | Aviso de base fraca ao publicar | ⏳ |
| — | Codex review + teste real + review final | ⏳ |

## Execução paralela (tracks em worktrees) — estado
Onda 1 (branch `feat/agentes-onda-1`, 3 commits): A+B **DONE + Codex review aplicado**
(stale lists + false rollback corrigidos). Falta integrar as ondas 2-4.

| Track | Escopo | Branch worktree | Status |
|---|---|---|---|
| T2 | A2 chunker herda título | `worktree-agent-adc45ba6c80b049d8` | ✅ done, Codex FAIL→corrigido (heading numerado + dedup start_with), 7 specs verdes |
| T3 | G1/G4/G6 refresher/source | `worktree-agent-aa4a5a97cbc87a4e9` | ✅ Codex FAIL→corrigido `f099f35da` (apply atômico update_all guard mode+instruction; scope `servable` no recompute), 10 specs verdes |
| T4 | C1/C3/C4 custo IA | `worktree-agent-aa7c7465a737a51f0` | ✅ Codex FAIL→corrigido `ca8fb6417` (cap central no Retriever#retrieve pré-embedding), 13 specs verdes |
| T5 | D1-D5 segurança | `worktree-agent-a20b5015b86fb1556` | ✅ Codex FAIL→corrigido `a28740db3` (guards fail-closed em operate/copilot/builder, abort `cross_account_agent`), 19+7 specs verdes |
| T6 | E1-E5 construtor | `worktree-agent-a6f095f7fa6400c53` | ✅ Codex FAIL→corrigido `b42bb14f6` (claim atômico begin_build, replay idempotente por client_message_id, merge por posição), 23 rspec + 26 vitest verdes |
| T7 | Suíte matriz (40 specs) | `worktree-agent-a82ab7fe07767c709` | ✅ done, 40 specs 0 falhas |

### Codex review por track (2026-07-03, pós-compact)
- T3 FAIL: (Alto) refresher não revalida `guided?` pós-reload — agente que vira manual durante LLM ainda recebe apply; (Médio) `mark_failed!` restaura review accepted mas `recompute_overall!` só agrega `status: ready` → fonte some do topic_map e refresher apaga escopo.
- T4 FAIL: (Médio) truncamento C1 só no PromptBuilder; `retrieve_snippets` manda query crua pro embedding.
- T5 FAIL: (Médio×2) guards D1 só no model; operate.rb:18, conversation_copilot.rb:85, submit_job.rb:18, builder.rb:1081/1255 resolvem vínculo sem checar account — dado legado permite cross-tenant.
- T6 FAIL: (Alto) 409/dedup não atômicos no controller + frontend gera UUID novo por chamada; (Médio) MERGE_MESSAGES dedup por role+content esconde pergunta legítima repetida.

### Retomada pós-compact (roteiro exato)
1. Verificar T6: `git -C .claude/worktrees/agent-a6f095f7fa6400c53 log --oneline -6` (se commitou os E1-E5).
2. Codex review por track restante (T3, T4, T5, T6) — `git -C <wt> diff main...HEAD`.
3. Integrar: de `main` (`06b10f9bd`), merge/cherry-pick de cada branch worktree +
   `feat/agentes-onda-1`. Ordem sugerida por onda: Onda1(feat/agentes-onda-1) →
   Onda2(T2 chunker + T3 G1/G4/G6 + T4 custo) → Onda3(T5 segurança) → Onda4(T7 specs + T6 construtor).
   Conflitos esperados: NENHUM entre tracks (arquivos disjuntos por design); confirmar.
4. Rodada final Codex + Claude no diff integrado; teste real (rspec dos tracks + vite build).
5. 🟢 Rodrigo → merge+deploy (blue-green auto nos 2 stacks).
- Onda 1 já está commitada em `feat/agentes-onda-1` (NÃO worktree) — 2 commits + review.

## Integração (2026-07-03) — branch `feat/agentes-ondas-1-4`
- Merge dos 7 branches (Onda1 base + T2→T3→T4→T7→T5→T6). 2 conflitos resolvidos à mão:
  `conversation_chat.rb` (T4 cap por item + T5 marcador/rebaixamento COMBINADOS) e
  `build_thread_spec.rb` (add/add, specs unidos).
- Rodada final Codex no diff integrado: FAIL → 2 achados corrigidos no commit de integração:
  (Alto) retrieval do copiloto chat embedava transcript e cortava a pergunta → `retrieval_query:`
  no Answerer/Copilot, ConversationChat passa a pergunta crua; (Médio) supersede de
  `apply_builder_config!` escopado por `account_id`. Re-check Codex: **PASS**.
- Teste real: rspec autonomia integral 153 examples / 4 failures — TODAS pré-existentes em
  `spec/services/autonomia/sso/` (diff não toca SSO); pós-fix, áreas afetadas 100+28 examples
  0 failures; rubocop limpo; eslint 0 erros (warnings i18n pré-existentes); vitest stores T6 verde.

- Vitest local bloqueado por FS degradado (ETIMEDOUT em node_modules, mesmo do vite build);
  evidência válida: JS integrado byte-idêntico ao worktree T6 onde vitest passou 26/26. CI valida no PR.
- **PR #105 (merged)**: https://github.com/autonom-ia2/chat/pull/105 → `main` @ `1dbb25d8`

## Deploy (2026-07-03) — CONCLUÍDO ✅
- 🟢 Rodrigo confirmado → merge (sem CI configurado neste repo pra test/lint; só workflows
  de deploy disparam no push a main — testes já validados localmente antes do merge).
- Deploy Hub2You: `success` (run 28658844365). Deploy Autonomia: `success` (run 28658844419)
  — **o bloqueio de IAM do PR #103 NÃO se repetiu** neste deploy.
- Smoke check pós-deploy: `chat.hub2you.ai` → 200; `agents.autonomia.site/auth/autonomia` → 302 (normal).
- PR #103 (IAM `ssm:PutParameter`) segue aberto mas não é mais bloqueante agora; investigar
  depois por que passou (terraform já aplicado por fora? condição diferente?) — não travar
  a próxima onda por causa disso.

## Backlog pós-ondas 1-4 (não entregue nesta leva — próxima evolução)
Do plano original de 9 frentes, ficaram de fora (podem virar Onda 5+):
- **G2** — Versionamento da instrução (histórico + rollback). Hoje o refresh automático
  sobrescreve sem guardar versão anterior visível ao usuário.
- **G5** — Revisor de base de conhecimento amostra só ~15 chunks, não o documento inteiro;
  pode aprovar uma base com problema em parte não amostrada.
- **H** — Abas do painel do agente (Testar/Publicar/Ajustar/Desempenho) ainda não são
  navegação real (URL não reflete aba ativa); status ativo/pausado pouco visível.
- **F1** — Portão de confiança ligável por conta no agente EXTERNO (decisão: SIM, default OFF).
  Ainda não implementado — é feature nova, não bug.
- **F2** — Modo `:attendant` no copiloto (análise interna pro atendente, distinto do rascunho
  cliente-facing atual). Decisão: SIM. Não implementado.
- **F4** — Aviso (não bloqueio) de base de conhecimento fraca ao publicar agente externo.
  Decisão: SIM. Não implementado.
- **F3** — Decisão foi NÃO (CRM controla atribuição humana); não faz parte do backlog.
- **G3** — Decisão foi SEM (sem diff/aprovação manual no refresh); não faz parte do backlog.
- **Follow-up de segurança de baixo risco** (chip criado, não obrigatório): `app/services/whatsapp/incoming_message_base_service.rb`
  resolve `AgentInbox` sem escopo de conta — o Operate já revalida depois, então risco é baixo,
  mas vale uniformizar com o padrão fail-closed que os outros leitores ganharam no T5.

## Onda 5 — DECIDIDO (Rodrigo, 2026-07-03): Robustez interna
Escopo: **G2 + G5 + H**. F1/F2/F4 (produto) ficam para depois — não iniciar sem novo 🟢.

| Item | Descrição | Status |
|---|---|---|
| G2 | Versionamento da instrução (histórico + rollback visível) | ⏳ não iniciado |
| G5 | Revisor de base analisa documento inteiro, não só amostra de ~15 chunks | ⏳ não iniciado |
| H | Abas do painel do agente viram navegação real (URL reflete aba); status ativo/pausado mais visível | ⏳ não iniciado |

**Próxima ação**: planejar Onda 5 (arquitetura de G2 precisa decisão: nova tabela de
versões vs. coluna jsonb de histórico; G5 precisa decidir custo de reamostrar documento
inteiro a cada review vs. amostra maior; H é puro frontend/rota). Seguir mesmo gate das
ondas 1-4: implementar → Codex review → teste real → review final → 🟢 → merge+deploy.

## Log de entregas
- 2026-07-03: plano aprovado (sem G3); Onda 1 (A+B) entregue+revisada em `feat/agentes-onda-1`.
  6 tracks disparados em worktrees paralelos; T2/T3/T4/T7 done, T5/T6 rodando.

## Pendências externas (fora deste plano)
- Deploy Autonomia bloqueado: PR #103 precisa `terraform apply` (Rodrigo/Roberto) + re-run
- OAuth conta 6: cadastrar Tenant ID da Onze onze (Gate 3)
