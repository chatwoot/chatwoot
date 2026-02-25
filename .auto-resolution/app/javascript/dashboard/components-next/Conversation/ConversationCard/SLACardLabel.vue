<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { evaluateSLAStatus } from '@chatwoot/utils';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const REFRESH_INTERVAL = 60000;

const timer = ref(null);
const slaStatus = ref({
  threshold: null,
  isSlaMissed: false,
  type: null,
  icon: null,
});

// TODO: Remove this once we update the helper from utils
// https://github.com/chatwoot/utils/blob/main/src/sla.ts#L73
const convertObjectCamelCaseToSnakeCase = object => {
  return Object.keys(object).reduce((acc, key) => {
    acc[key.replace(/([A-Z])/g, '_$1').toLowerCase()] = object[key];
    return acc;
  }, {});
};

const appliedSLA = computed(() => props.conversation?.appliedSla);
const isSlaMissed = computed(() => slaStatus.value?.isSlaMissed);

const hasSlaThreshold = computed(() => {
  return slaStatus.value?.threshold && appliedSLA.value?.id;
});

const slaStatusText = computed(() => {
  return slaStatus.value?.type?.toUpperCase();
});

const updateSlaStatus = () => {
  slaStatus.value = evaluateSLAStatus({
    appliedSla: convertObjectCamelCaseToSnakeCase(appliedSLA.value || {}),
    chat: props.conversation,
  });
};

const createTimer = () => {
  timer.value = setTimeout(() => {
    updateSlaStatus();
    createTimer();
  }, REFRESH_INTERVAL);
};

onMounted(() => {
  updateSlaStatus();
  createTimer();
});

onUnmounted(() => {
  if (timer.value) {
    clearTimeout(timer.value);
  }
});

watch(() => props.conversation, updateSlaStatus);

// This expose is to provide context to the parent component, so that it can decided weather
// a new row has to be added to the conversation card or not
// SLACardLabel > CardMessagePreviewWithMeta > ConversationCard
//
// We need to do this becuase each SLA card has it's own SLA timer
// and it's just convenient to have this logic in the SLACardLabel component
// However this is a bit hacky, and we should change this in the future
//
// TODO: A better implementation would be to have the timer as a shared composable, just like the provider pattern
// we use across the next components. Have the calculation be done on the top ConversationCard component
// and then the value be injected to the SLACardLabel component
defineExpose({
  hasSlaThreshold,
});
</script>

<template>
  <div class="flex items-center min-w-fit gap-0.5 h-6">
    <div class="flex items-center justify-center size-4">
      <svg
        width="10"
        height="13"
        viewBox="0 0 10 13"
        fill="none"
        :class="isSlaMissed ? 'fill-n-ruby-10' : 'fill-n-slate-9'"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M4.55091 12.412C7.44524 12.412 9.37939 10.4571 9.37939 7.51446C9.37939 2.63072 5.21405 0.599854 2.36808 0.599854C1.81546 0.599854 1.45626 0.800176 1.45626 1.1801C1.45626 1.32516 1.52534 1.48404 1.64277 1.62219C2.27828 2.38204 2.92069 3.27314 2.93451 4.36455C2.93451 4.5925 2.9276 4.78592 2.76181 5.08295L3.05194 5.03459C2.81017 4.21949 2.18848 3.63234 1.5806 3.63234C1.32501 3.63234 1.15232 3.81884 1.15232 4.09514C1.15232 4.23331 1.19377 4.56488 1.19377 4.79974C1.19377 5.95332 0.26123 6.69935 0.26123 8.67495C0.26123 10.92 1.97434 12.412 4.55091 12.412ZM4.68906 10.8923C3.65982 10.8923 2.96905 10.2637 2.96905 9.33119C2.96905 8.3572 3.66672 8.01181 3.75652 7.38322C3.76344 7.32796 3.79107 7.31414 3.83251 7.34867C4.08809 7.57663 4.24697 7.85293 4.37822 8.1776C4.67525 7.77696 4.81341 6.9204 4.73051 6.0293C4.72361 5.97404 4.75814 5.94642 4.80649 5.96713C6.02916 6.53357 6.65085 7.74241 6.65085 8.82693C6.65085 9.92527 6.00844 10.8923 4.68906 10.8923Z"
        />
      </svg>
    </div>

    <span
      class="text-sm truncate"
      :class="isSlaMissed ? 'text-n-ruby-11' : 'text-n-slate-11'"
    >
      {{ `${slaStatusText}: ${slaStatus.threshold}` }}
    </span>
  </div>
</template>
