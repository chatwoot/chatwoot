<script>
import axios from 'axios';

export default {
  name: 'ConnectionHealthDashboard',
  data() {
    return {
      connections: [],
      loading: false,
    };
  },
  computed: {
    totalConnections() {
      return this.connections.length;
    },
    connectedCount() {
      return this.connections.filter(c => c.status === 'connected').length;
    },
    attentionCount() {
      return this.connections.filter(
        c => c.status === 'error' || c.status === 'rate_limit'
      ).length;
    },
    disconnectedCount() {
      return this.connections.filter(c => c.status === 'disconnected').length;
    },
  },
  mounted() {
    this.fetchData();
  },
  methods: {
    async fetchData() {
      this.loading = true;
      try {
        const response = await axios.get('/super_admin/api/connection_health');
        this.connections = response.data;
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error('Falha ao carregar conexões:', error);
      } finally {
        this.loading = false;
      }
    },
    statusBadgeClass(status) {
      if (status === 'connected')
        return 'bg-green-50 text-green-700 border-green-200';
      if (status === 'error' || status === 'rate_limit')
        return 'bg-yellow-50 text-yellow-700 border-yellow-200';
      return 'bg-red-50 text-red-700 border-red-200';
    },
    statusDotClass(status) {
      if (status === 'connected') return 'bg-green-500';
      if (status === 'error' || status === 'rate_limit') return 'bg-yellow-500';
      return 'bg-red-500';
    },
    statusLabel(status) {
      if (status === 'connected') return 'Conectado';
      if (status === 'error' || status === 'rate_limit') return 'Atenção';
      return 'Desconectado';
    },
  },
};
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
  <div
    class="flex flex-col h-full w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6"
  >
    <div class="flex items-center justify-between mb-10">
      <div>
        <h1 class="text-2xl font-semibold text-slate-900 tracking-tight">
          {{ 'Monitoramento de Conexões' }}
        </h1>
        <p class="text-slate-500 text-sm mt-1">
          {{
            'Verifique a saúde em tempo real das conexões de WhatsApp e API das contas.'
          }}
        </p>
      </div>
      <button
        class="bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 hover:text-slate-900 font-medium py-2 px-5 rounded-md shadow-sm flex items-center gap-2 transition-all focus:outline-none focus:ring-2 focus:ring-slate-200 disabled:opacity-50"
        :disabled="loading"
        @click="fetchData"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-4 w-4 text-slate-500"
          :class="{ 'animate-spin': loading }"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
          />
        </svg>
        <span>{{ 'Atualizar' }}</span>
      </button>
    </div>

    <!-- Summary Cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
      <div
        class="bg-white rounded-xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.08)] border border-slate-100 p-6 transition-all hover:shadow-md flex flex-col justify-center"
      >
        <h3
          class="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-2"
        >
          {{ 'Total de Conexões' }}
        </h3>
        <p class="text-4xl font-bold text-slate-800">{{ totalConnections }}</p>
      </div>

      <div
        class="bg-white rounded-xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.08)] border border-slate-100 p-6 transition-all hover:shadow-md flex flex-col justify-center relative overflow-hidden"
      >
        <div class="absolute top-0 right-0 w-2 h-full bg-green-500" />
        <h3
          class="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-2 flex items-center gap-2"
        >
          {{ 'Conectadas' }}
        </h3>
        <p class="text-4xl font-bold text-slate-800">{{ connectedCount }}</p>
      </div>

      <div
        class="bg-white rounded-xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.08)] border border-slate-100 p-6 transition-all hover:shadow-md flex flex-col justify-center relative overflow-hidden"
      >
        <div class="absolute top-0 right-0 w-2 h-full bg-yellow-400" />
        <h3
          class="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-2 flex items-center gap-2"
        >
          {{ 'Atenção' }}
        </h3>
        <p class="text-4xl font-bold text-slate-800">{{ attentionCount }}</p>
      </div>

      <div
        class="bg-white rounded-xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.08)] border border-slate-100 p-6 transition-all hover:shadow-md flex flex-col justify-center relative overflow-hidden"
      >
        <div class="absolute top-0 right-0 w-2 h-full bg-red-500" />
        <h3
          class="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-2 flex items-center gap-2"
        >
          {{ 'Desconectadas' }}
        </h3>
        <p class="text-4xl font-bold text-slate-800">{{ disconnectedCount }}</p>
      </div>
    </div>

    <!-- Data Table -->
    <div
      class="bg-white rounded-xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.08)] border border-slate-100 overflow-hidden flex-grow flex flex-col"
    >
      <div class="px-6 py-4 border-b border-slate-100 bg-white">
        <h2 class="text-lg font-semibold text-slate-800">
          {{ 'Listagem de Caixas de Entrada' }}
        </h2>
      </div>
      <div class="overflow-x-auto flex-grow">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr
              class="bg-slate-50 text-xs uppercase tracking-wider font-semibold text-slate-500 border-b border-slate-100"
            >
              <th class="px-6 py-4 pl-6">{{ 'Conta' }}</th>
              <th class="px-6 py-4">{{ 'Caixa de Entrada' }}</th>
              <th class="px-6 py-4">{{ 'Canal' }}</th>
              <th class="px-6 py-4">{{ 'Telefone' }}</th>
              <th class="px-6 py-4">{{ 'Status' }}</th>
              <th class="px-6 py-4">{{ 'Último Erro' }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-50 text-sm">
            <tr v-if="loading && connections.length === 0">
              <td colspan="6" class="px-6 py-12 text-center text-slate-500">
                <div class="flex justify-center items-center gap-2">
                  <svg
                    class="animate-spin h-5 w-5 text-slate-400"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    />
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    />
                  </svg>
                  {{ 'Buscando conexões...' }}
                </div>
              </td>
            </tr>
            <tr v-else-if="connections.length === 0">
              <td
                colspan="6"
                class="px-6 py-12 text-center text-slate-500 text-sm"
              >
                {{ 'Nenhuma conexão webhooks ou whatsapp encontrada.' }}
              </td>
            </tr>
            <template v-else>
              <tr
                v-for="(conn, idx) in connections"
                :key="idx"
                class="hover:bg-slate-50/50 transition-colors"
              >
                <td class="px-6 py-4 font-medium text-slate-800 pl-6">
                  {{ conn.account_name }}
                </td>
                <td class="px-6 py-4 text-slate-600">{{ conn.inbox_name }}</td>
                <td class="px-6 py-4 text-slate-600">
                  <span
                    class="bg-indigo-50 text-indigo-700 border border-indigo-100 px-2.5 py-1 rounded-md text-xs font-semibold"
                  >
                    {{ conn.channel_type }}
                  </span>
                </td>
                <td class="px-6 py-4 text-slate-500 font-mono text-xs">
                  {{ conn.phone_number }}
                </td>
                <td class="px-6 py-4">
                  <span
                    class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border"
                    :class="statusBadgeClass(conn.status)"
                  >
                    <span
                      class="w-1.5 h-1.5 rounded-full"
                      :class="statusDotClass(conn.status)"
                    />
                    {{ statusLabel(conn.status) }}
                  </span>
                </td>
                <td
                  class="px-6 py-4 text-slate-500 max-w-[200px] truncate"
                  :title="conn.last_error"
                >
                  {{ conn.last_error || 'Nenhum erro reportado' }}
                </td>
              </tr>
            </template>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
