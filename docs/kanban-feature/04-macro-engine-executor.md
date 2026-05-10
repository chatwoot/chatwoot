# Fase 4 — Engine de macros: executor e dispatcher

## Objetivo
Conectar a engine (Fase 3) ao ciclo de vida do produto: detectar eventos relevantes (mensagem entrante, conversa reaberta, conversa resolvida, etc), instanciar `Kanban::Macros::Event`, encontrar macros aplicáveis, avaliar condições e executar ações — tudo de forma assíncrona e idempotente.

---

## Mudanças de schema

Nenhuma. Tudo o que precisa para runtime já está em Fase 1 e 3.

**Possível futura:** tabela `kanban_macro_runs` para auditar execuções (which macro fired, when, on which card, success/failure). **Não fazer agora** — registramos no `kanban_card_activities` quando há ação efetiva. Audit log dedicado entra se observabilidade exigir.

---

## Novas classes / serviços e responsabilidades

### `Kanban::Macros::Engine` ([app/services/kanban/macros/engine.rb](app/services/kanban/macros/engine.rb))

Orquestrador. Recebe um `Event`, encontra macros aplicáveis, avalia, executa.

```ruby
module Kanban::Macros
  class Engine
    def initialize(event)
      @event = event
    end
    
    def evaluate
      card = resolve_card
      return unless card  # early return: sem card kanban, nada a fazer
      
      applicable_macros.each do |macro|
        next unless trigger_matches?(macro)
        next unless conditions_match?(macro, card)
        execute_actions(macro, card)
      end
    end
    
    private
    
    def resolve_card
      conv_id = @event.payload[:conversation_id]
      return nil unless conv_id
      KanbanCard.find_by(conversation_id: conv_id)
    end
    
    def applicable_macros
      return @applicable_macros if defined?(@applicable_macros)
      account = resolve_account
      @applicable_macros = account ? Kanban::Macro.where(account: account).enabled.ordered.to_a : []
    end
    
    def resolve_account
      @event.conversation&.account || @event.card&.account
    end
    
    def trigger_matches?(macro)
      macro.trigger_objects.any? { |t| t.matches?(@event) }
    end
    
    def conditions_match?(macro, card)
      macro.condition_objects.all? { |c| c.matches?(card: card, event: @event) }
    end
    
    def execute_actions(macro, card)
      ActiveRecord::Base.transaction do
        macro.action_objects.each do |action|
          action.execute(card: card, event: @event, macro: macro)
        end
      end
    rescue StandardError => e
      Rails.logger.error("[Kanban::Macros] macro #{macro.id} failed: #{e.class}: #{e.message}")
      Sentry.capture_exception(e) if defined?(Sentry)
      # não re-raise — falha de macro não pode quebrar o caller (criação de mensagem)
    end
  end
end
```

- `resolve_card` roda **uma vez** por evento, evitando N+1 quando há múltiplos macros.
- `applicable_macros` é memoizado.
- Sem card kanban associado à conversa → engine retorna early (early return é o filtro fino).

**Decisões internas explicitadas:**
- **Erro em uma macro não afeta as outras?** No exemplo acima, sim afeta — o `rescue` é por-execução-de-macro. Decisão final: rescue por macro individual (cada macro é independente).
- **Atomicidade:** ações de uma mesma macro rodam em transação. Se a action 2 falha, a action 1 reverte. Macro inteira é atômica; macros entre si são independentes.
- **Sem evento-rebound:** ações que disparariam novos eventos (ex: mover card → callback que dispara `card_moved`) são tratadas com guard de loop. Por ora, o único evento que circulamos é `message_created` e ações não criam mensagens; risco zero. Documentar no README.

### Job `Kanban::Macros::EvaluateJob` ([app/jobs/kanban/macros/evaluate_job.rb](app/jobs/kanban/macros/evaluate_job.rb))

Wrapper assíncrono para que macros não bloqueiem o request HTTP que disparou o evento.

```ruby
module Kanban::Macros
  class EvaluateJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: 5.seconds, attempts: 3
    
    def perform(event_type:, payload:)
      event = Kanban::Macros::Event.new(type: event_type.to_sym, payload: payload.symbolize_keys)
      Kanban::Macros::Engine.new(event).evaluate
    end
  end
end
```

