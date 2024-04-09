<script setup>
import { ref } from 'vue';
import SLAEventItem from './SLAEventItem.vue';
import wootConstants from 'dashboard/constants/globals';

const { SLA_MISS_TYPES } = wootConstants;

const props = defineProps({
  slaMissedEvents: {
    type: Array,
    required: true,
  },
});

const nrtMisses = props.slaMissedEvents.filter(
  slaEvent => slaEvent.event_type === SLA_MISS_TYPES.NRT
);
const frtMiss = props.slaMissedEvents.filter(
  slaEvent => slaEvent.event_type === SLA_MISS_TYPES.FRT
);
const rtMiss = props.slaMissedEvents.filter(
  slaEvent => slaEvent.event_type === SLA_MISS_TYPES.RT
);
const showAllNRT = ref(false);
const toggleShowAllNRT = () => {
  showAllNRT.value = !showAllNRT.value;
};
</script>
<template>
  <div
    class="absolute flex flex-col items-start bg-[#fdfdfd] dark:bg-slate-800 z-50 p-4 border border-solid border-slate-75 dark:border-slate-700 w-[384px] rounded-xl gap-4 max-h-96 overflow-auto"
  >
    <span class="text-sm font-medium text-slate-900 dark:text-slate-25">
      {{ $t('SLA.EVENTS.TITLE') }}
    </span>
    <SLA-event-item
      v-if="frtMiss.length"
      :label="$t('SLA.EVENTS.FRT')"
      :items="frtMiss"
    />
    <SLA-event-item
      v-if="nrtMisses.length"
      :label="$t('SLA.EVENTS.NRT')"
      :items="showAllNRT ? nrtMisses : nrtMisses.slice(0, 6)"
    >
      <template #showMore>
        <div v-if="nrtMisses.length > 6" class="flex flex-col items-end w-full">
          <woot-button
            size="small"
            :icon="!showAllNRT ? 'plus-sign' : ''"
            variant="link"
            color-scheme="secondary"
            class="hover:!no-underline !gap-1 hover:!bg-transparent dark:hover:!bg-transparent"
            @click="toggleShowAllNRT"
          >
            {{
              showAllNRT
                ? $t('SLA.EVENTS.HIDE', { count: nrtMisses.length })
                : $t('SLA.EVENTS.SHOW_MORE', { count: nrtMisses.length })
            }}
          </woot-button>
        </div>
      </template>
    </SLA-event-item>
    <SLA-event-item
      v-if="rtMiss.length > 6"
      :label="$t('SLA.EVENTS.RT')"
      :items="rtMiss"
    />
  </div>
</template>
