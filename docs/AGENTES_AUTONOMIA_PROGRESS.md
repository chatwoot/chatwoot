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
| A1 | DELETE_DIALOG i18n ausente (apagar agente quebra tela) | 🔄 em curso |
| A3 | Painel não recarrega ao trocar de agente (mistura dados) | ⏳ |
| A4 | Publicar externo não-atômico (agente zumbi se conexão falha) | ⏳ |
| B1 | Toast pós-ativação do copiloto (onde encontrar) | ⏳ |
| B2 | Selo "Copiloto interno" no card do hub | ⏳ |
| B3 | Estado vazio da aba Desempenho com orientação | ⏳ |
| B4 | Slider de confiança com legenda | ⏳ |
| B5 | Erro de upload com mensagem acionável | ⏳ |
| — | Codex review Onda 1 | ⏳ |
| — | Teste real (specs + servidor local) | ⏳ |

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

## Log de entregas
- 2026-07-03: plano aprovado (sem G3); branch Onda 1 criada em `06b10f9bd`.

## Pendências externas (fora deste plano)
- Deploy Autonomia bloqueado: PR #103 precisa `terraform apply` (Rodrigo/Roberto) + re-run
- OAuth conta 6: cadastrar Tenant ID da Onze onze (Gate 3)
