# Fase 6 — UI do construtor de macros

## Objetivo
Expor os macros como recurso configurável pelos administradores: tela de listagem, criação, edição, ativação/desativação. UI dinâmica baseada nos `config_schema` declarados pelas classes (Fase 3) — adicionar uma trigger/condition/action nova no backend faz a UI suportá-la sem mudança de frontend.

---

## Mudanças de schema

Nenhuma. Tudo construído sobre Fase 3.

---

## Novas classes / serviços e responsabilidades

### Backend — controller CRUD

`Api::V1::Accounts::Kanban::MacrosController` ([app/controllers/api/v1/accounts/kanban/macros_controller.rb](app/controllers/api/v1/accounts/kanban/macros_controller.rb))

```ruby
class Api::V1::Accounts::Kanban::MacrosController < Api::V1::Accounts::BaseController
  before_action :authorize_admin!  # ver Policy abaixo
  before_action :fetch_macro, only: %i[show update destroy]
  
  def index
    @macros = Current.account.kanban_macros.ordered
    render json: @macros.map { |m| serialize(m) }
  end
  
  def show
    render json: serialize(@macro)
  end
  
  def create
    macro = Current.account.kanban_macros.new(macro_params)
    macro.save!
    render json: serialize(macro), status: :created
  end
  
  def update
    @macro.update!(macro_params)
    render json: serialize(@macro)
  end
  
  def destroy
    if @macro.system?
      render json: { error: 'macro do sistema não pode ser deletado' }, status: :forbidden
      return
    end
    @macro.destroy!
    head :no_content
  end
  
  # Endpoint auxiliar pra UI: lista triggers/conditions/actions disponíveis com seus schemas
  def schema
    payload = build_schema_payload
    fresh_when(etag: payload, public: false)
    render json: payload
  end
  
  # Restaura macro system pro estado original definido em Seeder::DEFAULTS
  def restore
    raise ActionController::BadRequest, 'macro não é system' unless @macro.system?
    default = Kanban::Macros::Seeder.find_default_by_name(@macro.name)
    raise ActiveRecord::RecordNotFound, 'definição padrão não encontrada' unless default
    @macro.update!(triggers: default[:triggers], conditions: default[:conditions], actions: default[:actions])
    render json: serialize(@macro)
  end
  
  private
  
  def macro_params
    params.require(:macro).permit(:name, :description, :enabled, :position,
                                   triggers: [], conditions: [], actions: [])
  end
  
  def fetch_macro
    @macro = Current.account.kanban_macros.find(params[:id])
  end
end
```

**Sobre strong params com array de hashes com `config` aninhado livre:**
```ruby
def macro_params
  permitted = params.require(:macro).permit(:name, :description, :enabled, :position)
  %i[triggers conditions actions].each do |key|
    raw = params.dig(:macro, key)
    next unless raw.is_a?(Array) || (raw.respond_to?(:each) && !raw.is_a?(String))
    permitted[key] = raw.map do |item|
      {
        'type' => item[:type] || item['type'],
        'config' => (item[:config] || item['config'] || {}).to_unsafe_h
      }
    end
  end
  permitted
end
```

`to_unsafe_h` é seguro aqui porque a validação real do conteúdo do `config` acontece no model (`Kanban::Macros::*::Registry.fetch(type).validate_config!(config)` — ver Doc 03). Controller só passa o shape correto.

### Policy — `Kanban::MacroPolicy`
[app/policies/kanban/macro_policy.rb](app/policies/kanban/macro_policy.rb)

Apenas admins (e custom roles com permissão de gerenciar kanban) podem manipular macros. Seguir padrão de outras policies kanban existentes — provavelmente `KanbanColumnPolicy` ou similar.

```ruby
class Kanban::MacroPolicy < ApplicationPolicy
  def index?     = user_admin? || user_has_role?
  def show?      = index?
  def create?    = user_admin?
  def update?    = user_admin?
  def destroy?   = user_admin?
  def schema?    = index?
end
```