**Por que async:** macros podem fazer várias queries e updates; manter síncrono no callback de `Message.after_create_commit` arrisca lentidão visível. Async via Sidekiq é o padrão Chatwoot.

**Trade-off:** mensagens chegam no kanban com delay de ~milissegundos (job picking time). Aceitável — kanban não é UI de chat instantâneo.

### Hook em `Message` ([app/models/message.rb](app/models/message.rb))

Callback após criação de mensagem dispara o job, mas só quando faz sentido:
```ruby
after_create_commit :enqueue_kanban_macros, if: :should_evaluate_kanban_macros?

private

def should_evaluate_kanban_macros?
  # Filtros em memória, custo zero:
  # - Sem conversation_id: mensagem órfã, nada a fazer.
  # - Outgoing/template: nunca satisfaz trigger `lead_message_received`; descarta cedo.
  conversation_id.present? && incoming?
end

def enqueue_kanban_macros
  Kanban::Macros::EvaluateJob.perform_later(
    event_type: 'message_created',
    payload: { message_id: id, conversation_id: conversation_id }
  )
end
```

**Decisão de filtro:** dois filtros baratos em memória (`conversation_id` e `incoming?`) eliminam o ruído principal — mensagens outgoing e template jamais disparam o macro padrão. O filtro fino "existe card kanban?" fica no Engine (early return). Sem query síncrona no callback.

### Hooks adicionais para outros eventos (preparados, mas com triggers que serão usados em fases posteriores)

A Fase 4 prepara o pipe; nem todos os eventos têm consumidor agora.

| Evento | Disparado em | Trigger correspondente (futuro) |
|---|---|---|
| `message_created` | `Message after_create_commit` | `lead_message_received` (Fase 5) |
| `conversation_resolved` | `Conversation after_update_commit` (status muda para `resolved`) | reservado para Fase 8 |
| `conversation_reopened` | `Conversation after_update_commit` (status muda de `resolved` para `open`) | `closure_cancelled_by_message` (Fase 8) |
| `card_moved` | `KanbanCard after_update_commit` (column_id mudou) | reservado |

**Implementação nesta fase:** apenas o hook em `Message`. Hooks de Conversation/Card vêm em fases que precisam deles, para evitar código morto.

### Idempotência

Garantida em duas camadas:
1. **Conditions:** macro do tipo "mover para auto_receive" tem condição `card_not_in_column_function(auto_receive)`. Se já está lá, condição falha, ação não roda.
2. **Actions:** mesmo se a condição não barrar, a ação `move_card_to_column_function` é guarded:
   ```ruby
   def execute(card:, event:, macro:)
     target = KanbanColumn.find_by(account: card.account, column_function: config[:column_function])
     return { skipped: 'already_in_target' } if target.nil? || card.kanban_column_id == target.id
     # ... move
   end
   ```

Fingerprint baseado em `(macro_id, event payload hash)` poderia ser persistido para evitar re-execução em retries do job, mas:
- Sidekiq retries são raros e geralmente intencionais.
- Idempotência via condition+action guard é suficiente.
- **Não implementar** fingerprint nesta fase. Adicionar se observabilidade mostrar problema.

---

## Pontos de integração com código existente

| Arquivo | Mudança |
|---|---|
| [app/models/message.rb](app/models/message.rb) | Adicionar `after_create_commit :enqueue_kanban_macros` |
| `app/services/kanban/macros/engine.rb` | novo |
| `app/jobs/kanban/macros/evaluate_job.rb` | novo |
| [app/models/account.rb](app/models/account.rb) | já tocado em Fase 3 (`has_many :kanban_macros`) |

**Observação Enterprise:** Chatwoot tem overlay `enterprise/`. Mensagens podem ter override em `enterprise/app/models/concerns/`. Verificar se `after_create_commit` é seguro (não override silenciado por enterprise). Se houver módulo Enterprise tocando `Message`, seguir pattern `prepend_mod_with` documentado no CLAUDE.md.

---

## Endpoints novos ou modificados

**Nenhum.** Engine é interna; UI de macros vem na Fase 6.

---

## Mudanças no frontend

**Nenhuma.**

---

## Trade-offs e decisões não óbvias

