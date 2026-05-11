# Fase 8 — Fluxo de encerramento + cancelamento implícito

## Objetivo
Concluir o ciclo de encerramento da conversa via kanban: registrar evento estruturado quando uma conversa é resolvida via fluxo do kanban, e detectar/registrar o caso em que uma resolução é "cancelada" implicitamente por uma nova mensagem do lead chegando logo após. Reaproveita 100% da `ResolutionModal` que já existe.

---

## Mudanças de schema

**Nenhuma.** Toda estrutura necessária já está em Fase 1 (`event_type: conversation_closed` e `closure_cancelled`, `metadata` jsonb).

---

## Novas classes / serviços e responsabilidades

Esta fase é **mais sobre integração e regra de negócio** do que sobre classes novas.

### Hook — `Conversation` ([app/models/conversation.rb](app/models/conversation.rb))

Já existe `after_update_commit :sync_kanban_card`. Estender a lógica para emitir eventos pra engine de macros e registrar activities específicas:

```ruby
KANBAN_CLOSURE_CANCELLATION_WINDOW = 5.minutes

after_update_commit :handle_kanban_status_transitions

private

def handle_kanban_status_transitions
  return unless saved_change_to_status?
  before, after = saved_change_to_status
  
  if before != 'resolved' && after == 'resolved'
    record_kanban_closure
    Kanban::CardSyncService.new(self).sync_on_resolution  # chamada explícita; ordem controlada
  elsif before == 'resolved' && after == 'open'
    record_kanban_reopening_if_recent
  end
end

def record_kanban_closure
  card = kanban_card
  return unless card
  KanbanCardActivity.create!(
    kanban_card: card,
    from_column: nil,  # encerramento não é move
    to_column: nil,
    user: Current.user,
    source: Current.user.present? ? :manual : :system,
    event_type: :conversation_closed,
    metadata: build_closure_metadata
  )
end

def build_closure_metadata
  return {} unless classification
  {
    classification_id: classification.id,
    classification_name: classification.name,
    classification_type: classification.classification_type
  }
end

def record_kanban_reopening_if_recent
  card = kanban_card
  return unless card
  
  recent_closure = card.kanban_card_activities
                       .where(event_type: :conversation_closed)
                       .where('created_at > ?', KANBAN_CLOSURE_CANCELLATION_WINDOW.ago)
                       .order(created_at: :desc)
                       .first
  
  reason = if recent_closure && has_recent_incoming_message?
             'new_message_received'
           elsif recent_closure
             'manual_reopen_within_window'
           else
             'manual_reopen'
           end
  
  KanbanCardActivity.create!(
    kanban_card: card,
    from_column: nil,
    to_column: nil,
    user: nil,
    source: :system,
    event_type: :closure_cancelled,
    metadata: {
      original_classification_id: recent_closure&.metadata&.dig('classification_id'),
      reason: reason
    }
  )
  
  Kanban::Macros::EvaluateJob.perform_later(
    event_type: 'conversation_reopened',
    payload: { conversation_id: id }
  )
end

def has_recent_incoming_message?
  messages.where(message_type: :incoming)
          .where('created_at > ?', KANBAN_CLOSURE_CANCELLATION_WINDOW.ago)
          .exists?
end
```

**Mudanças importantes em relação à versão original:**
- `KANBAN_CLOSURE_CANCELLATION_WINDOW = 5.minutes` como constante nomeada (não literal espalhada).
- `record_kanban_closure` usa `from_column: nil, to_column: nil` — encerramento não é movimentação. Move pra won/lost vai como activity separada (`stage_changed`, source: `system`) criada pelo `CardSyncService`.
- **Callback unificado:** `record_kanban_closure` + `Kanban::CardSyncService.new(self).sync_on_resolution` em sequência explícita. Não dependemos de ordem entre múltiplos `after_update_commit`.
- `record_kanban_reopening_if_recent` agora **sempre cria activity** de `closure_cancelled` quando há reabertura, com `reason` variável (`new_message_received` / `manual_reopen_within_window` / `manual_reopen`). Rastro sempre presente.

### Trigger novo — `ConversationReopened` (Fase 4 deixou o pipe pronto)

[app/services/kanban/macros/triggers/conversation_reopened.rb](app/services/kanban/macros/triggers/conversation_reopened.rb)

```ruby
module Kanban::Macros::Triggers
  class ConversationReopened < Base
    def self.key = 'conversation_reopened'
    def self.label = 'Conversa reaberta'
    
    def matches?(event)
      event.type == :conversation_reopened
    end
  end
end
```

