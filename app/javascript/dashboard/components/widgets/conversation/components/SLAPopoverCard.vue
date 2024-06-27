<script setup>
import { ref, computed } from 'vue';

import wootConstants from 'dashboard/constants/globals';
import SLAEventItem from './SLAEventItem.vue';

const { SLA_MISS_TYPES } = wootConstants;

const props = defineProps({
  slaMissedEvents: {
    type: Array,
    required: true,
  },
});

const shouldShowAllNrts = ref(false);

const frtMisses = computed(() =>
  props.slaMissedEvents.filter(
    slaEvent => slaEvent.event_type === SLA_MISS_TYPES.FRT
  )
);
const nrtMisses = computed(() => {
  const missedEvents = props.slaMissedEvents.filter(
    slaEvent => slaEvent.event_type === SLA_MISS_TYPES.NRT
  );
  return shouldShowAllNrts.value ? missedEvents : missedEvents.slice(0, 6);
});
const rtMisses = computed(() =>
  props.slaMissedEvents.filter(
    slaEvent => slaEvent.event_type === SLA_MISS_TYPES.RT
  )
);

const shouldShowMoreNRTButton = computed(() => nrtMisses.value.length > 6);
const toggleShowAllNRT = () => {
  shouldShowAllNrts.value = !shouldShowAllNrts.value;
};
</script>
<template>
  <div
    class="absolute flex flex-col items-start bg-white dark:bg-slate-800 z-50 p-4 border border-solid border-slate-75 dark:border-slate-700 w-[384px] rounded-xl gap-4 max-h-96 overflow-auto"
  >
    <span class="text-sm font-medium text-slate-900 dark:text-slate-25">
      {{ $t('SLA.EVENTS.TITLE') }}
    </span>
    <SLA-event-item
      v-if="frtMisses.length"
      :label="$t('SLA.EVENTS.FRT')"
      :items="frtMisses"
    />
    <SLA-event-item
      v-if="nrtMisses.length"
      :label="$t('SLA.EVENTS.NRT')"
      :items="nrtMisses"
    >
      <template #showMore>
        <div
          v-if="shouldShowMoreNRTButton"
          class="flex flex-col items-end w-full"
        >
          <woot-button
            size="small"
            :icon="!shouldShowAllNrts ? 'plus-sign' : ''"
            variant="link"
            color-scheme="secondary"
            class="hover:!no-underline !gap-1 hover:!bg-transparent dark:hover:!bg-transparent"
            @click="toggleShowAllNRT"
          >
            {{
              shouldShowAllNrts
                ? $t('SLA.EVENTS.HIDE', { count: nrtMisses.length })
                : $t('SLA.EVENTS.SHOW_MORE', { count: nrtMisses.length })
            }}
          </woot-button>
        </div>
      </template>
    </SLA-event-item>
    <SLA-event-item
      v-if="rtMisses.length"
      :label="$t('SLA.EVENTS.RT')"
      :items="rtMisses"
    />
  </div>
</template>
