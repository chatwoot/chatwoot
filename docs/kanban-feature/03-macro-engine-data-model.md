# Fase 3 — Engine de macros: modelo de dados e registries

## Objetivo
Modelar a estrutura de dados que representa macros como "Quando [gatilho] se [condições] então [ações]" e construir o sistema de registries que permite adicionar novos triggers/conditions/actions sem alterar o core. Esta fase entrega persistência e classes Ruby; **não** entrega execução nem UI ainda.

---

## Mudanças de schema

### Nova tabela `kanban_macros`
| Campo | Tipo | Null? | Default | Observação |
|---|---|---|---|---|
| `id` | bigserial | false | — | PK |
| `account_id` | bigint | false | — | FK → accounts, escopo multi-tenant |
| `name` | string | false | — | Rótulo configurado pelo usuário |
| `description` | text | true | null | Opcional |
| `enabled` | boolean | false | `true` | Toggle on/off |
| `position` | integer | false | `0` | Ordem de avaliação (menor primeiro) |
| `triggers` | jsonb | false | `[]` | Array de objetos `{type, config}` |
| `conditions` | jsonb | false | `[]` | Array de objetos `{type, config}` |
| `actions` | jsonb | false | `[]` | Array de objetos `{type, config}` |
| `system` | boolean | false | `false` | `true` para macros gerados via seed (não deletáveis pela UI, mas editáveis) |
| `created_at` / `updated_at` | datetime | false | — | — |

**Índices**:
- `add_index :kanban_macros, [:account_id, :enabled]` — para busca rápida em runtime
- `add_index :kanban_macros, [:account_id, :position]`

**FK**: `add_foreign_key :kanban_macros, :accounts, on_delete: :cascade`

### Por que jsonb e não tabelas separadas (triggers/conditions/actions)?
- **Flexibilidade de schema por tipo:** cada trigger/condition/action tem um `config` próprio (ex: `column_function: "auto_receive"` para uma condition, `delay_seconds: 30` para outra). jsonb permite isso sem proliferação de tabelas.
- **Atomicidade:** salvar uma macro inteira é um único INSERT/UPDATE.
- **Custo:** não dá pra buscar "quais macros usam o trigger X" via JOIN; precisa scanner jsonb. Aceitável — esse tipo de query é raro.
- **Ferramentas de validação:** validação de schema feita em código Ruby (não no banco).

### Forma exata dos arrays jsonb

```jsonc
// triggers
[
  { "type": "lead_message_received", "config": {} }
]

// conditions
[
  { "type": "card_not_in_column_function", "config": { "column_function": "auto_receive" } },
  { "type": "conversation_status_is", "config": { "status": "open" } },
  { "type": "message_sender_is_lead", "config": {} }
]

// actions
[
  { "type": "move_card_to_column_function", "config": { "column_function": "auto_receive" } },
  { "type": "log_history", "config": { "text_key": "macro.lead_message_to_waiting" } }
]
```

**Cada item:** `type` (string, chave registrada no respectivo registry) + `config` (objeto opaco para o registry interpretar).

---

## Novas classes / serviços e responsabilidades

### Modelo `Kanban::Macro` ([app/models/kanban/macro.rb](app/models/kanban/macro.rb))
> **Decisão de namespace:** colocar sob módulo `Kanban::` para organização. Modelos kanban existentes hoje estão flat (`KanbanCard`, `KanbanColumn`). Para macros, há mais classes auxiliares (registries, triggers, conditions, actions) e namespace evita poluir top-level.

```ruby
module Kanban
  class Macro < ApplicationRecord
    self.table_name = 'kanban_macros'
    belongs_to :account
    
    validates :name, presence: true
    validate :triggers_present
    validate :actions_present
    validate :validate_triggers_structure
    validate :validate_conditions_structure
    validate :validate_actions_structure
    
    before_destroy :prevent_system_macro_deletion
    
    scope :enabled, -> { where(enabled: true) }
    scope :ordered, -> { order(:position, :id) }
    
    # Retorna trigger objects (instâncias das classes registradas)
    def trigger_objects
      triggers.map { |t| Kanban::Macros::Triggers::Registry.build(t['type'], t['config']) }
    end
    
    def condition_objects
      conditions.map { |c| Kanban::Macros::Conditions::Registry.build(c['type'], c['config']) }
    end
    
    def action_objects
      actions.map { |a| Kanban::Macros::Actions::Registry.build(a['type'], a['config']) }
    end
    
    private
    
    def triggers_present
      errors.add(:triggers, 'precisa de ao menos um gatilho') if Array(triggers).empty?
    end
    
    def actions_present
      errors.add(:actions, 'precisa de ao menos uma ação') if Array(actions).empty?
    end
    
    def validate_triggers_structure
      Array(triggers).each do |t|
        klass = Kanban::Macros::Triggers::Registry.fetch(t['type'])
        unless klass
          errors.add(:triggers, "tipo desconhecido: #{t['type']}")
          next
        end
        begin
          klass.validate_config!(t['config'] || {})
        rescue ArgumentError => e
          errors.add(:triggers, "config inválido para #{t['type']}: #{e.message}")
        end
      end
    end
    # idem validate_conditions_structure e validate_actions_structure
    
    def prevent_system_macro_deletion
      return unless system?
      errors.add(:base, 'macros de sistema não podem ser deletados')
      throw :abort
    end
  end
end
```

