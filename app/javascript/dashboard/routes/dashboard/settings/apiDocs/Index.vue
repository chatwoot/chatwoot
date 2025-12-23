<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import axios from 'axios';

const { t } = useI18n();
const store = useStore();
const { accountScopedRoute } = useAccount();
const { isAdmin } = useAdmin();

const currentUser = computed(() => store.getters.getCurrentUser);
const accessToken = ref(null);
const apiEndpoints = ref([]);
const loading = ref(true);
const error = ref(null);

const baseUrl = computed(() => {
  return window.location.origin;
});

const apiBaseUrl = computed(() => {
  return `${baseUrl.value}/api/v1`;
});

onMounted(async () => {
  if (!isAdmin.value) {
    error.value = 'Acesso negado. Apenas administradores podem acessar esta página.';
    loading.value = false;
    return;
  }

  // Primeiro, tentar buscar do store (mais rápido)
  if (currentUser.value?.access_token?.token) {
    accessToken.value = currentUser.value.access_token.token;
  }

  try {
    // Buscar access token do usuário através do endpoint de profile
    const userResponse = await axios.get('/api/v1/profile');
    
    // O endpoint retorna access_token como string direta (não como objeto)
    if (userResponse?.data?.access_token) {
      // Se for string, usar diretamente
      if (typeof userResponse.data.access_token === 'string') {
        accessToken.value = userResponse.data.access_token;
      } 
      // Se for objeto com token
      else if (userResponse.data.access_token.token) {
        accessToken.value = userResponse.data.access_token.token;
      }
    }

    // Se ainda não tiver token, tentar buscar do store novamente
    if (!accessToken.value && currentUser.value?.access_token?.token) {
      accessToken.value = currentUser.value.access_token.token;
    }

    // Buscar endpoints da API (sempre executar, mesmo se token falhar)
    await loadApiEndpoints();
    
    // Se não conseguiu o token, mostrar aviso mas não erro fatal
    if (!accessToken.value) {
      error.value = 'Não foi possível carregar o Access Token. Verifique se você está autenticado.';
    } else {
      error.value = null;
    }
  } catch (err) {
    console.error('Erro ao carregar dados:', err);
    
    // Se já tem token do store, não mostrar erro fatal
    if (accessToken.value) {
      error.value = null;
    } else {
      error.value = `Erro ao carregar informações da API: ${err.message || 'Erro desconhecido'}`;
    }
    
    // Sempre carregar endpoints mesmo com erro
    await loadApiEndpoints();
  } finally {
    loading.value = false;
  }
});

