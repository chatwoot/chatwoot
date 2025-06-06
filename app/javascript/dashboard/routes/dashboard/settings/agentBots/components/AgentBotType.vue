<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

defineProps({
  botType: {
    type: String,
    default: 'webhook',
  },
});

const { t } = useI18n();

const botTypeConfig = computed(() => ({
  csml: {
    label: t('AGENT_BOTS.TYPES.CSML'),
    thumbnail: '/dashboard/images/agent-bots/csml.png',
  },
  webhook: {
    label: t('AGENT_BOTS.TYPES.WEBHOOK'),
    thumbnail: '/dashboard/images/agent-bots/webhook.svg',
  },
}));
</script>

<template>
  <span class="inline-flex items-center gap-1">
    <img
      v-tooltip="botTypeConfig[botType].label"
      class="h-3 w-auto"
      :src="botTypeConfig[botType].thumbnail"
      :alt="botTypeConfig[botType].label"
    />
    <span>{{ botTypeConfig[botType].label }}</span>
  </span>
</template>
