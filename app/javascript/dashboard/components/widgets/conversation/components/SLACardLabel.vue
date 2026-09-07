<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useSlaStatus } from 'dashboard/composables/useSlaStatus';
import SLAPopoverCard from './SLAPopoverCard.vue';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
  showExtendedInfo: {
    type: Boolean,
    default: false,
  },
  parentWidth: {
    type: Number,
    default: 1000,
  },
});

const { t } = useI18n();

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
const slaTextStyles = computed(() =>
  isSlaMissed.value ? 'text-n-ruby-11' : 'text-n-amber-11'
);

const slaStatusText = computed(() => {
  const upperCaseType = slaStatus.value?.type?.toUpperCase(); // FRT, NRT, or RT
  const status = isSlaMissed.value
    ? t('CONVERSATION.HEADER.SLA_STATUS.MISSED')
    : t('CONVERSATION.HEADER.SLA_STATUS.DUE');

  return {
    FRT: t('CONVERSATION.HEADER.SLA_STATUS.FRT', { status }),
    NRT: t('CONVERSATION.HEADER.SLA_STATUS.NRT', { status }),
    RT: t('CONVERSATION.HEADER.SLA_STATUS.RT', { status }),
  }[upperCaseType];
});
const showFullStatusText = computed(
  () => props.showExtendedInfo && props.parentWidth > 650
);
const slaValueText = computed(
  () =>
    slaStatus.value?.threshold ||
    (showFullStatusText.value ? '' : slaStatusText.value)
);

const showSlaPopoverCard = computed(
  () => props.showExtendedInfo && slaEvents.value?.length > 0
);

const groupClass = computed(() => {
  return props.showExtendedInfo
    ? 'h-[26px] rounded-lg bg-n-alpha-1'
    : 'rounded h-5  border border-n-strong';
});

const slaPopoverClass = computed(() => {
  return props.showExtendedInfo ? 'pe-1.5 border-e border-n-strong' : '';
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="hasSlaThreshold"
    class="relative flex items-center cursor-pointer min-w-fit group"
    :class="groupClass"
  >
    <div
      class="flex items-center w-full truncate px-1.5"
      :class="showExtendedInfo ? '' : 'gap-1'"
    >
      <div class="flex items-center gap-1" :class="slaPopoverClass">
        <fluent-icon
          size="12"
          :icon="slaStatus.icon"
          type="outline"
          :icon-lib="isSlaMissed ? 'lucide' : 'fluent'"
          class="flex-shrink-0"
          :class="slaTextStyles"
        />
        <span
          v-if="showFullStatusText"
          class="text-xs font-medium"
          :class="slaTextStyles"
        >
          {{ slaStatusText }}
        </span>
      </div>
      <span
        v-if="slaValueText"
        class="text-xs font-medium"
        :class="[slaTextStyles, showExtendedInfo && 'ps-1.5']"
      >
        {{ slaValueText }}
      </span>
    </div>
    <SLAPopoverCard
      v-if="showSlaPopoverCard"
      :sla-missed-events="slaEvents"
      class="start-0 xl:start-auto xl:end-0 top-7 hidden group-hover:flex"
    />
  </div>
</template>
