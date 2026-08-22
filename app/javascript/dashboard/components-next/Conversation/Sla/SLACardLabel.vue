<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useSlaStatus } from 'dashboard/composables/useSlaStatus';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

defineOptions({
  inheritAttrs: false,
});

const chat = computed(() => props.chat);
const appliedSLA = computed(() => chat.value?.applied_sla);
const slaEvents = computed(() => chat.value?.sla_events);
const { slaStatus } = useSlaStatus({
  appliedSla: appliedSLA,
  chat,
  slaEvents,
});
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