const loadApiEndpoints = async () => {
  // Lista de endpoints principais da API
  const endpoints = [
    // Accounts
    { method: 'GET', path: '/accounts', description: 'Listar contas' },
    { method: 'GET', path: '/accounts/:id', description: 'Detalhes da conta' },
    { method: 'POST', path: '/accounts', description: 'Criar conta' },
    { method: 'PATCH', path: '/accounts/:id', description: 'Atualizar conta' },

    // Agents
    { method: 'GET', path: '/accounts/:account_id/agents', description: 'Listar agentes' },
    { method: 'POST', path: '/accounts/:account_id/agents', description: 'Criar agente' },
    { method: 'PATCH', path: '/accounts/:account_id/agents/:id', description: 'Atualizar agente' },
    { method: 'DELETE', path: '/accounts/:account_id/agents/:id', description: 'Deletar agente' },

    // Conversations
    { method: 'GET', path: '/accounts/:account_id/conversations', description: 'Listar conversas' },
    { method: 'GET', path: '/accounts/:account_id/conversations/:id', description: 'Detalhes da conversa' },
    { method: 'POST', path: '/accounts/:account_id/conversations', description: 'Criar conversa' },
    { method: 'PATCH', path: '/accounts/:account_id/conversations/:id', description: 'Atualizar conversa' },
    { method: 'DELETE', path: '/accounts/:account_id/conversations/:id', description: 'Deletar conversa' },

    // Messages
    { method: 'GET', path: '/accounts/:account_id/conversations/:id/messages', description: 'Listar mensagens' },
    { method: 'POST', path: '/accounts/:account_id/conversations/:id/messages', description: 'Enviar mensagem' },
    { method: 'PATCH', path: '/accounts/:account_id/conversations/:id/messages/:message_id', description: 'Atualizar mensagem' },
    { method: 'DELETE', path: '/accounts/:account_id/conversations/:id/messages/:message_id', description: 'Deletar mensagem' },

    // Contacts
    { method: 'GET', path: '/accounts/:account_id/contacts', description: 'Listar contatos' },
    { method: 'GET', path: '/accounts/:account_id/contacts/:id', description: 'Detalhes do contato' },
    { method: 'POST', path: '/accounts/:account_id/contacts', description: 'Criar contato' },
    { method: 'PATCH', path: '/accounts/:account_id/contacts/:id', description: 'Atualizar contato' },
    { method: 'DELETE', path: '/accounts/:account_id/contacts/:id', description: 'Deletar contato' },

    // Inboxes
    { method: 'GET', path: '/accounts/:account_id/inboxes', description: 'Listar caixas de entrada' },
    { method: 'GET', path: '/accounts/:account_id/inboxes/:id', description: 'Detalhes da caixa de entrada' },
    { method: 'POST', path: '/accounts/:account_id/inboxes', description: 'Criar caixa de entrada' },
    { method: 'PATCH', path: '/accounts/:account_id/inboxes/:id', description: 'Atualizar caixa de entrada' },
    { method: 'DELETE', path: '/accounts/:account_id/inboxes/:id', description: 'Deletar caixa de entrada' },

    // Teams
    { method: 'GET', path: '/accounts/:account_id/teams', description: 'Listar equipes' },
    { method: 'POST', path: '/accounts/:account_id/teams', description: 'Criar equipe' },
    { method: 'PATCH', path: '/accounts/:account_id/teams/:id', description: 'Atualizar equipe' },
    { method: 'DELETE', path: '/accounts/:account_id/teams/:id', description: 'Deletar equipe' },

    // Labels
    { method: 'GET', path: '/accounts/:account_id/labels', description: 'Listar etiquetas' },
    { method: 'POST', path: '/accounts/:account_id/labels', description: 'Criar etiqueta' },
    { method: 'PATCH', path: '/accounts/:account_id/labels/:id', description: 'Atualizar etiqueta' },
    { method: 'DELETE', path: '/accounts/:account_id/labels/:id', description: 'Deletar etiqueta' },

    // Reports
    { method: 'GET', path: '/accounts/:account_id/reports', description: 'Relatórios' },
    { method: 'GET', path: '/accounts/:account_id/reports/overview', description: 'Visão geral dos relatórios' },
    { method: 'GET', path: '/accounts/:account_id/reports/conversation', description: 'Relatório de conversas' },

    // Automation Rules
    { method: 'GET', path: '/accounts/:account_id/automation_rules', description: 'Listar regras de automação' },
    { method: 'POST', path: '/accounts/:account_id/automation_rules', description: 'Criar regra de automação' },
    { method: 'PATCH', path: '/accounts/:account_id/automation_rules/:id', description: 'Atualizar regra de automação' },
    { method: 'DELETE', path: '/accounts/:account_id/automation_rules/:id', description: 'Deletar regra de automação' },

    // Integrations
    { method: 'GET', path: '/accounts/:account_id/applications', description: 'Listar integrações' },
    { method: 'POST', path: '/accounts/:account_id/applications', description: 'Criar integração' },
    { method: 'DELETE', path: '/accounts/:account_id/applications/:id', description: 'Deletar integração' },
  ];

  apiEndpoints.value = endpoints;
};

const loadAccessToken = async () => {
  try {
    // Buscar access token do usuário através do endpoint de profile
    const userResponse = await axios.get('/api/v1/profile');
    
    console.log('Profile response:', userResponse?.data); // Debug
    
    // O endpoint retorna access_token como string direta (não objeto)
    // Segundo o jbuilder: json.access_token resource.access_token.token
    if (userResponse?.data?.access_token) {
      // Se for string, usar diretamente
      if (typeof userResponse.data.access_token === 'string') {
        accessToken.value = userResponse.data.access_token;
        console.log('Token carregado (string):', accessToken.value?.substring(0, 20) + '...');
        return true;
      } 
      // Se for objeto com token (fallback)
      else if (userResponse.data.access_token.token) {
        accessToken.value = userResponse.data.access_token.token;
        console.log('Token carregado (objeto):', accessToken.value?.substring(0, 20) + '...');
        return true;
      }
    }
    console.warn('Access token não encontrado na resposta');
    return false;
  } catch (err) {
    console.error('Erro ao buscar access token:', err);
    console.error('Detalhes do erro:', {
      message: err.message,
      status: err.response?.status,
      data: err.response?.data,
    });
    return false;
  }
};

const reloadData = async () => {
  loading.value = true;
  error.value = null;
  
  // Tentar buscar do store primeiro
  if (currentUser.value?.access_token?.token) {
    accessToken.value = currentUser.value.access_token.token;
  }
  
  // Tentar buscar da API
  const tokenLoaded = await loadAccessToken();
  
  // Se não conseguiu, tentar do store novamente
  if (!tokenLoaded && currentUser.value?.access_token?.token) {
    accessToken.value = currentUser.value.access_token.token;
  }
  
  // Sempre carregar endpoints
  await loadApiEndpoints();
  
  // Se ainda não tem token, mostrar aviso
  if (!accessToken.value) {
    error.value = 'Não foi possível carregar o Access Token. Verifique se você está autenticado ou tente recarregar a página.';
  }
  
  loading.value = false;
};

