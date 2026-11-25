<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import CaptainAssistantAPI from 'dashboard/api/captain/assistant';
import CaptainInboxesAPI from 'dashboard/api/captain/inboxes';
import { isAssistantSearched } from '../constants';

import SectionLayout from '../../account/components/SectionLayout.vue';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
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

const isLoading = ref(true);
const faqCounts = ref({});
const inboxNames = ref({});

const tableHeaders = computed(() => [
  t('COPILOT_SETTINGS.KNOWLEDGE.TABLE.ASSISTANT'),
  t('COPILOT_SETTINGS.KNOWLEDGE.TABLE.FAQS'),
  t('COPILOT_SETTINGS.KNOWLEDGE.TABLE.INBOXES'),
  t('COPILOT_SETTINGS.KNOWLEDGE.TABLE.USE'),
]);

// Missing means on, so accounts that never saved this page keep searching every assistant
const includeNewAssistants = computed(
  () => props.settings.include_new_assistants !== false
);

const isAssistantOn = id => isAssistantSearched(props.settings, id);

// Saves the choice for every assistant on the page, so later assistants are the only ones left to the default
const saveSelection = ({ changedId, enabled, includeNew }) => {
  const onIds = assistants.value
    .map(assistant => assistant.id)
    .filter(id => (id === changedId ? enabled : isAssistantOn(id)));
  const offIds = assistants.value
    .map(assistant => assistant.id)
    .filter(id => !onIds.includes(id));

  emit('update', {
    include_new_assistants: includeNew ?? includeNewAssistants.value,
    assistant_ids: onIds,
    excluded_assistant_ids: offIds,
  });
};

const includeNewModel = computed({
  get: () => includeNewAssistants.value,
  set: value => saveSelection({ includeNew: value }),
});

const loadAssistantDetails = async assistant => {
  const [{ data: stats }, { data: inboxes }] = await Promise.all([
    CaptainAssistantAPI.getFaqStats({ assistantId: assistant.id }),
    CaptainInboxesAPI.get({ assistantId: assistant.id }),
  ]);
  faqCounts.value[assistant.id] = stats.approved;
  inboxNames.value[assistant.id] = inboxes.payload.map(inbox => inbox.name);
};

onMounted(async () => {
  try {
    await store.dispatch('captainAssistants/get');
    await Promise.all(assistants.value.map(loadAssistantDetails));
  } finally {
    isLoading.value = false;
  }
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
      <div v-else class="flex flex-col gap-4">
        <div class="overflow-x-auto">
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
                  <span v-if="faqCounts[assistant.id]">
                    {{ faqCounts[assistant.id] }}
                  </span>
                  <span v-else class="text-n-slate-10">
                    {{ t('COPILOT_SETTINGS.KNOWLEDGE.NO_FAQS') }}
                  </span>
                </BaseTableCell>
                <BaseTableCell>
                  <span v-if="inboxNames[assistant.id]?.length">
                    {{ inboxNames[assistant.id].join(', ') }}
                  </span>
                  <span v-else class="text-n-slate-10">
                    {{ t('COPILOT_SETTINGS.KNOWLEDGE.NO_INBOXES') }}
                  </span>
                </BaseTableCell>
                <BaseTableCell>
                  <Switch
                    :model-value="isAssistantOn(assistant.id)"
                    @update:model-value="
                      enabled =>
                        saveSelection({ changedId: assistant.id, enabled })
                    "
                  />
                </BaseTableCell>
              </BaseTableRow>
            </template>
          </BaseTable>
        </div>
        <SettingsToggleSection
          v-model="includeNewModel"
          :header="t('COPILOT_SETTINGS.KNOWLEDGE.INCLUDE_NEW.TITLE')"
          :description="t('COPILOT_SETTINGS.KNOWLEDGE.INCLUDE_NEW.DESCRIPTION')"
        />
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
