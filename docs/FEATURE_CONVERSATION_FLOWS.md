# Conversation Flows — Potenciar Automatizaciones con Flujos Conversacionales

> **Estado:** WIP listo para review local (rama `feat/conversation-flows`)
> **Feature flag:** `flows_v1` (bit index ~56 en `features.yml`; default `enabled: true`)
> **UI:** Settings → Flows (editor estilo Macros) + Automation action `enter_flow`
> **Semáforo:** reutiliza `panel_ia_estado` / `PanelIaStateIndicator` vía `flow_run`
> **Salida:** `exit_policy` (limbo unassigned / pending / team / agent / owner)

## Cómo probar en local (Docker)

```powershell
cd d:\DOCUMENTOS\GITHUB\chatwoot\chatwoot
docker exec chatwoot-chatwoot-rails-1 bundle exec rails db:migrate
pnpm exec vite build
docker cp public/vite chatwoot-chatwoot-rails-1:/app/public/
docker restart chatwoot-chatwoot-rails-1 chatwoot-chatwoot-sidekiq-1
# Flag (si no aparece el menú):
# rails runner: Account.find(1).enable_features('flows_v1'); Account.find(1).save!
```

- **Lista:** http://localhost:3000/app/accounts/1/settings/flows
- **Nuevo:** http://localhost:3000/app/accounts/1/settings/flows/new
- También: Settings → Conversation Workflow → Flows CTA
- Disparo: Automatizaciones → acción **Enter conversation flow**

### Editor (Macros language)

- Izquierda: árbol de pasos (acciones + preview de ramas / fork)
- Derecha: nombre/activo, propiedades del paso seleccionado (botones, branch, delay), exit policy (team/agent pickers + private note)
- Sin canvas drag-and-drop (v2)

### Gaps conocidos (follow-up)

- No hay start manual desde el panel de conversación ni webhook `/start` aún
- Timeout automático en `wait_response` no implementado
- Specs RSpec / FE no escritos (a propósito en WIP)
- Canvas visual v2 diferido

---

## TL;DR

Sistema de **Flujos conversacionales** (graph multi-step) independiente de `AutomationRule`. Las automatizaciones invocan un flujo con `enter_flow` **una sola vez**. A partir de ahí el motor del flujo posee el recorrido (`FlowRun` + `current_node_id` + edges): **no hace falta encadenar automatizaciones** con condiciones del estilo “¿ya pasó auto1/auto2?”.

Cada paso puede ejecutar el **mismo catálogo de acciones** que Automatizaciones/Macros (`Flows::ActionService` reutiliza `ActionService`), más conceptos propios del flujo: `wait_response` / match / ramas / `exit_policy`. Mensajes al cliente usan typing+delay (`Flows::HumanLikeSendService`). Al salir, `Flows::ExitPolicyService` aplica status/asignación.

---

## Por qué Flows (vs solo Automatizaciones)

**Dolor con solo Automations:** para un diálogo de varios turnos había que crear muchas reglas encadenadas (“si dice hola → X”, “si dice buenos días **y** pasó auto1 → Y”, “si pasó auto1+auto2 **y** match → auto4”). Cada paso re-evalúa condiciones globales sobre *qué otras reglas ya corrieron*.

**Qué aporta el flujo:** entrar una vez (`enter_flow`) → estado `in_flow` / `FlowRun` → avanzar por edges del grafo (acciones + wait/match) con trazabilidad (`trail` / `flow_events`). Las Macros/Automations siguen siendo el catálogo mental de acciones; el flujo aporta **conexión + path state**.

---

## Motivación

### Lo que existe hoy
- `AutomationRule` = **1 evento → 1 set de acciones plano** (rule-based, no flow)
- `ConditionsFilterService` evalúa JSON conditions (country, label, message_type, etc.)
- `ActionService` ejecuta send_message, add_label, change_status, etc.
- `AgentBot` + `bot_handoff!` para handoff al humano
- `bot_handling?` boolean en Conversation pero **sin badge UI fase-aware**

### El problema
Las automatizaciones son **transaccionales**. No hay:
- concepto de "el cliente está recorriendo un flujo"
- espera interactiva por respuesta del cliente
- estado intermedio (esperando match / procesando / completado)
- handoff limpio con contexto del flujo

El usuario quiere que la automatización **abra** la conversación en un camino, y que el motor del flujo **dirija** el resto: acciones ricas, opciones, esperar respuesta, branch, terminar.

