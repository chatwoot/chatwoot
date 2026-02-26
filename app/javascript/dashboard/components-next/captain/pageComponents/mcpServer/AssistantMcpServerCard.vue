<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Policy from 'dashboard/components/policy.vue';

const props = defineProps({
  record: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['detach']);

const { t } = useI18n();

const server = computed(() => props.record.mcp_server || {});

const statusLabel = computed(() => {
  const status = server.value.status || 'disconnected';
  if (status === 'connected') {
    return t('CAPTAIN_SETTINGS.MCP_SERVERS.STATUS.CONNECTED');
  }
  if (status === 'connecting') {
    return t('CAPTAIN_SETTINGS.MCP_SERVERS.STATUS.CONNECTING');
  }
  if (status === 'error') {
    return t('CAPTAIN_SETTINGS.MCP_SERVERS.STATUS.ERROR');
  }
  return t('CAPTAIN_SETTINGS.MCP_SERVERS.STATUS.DISCONNECTED');
});

const statusClass = computed(() => {
  const status = server.value.status;
  if (status === 'connected') return 'text-n-teal-11 bg-n-teal-3';
  if (status === 'connecting') return 'text-n-amber-11 bg-n-amber-3';
  if (status === 'error') return 'text-n-ruby-11 bg-n-ruby-3';
  return 'text-n-slate-11 bg-n-slate-3';
});
</script>

<template>
  <CardLayout>
    <div class="flex items-start justify-between gap-4">
      <div class="flex flex-col gap-1 min-w-0">
        <div class="flex items-center gap-2">
          <span class="text-base font-medium text-n-slate-12 truncate">
            {{ server.name }}
          </span>
          <span
            class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
            :class="statusClass"
          >
            {{ statusLabel }}
          </span>
        </div>
        <p v-if="server.description" class="text-sm text-n-slate-11">
          {{ server.description }}
        </p>
        <span class="text-xs text-n-slate-10 truncate">
          {{ server.url }}
        </span>
      </div>

      <Policy :permissions="['administrator']">
        <Button
          color="slate"
          size="xs"
          :label="t('CAPTAIN.MCP_SERVERS.DETACH')"
          @click="emit('detach', record)"
        />
      </Policy>
    </div>
  </CardLayout>
</template>
