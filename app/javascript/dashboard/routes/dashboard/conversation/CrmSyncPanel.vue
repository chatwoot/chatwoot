<script setup>
import { computed, onMounted } from 'vue';
import { useStoreGetters, useStore } from 'dashboard/composables/store';

const store = useStore();
const getters = useStoreGetters();

const props = defineProps({
  conversationId: { type: [Number, String], required: true },
});

const executions = computed(() =>
  getters['crmFlows/getConversationExecutions'].value(props.conversationId)
);

onMounted(() => {
  store.dispatch('crmFlows/getConversationExecutions', props.conversationId);
});

function statusBg(status) {
  switch (status) {
    case 'success': return 'bg-n-teal-5 text-n-teal-12';
    case 'failed':  return 'bg-n-solid-3 text-n-ruby-12';
    case 'partial': return 'bg-n-solid-3 text-n-amber-12';
    default:        return 'bg-n-solid-3 text-n-slate-12';
  }
}

function formatTime(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

function resultIcon(status) {
  switch (status) {
    case 'success': return 'i-lucide-check-circle';
    case 'skipped': return 'i-lucide-minus-circle';
    case 'failed':  return 'i-lucide-x-circle';
    default:        return 'i-lucide-circle';
  }
}

function resultColor(status) {
  switch (status) {
    case 'success': return 'text-n-green-11';
    case 'skipped': return 'text-n-slate-11';
    case 'failed':  return 'text-n-ruby-11';
    default:        return 'text-n-slate-11';
  }
}
</script>

<template>
  <div>
    <!-- Estado vacío -->
    <div v-if="!executions.length" class="flex justify-center p-4">
      <p class="text-sm text-n-slate-11">
        {{ $t('CRM_FLOWS.CRM_SYNC.EMPTY') }}
      </p>
    </div>

    <!-- Lista de ejecuciones -->
    <div v-else class="max-h-[300px] overflow-y-auto">
      <div
        v-for="exec in executions"
        :key="exec.id"
        class="px-4 py-3 border-b border-n-weak last:border-b-0"
      >
        <!-- Header: nombre del flow + badge de status -->
        <div class="flex items-center justify-between gap-2 mb-1">
          <span class="text-sm font-medium text-n-slate-12 truncate">
            {{ exec.flow_name }}
          </span>
          <span
            :class="statusBg(exec.status)"
            class="text-xs px-2 py-0.5 rounded flex-shrink-0 capitalize"
          >
            {{ $t(`CRM_FLOWS.CRM_SYNC.STATUS.${exec.status.toUpperCase()}`) }}
          </span>
        </div>

        <!-- Timestamp -->
        <p class="text-xs text-n-slate-11 mb-2">
          {{ $t('CRM_FLOWS.CRM_SYNC.EXECUTED_AT', { time: formatTime(exec.created_at) }) }}
        </p>

        <!-- Resultados por acción -->
        <div class="flex flex-col gap-1.5">
          <div
            v-for="(result, idx) in (exec.results || [])"
            :key="idx"
            class="flex items-center gap-2"
          >
            <i
              :class="[resultIcon(result.status), resultColor(result.status)]"
              class="w-3.5 h-3.5 flex-shrink-0"
            />
            <span class="text-xs text-n-slate-12 truncate">
              {{ result.action?.replace(/_/g, ' ') }}
              <span v-if="result.crm" class="text-n-slate-11">en {{ result.crm }}</span>
            </span>
            <span
              v-if="result.status === 'failed' && result.error"
              class="text-xs text-n-ruby-11 ml-auto truncate"
            >
              {{ result.error }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