---

## Decisiones de diseño

### 1. Modelo de datos: nuevo y separado

Tres models nuevos (NO extender `AutomationRule`):

```
flows            — definición reusable por cuenta (graph JSON)
flow_runs        — instancia por conversación (state + variables)
flow_events      — log de auditoría (opcional)
```

Por qué separado de `AutomationRule`:
- Las reglas siguen siendo declarativas (evento → acción) y simples de configurar
- Los flujos son máquinas de estado con su propio ciclo de vida
- Una regla puede **disparar** un flujo (con la nueva action `enter_flow`) sin acoplarse
- Los flujos pueden tener su propio editor visual

### 2. Graph JSON

El flujo se almacena como JSON en `flows.graph`:

```json
{
  "nodes": [
    {
      "id": "n1",
      "type": "actions",
      "data": {
        "actions": [
          {"action_name": "add_label", "action_params": ["soporte"]},
          {"action_name": "send_message", "action_params": ["Hola, ¿qué necesitas?"], "delivery": {"delay_seconds": 3, "mark_read_and_typing": true}}
        ],
        "buttons": [{"title": "A", "value": "A"}, {"title": "B", "value": "B"}, {"title": "C", "value": "C"}]
      }
    },
    {"id": "n2", "type": "wait_response", "data": {"match": [{"label": "A", "pattern": "^A$"}, {"label": "B", "pattern": "^B$"}, {"label": "C", "pattern": "^C$"}]}},
    {"id": "n3", "type": "actions", "data": {"actions": [{"action_name": "send_message", "action_params": ["Tu pedido está en camino."]}], "buttons": []}},
    {"id": "n4", "type": "actions", "data": {"actions": [{"action_name": "send_message", "action_params": ["Devoluciones: ..."]}], "buttons": []}},
    {"id": "n5", "type": "handoff", "data": {"reason": "Cliente eligió 'Otro'"}},
    {"id": "nE", "type": "end", "data": {}}
  ],
  "edges": [
    {"from": "n1", "to": "n2"},
    {"from": "n2", "to": "n3", "when": {"match_label": "A"}},
    {"from": "n2", "to": "n4", "when": {"match_label": "B"}},
    {"from": "n2", "to": "n5", "when": {"match_label": "C"}}
  ],
  "entry_node_id": "n1"
}
```

Tipos de nodo soportados:

| Tipo | Descripción |
|------|-------------|
| `actions` | Lista de acciones estilo Automatización/Macro (`action_name` + `action_params`). `send_message` usa HumanLikeSend + botones opcionales del paso |
| `send_message` | Legacy (sigue ejecutándose); el editor guarda `actions` |
| `wait_response` | Pausa hasta respuesta del cliente y matchea patterns / botones |
| `set_variable` | Guarda un valor en el run |
| `handoff` | Escala a humano (`exit_policy.on_handoff`) |
| `end` | Cierra el run (`on_complete`) |

**Acciones reutilizadas** (vía `Flows::ActionService` ← `ActionService`): assign agent/team, labels, mute/snooze/resolve/open/pending, private note, webhook, email transcript / email to team, priority, custom attributes, `send_message`.

**Excluidas mid-flow:** `enter_flow`, `execute_macro`, `add_sla`, `send_attachment` (sin storage de archivos en Flow aún).

### 3. Disparador: automatización lanza, flujo opera

Tres formas de iniciar un flujo:

1. **Desde una AutomationRule existente** (nueva action `enter_flow`):
   ```yaml
   event_name: message_created
   conditions:
     - attribute_key: message_content
       filter_operator: contains
       values: ["envío", "devolución"]
   actions:
     - action_name: enter_flow
       action_params: ["soporte_compra"]
   ```

2. **Manual desde el dashboard**: botón "Iniciar flujo X" en el panel lateral de la conversación

3. **Webhook externo**:
   ```
   POST /api/v2/accounts/:account_id/flows/:flow_name/start
   ```

### 4. Handoff automático cuando humano responde

Si `Message#human_response?` (User outbound) llega mientras `conversation.in_flow?`:
- El run se cierra con `state: 'handed_off'`, `ended_reason: 'human_responded'`
- Se crea un activity message con resumen del flujo recorrido
- El control pasa al humano, sin reanudar el run

**Resumen del handoff** (formato libre, generado por `Flows::HandoffService`):

