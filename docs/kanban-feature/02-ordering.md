# Fase 2 — Ordenação FIFO determinística

## Objetivo
Substituir a ordenação manual por `position` (drag-drop) por ordenação determinística por timestamps: `auto_receive` ordena por `conversation.created_at` ascendente, demais colunas por `entered_stage_at` ascendente. Drag intra-coluna fica desabilitado; drag entre colunas continua.

---

## Mudanças de schema

Nenhuma. Tudo o que é necessário foi entregue na Fase 1 (`entered_stage_at` no card, `entered_stage_at` indexado por coluna).

**Sobre o campo `position`:** mantido por compatibilidade, deixa de ser lido e escrito. Adicionar comentário no model:
```ruby
# DEPRECATED: ordenação agora é determinística via `entered_stage_at`
# (ou `conversation.created_at` em colunas auto_receive). Campo mantido
# por compatibilidade. Remover em PR de cleanup futuro.
```
Remoção fica para um PR de cleanup futuro (não bloqueante).

**Sobre `entered_stage_at` na API:** strong params dos endpoints de update **não devem aceitar** `entered_stage_at` — campo é gerenciado exclusivamente pelo callback. Comentário no model:
```ruby
# Managed exclusively by the before_save callback `touch_entered_stage_at`.
# Do not assign directly — manual edits break FIFO ordering guarantees.
```

**Índice em `conversations(created_at)` — VERIFICADO ✓:**
- Existe `index_conversations_on_account_id_and_created_at` (composto, `account_id + created_at`).
- O JOIN do scope `ordered_for_column` filtrará por `account` indiretamente (via card.account → conversation.account), e o ORDER BY usará a porção `created_at` do índice composto.
- **Nenhuma migration adicional necessária.** Registrar nessa descrição do PR1.

---

## Novas classes / serviços e responsabilidades

Nenhuma classe nova. Apenas extensões em [kanban_card.rb](app/models/kanban_card.rb):

### Scope `ordered_for_column(column)`
```ruby
scope :ordered_for_column, ->(column) {
  if column.column_function == 'auto_receive'
    left_joins(:conversation)
      .order(Arel.sql('COALESCE(conversations.created_at, kanban_cards.created_at) ASC'))
      .order(:id)
  else
    order(:entered_stage_at).order(:id)
  end
}
```

- Tie-break por `id ASC` para determinismo (dois cards com mesmo timestamp).
- `LEFT JOIN` + `COALESCE` para suportar cards manuais sem `conversation_id`.

### Remover `default_scope { order(:position) }` (se existir)
Default scopes são pegadinha em Rails — preferir scope explícito chamado no controller.

---

## Pontos de integração com código existente