### Sistema de Registry (3 registries simétricos)

Cada registry mantém um mapa `key => class` e expõe `register`, `build(key, config)`, `registered?(key)`, `all`.

#### `Kanban::Macros::Triggers::Registry` ([app/services/kanban/macros/triggers/registry.rb](app/services/kanban/macros/triggers/registry.rb))
```ruby
module Kanban::Macros::Triggers
  class Registry
    @registry = {}
    
    class << self
      def register(klass)
        @registry[klass.key] = klass
      end
      
      def fetch(key)
        @registry[key]
      end
      
      def build(key, config)
        klass = fetch(key)
        raise ArgumentError, "trigger desconhecido: #{key}" unless klass
        klass.new(config || {})
      end
      
      def registered?(key) = @registry.key?(key)
      def all = @registry.values
    end
  end
end
```

#### Mesmo padrão para `Conditions::Registry` e `Actions::Registry`.

### Classes base

#### `Kanban::Macros::Triggers::Base`
```ruby
module Kanban::Macros::Triggers
  class Base
    attr_reader :config
    
    def initialize(config)
      @config = config.with_indifferent_access
    end
    
    # Override nas subclasses
    def self.key = raise NotImplementedError
    def self.label = raise NotImplementedError
    def self.config_schema = {}  # JSON schema descritivo para UI
    
    # Override nas subclasses com config obrigatório. Raise ArgumentError em config inválido.
    def self.validate_config!(config)
      true
    end
    
    # Recebe um Event genérico, retorna boolean
    def matches?(event)
      raise NotImplementedError
    end
  end
end
```

> O `validate_config!` aparece na classe Base de **Triggers**, **Conditions** e **Actions**. Subclasses com config obrigatório fazem override. Exemplo (Action `MoveCardToColumnFunction`):
> ```ruby
> def self.validate_config!(config)
>   raise ArgumentError, 'column_function é obrigatório' unless config['column_function'].present?
>   true
> end
> ```

#### `Kanban::Macros::Conditions::Base`
```ruby
module Kanban::Macros::Conditions
  class Base
    attr_reader :config
    def initialize(config) = @config = config.with_indifferent_access
    def self.key = raise NotImplementedError
    def self.label = raise NotImplementedError
    def self.config_schema = {}
    
    # Avalia condição contra um card e o evento
    def matches?(card:, event:)
      raise NotImplementedError
    end
  end
end
```

#### `Kanban::Macros::Actions::Base`
```ruby
module Kanban::Macros::Actions
  class Base
    attr_reader :config
    def initialize(config) = @config = config.with_indifferent_access
    def self.key = raise NotImplementedError
    def self.label = raise NotImplementedError
    def self.config_schema = {}
    
    # Executa ação. Retorna hash com info para log/metadata.
    def execute(card:, event:, macro:)
      raise NotImplementedError
    end
  end
end
```

### Classe `Kanban::Macros::Event` (PORO)

Encapsula o que aconteceu no sistema, desacoplado de Message/Conversation diretos:
```ruby
module Kanban::Macros
  class Event
    attr_reader :type, :payload
    
    def initialize(type:, payload:)
      @type = type  # ex: :message_created, :conversation_resolved
      @payload = payload  # hash com referências (message_id, conversation_id, etc)
    end
    
    def message
      @message ||= payload[:message_id] && Message.find_by(id: payload[:message_id])
    end
    
    def conversation
      @conversation ||= payload[:conversation_id] && Conversation.find_by(id: payload[:conversation_id])
    end
    
    def card
      @card ||= payload[:card_id] && KanbanCard.find_by(id: payload[:card_id])
    end
  end
end
```

Por que PORO em vez de PSO no model: eventos não persistem; são instantâneos.

### Auto-loading dos triggers/conditions/actions

Rails autoload (Zeitwerk) carrega arquivos em `app/services/kanban/macros/{triggers,conditions,actions}/*.rb`. Para garantir que os registries sejam populados, cada classe chama `Registry.register(self)` no fim do arquivo:

```ruby
# app/services/kanban/macros/triggers/lead_message_received.rb
module Kanban::Macros::Triggers
  class LeadMessageReceived < Base
    def self.key = 'lead_message_received'
    def self.label = 'Mensagem recebida do lead'
    
    def matches?(event)
      event.type == :message_created && event.message&.incoming?
    end
  end
end

Kanban::Macros::Triggers::Registry.register(Kanban::Macros::Triggers::LeadMessageReceived)
```

**Risco do registro no fim do arquivo:** o arquivo precisa ser carregado uma vez para que o `register` rode. Em produção (eager_load), Rails carrega tudo no boot — OK. Em dev (autoload lazy), pode haver triggers não registrados até a primeira referência.
**Mitigação:** initializer `config/initializers/kanban_macros.rb` que faz `Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/services/kanban/macros'))` em desenvolvimento também, OU usar uma constante `MACRO_CLASSES` listada no initializer e iterar para registrar.

