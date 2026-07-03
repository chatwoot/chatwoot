# Agentes Autonomia — Progresso do plano de evolução

> Fonte: auditoria de 11 agentes (2026-07-03). Plano completo na conversa/memória
> (`agentes-autonomia-audit-plan`). Este arquivo é o estado vivo — atualizar a cada
> item entregue. Gate por onda: implementado → Codex review → teste real → review
> final (Codex + Claude) → 🟢 Rodrigo → merge+deploy.

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

**Próxima ação (pós-compact):** Codex review T3/T4/T5/T6; integrar todos os branches
numa branch de release por onda (ou uma só); rodada final (Codex + Claude); teste real;
🟢 Rodrigo → merge+deploy. Integração = `git -C <worktree> diff main...HEAD` por track,
cherry-pick/merge na branch alvo; cuidado só com C2 (web search) se algum track tocou
os mesmos call sites.

## Log de entregas
- 2026-07-03: plano aprovado (sem G3); Onda 1 (A+B) entregue+revisada em `feat/agentes-onda-1`.
  6 tracks disparados em worktrees paralelos; T2/T3/T4/T7 done, T5/T6 rodando.

## Pendências externas (fora deste plano)
- Deploy Autonomia bloqueado: PR #103 precisa `terraform apply` (Rodrigo/Roberto) + re-run
- OAuth conta 6: cadastrar Tenant ID da Onze onze (Gate 3)