### Rotas — [config/routes.rb](config/routes.rb)

Adicionar dentro do scope `:kanban`:
```ruby
namespace :kanban do
  resources :macros do
    collection do
      get :schema
    end
    member do
      post :restore
    end
  end
  # ... existing
end
```

Endpoints resultantes:
- `GET    /api/v1/accounts/:account_id/kanban/macros`
- `GET    /api/v1/accounts/:account_id/kanban/macros/schema`
- `GET    /api/v1/accounts/:account_id/kanban/macros/:id`
- `POST   /api/v1/accounts/:account_id/kanban/macros`
- `PATCH  /api/v1/accounts/:account_id/kanban/macros/:id`
- `DELETE /api/v1/accounts/:account_id/kanban/macros/:id`
- `POST   /api/v1/accounts/:account_id/kanban/macros/:id/restore` — restaura triggers/conditions/actions para o padrão (apenas macros `system: true`)

### Frontend — store Vuex

Novo módulo `app/javascript/dashboard/store/modules/kanban/macros/`:
- `actions.js` — `fetchMacros`, `fetchSchema`, `createMacro`, `updateMacro`, `deleteMacro`, `toggleEnabled`, `restoreMacro`. `fetchMacros` chama `RESET_MACROS` antes do request para limpar estado de account anterior.
- `mutations.js` — `SET_MACROS`, `SET_SCHEMA`, `ADD_MACRO`, `UPDATE_MACRO`, `REMOVE_MACRO`, `RESET_MACROS`
- `getters.js` — `getMacros`, `getSchema`. Schema é cacheado em memória até reload da página (alinhado com ETag no backend).
- `index.js` — registro do módulo. Hook na troca de account / logout chama `RESET_MACROS` (seguir pattern global do Chatwoot — verificar `app/javascript/dashboard/store/index.js` para handler de logout).

API client: estender [app/javascript/dashboard/api/kanban.js](app/javascript/dashboard/api/kanban.js) com endpoints `/macros` e `/macros/schema`.

### Frontend — componentes

Diretório `app/javascript/dashboard/routes/dashboard/settings/kanban/` (ou onde lives configurações kanban):

| Componente | Responsabilidade |
|---|---|
| `MacrosList.vue` | Listagem com toggle enabled, botões editar/deletar, badge "Padrão do sistema" se `system: true` |
| `MacroForm.vue` | Form de criação/edição. Recebe `schema` do backend e renderiza UI dinâmica. |
| `MacroBuilder.vue` | Componente filho — área "Quando/Se/Então" com listas editáveis de triggers/conditions/actions |
| `MacroItemEditor.vue` | Editor de um único item (trigger/condition/action) — select de `type` + form dinâmico baseado em `config_schema` |
| `DynamicConfigField.vue` | Renderiza um campo (input/select/etc) baseado em uma entrada do `config_schema` |

### Estrutura do `config_schema` (contrato frontend ↔ backend)

Cada item do schema tem o formato:
```jsonc
{
  "column_function": {
    "type": "enum",       // string | enum | number | boolean
    "values": ["auto_receive"],  // se enum
    "label": "Função da coluna",  // opcional, fallback = key humanizada
    "required": true
  }
}
```

Tipos suportados na primeira versão:
- `string` — `<input type="text">`
- `enum` (com `values`) — `<select>`
- `number` — `<input type="number">`
- `boolean` — `<input type="checkbox">`

Tipos avançados (`column_id`, `classification_id`, `user_id`) podem ser adicionados como tipos especiais que renderizam um picker específico — não na primeira versão.

### Rota de UI

