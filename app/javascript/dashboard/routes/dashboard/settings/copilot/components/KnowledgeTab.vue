<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { findSearchedAssistant } from '../constants';

import SectionLayout from '../../account/components/SectionLayout.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const props = defineProps({
  settings: { type: Object, required: true },
});

const emit = defineEmits(['update']);

const { t } = useI18n();
const store = useStore();
const assistants = useMapGetter('captainAssistants/getRecords');
const assistantFlags = useMapGetter('captainAssistants/getUIFlags');
const inboxes = useMapGetter('inboxes/getInboxes');

const isLoading = computed(() => assistantFlags.value.fetchingList);

const inboxNames = assistant =>
  inboxes.value
    .filter(inbox => assistant.inbox_ids?.includes(inbox.id))
    .map(inbox => inbox.name);

const tableHeaders = computed(() => [
  t('COPILOT_SETTINGS.KNOWLEDGE.TABLE.ASSISTANT'),
  t('COPILOT_SETTINGS.KNOWLEDGE.TABLE.FAQS'),
  t('COPILOT_SETTINGS.KNOWLEDGE.TABLE.INBOXES'),
  // The switch column has no heading, because the table only aligns headings to the start and the switches sit at the end
  '',
]);

const searchedAssistantId = computed(
  () => findSearchedAssistant(props.settings, assistants.value)?.id
);

// Only one assistant is searched, so turning one on turns the others off, and turning it off leaves none
const toggleAssistant = (id, enabled) => {
  emit('update', { assistant_id: enabled ? id : null });
};

onMounted(() => {
  store.dispatch('captainAssistants/get');
});
</script>

<template>
  <div class="flex flex-col">
    <SectionLayout
      :title="t('COPILOT_SETTINGS.KNOWLEDGE.TITLE')"
      :description="t('COPILOT_SETTINGS.KNOWLEDGE.DESCRIPTION')"
    >
      <div v-if="isLoading" class="flex justify-center py-10">
        <Spinner />
      </div>
      <div v-else class="overflow-x-auto">
        <BaseTable
          :headers="tableHeaders"
          :items="assistants"
          :no-data-message="t('COPILOT_SETTINGS.KNOWLEDGE.EMPTY')"
        >
          <template #row="{ items }">
            <BaseTableRow
              v-for="assistant in items"
              :key="assistant.id"
              :item="assistant"
            >
              <BaseTableCell>
                <div class="flex items-center gap-2 min-w-0">
                  <Avatar
                    :name="assistant.name"
                    :src="assistant.avatar_url"
                    :size="24"
                    rounded-full
                  />
                  <span class="text-n-slate-12 truncate">
                    {{ assistant.name }}
                  </span>
                </div>
              </BaseTableCell>
              <BaseTableCell class="whitespace-nowrap">
                <span v-if="assistant.approved_responses_count">
                  {{ assistant.approved_responses_count }}
                </span>
                <span v-else class="text-n-slate-10">
                  {{ t('COPILOT_SETTINGS.KNOWLEDGE.NO_FAQS') }}
                </span>
              </BaseTableCell>
              <BaseTableCell>
                <span v-if="inboxNames(assistant).length">
                  {{ inboxNames(assistant).join(', ') }}
                </span>
                <span v-else class="text-n-slate-10">
                  {{ t('COPILOT_SETTINGS.KNOWLEDGE.NO_INBOXES') }}
                </span>
              </BaseTableCell>
              <BaseTableCell align="end">
                <Switch
                  :model-value="searchedAssistantId === assistant.id"
                  @update:model-value="
                    enabled => toggleAssistant(assistant.id, enabled)
                  "
                />
              </BaseTableCell>
            </BaseTableRow>
          </template>
        </BaseTable>
      </div>
    </SectionLayout>
    <SectionLayout
      :title="t('COPILOT_SETTINGS.KNOWLEDGE.SUGGEST.TITLE')"
      :description="t('COPILOT_SETTINGS.KNOWLEDGE.SUGGEST.DESCRIPTION')"
      with-border
      hide-content
    />
  </div>
</template>
