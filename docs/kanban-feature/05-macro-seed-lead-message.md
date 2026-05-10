# Fase 5 — Macro seed: "Lead enviou mensagem → Aguardando atendimento"

## Objetivo
Implementar as classes concretas (1 trigger, 3 conditions, 2 actions) e a data migration que cria o macro padrão para todas as contas existentes (e novas, via callback). É a primeira macro funcional do sistema, valida a engine de ponta a ponta.

---

## Mudanças de schema

Nenhuma. Apenas insert de dados.

**Data migration:** `db/data/<ts>_seed_default_kanban_macro.rb` (ou regular migration com `up` que cria registros). Estilo Chatwoot: verificar se há gem `data_migrate` ou se project usa migrations Rails padrão para data — se for o último, criar como migration normal com guard de idempotência.

```ruby
class SeedDefaultKanbanMacro < ActiveRecord::Migration[7.0]
  def up
    Account.find_each do |account|
      Kanban::Macros::Seeder.new(account).seed_defaults!
    end
  end
  
  def down
    Kanban::Macro.where(system: true, name: 'Lead enviou mensagem').delete_all
  end
end
```

A migration é fina; **toda a idempotência (`next if exists?`) vive no `Seeder`**, evitando divergência entre migration e callback de account.

**Callback em `Account` para novas contas:** após esta migration, novas contas devem ganhar o macro. Adicionar em [app/models/account.rb](app/models/account.rb):
```ruby
after_create_commit :seed_default_kanban_macros

private

def seed_default_kanban_macros
  Kanban::Macros::Seeder.new(self).seed_defaults!
end
```

E classe utilitária [app/services/kanban/macros/seeder.rb](app/services/kanban/macros/seeder.rb) que centraliza a lista de defaults — usada tanto na migration quanto no after_create — para não duplicar o conteúdo do macro:
```ruby
module Kanban::Macros
  class Seeder
    DEFAULTS = [
      {
        name: 'Lead enviou mensagem',
        description: '...',
        triggers: [...],
        conditions: [...],
        actions: [...],
      }
    ].freeze
    
    def initialize(account)
      @account = account
    end
    
    def seed_defaults!
      DEFAULTS.each do |spec|
        next if Kanban::Macro.exists?(account: @account, name: spec[:name], system: true)
        Kanban::Macro.create!(spec.merge(account: @account, system: true, enabled: true, position: 0))
      end
    end
  end
end
```

A migration usa `Kanban::Macros::Seeder.new(account).seed_defaults!`.

---

## Novas classes / serviços e responsabilidades

### Trigger: `Kanban::Macros::Triggers::LeadMessageReceived`
[app/services/kanban/macros/triggers/lead_message_received.rb](app/services/kanban/macros/triggers/lead_message_received.rb)

```ruby
module Kanban::Macros::Triggers
  class LeadMessageReceived < Base
    def self.key = 'lead_message_received'
    def self.label = 'Mensagem recebida do lead'
    def self.config_schema = {}  # sem config
    
    def matches?(event)
      return false unless event.type == :message_created
      message = event.message
      return false unless message
      message.incoming?  # message_type: 0 (incoming) — não outgoing, não template, não activity
    end
  end
end
```

**Por que `message.incoming?` é suficiente:**
- Chatwoot tem 4 tipos: `incoming` (do contato), `outgoing` (do agente), `activity` (system events), `template`.
- Mensagens de bot via integração (Dialogflow, etc) entram como `outgoing` ou `template`, então o filtro `incoming?` já exclui bot.
- "Story reply", "reaction", áudio, sticker no Instagram/WhatsApp são todos criados como `incoming` no Chatwoot — o macro pega.

### Condition: `CardNotInColumnFunction`
[app/services/kanban/macros/conditions/card_not_in_column_function.rb](app/services/kanban/macros/conditions/card_not_in_column_function.rb)

```ruby
module Kanban::Macros::Conditions
  class CardNotInColumnFunction < Base
    def self.key = 'card_not_in_column_function'
    def self.label = 'Card NÃO está em coluna com função X'
    def self.config_schema = { column_function: { type: 'enum', values: %w[auto_receive] } }
    
    def matches?(card:, event:)
      return false unless card
      card.kanban_column.column_function != config[:column_function]
    end
  end
end
```

### Condition: `ConversationStatusIs`
[app/services/kanban/macros/conditions/conversation_status_is.rb](app/services/kanban/macros/conditions/conversation_status_is.rb)

```ruby
module Kanban::Macros::Conditions
  class ConversationStatusIs < Base
    def self.key = 'conversation_status_is'
    def self.label = 'Status da conversa é X'
    def self.config_schema = { status: { type: 'enum', values: %w[open resolved pending snoozed] } }
    
    def matches?(card:, event:)
      conv = event.conversation
      return false unless conv
      conv.status == config[:status]
    end
  end
end
```

