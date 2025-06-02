<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { evaluateSLAStatus } from '@chatwoot/utils';
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

const REFRESH_INTERVAL = 60000;
const { t } = useI18n();

const timer = ref(null);
const slaStatus = ref({
  threshold: null,
  isSlaMissed: false,
  type: null,
  icon: null,
});

const appliedSLA = computed(() => props.chat?.applied_sla);
const slaEvents = computed(() => props.chat?.sla_events);
const hasSlaThreshold = computed(() => slaStatus.value?.threshold);
const isSlaMissed = computed(() => slaStatus.value?.isSlaMissed);
const slaTextStyles = computed(() =>
  isSlaMissed.value ? 'text-n-ruby-11' : 'text-n-amber-11'
);

const slaStatusText = computed(() => {
  const upperCaseType = slaStatus.value?.type?.toUpperCase(); // FRT, NRT, or RT
  const statusKey = isSlaMissed.value ? 'MISSED' : 'DUE';

  return t(`CONVERSATION.HEADER.SLA_STATUS.${upperCaseType}`, {
    status: t(`CONVERSATION.HEADER.SLA_STATUS.${statusKey}`),
  });
});

const showSlaPopoverCard = computed(
  () => props.showExtendedInfo && slaEvents.value?.length > 0
);

const groupClass = computed(() => {
  return props.showExtendedInfo
    ? 'h-[26px] rounded-lg bg-n-alpha-1'
    : 'rounded h-5  border border-n-strong';
});

const updateSlaStatus = () => {
  slaStatus.value = evaluateSLAStatus({
    appliedSla: appliedSLA.value,
    chat: props.chat,
  });
};

const createTimer = () => {
  timer.value = setTimeout(() => {
    updateSlaStatus();
    createTimer();
  }, REFRESH_INTERVAL);
};

watch(
  () => props.chat,
  () => {
    updateSlaStatus();
  }
);

const slaPopoverClass = computed(() => {
  return props.showExtendedInfo
    ? 'ltr:pr-1.5 rtl:pl-1.5 ltr:border-r rtl:border-l border-n-strong'
    : '';
});

onMounted(() => {
  updateSlaStatus();
  createTimer();
});

onUnmounted(() => {
  if (timer.value) {
    clearTimeout(timer.value);
  }
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
          v-if="showExtendedInfo && parentWidth > 650"
          class="text-xs font-medium"
          :class="slaTextStyles"
        >
          {{ slaStatusText }}
        </span>
      </div>
      <span
        class="text-xs font-medium"
        :class="[slaTextStyles, showExtendedInfo && 'ltr:pl-1.5 rtl:pr-1.5']"
      >
        {{ slaStatus.threshold }}
      </span>
    </div>
    <SLAPopoverCard
      v-if="showSlaPopoverCard"
      :sla-missed-events="slaEvents"
      class="rtl:left-0 ltr:right-0 top-7 hidden group-hover:flex"
    />
  </div>
</template>