### Backend
| Arquivo | Mudança |
|---|---|
| [app/models/kanban_card.rb](app/models/kanban_card.rb) | Adicionar `ordered_for_column`. Remover ordenação default por `position` se houver. |
| [app/controllers/api/v1/accounts/kanban/boards_controller.rb](app/controllers/api/v1/accounts/kanban/boards_controller.rb) (ou onde monta payload do board) | Aplicar `cards.ordered_for_column(column)` ao agrupar cards por coluna |
| [app/controllers/api/v1/accounts/kanban/cards_controller.rb#move](app/controllers/api/v1/accounts/kanban/cards_controller.rb) | Endpoint deixa de aceitar/usar `before_position` e `after_position` (parâmetros são ignorados). `target_column_id` é o único que importa. Log warn se vierem para auditar callers. |
| [app/services/kanban/card_sync_service.rb](app/services/kanban/card_sync_service.rb) | Remover `with_position_retry` e cálculo de `position`. Posição é determinística pelo timestamp; race conditions de posição deixam de existir. |

### Frontend
| Arquivo | Mudança |
|---|---|
| [KanbanColumn.vue](app/javascript/dashboard/routes/dashboard/kanban/components/KanbanColumn.vue) | Configurar `vuedraggable` com `:sort="false"` para impedir reordenação intra-coluna. Drag entre colunas mantém-se via `group="kanban-cards"`. |
| [actions.js — kanban store](app/javascript/dashboard/store/modules/kanban/actions.js) | `moveCard` deixa de enviar `before_position` / `after_position` ao backend |
| [getters.js — kanban store](app/javascript/dashboard/store/modules/kanban/getters.js) | `getCardsByColumn` deixa de re-ordenar por `position` no client; usa a ordem do servidor (server entrega já ordenado) |
| [mutations.js](app/javascript/dashboard/store/modules/kanban/mutations.js) | `MOVE_CARD_OPTIMISTIC` insere card no fim da coluna destino (será reordenado quando server responder e o reload acontecer); ajustar `REVERT_CARD_MOVE` para não depender de posição original |

---

## Endpoints novos ou modificados

### `GET /api/v1/accounts/:id/kanban/board`
- **Sem breaking change.** Cards já vêm ordenados por coluna conforme regra.
- Campo `position` continua presente no payload (por compatibilidade) mas frontend ignora.

### `POST /api/v1/accounts/:id/kanban/cards/:id/move`
- **Parâmetros aceitos:** `target_column_id` (obrigatório).
- **Parâmetros ignorados (deprecados):** `before_position`, `after_position`. Não retorna erro se vierem — apenas ignora.
- Resposta: o card movido com `entered_stage_at` atualizado.

---

## Mudanças no frontend (detalhe)

### Drag-drop comportamental

`vuedraggable` (Vue 3 wrapper de `Sortable.js`):
- `:sort="false"` na lista impede reordenação dentro daquela lista (drop dentro da mesma lista não muda ordem visualmente).
- `group="kanban-cards"` mantido para permitir drag entre listas (entre colunas).
- Como `sort: false` afeta o comportamento de drop de fora também (validar): pode ser necessário usar `:move="onMoveValidator"` que retorna `true` se `evt.from !== evt.to` e `false` se for o mesmo container.

**Validação prática necessária:** testar empiricamente se `sort: false` na lista mantém drag inter-coluna saudável. Se houver glitch, alternativa é interceptar no `@change` e ignorar eventos `moved` (intra-lista) processando só `added`/`removed`.

### Atualização otimista após drop — inserção ordenada

Para evitar "snap" visual (card aparece no fim e depois pula pra posição correta), o store calcula a posição ordenada localmente:

```js
// helper no store kanban
function insertSortedByRule(cards, newCard, column) {
  if (column.column_function === 'auto_receive') {
    // Ordenar por conversation.created_at ASC, tie-break por id
    const ts = c => new Date(c.conversation?.created_at || c.created_at).getTime();
    const idx = cards.findIndex(c => ts(c) > ts(newCard) || (ts(c) === ts(newCard) && c.id > newCard.id));
    if (idx === -1) cards.push(newCard); else cards.splice(idx, 0, newCard);
  } else {
    // Demais colunas: entered_stage_at é "agora" (mais recente) → vai pro fim
    cards.push(newCard);
  }
}
```

- `MOVE_CARD_OPTIMISTIC`: remove da coluna origem, chama `insertSortedByRule(targetColumnCards, card, targetColumn)`.
- Após response do servidor, substitui o card pelo retorno (entered_stage_at definitivo) e reordena se necessário.
- `REVERT_CARD_MOVE`: chama `insertSortedByRule` na coluna original (mantém ordem correta no rollback).

Elimina o "snap" no caminho feliz e no de erro.

### UX: feedback visual

- Drag começa normalmente. Se usuário tenta soltar na mesma coluna, o item retorna sem chamar API (pode ter um pequeno "snap back" visual — aceitável).
- **Decisão de polish para iteração futura:** se o snap back incomodar, mudar cursor durante drag intra-coluna ou exibir tooltip "Ordem é automática nesta etapa".

---

## Trade-offs e decisões não óbvias

### 1. JOIN com `conversations` na auto_receive
- **Custo:** uma query extra (LEFT JOIN) ao montar o board.
- **Mitigação:** índice em `conversations(created_at)` já existe (provável); se não, criar.
- **Plano de fallback:** se virar gargalo medível, denormalizar `conversation_created_at` no card (atualizado via callback no `Conversation` quando `created_at` muda — i.e., apenas na criação). Custo: campo redundante. Não fazer agora.

### 2. Cards manuais (sem `conversation_id`) na auto_receive
- Usar `COALESCE(conversations.created_at, kanban_cards.created_at)` no ORDER BY.
- Card manual entra "no momento de sua criação", consistente com a lógica de FIFO.

### 3. Posicionamento determinístico elimina race conditions
- Antes, `with_position_retry` em [CardSyncService](app/services/kanban/card_sync_service.rb) lidava com `RecordNotUnique` em `(column_id, position)`.
- Sem `position`, sem race. Código fica mais simples.
- **Cuidado:** se algum código externo ainda escreve em `position`, validar que é morto.

### 4. `position` deprecado mas mantido
- Remover em PR futuro reduz risco desta fase.
- Não escrever mais nele evita drift; ler dele é zero (frontend ignora).

### 5. Drag intra-coluna desabilitado: UX consistente
- Reforça a mensagem "ordem é determinística" para o usuário. Atendentes entendem que não há "manipulação de fila".
- Se UX feedback futuro pedir override manual em casos especiais, adicionamos um campo `manual_priority_override` separado, sem voltar ao `position`. Não fazer agora.

### 6. Atomicidade da ordenação após move automático
- Quando macro move card via Fase 5, o `entered_stage_at` é atualizado dentro do mesmo callback. Não há risco de ver o card "fora de ordem" no intervalo.

---

## Riscos e mitigação

| Risco | Mitigação |
|---|---|
| `vuedraggable` `sort: false` ter comportamento inesperado para drag inter-coluna | Validar empiricamente; alternativa: interceptar `@change` ignorando eventos `moved` |
| Performance do JOIN em board com muitas colunas/cards | Índice composto `(account_id, created_at)` confirmado em `conversations`. Plano B (denormalização de `conversation_created_at` no card) documentado se virar gargalo. Validar com `EXPLAIN ANALYZE` em volume razoável antes do merge — o composto pode degradar para seq scan se o ORDER BY não conseguir aproveitar o sufixo do índice. |
| Cards "saltam" visualmente após server response | Mitigado pelo `insertSortedByRule` (inserção otimista já ordenada). Pequeno ajuste só se timestamps locais divergirem do servidor por skew de clock — aceitável. |
| Frontend antigo cacheado tenta enviar `before_position`/`after_position` | Backend ignora silenciosamente (não retorna 422); deploy backend antes de frontend |

---

## Critérios de aceite (validação manual)
1. Em "Aguardando atendimento" (auto_receive), cards aparecem ordenados por `conversation.created_at` ascendente.
2. Em demais colunas, cards aparecem ordenados por `entered_stage_at` ascendente.
3. Tentar arrastar um card para reordenar dentro da mesma coluna não tem efeito.
4. Arrastar um card de uma coluna para outra funciona; ele aparece na posição correta na coluna destino conforme o critério.
5. `entered_stage_at` é atualizado quando card muda de coluna (validar via API).
6. Cards manuais (sem conversation) na auto_receive ordenam pelo `created_at` do card.
7. Empate de timestamps: ordem é estável entre refreshes (tie-break por `id`).