const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text);
    // Você pode adicionar uma notificação aqui
  } catch (err) {
    console.error('Erro ao copiar:', err);
  }
};

const getMethodColor = (method) => {
  const colors = {
    GET: 'bg-blue-100 text-blue-800',
    POST: 'bg-green-100 text-green-800',
    PATCH: 'bg-yellow-100 text-yellow-800',
    PUT: 'bg-orange-100 text-orange-800',
    DELETE: 'bg-red-100 text-red-800',
  };
  return colors[method] || 'bg-gray-100 text-gray-800';
};
</script>

<template>
  <div class="w-full h-full overflow-y-auto overflow-x-hidden">
    <div class="p-6 max-w-7xl mx-auto pb-12">
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-900 mb-2">
        Documentação da API
      </h1>
      <p class="text-gray-600">
        Endpoints e chaves de acesso disponíveis para administradores
      </p>
    </div>

    <div v-if="error" class="bg-yellow-50 border border-yellow-200 text-yellow-800 px-4 py-3 rounded mb-4">
      <p class="font-medium">Aviso:</p>
      <p>{{ error }}</p>
    </div>

    <div v-if="loading" class="text-center py-8">
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
      <p class="mt-2 text-gray-600">Carregando...</p>
    </div>

    <div v-else class="space-y-6">
      <!-- Access Token Section -->
      <div class="bg-white border border-gray-200 rounded-lg p-6">
        <h2 class="text-xl font-semibold text-gray-900 mb-4">Sua Chave de Acesso (Access Token)</h2>
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Token de Acesso
            </label>
            <div class="flex gap-2">
              <input
                :value="accessToken || 'Carregando...'"
                readonly
                :class="[
                  'flex-1 px-4 py-2 border rounded-lg font-mono text-sm',
                  accessToken 
                    ? 'border-gray-300 bg-gray-50' 
                    : 'border-yellow-300 bg-yellow-50'
                ]"
              />
              <button
                v-if="accessToken"
                @click="copyToClipboard(accessToken)"
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
              >
                Copiar
              </button>
              <button
                v-else
                @click="reloadData()"
                class="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition"
              >
                Recarregar
              </button>
            </div>
            <p class="mt-2 text-sm text-gray-500">
              Use este token no header <code class="bg-gray-100 px-1 rounded">api_access_token</code> para autenticar requisições à API
            </p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              URL Base da API
            </label>
            <div class="flex gap-2">
              <input
                :value="apiBaseUrl"
                readonly
                class="flex-1 px-4 py-2 border border-gray-300 rounded-lg bg-gray-50 font-mono text-sm"
              />
              <button
                @click="copyToClipboard(apiBaseUrl)"
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
              >
                Copiar
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- API Endpoints Section -->
      <div class="bg-white border border-gray-200 rounded-lg p-6">
        <h2 class="text-xl font-semibold text-gray-900 mb-4">Endpoints da API</h2>
        <div class="border border-gray-200 rounded-lg overflow-hidden">
          <div class="overflow-x-auto overflow-y-auto max-h-[600px]">
            <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Método
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Endpoint
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Descrição
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  URL Completa
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="(endpoint, index) in apiEndpoints" :key="index" class="hover:bg-gray-50">
                <td class="px-4 py-3 whitespace-nowrap">
                  <span
                    :class="[
                      'px-2 py-1 text-xs font-semibold rounded',
                      getMethodColor(endpoint.method),
                    ]"
                  >
                    {{ endpoint.method }}
                  </span>
                </td>
                <td class="px-4 py-3">
                  <code class="text-sm font-mono text-gray-900">{{ endpoint.path }}</code>
                </td>
                <td class="px-4 py-3 text-sm text-gray-600">
                  {{ endpoint.description }}
                </td>
                <td class="px-4 py-3">
                  <div class="flex items-center gap-2">
                    <code class="text-xs font-mono text-gray-600 flex-1">
                      {{ apiBaseUrl }}{{ endpoint.path }}
                    </code>
                    <button
                      @click="copyToClipboard(`${apiBaseUrl}${endpoint.path}`)"
                      class="text-blue-600 hover:text-blue-800 text-xs"
                      title="Copiar URL"
                    >
                      📋
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
          </div>
        </div>
      </div>

      <!-- Embed URLs Section -->
      <div class="bg-white border border-gray-200 rounded-lg p-6">
        <h2 class="text-xl font-semibold text-gray-900 mb-4">Gerar URL para Embed em iframe</h2>
        <div class="space-y-4">
          <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <h3 class="font-semibold text-blue-900 mb-2">📋 Procedimento:</h3>
            <ol class="list-decimal list-inside space-y-2 text-blue-800 text-sm">
              <li>Faça uma requisição POST para criar um embed token</li>
              <li>Use o <code class="bg-blue-100 px-1 rounded">embed_url</code> retornado na resposta</li>
              <li>Use essa URL no atributo <code class="bg-blue-100 px-1 rounded">src</code> do seu iframe</li>
            </ol>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Endpoint para criar embed token
            </label>
            <div class="flex gap-2 mb-2">
              <code class="flex-1 px-4 py-2 border border-gray-300 rounded-lg bg-gray-50 font-mono text-sm">
                POST {{ apiBaseUrl }}/accounts/:account_id/embed_tokens
              </code>
              <button
                @click="copyToClipboard(`${apiBaseUrl}/accounts/:account_id/embed_tokens`)"
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
              >
                Copiar
              </button>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Parâmetros (JSON Body)
            </label>
            <pre class="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto text-sm"><code>{
  "user_id": 123,           // ID do usuário que será autenticado
  "inbox_id": 456,          // (Opcional) ID da inbox específica
  "note": "Embed para cliente X"  // (Opcional) Nota descritiva
}</code></pre>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Resposta da API
            </label>
            <pre class="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto text-sm"><code>{
  "embed_token": {
    "id": 1,
    "jti": "uuid-do-token",
    "user_id": 123,
    "account_id": 1,
    "inbox_id": 456,
    "created_at": "2024-01-01T00:00:00Z",
    "note": "Embed para cliente X"
  },
  "embed_url": "https://chat.synkicrm.com.br/embed/auth?token=JWT_TOKEN_AQUI"
}</code></pre>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Exemplo de uso em HTML (iframe)
            </label>
            <pre class="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto text-sm"><code>&lt;iframe
  src="https://chat.synkicrm.com.br/embed/auth?token=JWT_TOKEN_AQUI"
  width="100%"
  height="600"
  frameborder="0"
  allow="camera; microphone; fullscreen"