Adicionar em [app/javascript/dashboard/routes/dashboard/settings/settings.routes.js](app/javascript/dashboard/routes/dashboard/settings/settings.routes.js):
- `/app/accounts/:accountId/settings/kanban/macros` — `MacrosList`
- `/app/accounts/:accountId/settings/kanban/macros/new` — `MacroForm` (modo create)
- `/app/accounts/:accountId/settings/kanban/macros/:id/edit` — `MacroForm` (modo edit)

Se já existe seção "Configurações de Kanban" em settings, adicionar item no menu lateral. Se não, criar.

### I18n

Adicionar em `config/locales/en.json`:
```json
{
  "KANBAN_MACROS": {
    "TITLE": "Kanban Macros",
    "SUBTITLE": "Configure automated rules for your kanban boards",
    "NEW_BUTTON": "New macro",
    "FORM": {
      "NAME": "Name",
      "DESCRIPTION": "Description",
      "ENABLED": "Enabled",
      "WHEN": "When",
      "IF": "If",
      "THEN": "Then",
      "ADD_TRIGGER": "Add trigger",
      "ADD_CONDITION": "Add condition",
      "ADD_ACTION": "Add action",
      "TYPE": "Type",
      "SAVE": "Save",
      "CANCEL": "Cancel",
      "SYSTEM_BADGE": "System default"
    },
    "DELETE_CONFIRM": "Delete this macro? This cannot be undone.",
    "DELETE_SYSTEM_FORBIDDEN": "System macros cannot be deleted, but you can disable them."
  }
}
```

(Apenas en.json — pt-BR e demais idiomas são mantidos pela comunidade conforme CLAUDE.md.)

---

## Pontos de integração com código existente

| Arquivo | Mudança |
|---|---|
| [config/routes.rb](config/routes.rb) | adicionar rotas |
| [app/controllers/api/v1/accounts/kanban/macros_controller.rb](app/controllers/api/v1/accounts/kanban/macros_controller.rb) | novo |
| [app/policies/kanban/macro_policy.rb](app/policies/kanban/macro_policy.rb) | novo |
| [app/javascript/dashboard/api/kanban.js](app/javascript/dashboard/api/kanban.js) | adicionar métodos |
| [app/javascript/dashboard/store/modules/kanban/](app/javascript/dashboard/store/modules/kanban/) | submódulo macros |
| [app/javascript/dashboard/routes/dashboard/settings/](app/javascript/dashboard/routes/dashboard/settings/) | nova seção kanban/macros |
| `config/locales/en.json` | i18n |

**Enterprise:** verificar se policies de admin têm overlay enterprise. Provavelmente não para um recurso novo; mas se houver concept de "feature flag" enterprise (ex: macros é feature paid), adicionar gate em policy.

---

## Endpoints novos ou modificados

Detalhados acima. Resumo:
- 5 endpoints CRUD + 1 schema (helper).

---

## Mudanças no frontend

Detalhadas acima. Resumo: 1 módulo store, 5 componentes, 3 rotas, 1 entrada de menu.

### UX — fluxo de criação

1. Usuário clica "Novo macro".
2. Form abre vazio. Carrega schema via `fetchSchema`.
3. Campo "Nome" e "Descrição" (text inputs).
4. Seção "Quando" (triggers): botão "Adicionar gatilho" abre dropdown com `schema.triggers.map(t => t.label)`. Selecionar adiciona o item; render do form dinâmico baseado em `config_schema`.
5. Seções "Se" (conditions) e "Então" (actions) — mesmo padrão.
6. Toggle "Habilitado".
7. Submit → POST. Sucesso → redireciona pra lista.

### Validação no frontend (camada de UX)
- Pelo menos 1 trigger e 1 action obrigatórios.
- Cada item com `type` selecionado e configs obrigatórios preenchidos.
- Backend valida tudo de novo (`Kanban::Macro.valid?`).

### Toggle inline na lista
- Cada macro na lista tem um switch ON/OFF que dispara `PATCH /macros/:id` com `enabled: false/true` sem abrir form.

---

## Trade-offs e decisões não óbvias

