<script setup>
import { ref } from 'vue';
import ReportFilterSelector from 'dashboard/routes/dashboard/settings/reports/components/FilterSelector.vue';
import ReportsFiltersAgents from './Filters/Agents.vue';
import ReportsFiltersInboxes from './Filters/Inboxes.vue';
import ReportsFiltersTeams from './Filters/Teams.vue';

const emit = defineEmits(['filtersChange']);

const selectedAgents = ref([]);
const selectedInbox = ref([]);
const selectedTeam = ref([]);

const filterData = ref({
  from: 0,
  to: 0,
  businessHours: false,
  timeRange: {
    since: '00:00',
    until: '23:59',
  },
});

const emitChange = () => {
  emit('filtersChange', {
    since: filterData.value.from,
    until: filterData.value.to,
    userIds: selectedAgents.value.map(agent => agent.id),
    teamIds: selectedTeam.value.map(team => team.id),
    inboxIds: selectedInbox.value.map(inbox => inbox.id),
    businessHours: filterData.value.businessHours,
    timeRange: filterData.value.timeRange,
  });
};

const onFilterChange = updatedFilter => {
  filterData.value = {
    from: updatedFilter.from,
    to: updatedFilter.to,
    businessHours: updatedFilter.businessHours,
    timeRange: updatedFilter.timeRange,
  };
  emitChange();
};
</script>

<template>
  <div class="flex flex-col gap-3">
    <ReportFilterSelector
      show-time-range-filter
      @filter-change="onFilterChange"
    />

    <div
      class="rounded-xl outline outline-1 outline-n-container flex items-center gap-3 flex-wrap"
    >
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