### Condition: `MessageSenderIsLead`
[app/services/kanban/macros/conditions/message_sender_is_lead.rb](app/services/kanban/macros/conditions/message_sender_is_lead.rb)

```ruby
module Kanban::Macros::Conditions
  class MessageSenderIsLead < Base
    def self.key = 'message_sender_is_lead'
    def self.label = 'Mensagem foi enviada pelo lead'
    def self.config_schema = {}
    
    def matches?(card:, event:)
      msg = event.message
      return false unless msg
      msg.incoming? && msg.sender_type == 'Contact'
    end
  end
end
```

**Nota:** condition é redundante com o trigger `LeadMessageReceived` que já filtra `incoming?`. Mantida porque:
- Triggers podem mudar (ex: trigger genérico `message_created` no futuro); condition garante a regra independente do trigger.
- Filosofia da engine: triggers são "quando", conditions são "se" — mesmo redundância casual é aceitável para clareza.

### Action: `MoveCardToColumnFunction`
[app/services/kanban/macros/actions/move_card_to_column_function.rb](app/services/kanban/macros/actions/move_card_to_column_function.rb)

```ruby
module Kanban::Macros::Actions
  class MoveCardToColumnFunction < Base
    def self.key = 'move_card_to_column_function'
    def self.label = 'Mover card para coluna com função X'
    def self.config_schema = { column_function: { type: 'enum', values: %w[auto_receive], required: true } }
    
    def self.validate_config!(config)
      raise ArgumentError, 'column_function é obrigatório' unless config['column_function'].present?
      true
    end
    
    def execute(card:, event:, macro:)
      raise 'card ausente' unless card
      target = KanbanColumn.find_by(account: card.account, column_function: config[:column_function])
      
      unless target
        Rails.logger.warn("[Kanban::Macros] account #{card.account_id} sem coluna #{config[:column_function]} — macro #{macro.id} ignorado")
        return { skipped: 'target_column_not_configured' }
      end
      
      return { skipped: 'already_in_target' } if card.kanban_column_id == target.id
      
      from_column = card.kanban_column
      ActiveRecord::Base.transaction do
        card.update!(kanban_column: target)  # callback de Fase 1 atualiza entered_stage_at
        KanbanCardActivity.create!(
          kanban_card: card,
          from_column: from_column,
          to_column: target,
          user: nil,
          source: :macro,
          event_type: :stage_changed,
          metadata: { macro_id: macro.id, macro_name: macro.name }
        )
      end
      { moved: true, from: from_column.id, to: target.id }
    end
  end
end
```

**Por que warn e não raise quando coluna não existe:** configuração ausente é estado esperado (admin ainda não configurou auto_receive), não erro de execução. Loga e segue, sem poluir Sentry.

**Nota sobre o metadata:** segue exatamente o schema definido no Doc 01 para `(event_type: stage_changed, source: macro)` → `{ macro_id, macro_name }`. Sem `trigger_event` aqui.

---

## Pontos de integração com código existente

| Arquivo | Mudança |
|---|---|
| Diretório `app/services/kanban/macros/triggers/` | 1 arquivo novo |
| Diretório `app/services/kanban/macros/conditions/` | 3 arquivos novos |
| Diretório `app/services/kanban/macros/actions/` | 1 arquivo novo (`MoveCardToColumnFunction`) |
| [app/services/kanban/macros/seeder.rb](app/services/kanban/macros/seeder.rb) | novo |
| [config/initializers/kanban_macros.rb](config/initializers/kanban_macros.rb) | atualizar lista de classes registradas (Fase 3 deixa initializer pronto; aqui é só adicionar entradas) |
| [app/models/account.rb](app/models/account.rb) | adicionar `after_create_commit :seed_default_kanban_macros` |
| `db/migrate/<ts>_seed_default_kanban_macro.rb` | data migration |

---

## Endpoints novos ou modificados

**Nenhum.**

---

## Mudanças no frontend

**Nenhuma de comportamento.** O macro funciona "invisível" até a UI da Fase 6.

**i18n adicional** em `config/locales/en.json` (escopo `KANBAN.CARD_HISTORY`):
```json
{
  "STAGE_CHANGED_BY_MACRO": "Macro \"{macroName}\" moveu para {toColumn}"
}
```
- `macroName` ← `activity.metadata.macro_name`
- `toColumn` ← `activity.to_column.name`

Atendentes verão o efeito (cards movendo automaticamente) e o histórico do card renderizará a chave acima.

---

## Trade-offs e decisões não óbvias

### 1. `system: true` no macro seed
- Marcador para a UI (Fase 6) saber que é um macro padrão. Pode ser desabilitado/editado, mas a UI pode mostrar uma label "Padrão do sistema".
- Não impede deleção via API (validação pode ser adicionada se necessário).

