<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  agentName: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();

const tooltipText = computed(() =>
  t('CONVERSATION.ALOO.HEADER_TOOLTIP', { agentName: props.agentName })
);
</script>

<template>
  <span
    v-tooltip="tooltipText"
    class="inline-flex items-center justify-center gap-1 px-1.5 py-0.5 text-xs font-medium rounded-full bg-n-violet-3 text-n-violet-11 flex-shrink-0"
  >
    <span class="i-lucide-bot size-3" />
    {{ $t('CONVERSATION.ALOO.HEADER_BADGE') }}
  </span>
</template>
