<script setup>
import { ref, computed } from 'vue';

import wootConstants from 'dashboard/constants/globals';
import SLAEventItem from './SLAEventItem.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  slaMissedEvents: {
    type: Array,
    required: true,
  },
});

const { SLA_MISS_TYPES } = wootConstants;

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
    class="absolute flex flex-col items-start border-n-strong bg-n-solid-3 w-96 backdrop-blur-[100px] px-6 py-5 z-50 shadow rounded-xl gap-4 max-h-96 overflow-auto"
  >
    <span class="text-sm font-medium text-n-slate-12">
      {{ $t('SLA.EVENTS.TITLE') }}
    </span>
    <SLAEventItem
      v-if="frtMisses.length"
      :label="$t('SLA.EVENTS.FRT')"
      :items="frtMisses"
    />
    <SLAEventItem
      v-if="nrtMisses.length"
      :label="$t('SLA.EVENTS.NRT')"
      :items="nrtMisses"
    >
      <template #showMore>
        <div
          v-if="shouldShowMoreNRTButton"
          class="flex flex-col items-end w-full"
        >
          <Button
            link
            xs
            slate
            class="hover:!no-underline"
            :icon="!shouldShowAllNrts ? 'i-lucide-plus' : ''"
            :label="
              shouldShowAllNrts
                ? $t('SLA.EVENTS.HIDE', { count: nrtMisses.length })
                : $t('SLA.EVENTS.SHOW_MORE', { count: nrtMisses.length })
            "
            @click="toggleShowAllNRT"
          />
        </div>
      </template>
    </SLAEventItem>
    <SLAEventItem
      v-if="rtMisses.length"
      :label="$t('SLA.EVENTS.RT')"
      :items="rtMisses"
    />
  </div>
</template>