&gt;&lt;/iframe&gt;</code></pre>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Exemplo de requisição (cURL)
            </label>
            <pre class="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto text-sm"><code>curl -X POST "{{ apiBaseUrl }}/accounts/1/embed_tokens" \
  -H "api_access_token: {{ accessToken || 'SEU_TOKEN_AQUI' }}" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 123,
    "inbox_id": 456,
    "note": "Embed para cliente X"
  }'</code></pre>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Exemplo de requisição (JavaScript)
            </label>
            <pre class="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto text-sm"><code>const response = await fetch('{{ apiBaseUrl }}/accounts/1/embed_tokens', {
  method: 'POST',
  headers: {
    'api_access_token': '{{ accessToken || 'SEU_TOKEN_AQUI' }}',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    user_id: 123,
    inbox_id: 456,
    note: 'Embed para cliente X'
  })
});

const data = await response.json();
const embedUrl = data.embed_url;
// Use embedUrl no src do iframe</code></pre>
          </div>

          <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
            <h3 class="font-semibold text-yellow-900 mb-2">⚠️ Importante:</h3>
            <ul class="list-disc list-inside space-y-1 text-yellow-800 text-sm">
              <li>Apenas <strong>ADMIN</strong> pode criar embed tokens</li>
              <li>O token não expira automaticamente (apenas por revogação manual)</li>
              <li>Você pode revogar um token usando: <code class="bg-yellow-100 px-1 rounded">POST /api/v1/accounts/:account_id/embed_tokens/:id/revoke</code></li>
              <li>Listar todos os tokens: <code class="bg-yellow-100 px-1 rounded">GET /api/v1/accounts/:account_id/embed_tokens</code></li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Example Request Section -->
      <div class="bg-white border border-gray-200 rounded-lg p-6">
        <h2 class="text-xl font-semibold text-gray-900 mb-4">Exemplo de Requisição</h2>
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              cURL
            </label>
            <pre class="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto text-sm"><code>curl -X GET "{{ apiBaseUrl }}/accounts/:account_id/conversations" \
  -H "api_access_token: {{ accessToken || 'SEU_TOKEN_AQUI' }}" \
  -H "Content-Type: application/json"</code></pre>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              JavaScript (fetch)
            </label>
            <pre class="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto text-sm"><code>fetch('{{ apiBaseUrl }}/accounts/:account_id/conversations', {
  method: 'GET',
  headers: {
    'api_access_token': '{{ accessToken || 'SEU_TOKEN_AQUI' }}',
    'Content-Type': 'application/json'
  }
})
.then(response => response.json())
.then(data => console.log(data));</code></pre>
          </div>
        </div>
      </div>
    </div>
    </div>
  </div>
</template>