**Decisão recomendada:** initializer com lista explícita de classes, mais previsível:
```ruby
# config/initializers/kanban_macros.rb
Rails.application.config.to_prepare do
  [
    Kanban::Macros::Triggers::LeadMessageReceived,
    # ...
  ].each { |k| Kanban::Macros::Triggers::Registry.register(k) }
  # idem conditions e actions
end
```

---

## Pontos de integração com código existente

Esta fase é quase 100% novo código. Integrações:
- [config/initializers/kanban_macros.rb](config/initializers/kanban_macros.rb) — novo
- `Account` model: adicionar `has_many :kanban_macros, class_name: 'Kanban::Macro', dependent: :destroy` em [app/models/account.rb](app/models/account.rb)
- Nenhum service/controller existente é tocado nesta fase.

---

## Endpoints novos ou modificados

**Nenhum.** Fase 6 entrega os endpoints CRUD de macros. Fase 3 entrega só persistência e classes — testável via console Rails.

---

## Mudanças no frontend

**Nenhuma.** Fase 6.

---

## Trade-offs e decisões não óbvias

### 1. jsonb com array de `{type, config}` vs. tabelas relacionais (`kanban_macro_triggers`, `kanban_macro_conditions`, `kanban_macro_actions`)
- **jsonb (escolhido):** menos tabelas, schema flexível por tipo, salvar macro = 1 INSERT.
- **Relacional:** queries mais ricas (ex: "macros que usam trigger X"), mas exige tabela polimórfica ou múltiplas com FKs — overkill para o uso esperado.
- Decisão pode ser revisitada se queries por tipo virarem comum.

### 2. Namespace `Kanban::` para macros vs. flat
- Modelos atuais kanban são flat (`KanbanCard`). Macros têm muitas classes auxiliares; namespace evita poluição.
- **Inconsistência aceitável:** `KanbanCard` permanece flat (legado), `Kanban::Macro` é novo e agrupado. Renomear `KanbanCard → Kanban::Card` seria refator de fork não relacionado.

### 3. Registry como singleton vs. dependency injection
- Singleton com classe (`@registry = {}` em class var-like) é simples. Para tests, pode-se resetar em `before` block.
- DI seria mais purista mas introduz cerimônia. Não compensa neste contexto.

### 4. Validação estrutural via método custom em vez de json_schema gem
- Triggers/conditions/actions já têm `config_schema` (descritivo, para UI). Validação de presença e tipos das chaves do `config` é responsabilidade da própria classe (`#validate_config!` no Base, override nas subclasses).
- Evita dependência externa para um caso de uso pequeno.

### 5. PORO `Event` em vez de objetos de domínio diretos
- Eventos podem encapsular dados de múltiplas fontes (Message + Conversation + meta). Um PORO desacoplado fica mais fácil de evoluir.
- Permite testar matchers passando event mock sem precisar de fixture pesada.

### 6. Eager registration via initializer
- Garante que todas classes estejam no registry em qualquer ambiente.
- Custo: lista explícita precisa ser atualizada quando classe nova é adicionada. Documentar no README do diretório `app/services/kanban/macros/`.

### 7. `system: true` em macros seed
- **Guard de delete real no model** (`before_destroy :prevent_system_macro_deletion`), não só marcador de UI.
- Permite disable/edit normalmente; bloqueia delete via `errors.add` + `throw :abort`.
- Controller pode propagar o erro como 422.
- Usuário pode editar config do macro seed se quiser personalizar (ex: mudar texto do log).

### 8. Macro `enabled` granular vs. account-level kanban toggle
- Cada macro tem seu `enabled`. Não há "desligar todos macros da conta" em um único toggle (não pedido). Se necessário no futuro, adiciona-se feature flag.

---

## Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Registry não populado em ambiente de teste | Initializer roda em `to_prepare`; teste com `Rails.application.executor.wrap` ou load explícito |
| jsonb sem schema rígido permite dados malformados | Validação no `Macro#valid?` antes de save; rejeita types desconhecidos |
| `Kanban::Macros::Event` carrega Message/Conversation por id e modelo já foi deletado | Métodos `message`/`conversation` retornam `nil` se registro não existe; matchers fazem `nil`-safe |
| Migration de tabela vazia não causa downtime, mas FK em `accounts` cascata pode preocupar | `on_delete: :cascade` é apropriado — macros são por-conta; conta apagada → macros vão junto |

---

## Critérios de aceite (validação manual)
1. Criar macro via console: `Kanban::Macro.create!(account: a, name: "test", triggers: [{type: 'lead_message_received', config: {}}], conditions: [], actions: [])` funciona.
2. Tentar criar com trigger desconhecido falha validação.
3. `macro.trigger_objects` retorna array de instâncias da classe registrada.
4. Registry retorna trigger object com `matches?(event)` funcional (testar manualmente com event mock).
5. `Account#destroy` apaga `kanban_macros` associadas (cascata).
6. Initializer popula os 3 registries no boot da app.
