# Guia Completo: Como Alterar e Trabalhar no Frontend do Chatwoot

## 📋 Índice

1. [Visão Geral da Arquitetura](#visão-geral-da-arquitetura)
2. [Estrutura de Pastas](#estrutura-de-pastas)
3. [Entrypoints e Aplicações](#entrypoints-e-aplicações)
4. [Sistema de Componentes](#sistema-de-componentes)
5. [Gerenciamento de Estado (Vuex)](#gerenciamento-de-estado-vuex)
6. [Sistema de Rotas](#sistema-de-rotas)
7. [Comunicação com Backend (API)](#comunicação-com-backend-api)
8. [Internacionalização (i18n)](#internacionalização-i18n)
9. [Estilização com Tailwind CSS](#estilização-com-tailwind-css)
10. [Build e Desenvolvimento](#build-e-desenvolvimento)
11. [Boas Práticas e Convenções](#boas-práticas-e-convenções)
12. [Checklist para Modificações](#checklist-para-modificações)

---

## Visão Geral da Arquitetura

O Chatwoot utiliza uma arquitetura **Rails + Vue 3** onde:

- **Backend**: Ruby on Rails (API REST + ActionCable para WebSockets)
- **Frontend**: Vue 3 com Composition API (`<script setup>`)
- **Build Tool**: Vite (substituindo Webpack)
- **Gerenciamento de Estado**: Vuex 4
- **Roteamento**: Vue Router 4
- **Estilização**: Tailwind CSS (exclusivamente, sem CSS customizado)
- **Internacionalização**: Vue I18n

### Fluxo de Integração Rails ↔ Vue

```
Rails Controller (dashboard_controller.rb)
    ↓
Layout ERB (vueapp.html.erb) → Injeta window.chatwootConfig
    ↓
Entrypoint Vue (dashboard.js) → Cria app Vue e monta em #app
    ↓
App.vue → Componente raiz
    ↓
Router → Gerencia rotas e navegação
    ↓
Store (Vuex) → Gerencia estado global
    ↓
Componentes Vue → UI e lógica de negócio
```

---

## Estrutura de Pastas

### 📁 `app/javascript/` - Raiz do Frontend

```
app/javascript/
├── dashboard/          # Aplicação principal do dashboard (agentes/admin)
├── widget/             # Widget de chat para clientes
├── v3/                 # Aplicação de autenticação/login
├── portal/             # Portal de ajuda (help center)
├── survey/             # Sistema de pesquisas/CSAT
├── superadmin_pages/   # Páginas do super admin
├── shared/             # Código compartilhado entre aplicações
├── entrypoints/       # Pontos de entrada das aplicações
├── design-system/     # Design system e assets
└── sdk/               # SDK público do Chatwoot
```

### 📁 `app/javascript/dashboard/` - Estrutura Detalhada

```
dashboard/
├── api/                    # Clientes API (comunicação com backend)
│   ├── ApiClient.js        # Classe base para APIs
│   ├── conversations.js    # API de conversas
│   ├── contacts.js         # API de contatos
│   └── ...
├── assets/                  # Assets estáticos (imagens, SCSS)
├── components/              # ⚠️ DEPRECATED - Use components-next
│   └── index.js           # WootUIKit (deprecated)
├── components-next/         # ✅ NOVO - Componentes modernos
│   ├── button/            # Componentes de botão
│   ├── message/           # Componentes de mensagem (prioridade)
│   ├── Conversation/      # Componentes de conversa
│   └── ...
├── composables/            # Composables Vue (lógica reutilizável)
│   ├── useAccount.js
│   ├── useConversation.js
│   └── ...
├── constants/              # Constantes globais
│   ├── globals.js
│   ├── permissions.js
│   └── ...
├── helper/                 # Funções auxiliares
│   ├── APIHelper.js       # Configuração do Axios
│   ├── URLHelper.js       # Helpers de URL
│   └── ...
├── i18n/                   # Traduções do dashboard
│   └── locale/            # Arquivos JSON por idioma
├── mixins/                 # Mixins Vue (legacy)
├── modules/                # Módulos específicos
│   ├── contact/
│   ├── conversations/
│   └── search/
├── routes/                 # Configuração de rotas
│   ├── index.js           # Router principal
│   └── dashboard/         # Rotas do dashboard
├── store/                  # Store Vuex
│   ├── index.js          # Store principal
│   └── modules/           # Módulos do store
│       ├── conversations/
│       ├── contacts/
│       └── ...
├── App.vue                 # Componente raiz
└── assets/                 # SCSS e imagens
```

### 📁 `app/javascript/shared/` - Código Compartilhado

```
shared/
├── components/            # Componentes compartilhados
│   ├── FluentIcon/       # Sistema de ícones
│   ├── Spinner.vue
│   └── ...
├── composables/           # Composables compartilhados
├── constants/             # Constantes compartilhadas
│   ├── busEvents.js      # Eventos do event bus
│   └── messages.js       # Constantes de mensagens
├── helpers/               # Helpers compartilhados
│   ├── mitt.js           # Event emitter
│   ├── DateHelper.js
│   └── ...
└── store/                 # Store compartilhado
```

---

## Entrypoints e Aplicações

### Entrypoints Disponíveis

Os entrypoints são os pontos de entrada das aplicações Vue. Eles estão em `app/javascript/entrypoints/`:

1. **`dashboard.js`** - Aplicação principal do dashboard
2. **`widget.js`** - Widget de chat para clientes
3. **`v3app.js`** - Aplicação de autenticação/login
4. **`portal.js`** - Portal de ajuda
5. **`survey.js`** - Sistema de pesquisas
6. **`superadmin.js`** - Super admin
7. **`sdk.js`** - SDK público (build separado)

### Como Funciona um Entrypoint

```javascript
// app/javascript/entrypoints/dashboard.js
import { createApp } from 'vue';
import App from 'dashboard/App.vue';
import router from 'dashboard/routes';
import store from 'dashboard/store';
import i18n from 'dashboard/i18n';

const app = createApp(App);
app.use(i18n);
app.use(router);
app.use(store);
app.mount('#app');
```

### Integração com Rails

O Rails determina qual entrypoint carregar através do `dashboard_controller.rb`:

```ruby
def set_application_pack
  @application_pack = if request.path.include?('/auth') || request.path.include?('/login')
                        'v3app'
                      else
                        'dashboard'
                      end
end
```

E injeta no layout `vueapp.html.erb`:

```erb
<%= vite_javascript_tag @application_pack %>
```

**⚠️ IMPORTANTE**: Não altere os entrypoints sem entender o impacto. Eles são críticos para o funcionamento da aplicação.

---

## Sistema de Componentes

### Componentes Legacy vs Next

O Chatwoot está em transição de componentes:

- **`components/`** - ⚠️ **DEPRECATED** - Não adicione novos componentes aqui
- **`components-next/`** - ✅ **USE ESTE** - Componentes modernos com Composition API

### Regra de Ouro

> **Use `components-next/` para TODOS os novos componentes, especialmente para message bubbles.**

### Estrutura de um Componente Next

```vue
<script setup>
// ✅ SEMPRE use <script setup> no topo
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';

// Props
const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  count: {
    type: Number,
    default: 0,
  },
});

// Emits
const emit = defineEmits(['update', 'delete']);

// Composables
const { t } = useI18n();

// Estado reativo
const isOpen = ref(false);

// Computed
const displayTitle = computed(() => `${props.title} (${props.count})`);
</script>

<template>
  <!-- ✅ SEMPRE use Tailwind, nunca CSS customizado -->
  <div class="flex items-center justify-between p-4 bg-white rounded-lg">
    <h2 class="text-lg font-semantic">{{ displayTitle }}</h2>
    <button 
      @click="emit('update')"
      class="px-4 py-2 bg-slate-900 text-white rounded"
    >
      {{ t('common.update') }}
    </button>
  </div>
</template>
```

### Convenções de Nomenclatura

- **Componentes**: PascalCase (`Button.vue`, `MessageBubble.vue`)
- **Arquivos**: Mesmo nome do componente
- **Pastas**: camelCase para organização (`message/`, `buttonGroup/`)

### Aliases de Importação

O Vite configura aliases para facilitar imports:

```javascript
// vite.config.ts
resolve: {
  alias: {
    components: path.resolve('./app/javascript/dashboard/components'),
    next: path.resolve('./app/javascript/dashboard/components-next'),
    dashboard: path.resolve('./app/javascript/dashboard'),
    shared: path.resolve('./app/javascript/shared'),
    // ...
  }
}
```

**Uso nos componentes:**

```javascript
// ✅ Use aliases
import Button from 'next/button/Button.vue';
import { useAccount } from 'dashboard/composables';
import { formatDate } from 'shared/helpers/DateHelper';
```

---

## Gerenciamento de Estado (Vuex)

### Estrutura do Store

O store Vuex está organizado em módulos:

```
dashboard/store/
├── index.js                    # Store principal
└── modules/
    ├── conversations/         # Estado de conversas
    │   ├── index.js          # Módulo principal
    │   ├── actions.js        # Actions assíncronas
    │   ├── mutations.js      # Mutations síncronas
    │   ├── getters.js        # Getters computados
    │   └── helpers.js        # Funções auxiliares
    ├── contacts/              # Estado de contatos
    ├── auth/                  # Estado de autenticação
    └── ...
```

### Padrão de Módulo Vuex

```javascript
// store/modules/conversations/index.js
import types from '../../mutation-types';
import getters from './getters';
import actions from './actions';
import mutations from './mutations';

const state = {
  allConversations: [],
  selectedChatId: null,
  // ...
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
```

### Uso no Componente

```vue
<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';

const store = useStore();

// Acessar state
const conversations = computed(() => store.state.conversations.allConversations);

// Chamar actions
const loadConversations = () => {
  store.dispatch('conversations/fetch');
};

// Chamar mutations (geralmente via actions)
// store.commit('conversations/SET_CONVERSATIONS', data);
</script>
```

### Composables para Store

Use composables para encapsular lógica do store:

```javascript
// composables/useConversation.js
import { computed } from 'vue';
import { useStore } from 'vuex';

export const useConversation = () => {
  const store = useStore();
  
  const conversations = computed(() => store.state.conversations.allConversations);
  const selectedChat = computed(() => store.getters['conversations/getSelectedChat']);
  
  const fetchConversations = () => store.dispatch('conversations/fetch');
  const selectChat = (id) => store.dispatch('conversations/selectChat', id);
  
  return {
    conversations,
    selectedChat,
    fetchConversations,
    selectChat,
  };
};
```

**Uso:**

```vue
<script setup>
import { useConversation } from 'dashboard/composables';

const { conversations, fetchConversations } = useConversation();
</script>
```

---

## Sistema de Rotas

### Estrutura de Rotas

As rotas estão organizadas hierarquicamente:

```
dashboard/routes/
├── index.js                    # Router principal
└── dashboard/
    ├── dashboard.routes.js    # Rotas principais
    ├── conversation/
    │   └── conversation.routes.js
    ├── contacts/
    │   └── routes.js
    └── ...
```

### Configuração do Router

```javascript
// routes/index.js
import { createRouter, createWebHistory } from 'vue-router';
import dashboard from './dashboard/dashboard.routes';

const routes = [...dashboard.routes];

export const router = createRouter({
  history: createWebHistory(),
  routes,
});
```

### Exemplo de Rota

```javascript
// routes/dashboard/conversation/conversation.routes.js
export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/conversations/:id'),
      name: 'conversation_show',
      component: () => import('./ConversationView.vue'),
      meta: {
        permissions: ['administrator', 'agent'],
      },
    },
  ],
};
```

### Navigation Guards

O router usa guards para autenticação e permissões:

```javascript
router.beforeEach((to, from, next) => {
  // Valida autenticação
  // Valida permissões
  // Redireciona se necessário
  next();
});
```

**⚠️ IMPORTANTE**: Não remova ou modifique os guards sem entender o impacto na segurança.

---

## Comunicação com Backend (API)

### Cliente API Base

O Chatwoot usa `ApiClient` como classe base:

```javascript
// api/ApiClient.js
class ApiClient {
  constructor(resource, options = {}) {
    this.apiVersion = `/api/${options.apiVersion || 'v1'}`;
    this.resource = resource;
  }
  
  get url() {
    return `${this.baseUrl()}/${this.resource}`;
  }
  
  get() { return axios.get(this.url); }
  show(id) { return axios.get(`${this.url}/${id}`); }
  create(data) { return axios.post(this.url, data); }
  update(id, data) { return axios.patch(`${this.url}/${id}`, data); }
  delete(id) { return axios.delete(`${this.url}/${id}`); }
}
```

### Exemplo de API Específica

```javascript
// api/conversations.js
import ApiClient from './ApiClient';

class ConversationsAPI extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }
  
  getMessages(conversationId, params = {}) {
    return axios.get(`${this.url}/${conversationId}/messages`, { params });
  }
  
  sendMessage(conversationId, content) {
    return axios.post(`${this.url}/${conversationId}/messages`, { content });
  }
}

export default new ConversationsAPI();
```

### Configuração do Axios

O Axios é configurado em `helper/APIHelper.js`:

```javascript
// helper/APIHelper.js
export default axios => {
  const wootApi = axios.create({ baseURL: `${apiHost}/` });
  
  // Adiciona headers de autenticação
  if (Auth.hasAuthCookie()) {
    const authData = Auth.getAuthData();
    Object.assign(wootApi.defaults.headers.common, authData);
  }
  
  return wootApi;
};
```

### Uso no Componente

```vue
<script setup>
import { ref, onMounted } from 'vue';
import ConversationsAPI from 'dashboard/api/conversations';

const conversations = ref([]);
const loading = ref(false);

const fetchConversations = async () => {
  loading.value = true;
  try {
    const response = await ConversationsAPI.get();
    conversations.value = response.data;
  } catch (error) {
    console.error('Erro ao carregar conversas:', error);
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchConversations();
});
</script>
```

### WebSockets (ActionCable)

O Chatwoot usa ActionCable para comunicação em tempo real:

```javascript
// shared/helpers/BaseActionCableConnector.js
// Gerencia conexões WebSocket para atualizações em tempo real
```

**⚠️ IMPORTANTE**: Não modifique a lógica de WebSocket sem entender o impacto na sincronização de dados.

---

## Internacionalização (i18n)

### Estrutura de Traduções

```
dashboard/i18n/
├── index.js              # Exporta todas as traduções
└── locale/
    ├── en.json          # Inglês (base)
    ├── pt_BR.json       # Português Brasil
    └── ...
```

### Convenção de Chaves

```json
{
  "CONVERSATION": {
    "HEADER": {
      "TITLE": "Conversations",
      "SUBTITLE": "Manage your conversations"
    },
    "ACTIONS": {
      "REPLY": "Reply",
      "ARCHIVE": "Archive"
    }
  }
}
```

### Uso no Componente

```vue
<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
</script>

<template>
  <h1>{{ t('CONVERSATION.HEADER.TITLE') }}</h1>
  <button>{{ t('CONVERSATION.ACTIONS.REPLY') }}</button>
</template>
```

### Regra de Tradução

> **NUNCA use strings hardcoded. SEMPRE use i18n.**

```vue
<!-- ❌ ERRADO -->
<button>Reply</button>

<!-- ✅ CORRETO -->
<button>{{ t('CONVERSATION.ACTIONS.REPLY') }}</button>
```

### Adicionando Novas Traduções

1. Adicione apenas em `en.json` (outros idiomas são mantidos pela comunidade)
2. Use chaves descritivas e hierárquicas
3. Mantenha consistência com chaves existentes

---

## Estilização com Tailwind CSS

### Regra Absoluta

> **USE APENAS TAILWIND. NÃO escreva CSS customizado, scoped CSS ou inline styles.**

### Configuração do Tailwind

O Tailwind está configurado em `tailwind.config.js`:

```javascript
module.exports = {
  content: [
    './app/javascript/**/*.vue',
    './app/views/**/*.html.erb',
  ],
  theme: {
    extend: {
      colors: {
        // Cores customizadas do Chatwoot
      },
    },
  },
};
```

### Cores Disponíveis

Consulte `tailwind.config.js` para cores disponíveis. O Chatwoot usa um sistema de cores baseado em Radix UI.

### Exemplo de Uso

```vue
<template>
  <!-- ✅ CORRETO - Tailwind apenas -->
  <div class="flex items-center justify-between p-4 bg-white rounded-lg shadow-sm">
    <h2 class="text-lg font-semantic text-slate-900">Título</h2>
    <button class="px-4 py-2 bg-slate-900 text-white rounded hover:bg-slate-800">
      Ação
    </button>
  </div>
</template>

<!-- ❌ ERRADO - CSS customizado -->
<style scoped>
.custom-class {
  padding: 1rem;
}
</style>
```

### Dark Mode

O Tailwind suporta dark mode via classe:

```vue
<div class="bg-white dark:bg-slate-900 text-slate-900 dark:text-white">
  Conteúdo
</div>
```

---

## Build e Desenvolvimento

### Comandos Principais

```bash
# Instalar dependências
pnpm install

# Desenvolvimento (inicia Rails + Vite)
pnpm dev
# ou
overmind start -f ./Procfile.dev

# Build para produção
bin/vite build

# Lint
pnpm eslint
pnpm eslint:fix

# Testes
pnpm test
pnpm test:watch
```

### Processo de Build

O Vite compila os entrypoints e gera assets em `public/vite/`:

```
public/vite/
├── assets/
│   ├── dashboard-*.js
│   ├── widget-*.js
│   └── ...
└── manifest.json
```

### Modo de Desenvolvimento

No desenvolvimento, o Vite roda um servidor HMR (Hot Module Replacement):

```
Procfile.dev:
  backend: bin/rails s -p 3000
  worker: bundle exec sidekiq
  vite: bin/vite dev
```

O Rails carrega os assets do servidor Vite em desenvolvimento e dos arquivos compilados em produção.

### Alias de Importação

Use os aliases configurados no Vite:

```javascript
// ✅ Use aliases
import Button from 'next/button/Button.vue';
import { useAccount } from 'dashboard/composables';
import { formatDate } from 'shared/helpers/DateHelper';

// ❌ Evite caminhos relativos longos
import Button from '../../../components-next/button/Button.vue';
```

---

## Boas Práticas e Convenções

### 1. Composition API

**SEMPRE** use Composition API com `<script setup>`:

```vue
<script setup>
// ✅ CORRETO
import { ref, computed } from 'vue';
</script>
```

### 2. Nomenclatura

- **Componentes**: PascalCase (`Button.vue`)
- **Arquivos**: Mesmo nome do componente
- **Variáveis/Funções**: camelCase (`fetchData`, `isLoading`)
- **Constantes**: UPPER_SNAKE_CASE (`API_BASE_URL`)
- **Eventos**: camelCase (`update`, `delete-item`)

### 3. Props e Emits

```vue
<script setup>
// Props com validação
const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  count: {
    type: Number,
    default: 0,
  },
});

// Emits tipados
const emit = defineEmits(['update', 'delete']);
</script>
```

### 4. Composables

Extraia lógica reutilizável para composables:

```javascript
// composables/useDataFetching.js
export const useDataFetching = (fetchFn) => {
  const data = ref(null);
  const loading = ref(false);
  const error = ref(null);
  
  const fetch = async () => {
    loading.value = true;
    try {
      data.value = await fetchFn();
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  };
  
  return { data, loading, error, fetch };
};
```

### 5. Tratamento de Erros

```vue
<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
const error = ref(null);

const handleError = (err) => {
  error.value = err.response?.data?.message || t('ERROR.GENERIC');
  // Log para Sentry se necessário
};
</script>
```

### 6. Performance

- Use `v-show` para toggle frequente, `v-if` para renderização condicional
- Use `computed` para valores derivados
- Use `watch` com cuidado (prefira `computed` quando possível)
- Lazy load componentes grandes com `defineAsyncComponent`

### 7. Acessibilidade

- Use elementos semânticos (`<button>`, `<nav>`, etc.)
- Adicione `aria-label` quando necessário
- Mantenha ordem lógica de tabulação

---

## Checklist para Modificações

Antes de fazer qualquer modificação no frontend, verifique:

### ✅ Preparação

- [ ] Entendi qual aplicação será afetada (dashboard/widget/v3/portal)
- [ ] Identifiquei os arquivos relacionados
- [ ] Verifiquei se há código Enterprise em `enterprise/` que precisa ser atualizado
- [ ] Li a documentação relevante

### ✅ Estrutura

- [ ] Estou usando `components-next/` para novos componentes
- [ ] Estou usando Composition API com `<script setup>`
- [ ] Organizei o código em pastas apropriadas
- [ ] Usei aliases de importação (`next/`, `dashboard/`, `shared/`)

### ✅ Funcionalidade

- [ ] Implementei tratamento de erros
- [ ] Adicionei estados de loading quando necessário
- [ ] Validei props e emits
- [ ] Testei em diferentes cenários (sucesso, erro, loading)

### ✅ Internacionalização

- [ ] Não usei strings hardcoded
- [ ] Adicionei traduções em `en.json`
- [ ] Usei chaves de tradução consistentes

### ✅ Estilização

- [ ] Usei apenas Tailwind CSS
- [ ] Não escrevi CSS customizado
- [ ] Verifiquei responsividade
- [ ] Testei dark mode se aplicável

### ✅ Performance

- [ ] Evitei re-renderizações desnecessárias
- [ ] Usei `computed` para valores derivados
- [ ] Lazy load componentes grandes quando apropriado

### ✅ Testes

- [ ] Testei manualmente a funcionalidade
- [ ] Verifiquei que não quebrei funcionalidades existentes
- [ ] Executei `pnpm eslint` e corrigi erros
- [ ] Executei testes se existirem

### ✅ Build

- [ ] Verifiquei que o build funciona (`bin/vite build`)
- [ ] Testei em modo de desenvolvimento (`pnpm dev`)
- [ ] Verifiquei que não há erros no console

---

## Pontos Críticos - NÃO Modifique Sem Entender

### 🚨 Entrypoints (`entrypoints/*.js`)

Os entrypoints são críticos. Modificações podem quebrar toda a aplicação.

### 🚨 Router Guards (`routes/index.js`)

Os guards de navegação são essenciais para segurança. Não remova validações de autenticação.

### 🚨 Store Modules (`store/modules/*`)

Modificações no store podem afetar múltiplos componentes. Teste extensivamente.

### 🚨 API Client (`api/ApiClient.js`)

A classe base da API é usada por todas as chamadas. Mudanças afetam tudo.

### 🚨 WebSocket (`shared/helpers/BaseActionCableConnector.js`)

A lógica de WebSocket é crítica para sincronização em tempo real.

### 🚨 Configuração do Vite (`vite.config.ts`)

Mudanças podem quebrar o build ou aliases de importação.

---

## Recursos Adicionais

### Documentação Oficial

- [Vue 3 Documentation](https://vuejs.org/)
- [Vue Router 4](https://router.vuejs.org/)
- [Vuex 4](https://vuex.vuejs.org/)
- [Vite](https://vitejs.dev/)
- [Tailwind CSS](https://tailwindcss.com/)

### Arquivos de Referência no Projeto

- `AGENTS.md` - Guia de desenvolvimento geral
- `tailwind.config.js` - Configuração do Tailwind
- `vite.config.ts` - Configuração do Vite
- `package.json` - Dependências e scripts

### Padrões de Código

- Consulte componentes existentes em `components-next/` como referência
- Veja composables em `composables/` para padrões de lógica reutilizável
- Examine módulos do store em `store/modules/` para padrões de estado

---

## Conclusão

Este guia fornece uma visão completa da estrutura do frontend do Chatwoot. Ao seguir estas diretrizes e convenções, você pode fazer modificações de forma segura e consistente, mantendo a estrutura funcional e a qualidade do código.

**Lembre-se**: Quando em dúvida, consulte o código existente como referência e siga os padrões já estabelecidos no projeto.

