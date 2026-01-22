<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  reason: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();

const tooltipText = computed(() => {
  if (props.reason) {
    return t('CONVERSATION.ALOO.HUMAN_ASSISTANCE_REQUESTED_TOOLTIP', {
      reason: props.reason,
    });
  }
  return t('CONVERSATION.ALOO.HUMAN_ASSISTANCE_REQUESTED_BADGE');
});
</script>

<template>
  <span
    v-tooltip="tooltipText"
    class="inline-flex items-center justify-center gap-1 px-1.5 py-0.5 text-xs font-medium rounded-full bg-n-amber-3 text-n-amber-11 flex-shrink-0"
  >
    <span class="i-lucide-hand size-3" />
    {{ $t('CONVERSATION.ALOO.HUMAN_ASSISTANCE_REQUESTED_BADGE') }}
  </span>
</template>