> *Automation flow "Soporte Compra" handed off to agent.*
> *Last node: send_message "¿Qué necesitas?"*
> *Customer answered: "B"*
> *Variables: { intent: "devolución" }*
> *Steps completed: 2/5*

### 5. Badge de estado en conversación

Modelo `FlowRun#state` mapea a color en UI:

| Estado | Color | Significado |
|--------|-------|------------|
| `running` | 🟢 verde | Ejecutando paso del bot (send_message, condition, etc.) |
| `waiting` | 🟠 naranja | Esperando respuesta del cliente |
| `completed` | gris | Terminó con éxito (llegó a node `end`) |
| `handed_off` | 🔴 rojo | Humano tomó la conversación |
| `failed` | 🔴 rojo | Error en algún paso (timeout, no match, etc.) |
| `cancelled` | gris | Admin lo canceló manualmente |

---

## Plan de implementación

### Fase 1: Modelo de datos (1.5 días)

**Migrations:**

```ruby
# db/migrate/20260801xxxxxx_create_flows.rb
class CreateFlows < ActiveRecord::Migration[7.1]
  def change
    create_table :flows do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :active, null: true, default: true
      t.jsonb :graph, null: false, default: {}
      t.timestamps
    end
    add_index :flows, [:account_id, :name], unique: true
  end
end

# db/migrate/20260801xxxxxx_create_flow_runs.rb
class CreateFlowRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :flow_runs do |t|
      t.references :flow, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.integer :state, null: false, default: 0  # enum
      t.string :current_node_id
      t.jsonb :variables, null: false, default: {}
      t.jsonb :trail, null: false, default: []   # historial de nodos ejecutados
      t.datetime :started_at
      t.datetime :ended_at
      t.string :ended_reason
      t.timestamps
    end
    add_index :flow_runs, [:conversation_id, :state]
    add_index :flow_runs, :state
  end
end

# db/migrate/20260801xxxxxx_create_flow_events.rb (opcional, auditoría)
class CreateFlowEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :flow_events do |t|
      t.references :flow_run, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :node_id
      t.jsonb :data
      t.datetime :created_at, null: false
    end
    add_index :flow_events, [:flow_run_id, :event_type]
  end
end
```

**Models:**

```ruby
# app/models/flow.rb
class Flow < ApplicationRecord
  belongs_to :account
  has_many :flow_runs, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validate :validate_graph_schema

  scope :active, -> { where(active: true) }

  def entry_node
    graph['nodes'].find { |n| n['id'] == graph['entry_node_id'] }
  end
end

# app/models/flow_run.rb
class FlowRun < ApplicationRecord
  belongs_to :flow
  belongs_to :conversation
  belongs_to :account
  has_many :flow_events, dependent: :destroy

  enum state: { running: 0, waiting: 1, completed: 2, handed_off: 3, failed: 4, cancelled: 5 }

  validates :state, presence: true

  def current_node
    return nil if current_node_id.blank?

    flow.graph['nodes'].find { |n| n['id'] == current_node_id }
  end

  def append_to_trail!(node_id, result = nil)
    self.trail = trail + [{ node_id: node_id, at: Time.current.iso8601, result: result }]
  end

  def handoff!(reason:, agent_user: nil)
    update!(state: :handed_off, ended_at: Time.current, ended_reason: reason)
    Flows::HandoffService.new(run: self, agent_user: agent_user).perform
  end

  def complete!
    update!(state: :completed, ended_at: Time.current, ended_reason: 'reached_end')
  end

  def fail!(reason)
    update!(state: :failed, ended_at: Time.current, ended_reason: reason)
  end
end
```

**Concern:**

```ruby
# app/models/concerns/flowable.rb
module Flowable
  extend ActiveSupport::Concern

  included do
    has_many :flow_runs, dependent: :destroy
  end

  def in_flow?
    flow_runs.where(state: [:running, :waiting]).exists?
  end

  def active_flow_run
    flow_runs.where(state: [:running, :waiting]).order(started_at: :desc).first
  end
end
```

Agregar a `Conversation`:

```ruby
# app/models/conversation.rb
include Flowable
```

### Fase 2: Motor de ejecución (3 días)

**Services:**