A emissão do evento já está embutida no `record_kanban_reopening_if_recent` acima (`EvaluateJob.perform_later`).

**Decisão:** o macro padrão "Lead enviou mensagem" já move o card para auto_receive em `message_created`. Não precisamos de macro separado para "conversation_reopened mover card". Mas o trigger fica disponível para macros futuros (ex: notificar agente, atribuir automaticamente).

### Atualização: `Kanban::CardSyncService` integra `event_type: conversation_closed`

Hoje o service já move card para won/lost ao detectar resolução. Atualizar a criação da activity (que será adicionada nesta fase, se ainda não criar uma) para usar `event_type: stage_changed`, `source: :system`, `metadata: { trigger: 'conversation_resolved' }` (alinhado ao schema do Doc 01 para `(stage_changed, system)`).

**Sequência de activities ao resolver conversa com classification "won":**
1. `conversation_closed` (registrada no `record_kanban_closure`) — antes do move, sem from/to.
2. `stage_changed` (registrada no `CardSyncService.sync_on_resolution`, source: system) — quando moveu pra coluna `won`.

Histórico mostra os dois eventos, o que é informativo.

### Auditoria obrigatória antes de refatorar `CardSyncService`

Antes de extrair `sync_on_resolution` como método público chamado pelo callback unificado, mapear todos os callsites atuais:
```bash
grep -rn 'sync_kanban_card\|CardSyncService' app/
```
**Documentar os callsites na descrição do PR3** e garantir que nenhum fluxo legado quebre quando movermos a chamada para dentro do `handle_kanban_status_transitions`.

### Atualização: Modal de encerramento

A `ResolutionModal` já está integrada (botão "Resolver" + drag pra won/lost). Nada a mudar funcionalmente. O texto do log no histórico passa a ser estruturado via `metadata` (Fase 1 i18n já cobre).

---

## Pontos de integração com código existente

| Arquivo | Mudança |
|---|---|
| [app/models/conversation.rb](app/models/conversation.rb) | adicionar `handle_kanban_status_transitions` + `kanban_card` association se não existir |
| [app/services/kanban/card_sync_service.rb](app/services/kanban/card_sync_service.rb) | activities geradas pelo move automático → `metadata: { trigger: 'conversation_resolved' }` |
| [app/services/kanban/macros/triggers/conversation_reopened.rb](app/services/kanban/macros/triggers/conversation_reopened.rb) | novo |
| [config/initializers/kanban_macros.rb](config/initializers/kanban_macros.rb) | registrar novo trigger |
| Frontend: histórico no modal do card | renderizar texto de `closure_cancelled` (Fase 1 já listou texto sugerido, aqui só confirmar) |

**Enterprise:** verificar se `Conversation` tem callbacks Enterprise que possam interferir. Padrão `prepend_mod_with` se necessário.

---

## Endpoints novos ou modificados

**Nenhum.** Usa o que já existe.

---

## Mudanças no frontend

Mínimas:
1. Histórico do card já renderiza `closure_cancelled` conforme planejado em Fase 1.
2. Validar que ResolutionModal continua funcionando após mudanças em activities (não há breaking change esperado).

---

## Trade-offs e decisões não óbvias

### 1. Janela de "cancelamento implícito" como constante nomeada
- `KANBAN_CLOSURE_CANCELLATION_WINDOW = 5.minutes` definida no model.
- Heurística: distinguir "reabertura logo após resolve" de "lead voltou semanas depois".
- **Sempre criar activity de `closure_cancelled` em reabertura** — o que muda é o `reason`:
  - `new_message_received`: dentro da janela E há mensagem incoming recente.
  - `manual_reopen_within_window`: dentro da janela, sem mensagem incoming.
  - `manual_reopen`: fora da janela.
- Configurável? Não na v1. Se virar relevante, expor como setting de account.

### 2. `Current.user` no callback — fallback explícito
Cenários:
- Botão "Resolve" → request HTTP → `Current.user` setado → `source: :manual` ✓
- Drag pra won/lost → request HTTP → `Current.user` setado → `source: :manual` ✓
- Webhook/API externa → `Current.user` nil → `source: :system` ✓
- Job assíncrono → `Current.user` nil → `source: :system` ✓

**Confirmar antes de codar:** verificar em `ApplicationController` que `Current.user` é populado em todos os fluxos HTTP relevantes.

