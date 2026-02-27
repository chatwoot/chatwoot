# Blueprint de Criação de Módulos - Hubdesk (Chatwoot)

Este documento serve como um guia técnico detalhado para a implementação de novos módulos no Hubdesk, garantindo consistência com a arquitetura existente (Rails 7 + Vue 3).

## 📋 Checklist de Implementação

### 1. Backend (Ruby on Rails)
- [ ] **Migration**: Criar tabelas com `account_id` e chaves estrangeiras.
- [ ] **Model**: Definir relacionamentos (`belongs_to :account`), validações e hooks.
- [ ] **Policy**: Criar `app/policies/NovoModuloPolicy.rb` (Pundit) para controle de acesso.
- [ ] **Controller**: Criar `Api::V1::Accounts::NovoModuloController` com `before_action :authenticate_user!`.
- [ ] **Routes**: Adicionar recursos em `config/routes.rb` aninhados em `:accounts`.
- [ ] **Views**: Criar arquivos `.json.jbuilder` para serialização da resposta API.
- [ ] **Service/Job** (Opcional): Extrair lógica complexa para `app/services/` ou `app/jobs/`.

### 2. Frontend (Vue.js)
- [ ] **API Client**: Criar `app/javascript/dashboard/api/novoModulo.js`.
- [ ] **Store**: Criar módulo Vuex em `app/javascript/dashboard/store/modules/novoModulo/`.
- [ ] **Rotas**: Registrar rotas em `app/javascript/dashboard/routes/dashboard/dashboard.routes.js`.
- [ ] **Componentes**: Desenvolver UI em `app/javascript/dashboard/routes/dashboard/novoModulo/`.
- [ ] **Sidebar**: Adicionar item de menu em `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`.

### 3. Integração (Glue Code)
- [ ] **i18n Backend**: Adicionar chaves em `config/locales/en.yml` e `pt_BR.yml`.
- [ ] **i18n Frontend**: Adicionar JSONs em `app/javascript/dashboard/i18n/locale/*/novoModulo.json`.
- [ ] **Websockets**: Adicionar listeners em `app/javascript/dashboard/helper/actionCable.js` para atualizações em tempo real.

### 4. Testes (Quality Assurance)
- [ ] **RSpec**: Testes de Model (`spec/models/`) e Request (`spec/controllers/` ou `spec/requests/`).
- [ ] **Frontend Specs**: Testes de unidade para componentes e store (`.spec.js`).

---

## 📂 Estrutura de Diretórios Recomendada

```text
hubdesk/
├── app/
│   ├── controllers/api/v1/accounts/
│   │   └── novo_modulo_controller.rb  # Endpoint da API
│   ├── models/
│   │   └── novo_modulo.rb             # Lógica de Negócio
│   ├── policies/
│   │   └── novo_modulo_policy.rb      # Regras de Segurança
│   └── javascript/dashboard/
│       ├── api/
│       │   └── novoModulo.js          # Cliente HTTP (Axios)
│       ├── routes/dashboard/
│       │   └── novoModulo/            # Componentes Vue (Pages)
│       │       ├── Index.vue
│       │       └── novoModulo.routes.js
│       └── store/modules/
│           └── novoModulo/            # Gerenciamento de Estado
├── config/
│   └── locales/                       # Traduções Backend
└── spec/                              # Testes Automatizados
```

---

## 🛠️ Detalhes de Implementação

### 1. Backend: Model & Policy

**Model (`app/models/widget.rb`)**
```ruby
class Widget < ApplicationRecord
  belongs_to :account
  belongs_to :user

  validates :name, presence: true
  
  # Scopes para segurança
  scope :latest, -> { order(created_at: :desc) }
end
```

**Policy (`app/policies/widget_policy.rb`)**
```ruby
class WidgetPolicy < ApplicationPolicy
  def index?
    # Permite se for admin ou agente da conta
    @account_user.administrator? || @account_user.agent?
  end

  def create?
    # Apenas administradores podem criar
    @account_user.administrator?
  end
  
  def update?
    create?
  end

  def destroy?
    create?
  end
end
```

### 2. Backend: Controller

**Controller (`app/controllers/api/v1/accounts/widgets_controller.rb`)**
```ruby
class Api::V1::Accounts::WidgetsController < Api::V1::Accounts::BaseController
  before_action :fetch_widget, only: [:show, :update, :destroy]

  def index
    @widgets = Current.account.widgets.latest
  end

  def create
    @widget = Current.account.widgets.new(widget_params)
    @widget.user = current_user
    authorize @widget # Chama WidgetPolicy
    @widget.save!
  end

  private

  def widget_params
    params.require(:widget).permit(:name, :config)
  end

  def fetch_widget
    @widget = Current.account.widgets.find(params[:id])
    authorize @widget
  end
end
```

### 3. Frontend: API & Store

**API Client (`app/javascript/dashboard/api/widgets.js`)**
```javascript
import ApiClient from './ApiClient';

class WidgetsAPI extends ApiClient {
  constructor() {
    super('widgets', { accountScoped: true });
  }
}

export default new WidgetsAPI();
```

**Store Module (`app/javascript/dashboard/store/modules/widgets.js`)**
```javascript
import WidgetsAPI from '../../api/widgets';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit('SET_UI_FLAG', { isFetching: true });
    try {
      const response = await WidgetsAPI.get();
      commit('SET_RECORDS', response.data);
    } catch (error) {
      // Handle error
    } finally {
      commit('SET_UI_FLAG', { isFetching: false });
    }
  },
};

export const mutations = {
  SET_RECORDS($state, data) {
    $state.records = data;
  },
  SET_UI_FLAG($state, { isFetching }) {
    $state.uiFlags.isFetching = isFetching;
  },
};

export default {
  namespaced: true,
  state,
  actions,
  mutations,
};
```

### 4. Frontend: Rotas & Permissões

**Routes (`app/javascript/dashboard/routes/dashboard/widgets/routes.js`)**
```javascript
import { frontendURL } from '../../helper/URLHelper';
const WidgetsIndex = () => import('./pages/Index.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/widgets'),
    name: 'widgets_index',
    component: WidgetsIndex,
    meta: {
      permissions: ['administrator'], // Proteção de Rota
    },
  },
];
```

### 5. Glue Code: Internacionalização

**Backend (`config/locales/pt_BR.yml`)**
```yaml
pt_BR:
  widgets:
    create:
      success: "Widget criado com sucesso"
      error: "Erro ao criar widget"
```

**Frontend (`app/javascript/dashboard/i18n/locale/pt_BR/widgets.json`)**
```json
{
  "WIDGETS": {
    "HEADER": "Meus Widgets",
    "ADD_NEW": "Novo Widget",
    "FORM": {
      "NAME": "Nome do Widget"
    }
  }
}
```

---

## ⚠️ Padrões Importantes

1.  **Multitenancy**: Sempre use `Current.account` ou `account.widgets` no Backend. Nunca busque registros sem escopo de conta.
2.  **Segurança**: Nunca confie nos parâmetros do Frontend. Sempre use `strong params` e `Pundit`.
3.  **UI/UX**: Use os componentes base (`Button`, `Input`, `Modal`) localizados em `components-next/` ou `components/ui/` para manter o visual nativo.
4.  **Linting**: Rode `rubocop` e `eslint` antes de commitar.