```ruby
# app/services/flows/start_service.rb
class Flows::StartService
  def initialize(account:, conversation:, flow_name:, trigger:)
    @account = account
    @conversation = conversation
    @flow_name = flow_name
    @trigger = trigger # 'automation_rule', 'manual', 'webhook'
  end

  def perform
    return failure('already_in_flow') if @conversation.in_flow?

    flow = @account.flows.active.find_by(name: @flow_name)
    return failure('flow_not_found') unless flow

    run = FlowRun.create!(
      flow: flow,
      conversation: @conversation,
      account: @account,
      state: :running,
      current_node_id: flow.entry_node['id'],
      started_at: Time.current,
      variables: {},
      trail: []
    )

    Flows::ExecutionService.new(run: run).perform_next
    success(run)
  end
end

# app/services/flows/execution_service.rb
class Flows::ExecutionService
  def initialize(run:)
    @run = run
    @conversation = run.conversation
    @flow = run.flow
  end

  def perform_next
    node = @run.current_node
    return @run.complete! if node.nil?
    return @run.fail!('no_entry_node') if node.nil?

    case node['type']
    when 'send_message'
      handle_send_message(node)
    when 'wait_response'
      handle_wait_response(node)
    when 'condition'
      handle_condition(node)
    when 'set_variable'
      handle_set_variable(node)
    when 'delay'
      handle_delay(node)
    when 'handoff'
      handle_handoff(node)
    when 'end'
      @run.complete!
    else
      @run.fail!("unknown_node_type:#{node['type']}")
    end
  end

  private

  def handle_send_message(node)
    Messages::MessageBuilder.new(nil, @conversation, {
      message_type: :outgoing,
      content: node['data']['content'],
      content_attributes: {
        flow_run_id: @run.id,
        automation_rule_id: nil,
        is_flow_message: true
      }
    }).perform

    @run.append_to_trail!(node['id'], 'sent')
    @run.save!

    advance_to(node['id'])
  end

  def handle_wait_response(node)
    @run.update!(state: :waiting)
    @run.append_to_trail!(node['id'], 'waiting')
    @run.save!
  end

  def handle_condition(node)
    # evalúa node['data']['expression'] sobre @run.variables
    # bifurca a edge según resultado
    advance_to(node['id'])
  end

  def handle_set_variable(node)
    key = node['data']['key']
    value = node['data']['value']
    @run.variables = @run.variables.merge(key => value)
    @run.save!
    advance_to(node['id'])
  end

  def handle_delay(node)
    seconds = node['data']['seconds'].to_i
    Flows::DelayJob.set(wait: seconds.seconds).perform_later(@run.id, node['id'])
  end

  def handle_handoff(node)
    Flows::HandoffService.new(run: @run, reason: node['data']['reason']).perform
  end

  def advance_to(current_node_id)
    edges = @flow.graph['edges'].select { |e| e['from'] == current_node_id }
    next_edge = pick_next_edge(edges)
    return @run.fail!('no_next_edge') if next_edge.nil?

    @run.update!(current_node_id: next_edge['to'], state: :running)
    perform_next
  end

  def pick_next_edge(edges)
    return edges.first if edges.length == 1 && edges.first['when'].nil?
    edges.find { |e| match_condition?(e['when']) }
  end

  def match_condition?(when_clause)
    return true if when_clause.nil?
    label = when_clause['match_label']
    return false if label.nil?

    @run.variables['last_match_label'] == label
  end
end

# app/services/flows/evaluator_service.rb
class Flows::EvaluatorService
  def initialize(run:, message:)
    @run = run
    @message = message
  end

  def perform
    node = @run.current_node
    return if node.nil? || node['type'] != 'wait_response'

    content = @message.content.to_s.strip
    match_label = find_match(content, node['data']['match'])
    return @run.fail!('no_match_and_timeout') if match_label.nil?

    @run.variables = @run.variables.merge(
      'last_user_input' => content,
      'last_match_label' => match_label
    )
    @run.append_to_trail!(node['id'], 'matched')
    @run.state = :running
    @run.save!

    Flows::ExecutionService.new(run: @run).send(:advance_to, node['id'])
  end

  private

  def find_match(content, patterns)
    return nil if patterns.blank?

    patterns.each do |entry|
      pattern = entry['pattern']
      next if pattern.blank?

      if Regexp.new(pattern, Regexp::IGNORECASE).match?(content)
        return entry['label']
      end
    end
    nil
  end
end

# app/services/flows/handoff_service.rb
class Flows::HandoffService
  def initialize(run:, reason: nil, agent_user: nil)
    @run = run
    @reason = reason
    @agent_user = agent_user
  end

  def perform
    conversation = @run.conversation

    @run.update!(
      state: :handed_off,
      ended_at: Time.current,
      ended_reason: @reason || 'human_responded'
    )

    conversation.bot_handoff! if conversation.respond_to?(:bot_handoff!)

    Conversations::ActivityMessageJob.perform_later(
      conversation,
      {
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :activity,
        content: build_summary
      }
    )
  end

  private

  def build_summary
    last_node = @run.trail.last
    vars = @run.variables.reject { |k, _| k.start_with?('_') }

    parts = []
    parts << "Automation flow \"#{@run.flow.name}\" handed off to agent."
    parts << "Reason: #{@run.ended_reason}" if @run.ended_reason.present?
    parts << "Steps completed: #{@run.trail.size}"
    parts << "Variables: #{vars.inspect}" if vars.any?
    parts.last
  end
end
```

