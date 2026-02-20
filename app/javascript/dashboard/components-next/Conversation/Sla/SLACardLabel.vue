<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { evaluateSLAStatus } from '@chatwoot/utils';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';

import SLAPopoverCard from './SLAPopoverCard.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
  showExtendedInfo: {
    type: Boolean,
    default: false,
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
const slaEvents = computed(() => props.chat?.sla_events);
const hasSlaThreshold = computed(() => slaStatus.value?.threshold);
const isSlaMissed = computed(() => slaStatus.value?.isSlaMissed);

const conversation = computed(() => useCamelCase(props.chat, { deep: true }));

const showSlaPopoverCard = computed(
  () => props.showExtendedInfo && slaEvents.value?.length > 0
);

const updateSlaStatus = () => {
  slaStatus.value = evaluateSLAStatus({
    appliedSla: appliedSLA.value || {},
    chat: conversation.value,
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
    <SLAPopoverCard
      v-if="showSlaPopoverCard"
      :sla-missed-events="slaEvents"
      class="start-0 md:start-auto md:end-0 top-7 hidden group-hover:flex"
    />
  </div>
  <template v-else />
</template>
