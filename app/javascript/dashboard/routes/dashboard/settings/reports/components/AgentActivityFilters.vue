<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import DatePicker from 'dashboard/components/ui/DatePicker/DatePicker.vue';
import ReportsFiltersAgents from './Filters/Agents.vue';
import ReportsFiltersInboxes from './Filters/Inboxes.vue';
import ReportsFiltersTeams from './Filters/Teams.vue';
import ReportsFiltersTimeRange from './Filters/TimeRange.vue';

const props = defineProps({
  initialSince: {
    type: Number,
    default: null,
  },
  initialUntil: {
    type: Number,
    default: null,
  },
  initialHideInactive: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['filtersChange']);

const { t } = useI18n();
const since = ref(null);
const until = ref(null);

const timeFrom = ref('00:00');
const timeTo = ref('23:59');

const hideInactive = ref(false);
const selectedAgents = ref([]);
const selectedInbox = ref([]);
const selectedTeam = ref([]);

watch(
  () => props.initialSince,
  v => {
    since.value = v;
  },
  { immediate: true }
);

watch(
  () => props.initialUntil,
  v => {
    until.value = v;
  },
  { immediate: true }
);

watch(
  () => props.initialHideInactive,
  v => {
    hideInactive.value = v;
  },
  { immediate: true }
);

const applyTime = (timestamp, time) => {
  if (timestamp == null) return null;

  const d = new Date(timestamp);
  const [h, m] = time.split(':').map(Number);
  d.setHours(h, m, 0, 0);
  return d.getTime();
};

const emitChange = () => {
  emit('filtersChange', {
    since: applyTime(since.value, timeFrom.value),
    until: applyTime(until.value, timeTo.value),
    hideInactive: hideInactive.value,
    userIds: selectedAgents.value.map(agent => agent.id),
    teamIds: selectedTeam.value.map(team => team.id),
    inboxIds: selectedInbox.value.map(inbox => inbox.id),
  });
};

const onDateChange = payload => {
  const [start, end] = Array.isArray(payload) ? payload : [payload, payload];

  since.value = start instanceof Date ? start.getTime() : null;
  until.value =
    (end ?? start) instanceof Date ? (end ?? start).getTime() : null;

  emitChange();
};

const onTimeRangeChanged = ({ since: s, until: u }) => {
  timeFrom.value = s;
  timeTo.value = u;
  emitChange();
};
</script>

<template>
  <div
    class="p-4 rounded-xl bg-n-solid-2 outline outline-1 outline-n-container flex flex-col gap-3"
  >
    <div class="flex items-center gap-3 flex-wrap">
      <DatePicker @date-range-changed="onDateChange" />

      <ReportsFiltersTimeRange @time-range-changed="onTimeRangeChanged" />

      <label class="flex items-center gap-2 text-sm ml-auto">
        <input v-model="hideInactive" type="checkbox" @change="emitChange" />
        {{ t('AGENT_ACTIVITY_REPORTS.HIDE_INACTIVE') }}
      </label>
    </div>

    <div class="flex items-center gap-3 flex-wrap">
      <ReportsFiltersAgents
        @agents-filter-selection="
          selectedAgents = [...$event];
          emitChange();
        "
      />

      <ReportsFiltersInboxes
        @inbox-filter-selection="
          selectedInbox = [...$event];
          emitChange();
        "
      />

      <ReportsFiltersTeams
        @team-filter-selection="
          selectedTeam = [...$event];
          emitChange();
        "
      />
    </div>
  </div>
</template>