**Jobs:**

```ruby
# app/jobs/flows/execution_job.rb
class Flows::ExecutionJob < ApplicationJob
  queue_as :low

  def perform(run_id, node_id)
    run = FlowRun.find(run_id)
    Flows::ExecutionService.new(run: run).send(:advance_to, node_id)
  end
end

# app/jobs/flows/delay_job.rb
class Flows::DelayJob < ApplicationJob
  queue_as :low

  def perform(run_id, node_id)
    run = FlowRun.find(run_id)
    return unless run.state == 'running'

    Flows::ExecutionService.new(run: run).send(:advance_to, node_id)
  end
end
```

**Listener de respuesta del cliente:**

Extender `Message#after_create_commit` o crear un nuevo `Flows::MessageListener`:

```ruby
# app/listeners/flows/message_listener.rb
class Flows::MessageListener < BaseListener
  def message_created(event)
    message = event.data[:message]
    return unless message.incoming?
    return if message.private?

    conversation = message.conversation
    return unless conversation.in_flow?

    run = conversation.active_flow_run
    return if run.nil? || run.state != 'waiting'

    Flows::EvaluatorService.new(run: run, message: message).perform
  end
end
```

**Listener de respuesta del humano (handoff):**

Extender `Message#after_create_commit`:

```ruby
# En app/models/message.rb, agregar callback:
def break_flow_on_human_response
  return unless human_response?
  return unless conversation.in_flow?

  run = conversation.active_flow_run
  return if run.nil?

  Flows::HandoffService.new(run: run, reason: 'human_responded').perform
end
```

Registrar el callback:

```ruby
# En app/models/message.rb, dentro de execute_after_create_commit_callbacks:
break_flow_on_human_response
```

**Nueva action en AutomationRule:**

```ruby
# app/models/automation_rule.rb
def actions_attributes
  %w[send_message add_label remove_label send_email_to_team assign_team assign_agent
     remove_assigned_agent remove_assigned_team send_webhook_event mute_conversation
     send_attachment change_status resolve_conversation open_conversation
     pending_conversation snooze_conversation change_priority send_email_transcript
     add_private_note enter_flow].freeze
end
```

Implementar en `AutomationRules::ActionService`:

```ruby
# app/services/automation_rules/action_service.rb
def enter_flow(flow_name)
  Flows::StartService.new(
    account: @account,
    conversation: @conversation,
    flow_name: flow_name[0],
    trigger: 'automation_rule'
  ).perform
end
```

### Fase 3: UI (3-4 días)

**API endpoints:**

```ruby
# config/routes.rb
namespace :api do
  namespace :v2 do
    resources :accounts do
      resources :flows, only: [:index, :show, :create, :update, :destroy]
      post 'flows/:flow_name/start', to: 'flows#start'
    end
  end
end
```

**Controller:**

```ruby
# app/controllers/api/v2/accounts/flows_controller.rb
class Api::V2::Accounts::FlowsController < Api::V1::Accounts::BaseController
  before_action :fetch_flow, only: [:show, :update, :destroy, :start]

  def index
    @flows = Current.account.flows
    render json: @flows
  end

  def show
    render json: @flow
  end

  def create
    @flow = Current.account.flows.create!(flow_params)
    render json: @flow, status: :created
  end

  def update
    @flow.update!(flow_params)
    render json: @flow
  end

  def destroy
    @flow.destroy!
    head :no_content
  end

  def start
    result = Flows::StartService.new(
      account: Current.account,
      conversation: conversation,
      flow_name: @flow.name,
      trigger: 'manual'
    ).perform
    render json: result
  end

  private

  def fetch_flow
    @flow = Current.account.flows.find_by!(name: params[:id])
  end

  def conversation
    Current.account.conversations.find(params[:conversation_id])
  end

  def flow_params
    params.require(:flow).permit(:name, :description, :active, graph: {})
  end
end
```