### 2. Macro seed também em contas EXISTENTES (via migration), `enabled: true`
- **Decisão confirmada:** todas as contas existentes recebem o macro habilitado.
- Justificativa: a feature inteira existe pra mover automaticamente; opt-in derrota o propósito.
- **Mitigação:** admins podem desabilitar via console (antes da Fase 6) ou via UI (depois da Fase 6).
- Macro vem com `system: true`, então não pode ser deletado, mas pode ser desabilitado/editado.

### 3. Condições redundantes mantidas
- `MessageSenderIsLead` é redundante com o trigger `LeadMessageReceived`. Mantida pela clareza ("conditions explícitas tornam o que o macro faz auditável na UI").
- Custo: 1 método retornando true; negligível.

### 4. `column_function: 'auto_receive'` referenciado por string
- Acoplado ao enum existente em `KanbanColumn`. Se enum mudar nome, macros existentes quebram.
- **Mitigação:** validação no `valid?` do macro: a config aponta para um valor de enum válido.
- **Não migrar valores antigos** se enum mudar — registrar no changelog que existing macros precisam re-config.

### 5. Action de move atualiza `kanban_column`, deixando `entered_stage_at` para o callback
- Não duplicar lógica: callback do model (Fase 1) é a única autoridade.
- Action só faz `card.update!(kanban_column:)`; resto cai no callback.

### 6. Cardinalidade: 1 macro por trigger por conta?
- Não restringir. Múltiplos macros podem ter o mesmo trigger e diferentes condições/ações. Engine roda todos.
- Permite ao admin compor automações complexas.

### 7. Conta sem `auto_receive` configurada
- Se nenhuma coluna do board tem `column_function: 'auto_receive'`, o macro tenta mover e a action retorna erro ("coluna função não encontrada").
- Erro logado mas não escala. Admin precisa configurar a coluna.
- **Polish futuro:** validação no UI da Fase 6 alerta "macro depende de coluna auto_receive ainda não configurada".

### 8. Macro seed entre múltiplos boards na mesma conta — VERIFICAR ANTES DE CODAR
- Conta pode ter múltiplos `kanban_boards` (1 por usuário). Cada board tem suas próprias colunas.
- Action busca `KanbanColumn.find_by(account:, column_function: 'auto_receive')` — retorna a primeira que encontrar.
- **Validação documentada em [kanban_column.rb](app/models/kanban_column.rb):** `unique_auto_receive_per_account` impõe **uma** auto_receive por conta. Confirmação esperada.
- **Pré-requisito de implementação:** antes de codar a Fase 5, executar `\d kanban_columns` ou abrir `db/schema.rb` e confirmar a constraint. **Documentar o resultado na descrição do PR2.**
- **Se a constraint NÃO existir** (ou for por-board): `find_by` retorna primeiro arbitrário e o macro pode mover cards entre boards diferentes — comportamento errado. **Parar e consultar antes de continuar.**
- **Se confirmada:** prosseguir assumindo uma auto_receive por conta.

---

## Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Migration de seed roda em conta gigante (10k+ registros) e gera carga | Migration cria 1 macro por conta — overhead mínimo |
| Macro dispara em loop após mover (callback de move dispara evento que dispara macro de novo) | Não há trigger que escute `card_moved` na Fase 5; loop impossível por enquanto. Documentar para futuros macros. |
| Conta sem coluna auto_receive recebe erro a cada mensagem | Logado e não bloqueia mensagem. Admin alertado pela UI futura. Por ora, monitorar log. |
| Mensagens criadas em massa (import) disparam jobs em massa | Aceitável; Sidekiq absorve. Se virar problema, considerar trigger condicional (`skip_macros: true` em flags de import). |

---

## Critérios de aceite (validação manual end-to-end)
1. Conta nova é criada → macro "Lead enviou mensagem" aparece em `Kanban::Macro.where(account: ...)`.
2. Conta antiga após migration → macro existe.
3. Lead manda mensagem em conversa com card NA coluna auto_receive → nada acontece (já está lá).
4. Lead manda mensagem em conversa com card em coluna "Em atendimento" → após o job, card está em auto_receive, com `entered_stage_at` recente, e activity nova com `source: 'macro'`, `event_type: 'stage_changed'`, `metadata.macro_id` preenchido.
5. Agente manda mensagem (outgoing) → macro não dispara (filtro do trigger).
6. Conversa em status `pending` ou `resolved` → macro não dispara (condition `conversation_status_is: open`).
7. Histórico do card no modal mostra texto correto: `Macro "Lead enviou mensagem" moveu para Aguardando atendimento`.
8. Erro deliberado em macro (ex: coluna auto_receive deletada) → log/Sentry registra; mensagem não falha.
