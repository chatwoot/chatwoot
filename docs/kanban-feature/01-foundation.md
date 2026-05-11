# Fase 1 — Fundação de dados

## Objetivo
Preparar o schema para suportar ordenação automática por timestamps e histórico rico de eventos (com origem manual/macro/system, tipo de evento e metadata estruturada), sem alterar o comportamento atual do produto. Esta fase é apenas habilitadora — nada visível para o usuário muda.

---

## Mudanças de schema

### Tabela `kanban_cards`
| Campo | Tipo | Null? | Default | Observação |
|---|---|---|---|---|
| `entered_stage_at` | `datetime` | `false` | — | Data/hora em que o card entrou na coluna atual. Atualizado em todo move. Backfill = `created_at`. |

**Índice**: `add_index :kanban_cards, [:kanban_column_id, :entered_stage_at]` — composto, suporta ordenação por coluna na Fase 2.

### Tabela `kanban_card_activities`
| Campo | Tipo | Null? | Default | Observação |
|---|---|---|---|---|
| `source` | `integer` | `false` | `0` | Enum: `manual: 0`, `macro: 1`, `system: 2` |
| `event_type` | `integer` | `false` | `0` | Enum: `stage_changed: 0`, `conversation_closed: 1`, `closure_cancelled: 2`, `macro_triggered: 3` |
| `metadata` | `jsonb` | `false` | `{}` | Estrutura por event_type — ver tabela abaixo |

**Mudanças em colunas existentes** (associações se tornam opcionais para acomodar os novos `event_type`):
- `from_column_id`: passa a permitir `null` (já era opcional como FK; ajustar `belongs_to :from_column, optional: true` em [kanban_card_activity.rb](app/models/kanban_card_activity.rb))
- `to_column_id`: pode ser `null` em eventos sem mudança de coluna (ex: `closure_cancelled` registrado antes do macro mover)
- `user_id`: pode ser `null` quando ação é do sistema/macro

**Índice**: `add_index :kanban_card_activities, :event_type` — para queries futuras filtrando por tipo (ex: timeline filtrada).

### Backfill (mesmo migration ou separado)
- `kanban_cards.entered_stage_at = created_at` para todos registros existentes — usar batches:
  ```ruby
  KanbanCard.in_batches(of: 1000).update_all('entered_stage_at = created_at')
  ```
- `kanban_card_activities.source = 0` (manual) e `event_type = 0` (stage_changed) já vêm do default, mas garantir explicitamente

### Estrutura de `metadata` por `(event_type, source)`

| event_type | source | Chaves esperadas |
|---|---|---|
| `stage_changed` | `manual` | `{}` |
| `stage_changed` | `system` | `{ trigger: "conversation_resolved" }` |
| `stage_changed` | `macro` | `{ macro_id, macro_name }` |
| `conversation_closed` | `manual` ou `system` | `{ classification_id, classification_name, classification_type }` (vazio se sem classificação) |
| `closure_cancelled` | `system` | `{ original_classification_id, reason }` (reason ∈ `new_message_received` / `manual_reopen_within_window` / `manual_reopen`) |
| `macro_triggered` | `macro` | `{ macro_id, macro_name, action }` (uso futuro — ações de macro que não movem) |

Validação custom no model — método `validate_metadata_schema` checa a combinação `(event_type, source)` e exige as chaves obrigatórias da linha correspondente. Validação leve (presença), não tipagem rígida.

---

## Novas classes / serviços e responsabilidades

Nenhuma classe nova nesta fase. Apenas extensões:

### [app/models/kanban_card.rb](app/models/kanban_card.rb)
- Callback `before_save :touch_entered_stage_at` que atualiza `entered_stage_at = Time.current` quando `kanban_column_id_changed?`
- Na criação, `entered_stage_at = Time.current`

### [app/models/kanban_card_activity.rb](app/models/kanban_card_activity.rb)
- Definir os dois enums (`source`, `event_type`)
- Marcar `belongs_to :from_column`, `:to_column`, `:user` com `optional: true`
- Validação custom `validate :validate_metadata_schema` — checa chaves esperadas por combinação `(event_type, source)` conforme tabela acima
- Scope `recent` (ordenado desc por `created_at`) já existe — manter

### [app/services/kanban/card_sync_service.rb](app/services/kanban/card_sync_service.rb)
- Ao criar activities geradas pelo service (move automático para won/lost via resolução), passar `source: :system, event_type: :stage_changed`
- Passar `metadata: { classification_id: ..., classification_name: ..., classification_type: ... }` quando aplicável (toca também a Fase 8, mas o caminho de criação fica preparado aqui)

### [app/controllers/api/v1/accounts/kanban/cards_controller.rb#move](app/controllers/api/v1/accounts/kanban/cards_controller.rb)
- Passar `source: :manual, event_type: :stage_changed` ao criar a activity (linha ~48-56)

---

## Pontos de integração com código existente

| Arquivo | Mudança |
|---|---|
| `db/migrate/<ts>_add_entered_stage_at_to_kanban_cards.rb` | nova migration |
| `db/migrate/<ts>_extend_kanban_card_activities.rb` | nova migration (campos + backfill + opcionais) |
| [app/models/kanban_card.rb](app/models/kanban_card.rb) | callback de touch |
| [app/models/kanban_card_activity.rb](app/models/kanban_card_activity.rb) | enums, optional, validação |
| [app/services/kanban/card_sync_service.rb](app/services/kanban/card_sync_service.rb) | passar source/event_type/metadata em activities geradas |
| [app/controllers/api/v1/accounts/kanban/cards_controller.rb](app/controllers/api/v1/accounts/kanban/cards_controller.rb) | passar source/event_type no move manual |
| [app/views/api/v1/models/_kanban_card.json.jbuilder](app/views/api/v1/models/_kanban_card.json.jbuilder) (verificar nome real) | expor `entered_stage_at` no JSON do card |
| Serializer/jbuilder de activity | expor `source`, `event_type`, `metadata` |