**Routes (frontend):**

```javascript
// app/javascript/dashboard/routes/dashboard/settings/flow/flow.routes.js
export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/flow'),
      component: SettingsWrapper,
      children: [
        { path: '', redirect: { name: 'flow_list' } },
        {
          path: 'list',
          name: 'flow_list',
          component: () => import('./Index.vue'),
          meta: { featureFlag: 'flows_v1', permissions: ['administrator'] },
        },
        {
          path: 'new',
          name: 'flow_new',
          component: () => import('./Edit.vue'),
          meta: { featureFlag: 'flows_v1', permissions: ['administrator'] },
        },
        {
          path: ':flow_id/edit',
          name: 'flow_edit',
          component: () => import('./Edit.vue'),
          meta: { featureFlag: 'flows_v1', permissions: ['administrator'] },
        },
      ],
    },
  ],
};
```

**Lista de flows:**

```vue
<!-- app/javascript/dashboard/routes/dashboard/settings/flow/Index.vue -->
<template>
  <div class="px-4 py-6 max-w-5xl mx-auto">
    <header class="flex justify-between items-center mb-6">
      <h1 class="text-xl font-semibold">{{ $t('FLOW.HEADER_TITLE') }}</h1>
      <NextButton icon="i-lucide-plus" @click="$router.push({ name: 'flow_new' })">
        {{ $t('FLOW.NEW_FLOW') }}
      </NextButton>
    </header>

    <table v-if="flows.length" class="w-full">
      <thead>
        <tr>
          <th>{{ $t('FLOW.NAME') }}</th>
          <th>{{ $t('FLOW.STATUS') }}</th>
          <th>{{ $t('FLOW.RUNS') }}</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="flow in flows" :key="flow.id">
          <td>{{ flow.name }}</td>
          <td>
            <span :class="flow.active ? 'bg-n-teal-2 text-n-teal-11' : 'bg-n-slate-3 text-n-slate-11'">
              {{ flow.active ? $t('FLOW.ACTIVE') : $t('FLOW.INACTIVE') }}
            </span>
          </td>
          <td>{{ flowStats[flow.id] || 0 }}</td>
          <td>
            <NextButton sm slate @click="$router.push({ name: 'flow_edit', params: { flow_id: flow.id } })">
              {{ $t('FLOW.EDIT') }}
            </NextButton>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
```

**Editor visual (canvas):**

```vue
<!-- app/javascript/dashboard/routes/dashboard/settings/flow/Edit.vue -->
<template>
  <div class="flex h-full">
    <aside class="w-64 bg-n-surface-2 p-4 border-r border-n-weak">
      <h2 class="font-semibold mb-4">{{ $t('FLOW.EDITOR.NODE_PALETTE') }}</h2>
      <draggable
        :list="paletteNodes"
        :group="{ name: 'canvas', pull: 'clone', put: false }"
        item-key="type"
        :clone="cloneNode"
      >
        <template #item="{ element }">
          <div class="bg-n-surface-1 p-3 rounded-md mb-2 cursor-grab border border-n-weak">
            <i :class="element.icon" class="mr-2"></i>
            {{ $t(`FLOW.EDITOR.NODES.${element.type}`) }}
          </div>
        </template>
      </draggable>
    </aside>

    <main class="flex-1 p-6">
      <FlowGraphEditor v-model="graph" @change="markDirty" />
    </main>

    <aside class="w-80 bg-n-surface-2 p-4 border-l border-n-weak">
      <FlowNodeInspector :node="selectedNode" @update="updateNode" />
    </aside>
  </div>
</template>
```

**FlowBadge (header + lista):**