### 3. `kanban_card` association em `Conversation`
- Verificar se já existe `has_one :kanban_card` em Conversation (provavelmente sim, dado o refator card-por-conversa).
- Se não, adicionar.

### 4. Callback unificado: ordem controlada explicitamente
- Hoje há `after_update_commit :sync_kanban_card`. Esta fase substitui por `handle_kanban_status_transitions` que chama `record_kanban_closure` e `Kanban::CardSyncService.new(self).sync_on_resolution` em sequência explícita dentro do mesmo método.
- Elimina dependência de "ordem de declaração de callbacks", que é frágil.
- **Auditar callsites do `sync_kanban_card`/`CardSyncService` antes:** ver bloco grep acima e documentar resultado no PR3.

### 5. Conversa reaberta sem ser por mensagem de lead — `reason` reflete a causa
- Lógica do `reason` detalhada no item 1. Resumo:
  - Há mensagem incoming recente → `new_message_received`
  - Sem mensagem mas dentro da janela → `manual_reopen_within_window`
  - Fora da janela → `manual_reopen`
- **Toda reabertura deixa rastro** via activity `closure_cancelled` — atendentes vendo o histórico entendem o que aconteceu.

### 6. Onde o "cancelamento implícito" do brief realmente acontece — documentar no PR3
Como o status da conversa só muda para `resolved` quando o modal de resolução é salvo, o cenário literal do brief ("lead manda mensagem entre arrasto e preenchimento do modal") **acontece com a conversa ainda em `open`**:
- O macro padrão "Lead enviou mensagem" (Fase 5) dispara em `message_created`.
- Move o card de volta para `auto_receive`.
- O modal pendente fica visualmente cancelado quando o atendente percebe que o card sumiu.
- **Sem necessidade de fluxo especial** — é comportamento natural emergente.

O `event_type: closure_cancelled` cobre o cenário **pós-resolução**: modal salvo, conversa já está `resolved`, e reabertura acontece (manual ou via canal específico).

A maior parte do "cancelamento" do brief acontece como "card antigo permanece arquivado, card novo entra" — coberto pelo comportamento padrão Chatwoot de nova mensagem em conversa resolved criar nova conversa.

**Incluir essa explicação na descrição do PR3 para o reviewer.**

### 7. Indicador visual de movimentação automática (brief: "distinguível visualmente ou no histórico")
- Histórico já mostra `source: macro` / `system` distinto de `manual`.
- **Opcional v2:** ícone no card indicando "movido automaticamente recentemente" (caduca após N tempo). Não fazer agora.

### 8. CardSyncService já existe e move pra won/lost — esta fase não duplica
- Service permanece autoridade do move. Esta fase adiciona o evento estruturado ANTES do move, no callback.
- `metadata.trigger: 'conversation_resolved'` no activity de stage_changed deixa rastro de "esse move foi parte de um encerramento", o que ajuda na UI do histórico. Chave `trigger` é extensível para futuros valores (`conversation_archived`, `card_imported`, etc).

---

## Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Callbacks duplicados ou em ordem errada (closure activity criada antes do CardSyncService) | Testar manualmente; ordem de declaração em `after_update_commit` é determinística |
| `Current.user` nil em contextos não-HTTP (background sync) | source: :system fallback |
| Janela de 5 min muito apertada/larga | Configurável via constant; ajustar com feedback de uso |
| Conversation reaberta dispara macros que não deveriam | Por agora, único trigger reaberto registrado é `conversation_reopened`; macros usuário-criados podem se sobrepor mas não há macro padrão para esse evento |

---

## Critérios de aceite (validação manual)
1. Resolver conversa via botão "Resolver" → activity `conversation_closed` criada com classification metadata; activity `stage_changed` com `metadata.trigger: 'conversation_resolved'` criada (move pra won/lost).
2. Resolver conversa via drag → mesmo comportamento.
3. Reabrir conversa <5min após resolver → activity `closure_cancelled` criada. Histórico mostra texto correto.
4. Reabrir >5min depois → sem activity de cancelamento.
5. Conversa sem `kanban_card` (kanban desabilitado): nada acontece, sem erro.
6. Resolução sem classification (se permitido pelo modal): activity `conversation_closed` criada com `metadata: {}`.
7. Macro futuro com trigger `conversation_reopened` dispara corretamente.
8. Comportamento padrão Chatwoot mantido: nova mensagem em conversa resolvida → nova conversa criada (regra fora do escopo do kanban, mas valida que não quebrou).