---

## Endpoints novos ou modificados

Nenhum endpoint novo. Resposta de `GET /api/v1/accounts/:id/kanban/board` ganha campos:
- Card: `entered_stage_at` (ISO 8601 com timezone — confirmar formato no serializer/jbuilder; alinhado com `created_at` e demais timestamps do payload)
- Activity: `source` (string), `event_type` (string), `metadata` (object)

Sem breaking change — apenas adições.

---

## Mudanças no frontend

Mínimas. O modal de histórico do card ([KanbanCardModal.vue](app/javascript/dashboard/routes/dashboard/kanban/components/KanbanCardModal.vue), aba `history`) precisa renderizar texto adequado por `event_type`:

| event_type | Texto sugerido (i18n) |
|---|---|
| `stage_changed` (manual, com user) | "{user} moveu de {from} para {to}" |
| `stage_changed` (system, sem user) | "Sistema moveu para {to}" |
| `stage_changed` (macro) | "Macro \"{macro_name}\" moveu para {to}" |
| `conversation_closed` | "Conversa encerrada — classificação: {classification_name}" |
| `closure_cancelled` | "Encerramento cancelado por nova mensagem" |
| `macro_triggered` (sem move) | "Macro \"{macro_name}\" disparou" |

Adicionar chaves em `config/locales/en.json` (frontend) sob `KANBAN.CARD_HISTORY.*`.

Componente segue o mesmo layout existente; só muda a função que monta o texto.

---

## Trade-offs e decisões não óbvias

### 1. `entered_stage_at` denormalizado em vez de derivado do último activity
**Escolha já decidida pelo usuário.**
- **Por quê:** ordenação por timestamp em SQL é direta com índice; derivar exigiria subquery/window function por card.
- **Risco:** dessincronia se algum código bypass o callback. **Mitigação:** callback no `before_save` do model — não confiar em chamadas via service.

### 2. `event_type` como enum em vez de string livre
- **Por quê:** os tipos são finitos e conhecidos; queries por tipo são frequentes.
- **Implicação:** macros novos NÃO criam `event_type` novo. Todos macros usam `macro_triggered` e diferenciam por `metadata.macro_id`. Isso mantém o enum estável.

### 3. Tornar `from_column_id`, `to_column_id`, `user_id` opcionais
- Hoje toda activity é uma movimentação manual com from→to e user.
- Eventos novos (ex: `macro_triggered` que só logou sem mover, `closure_cancelled`) precisam dessas FKs nulas.
- **Mitigação:** validação condicional por `event_type`:
  - `stage_changed` exige `to_column_id` presente
  - `conversation_closed` exige `metadata.classification_id`
  - etc.

### 4. Backfill de `entered_stage_at` usando `created_at`
- Aproximação. Para precisão, derivar do último activity de tipo `stage_changed`.
- **Decisão:** `created_at` é suficiente — feature é nova, dados existentes têm vida curta como referência de ordenação.

### 5. Não tocar em `position` ainda
- Mantém o campo, drag manual atual continua funcional até a Fase 2 desabilitar.
- Posicionalmente: Fase 2 para de gravar/ler `position`; remoção do campo pode acontecer em PR futuro de cleanup.

### 6. Validação de `metadata` por event_type
- Fazer no model (`validate :validate_metadata_schema`) com lógica simples de presença de chaves obrigatórias.
- Não usar `json_schema` gem por enquanto — overhead desnecessário para 4 tipos.

---

## Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Migration de backfill demora em conta com muitos cards/activities | Usar `update_all` em batches; rodar fora do pico se necessário |
| Callback `touch_entered_stage_at` não dispara em `update_columns` (pula callbacks) | Documentar no model; auditar uso de `update_columns` em código que move cards |
| Validação de metadata muito estrita quebra criação de activities legadas | Permitir `metadata: {}` para `stage_changed` (default), exigir só nos novos tipos |

---

## Critérios de aceite (validação manual)
1. Cards existentes têm `entered_stage_at` preenchido após migration (= `created_at`).
2. Mover um card via API atualiza `entered_stage_at` para `Time.current`.
3. Activity criada via move manual tem `source: 'manual'`, `event_type: 'stage_changed'`.
4. Activity criada via `CardSyncService` (resolução de conversa) tem `source: 'system'`.
5. Histórico no modal continua renderizando corretamente para activities antigas (compatibilidade).
6. Nenhum endpoint público quebra (apenas campos adicionais aparecem).

---

## Checklist concreta do PR1 (entrega da fase)

- [ ] **Auditar `update_columns` / `update_column` em `KanbanCard`:**
  ```bash
  grep -rn 'update_columns\|update_column' app/ | grep -i kanban
  ```
  Para cada ocorrência:
  - Trocar por `update` (passa pelos callbacks), **ou**
  - Manter e adicionar `touch :entered_stage_at` explícito se a coluna mudou.
  - **Listar todas as ocorrências encontradas (e como foram tratadas) na descrição do PR.**
- [ ] Migration de schema (kanban_cards) com backfill em batches.
- [ ] Migration de schema (kanban_card_activities) com defaults explícitos.
- [ ] Callback `before_save :touch_entered_stage_at` no model.
- [ ] Validação `validate_metadata_schema` no `KanbanCardActivity`.
- [ ] Serializer/jbuilder atualizado para expor novos campos.
- [ ] Frontend: renderização de novos `event_type`s no histórico.
- [ ] i18n: novas chaves em `en.json`.