### 1. UI dinâmica baseada em `config_schema` vs. UI hardcoded por tipo
- **Dinâmica (escolhida):** custo inicial maior (componente DynamicConfigField), mas ZERO mudança de frontend para adicionar trigger/condition/action novo.
- **Hardcoded:** mais bonito por tipo, mas todo trigger novo exige mudança no frontend.
- Decisão alinhada com escopo "engine genérica" da Fase 3.

### 2. Tipos de campo limitados na v1
- `string`, `enum`, `number`, `boolean`. Outros viram texto string ou enum.
- Pickers especiais (column, classification, user) ficam para v2 quando alguma trigger/condition/action precisar.
- Em [Fase 5], a action `MoveCardToColumnFunction` usa `column_function` que é `enum` simples — cabe na v1.

### 3. Endpoint `schema` separado vs. embutido no fetch de macros
- Separado é mais cacheável (schema só muda quando deploy backend).
- UI carrega `schema` 1x ao montar `MacroForm`, em paralelo ao macro a editar.

### 4. Permission gate: admin-only **confirmado**
- Custom roles ("Gerente de vendas", "Consultor(a)") **não** têm acesso à gestão de macros.
- Justificativa: macros são automação crítica do funil; risco de alteração indevida por roles operacionais.
- Reavaliar com base em uso real se houver demanda.

### 5. `system: true` macros não-deletáveis (model-level guard, ver Doc 03)
- Botão delete renderiza desabilitado com tooltip "Macros padrão não podem ser deletados, mas podem ser desabilitados".
- Edit é permitido (admin pode personalizar nome, conditions, actions).
- **Botão "Restaurar padrão"** visível apenas em macros `system: true`: chama `POST /macros/:id/restore`, reverte triggers/conditions/actions para definição original do `Seeder::DEFAULTS`. Útil quando admin alterou e quer voltar ao baseline.

### 6. Reordenação por position
- Lista mostra ordem; drag-drop pra reordenar é complexity desnecessária na v1.
- v1: edição manual do campo `position` (number input no form). v2: drag.

### 7. Validação client-side mínima
- Backend é fonte de verdade. Frontend só evita submit obviamente vazio (sem trigger ou action).
- Mensagens de erro do backend são renderizadas inline no form.

### 8. Atualizações otimistas ou síncronas
- Toggle inline na lista: otimista (flip imediato, rollback em erro).
- Form save: síncrono (espera response, mostra estado de loading).

---

## Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Schema novo no backend quebra UI antiga cacheada | UI tolera tipos desconhecidos (renderiza placeholder "Tipo desconhecido — atualize"); deploy backend antes de FE em geral |
| Strong params com array de objetos é frágil | Tratamento manual em `macro_params` (mostrado acima) |
| Usuário cria macro com loop infinito (action que dispara o mesmo trigger) | Não há loop possível com ações da Fase 5; documentar para futuro |
| Deletar macro em uso quebra histórico de cards | Activities têm `metadata.macro_id` (id que pode não existir mais); UI do histórico tolera macro deletado mostrando só `metadata.macro_name` (ainda no metadata) |
| Performance da listagem com N macros | Paginação não necessária no início (poucos macros por conta); adicionar se virar problema |

---

## Critérios de aceite (validação manual)
1. Admin acessa Settings → Kanban → Macros → vê o macro padrão "Lead enviou mensagem" (system).
2. Admin desabilita o macro pelo toggle → persistido; lead novo manda mensagem → não há move.
3. Admin reabilita → comportamento volta.
4. Admin edita o macro: muda nome para "Mensagem entrante" → persistido.
5. Admin tenta deletar macro system → bloqueado com tooltip.
6. Admin cria macro novo: trigger `lead_message_received`, sem conditions, action `log_history` → salva, dispara em mensagem entrante e cria activity.
7. Não-admin acessa rota → redirect/erro 403.
8. UI mostra mensagens i18n corretas.