```vue
<!-- app/javascript/dashboard/components-next/Conversation/FlowBadge.vue -->
<template>
  <span v-if="run" :class="badgeClasses" :title="title">
    <i :class="iconClasses"></i>
    {{ label }}
  </span>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  run: { type: Object, default: null },
});

const colorMap = {
  running: { class: 'bg-n-teal-2 text-n-teal-11', icon: 'i-lucide-play-circle', label: 'Flow' },
  waiting: { class: 'bg-n-amber-2 text-n-amber-11', icon: 'i-lucide-clock', label: 'Esperando' },
  completed: { class: 'bg-n-slate-2 text-n-slate-11', icon: 'i-lucide-check', label: 'Completado' },
  handed_off: { class: 'bg-n-ruby-2 text-n-ruby-11', icon: 'i-lucide-user', label: 'Handoff' },
  failed: { class: 'bg-n-ruby-3 text-n-ruby-12', icon: 'i-lucide-alert-triangle', label: 'Falló' },
  cancelled: { class: 'bg-n-slate-2 text-n-slate-11', icon: 'i-lucide-x', label: 'Cancelado' },
};

const badgeClasses = computed(() => colorMap[props.run?.state]?.class || '');
const iconClasses = computed(() => colorMap[props.run?.state]?.icon || '');
const label = computed(() => colorMap[props.run?.state]?.label || '');
const title = computed(() => `Flow: ${props.run?.flow?.name} — ${props.run?.state}`);
</script>
```

Integrar en `ConversationHeader.vue`:

```vue
<FlowBadge v-if="currentFlowRun" :run="currentFlowRun" class="mx-2" />
```

Y en `ChatList.vue` (lista de conversaciones):

```vue
<FlowBadge v-if="chat.flow_run" :run="chat.flow_run" />
```

Exponer en el jbuilder:

```ruby
# app/views/api/v1/conversations/partials/_conversation.json.jbuilder
json.flow_run conversation.flow_runs.where(state: %i[running waiting]).order(started_at: :desc).first if conversation.in_flow?
```

### Feature flag

```yaml
# config/features.yml
flows_v1: true
```

```javascript
// app/javascript/dashboard/featureFlags.js
export const FEATURE_FLAGS = {
  // ...
  FLOWS_V1: 'flows_v1',
};
```

---

## Tests

### Backend (RSpec)

```ruby
# spec/models/flow_spec.rb
RSpec.describe Flow do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:account_id) }
  end
end

# spec/models/flow_run_spec.rb
RSpec.describe FlowRun do
  describe '#handoff!' do
    it 'closes the run and creates an activity message'
  end
end

# spec/services/flows/start_service_spec.rb
RSpec.describe Flows::StartService do
  it 'starts a run and executes the entry node'
  it 'does not start a run if conversation already in flow'
  it 'fails if flow not found'
end

# spec/services/flows/execution_service_spec.rb
RSpec.describe Flows::ExecutionService do
  context 'with send_message node' do
    it 'creates an outgoing message and advances'
  end

  context 'with wait_response node' do
    it 'pauses and waits for client input'
  end

  context 'with condition node' do
    it 'evaluates expression and branches'
  end

  context 'with handoff node' do
    it 'closes the run and transfers to agent'
  end
end

# spec/services/flows/evaluator_service_spec.rb
RSpec.describe Flows::EvaluatorService do
  it 'matches user input against patterns'
  it 'advances to the correct edge based on match label'
  it 'fails if no pattern matches and timeout configured'
end

# spec/services/flows/handoff_service_spec.rb
RSpec.describe Flows::HandoffService do
  it 'creates an activity message with flow summary'
  it 'includes variables collected during the flow'
end

# spec/integration/conversation_flow_spec.rb
RSpec.describe 'Conversation flow integration', type: :request do
  it 'creates a run via API, runs through nodes, and hands off on human response'
end
```

### Frontend (Jest/Vitest)

```javascript
// app/javascript/dashboard/components-next/Conversation/FlowBadge.spec.js
import FlowBadge from './FlowBadge.vue';
import { mount } from '@vue/test-utils';

describe('FlowBadge', () => {
  it('renders green badge for running state', () => {});
  it('renders orange badge for waiting state', () => {});
  it('renders red badge for handed_off state', () => {});
});
```

---

## Ejemplo de uso

### Admin crea Flow "Soporte Compra"