### 1. Async (job) vs. síncrono (inline no callback)
- **Async (escolhido):** isola latência do macro do request principal. Kanban tolera delay.
- **Síncrono:** garante que ao retornar do POST de mensagem, o card já moveu. Custo: latência variável por número de macros. Não compensa.

### 2. Resolução do `card` no Engine, não no payload do job
- Job recebe `message_id, conversation_id` (não `card_id`). Engine resolve card via `KanbanCard.find_by(conversation_id:)`.
- **Por quê:** o card pode não existir ainda quando o job é enfileirado (race rara). Resolver no momento da execução é mais robusto.

### 3. Erro em uma macro não derruba as outras
- Cada `execute_actions(macro)` tem `rescue` próprio.
- Cada macro é uma transação isolada — falha em ação 2 reverte ação 1 da mesma macro, mas próxima macro roda normalmente.

### 4. Filtro grosso no callback (apenas `conversation_id.present?`) vs. filtro fino
- Filtro grosso: mais jobs enfileirados, mas zero queries no callback.
- Filtro fino com `KanbanCard.exists?`: query síncrona no callback, mais custo no path crítico.
- **Escolha:** filtro grosso. Sidekiq processa jobs vazios rapidamente.
- Se em produção o ruído for problema, adicionar feature flag `Account#kanban_enabled?` como filtro intermediário.

### 5. Não persistir fingerprint de execução
- Idempotência via guards é suficiente.
- Audit detalhado fica para observabilidade futura (tabela `kanban_macro_runs` se necessário).

### 6. Loop prevention
- Por agora, ações não disparam eventos de macro.
- **Documentar restrição:** novas ações que crucem fronteiras (ex: action "criar mensagem automática") devem usar canal/método que NÃO dispare `message_created` ao mesmo macro engine, ou usar marker no payload (ex: `skip_macros: true` no Event).
- Adicionar guard no Engine futuro se necessário.

### 7. Job em fila `default` vs. fila dedicada
- `default` está bom inicialmente. Se observabilidade indicar contenção, criar fila `kanban_macros` com workers dedicados.

### 8. Hook em `Message` — decidir A vs B ANTES de codar
Antes de implementar PR2, rodar:
```bash
grep -rn 'MESSAGE_CREATED\|message_created' app/listeners/ app/dispatchers/ lib/
```
- **Se aparecer:** Plano A — listener no dispatcher (padrão idiomático do projeto). Criar `Kanban::Macros::Listener` registrado em `Events::Types::MESSAGE_CREATED`.
- **Se NÃO aparecer:** Plano B — `after_create_commit` em `Message`.

**Documentar a escolha (e o output do grep) na descrição do PR2.**

---

## Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Job falha e fica em retry infinito por bug em ação | Sidekiq tem max_retries; ação tem rescue interno; logar e não-retentar erros não-recuperáveis (raise `Sidekiq::JobRetry::Skip` se aplicável) |
| Engine causa N+1 ao iterar macros e cards | Pré-carregar `account.kanban_macros.enabled.ordered` uma vez; card é um único find_by |
| Listener `after_create_commit` em Message rodando para mensagens não-kanban impacta perf | Filtro grosso minimiza; jobs vazios consomem ~1ms |
| Macro mal configurada bloqueia conversa (action falha consistentemente) | Falha registrada em log/Sentry; não afeta criação da mensagem; admin pode desabilitar via UI da Fase 6 |
| Override Enterprise em Message pode ocultar callback | Auditar `enterprise/app/models/` antes de adicionar; usar concern se necessário |

---

## Critérios de aceite (validação manual)
1. Criar macro via console (Fase 3) com trigger `lead_message_received` e action de log; criar mensagem entrante; ver entrada no log de macro (após o job rodar).
2. Macro desabilitado (`enabled: false`) não dispara.
3. Erro deliberado em uma ação (ex: raise) é capturado, logado, e não impede criação da mensagem.
4. Mensagem criada por agente (`message_type: outgoing`) não dispara macro com trigger `lead_message_received` (validado pela `matches?` da classe trigger, que filtra por `incoming`).
5. Conversa sem card kanban: job é enfileirado mas Engine retorna early sem efeito.
6. Macros executam em ordem de `position`.
