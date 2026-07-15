<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  evaluateSLAStatus,
  shouldRefreshSLAStatus,
} from 'dashboard/helper/slaHelper';

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
const { t } = useI18n();
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
const hasSlaThreshold = computed(() => slaStatus.value?.type);
const isSlaMissed = computed(() => slaStatus.value?.isSlaMissed);
const slaLabel = computed(() => {
  if (slaStatus.value?.threshold) return slaStatus.value.threshold;

  const status = t('CONVERSATION.HEADER.SLA_STATUS.MISSED');
  return {
    FRT: t('CONVERSATION.HEADER.SLA_STATUS.FRT', { status }),
    NRT: t('CONVERSATION.HEADER.SLA_STATUS.NRT', { status }),
    RT: t('CONVERSATION.HEADER.SLA_STATUS.RT', { status }),
  }[slaStatus.value.type];
});

const updateSlaStatus = () => {
  slaStatus.value = evaluateSLAStatus({
    appliedSla: appliedSLA.value || {},
    chat: props.chat,
    slaEvents: slaEvents.value || [],
  });
};

const clearTimer = () => {
  if (timer.value) {
    clearTimeout(timer.value);
    timer.value = null;
  }
};

const createTimer = () => {
  clearTimer();
  if (
    !shouldRefreshSLAStatus({
      appliedSla: appliedSLA.value,
      chat: props.chat,
    })
  ) {
    return;
  }

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
  clearTimer();
});

watch(
  () => props.chat,
  () => {
    updateSlaStatus();
    createTimer();
  }
);

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
    <Label :label="slaLabel" :color="isSlaMissed ? 'ruby' : 'amber'" compact>
      <template #icon>
        <Icon icon="i-lucide-flame" class="flex-shrink-0 size-3.5" />
      </template>
    </Label>
  </div>
  <template v-else />
</template>
