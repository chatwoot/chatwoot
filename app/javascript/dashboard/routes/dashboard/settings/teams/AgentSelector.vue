<script setup>
import { computed } from 'vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Avatar from 'next/avatar/Avatar.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import BaseTable from 'dashboard/components-next/table/BaseTable.vue';
import BaseTableRow from 'dashboard/components-next/table/BaseTableRow.vue';
import BaseTableCell from 'dashboard/components-next/table/BaseTableCell.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  agentList: {
    type: Array,
    default: () => [],
  },
  selectedAgents: {
    type: Array,
    default: () => [],
  },
  updateSelectedAgents: {
    type: Function,
    default: () => {},
  },
  isWorking: {
    type: Boolean,
    default: false,
  },
  submitButtonText: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();

const selectedAgentCount = computed(() => props.selectedAgents.length);

const allAgentsSelected = computed(
  () =>
    props.selectedAgents.length === props.agentList.length &&
    props.agentList.length > 0
);

const someAgentsSelected = computed(
  () => props.selectedAgents.length > 0 && !allAgentsSelected.value
);

const disableSubmitButton = computed(() => selectedAgentCount.value === 0);

const isAgentSelected = agentId => {
  return props.selectedAgents.includes(agentId);
};

const handleSelectAgent = agentId => {
  const shouldRemove = isAgentSelected(agentId);

  let result = [];
  if (shouldRemove) {
    result = props.selectedAgents.filter(item => item !== agentId);
  } else {
    result = [...props.selectedAgents, agentId];
  }

  props.updateSelectedAgents(result);
};

const toggleSelectAll = () => {
  if (allAgentsSelected.value) {
    props.updateSelectedAgents([]);
  } else {
    const result = props.agentList.map(item => item.id);
    props.updateSelectedAgents(result);
  }
};

const headers = computed(() => [
  '',
  t('TEAMS_SETTINGS.AGENTS.AGENT'),
  t('TEAMS_SETTINGS.AGENTS.EMAIL'),
]);
</script>

<template>
  <BaseTable :headers="headers" :items="agentList">
    <template #header-0>
      <div class="flex items-center">
        <Checkbox
          :model-value="allAgentsSelected"
          :indeterminate="someAgentsSelected"
          :title="$t('TEAMS_SETTINGS.AGENTS.SELECT_ALL')"
          @change="toggleSelectAll"
        />
      </div>
    </template>

    <template #row="{ items }">
      <BaseTableRow v-for="agent in items" :key="agent.id" :item="agent">
        <template #default>
          <BaseTableCell class="w-5">
            <div class="flex items-center">
              <Checkbox
                :model-value="isAgentSelected(agent.id)"
                @change="() => handleSelectAgent(agent.id)"
              />
            </div>
          </BaseTableCell>

          <BaseTableCell class="min-w-0 max-w-40">
            <div class="flex items-center gap-2 min-w-0">
              <Avatar
                :src="agent.thumbnail"
                :name="agent.name"
                :status="agent.availability_status"
                :size="24"
                hide-offline-status
                rounded-full
                class="flex-shrink-0"
              />
              <h4 class="text-heading-3 mb-0 text-n-slate-12 truncate">
                {{ agent.name }}
              </h4>
            </div>
          </BaseTableCell>

          <BaseTableCell class="min-w-0">
            <span class="text-body-main text-n-slate-11 truncate block">
              {{ agent.email || '---' }}
            </span>
          </BaseTableCell>
        </template>
      </BaseTableRow>
    </template>
  </BaseTable>

  <div class="flex items-center justify-between mt-4">
    <p class="text-body-main text-n-slate-11">
      {{
        $t('TEAMS_SETTINGS.AGENTS.SELECTED_COUNT', {
          selected: selectedAgents.length,
          total: agentList.length,
        })
      }}
    </p>
    <NextButton
      type="submit"
      :label="submitButtonText"
      :disabled="disableSubmitButton"
      :is-loading="isWorking"
    />
  </div>
</template>
