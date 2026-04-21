<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { evaluateSLAStatus } from '@chatwoot/utils';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
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

defineOptions({
  inheritAttrs: false,
});

const appliedSLA = computed(() => props.chat?.applied_sla);
const hasSlaThreshold = computed(() => slaStatus.value?.threshold);
const isSlaMissed = computed(() => slaStatus.value?.isSlaMissed);

const updateSlaStatus = () => {
  slaStatus.value = evaluateSLAStatus({
    appliedSla: appliedSLA.value || {},
    chat: props.chat,
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

watch(() => props.chat, updateSlaStatus);

defineExpose({
  hasSlaThreshold,
});
</script>

<template>
  <div
    v-if="hasSlaThreshold"
    v-bind="$attrs"
    class="relative flex items-center cursor-pointer min-w-fit group"
  >
    <Label
      :label="slaStatus.threshold"
      :color="isSlaMissed ? 'ruby' : 'amber'"
      compact
    >
      <template #icon>
        <Icon icon="i-lucide-flame" class="flex-shrink-0 size-3.5" />
      </template>
    </Label>
  </div>
  <template v-else />
</template>