```json
{
  "name": "soporte_compra",
  "description": "Rutea consultas de compra/envío/devolución",
  "graph": {
    "entry_node_id": "n1",
    "nodes": [
      {"id": "n1", "type": "send_message", "data": {"content": "¡Hola! ¿En qué te ayudo?", "buttons": ["A", "B", "C"]}},
      {"id": "n2", "type": "wait_response", "data": {"match": [
        {"label": "A", "pattern": "^a$|env[ií]o"},
        {"label": "B", "pattern": "^b$|devolu"},
        {"label": "C", "pattern": "^c$|otro"}
      ]}},
      {"id": "n3", "type": "set_variable", "data": {"key": "intent", "value": "shipping"}},
      {"id": "n4", "type": "send_message", "data": {"content": "Tu pedido está en camino. Llega en 2-3 días."}},
      {"id": "n5", "type": "set_variable", "data": {"key": "intent", "value": "return"}},
      {"id": "n6", "type": "send_message", "data": {"content": "Para devoluciones completa: https://ejemplo.dev"}},
      {"id": "n7", "type": "handoff", "data": {"reason": "Cliente eligió 'Otro'"}},
      {"id": "nE", "type": "end", "data": {}}
    ],
    "edges": [
      {"from": "n1", "to": "n2"},
      {"from": "n2", "to": "n3", "when": {"match_label": "A"}},
      {"from": "n2", "to": "n5", "when": {"match_label": "B"}},
      {"from": "n2", "to": "n7", "when": {"match_label": "C"}},
      {"from": "n3", "to": "n4"},
      {"from": "n4", "to": "nE"},
      {"from": "n5", "to": "n6"},
      {"from": "n6", "to": "nE"},
      {"from": "n7", "to": "nE"}
    ]
  }
}
```

### Admin crea Automation Rule "Trigger Compra"

```yaml
name: "Trigger Compra"
event_name: message_created
conditions:
  - attribute_key: message_content
    filter_operator: contains
    values: ["envío", "devolución", "otro"]
actions:
  - action_name: enter_flow
    action_params: ["soporte_compra"]
```

### Cliente escribe "hola, dónde está mi envío"

1. Mensaje incoming entra
2. AutomationRuleListener detecta → invoca `enter_flow("soporte_compra")`
3. FlowRun creado en estado `running`
4. Bot envía "¡Hola! ¿En qué te ayudo?" (badge 🟢)
5. FlowRun pasa a `waiting` (badge 🟠)
6. Cliente responde "A"
7. Evaluator matchea "A" → set_variable + send_message → end
8. FlowRun pasa a `completed` (badge gris)
9. Cliente luego responde algo más → human_response → flow ya cerrado, no pasa nada
10. O si agente responde → human_response → handoff (badge 🔴)

---

## Tradeoffs y riesgos

| Riesgo | Mitigación |
|--------|-----------|
| Canvas UI es trabajo grande (4-6 días) | Empezar con editor JSON simple + vista previa; refactorizar a canvas real en v2 |
| Polling / timeouts en `wait_response` requiere Sidekiq | Job `Flows::DelayJob` + interval configurable por flow |
| Conversación ya en flow → ¿re-entrarla? | Validar `in_flow?` antes de iniciar nuevo; documentar comportamiento |
| Run huérfano si conversation se borra | `dependent: :destroy` en FlowRun |
| Handoff sin contexto | Activity message con resumen + variables recogidas |
| Flow mal diseñado bloquea conversación | Timeouts automáticos (ej: 24h en `waiting` → fail) |
| Patrones regex pueden ser peligrosos | Sandbox regex (no `eval`, no backtracking infinito) |
| Race conditions en message_created + flow execution | Locks con `with_lock` en FlowRun |
| Recursión (flow entra a flow) | Bloquear por diseño: si ya está en flow, error |

---

## Configuración / Pre-requisitos

1. **Feature flag**: agregar `:flows_v1` en `config/features.yml` y `app/javascript/dashboard/featureFlags.js`
2. **Permisos**: agregar `flows.manage` permission si se quiere granular (opcional para v1)
3. **i18n keys**: agregar en `en.json` y `es.json` todas las strings del editor y badge
4. **Enterprise override**: el listener de handoff podría querer override en enterprise para Captain

---

## Roadmap posterior (no incluido en esta rama)

- **v2**: canvas visual con drag-and-drop nativo (sin librería externa)
- **v3**: variables de sistema (`{{conversation.id}}`, `{{contact.email}}`)
- **v4**: integración con Captain LLM (decidir próximo nodo con AI)
- **v5**: A/B testing de flows
- **v6**: analytics dashboard por flow (conversión, drop-off por nodo)

---

## Changelog de la propuesta

- **2026-07-21** v0.1 — propuesta inicial, status borrador