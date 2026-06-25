<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import SettingsHeader from 'dashboard/components-next/captain/pageComponents/settings/SettingsHeader.vue';
import SuggestedRules from 'dashboard/components-next/captain/assistant/SuggestedRules.vue';
import AddNewRulesInput from 'dashboard/components-next/captain/assistant/AddNewRulesInput.vue';
import AddNewRulesDialog from 'dashboard/components-next/captain/assistant/AddNewRulesDialog.vue';
import RuleCard from 'dashboard/components-next/captain/assistant/RuleCard.vue';
import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';

const { t } = useI18n();
const route = useRoute();
const store = useStore();
const { uiSettings, updateUISettings } = useUISettings();

const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const assistantId = computed(() => Number(route.params.assistantId));
const isFetching = computed(() => uiFlags.value.fetchingItem);
const assistant = computed(() =>
  store.getters['captainAssistants/getRecord'](assistantId.value)
);

const searchQuery = ref('');
const newInlineRule = ref('');
const newDialogRule = ref('');

const guardrailsContent = computed(() => assistant.value?.guardrails || []);

const backUrl = computed(() => ({
  name: 'captain_assistants_settings_index',
  params: {
    accountId: route.params.accountId,
    assistantId: assistantId.value,
  },
}));

const displayGuardrails = computed(() =>
  guardrailsContent.value.map((c, idx) => ({ id: idx, content: c }))
);

const guardrailsExample = [
  {
    id: 1,
    content:
      'Block queries that share or request sensitive personal information (e.g. phone numbers, passwords).',
  },
  {
    id: 2,
    content:
      'Reject queries that include offensive, discriminatory, or threatening language.',
  },
  {
    id: 3,
    content:
      'Deflect when the assistant is asked for legal or medical diagnosis or treatment.',
  },
];

const filteredGuardrails = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return displayGuardrails.value;
  return picoSearch(displayGuardrails.value, query, ['content']);
});

const shouldShowSuggestedRules = computed(() => {
  return uiSettings.value?.show_guardrails_suggestions !== false;
});

const closeSuggestedRules = () => {
  updateUISettings({ show_guardrails_suggestions: false });
};

// Bulk selection & hover state
const bulkSelectedIds = ref(new Set());
const hoveredCard = ref(null);

const handleRuleSelect = id => {
  const selected = new Set(bulkSelectedIds.value);
  selected[selected.has(id) ? 'delete' : 'add'](id);
  bulkSelectedIds.value = selected;
};

const handleRuleHover = (isHovered, id) => {
  hoveredCard.value = isHovered ? id : null;
};

const buildSelectedCountLabel = computed(() => {
  const count = displayGuardrails.value.length || 0;
  const isAllSelected = bulkSelectedIds.value.size === count && count > 0;
  return isAllSelected
    ? t('CAPTAIN.ASSISTANTS.GUARDRAILS.BULK_ACTION.UNSELECT_ALL', { count })
    : t('CAPTAIN.ASSISTANTS.GUARDRAILS.BULK_ACTION.SELECT_ALL', { count });
});

const selectedCountLabel = computed(() => {
  return t('CAPTAIN.ASSISTANTS.GUARDRAILS.BULK_ACTION.SELECTED', {
    count: bulkSelectedIds.value.size,
  });
});

const saveGuardrails = async list => {
  await store.dispatch('captainAssistants/update', {
    id: assistantId.value,
    assistant: { guardrails: list },
  });
};

const addGuardrail = async content => {
  try {
    const newGuardrails = [...guardrailsContent.value, content];
    await saveGuardrails(newGuardrails);
    useAlert(t('CAPTAIN.ASSISTANTS.GUARDRAILS.API.ADD.SUCCESS'));
  } catch (error) {
    useAlert(t('CAPTAIN.ASSISTANTS.GUARDRAILS.API.ADD.ERROR'));
  }
};

const editGuardrail = async ({ id, content }) => {
  try {
    const updated = [...guardrailsContent.value];
    updated[id] = content;
    await saveGuardrails(updated);
    useAlert(t('CAPTAIN.ASSISTANTS.GUARDRAILS.API.UPDATE.SUCCESS'));
  } catch {
    useAlert(t('CAPTAIN.ASSISTANTS.GUARDRAILS.API.UPDATE.ERROR'));
  }
};

const deleteGuardrail = async id => {
  try {
    const updated = guardrailsContent.value.filter((_, idx) => idx !== id);
    await saveGuardrails(updated);
    useAlert(t('CAPTAIN.ASSISTANTS.GUARDRAILS.API.DELETE.SUCCESS'));
  } catch {
    useAlert(t('CAPTAIN.ASSISTANTS.GUARDRAILS.API.DELETE.ERROR'));
  }
};

const bulkDeleteGuardrails = async () => {
  try {
    if (bulkSelectedIds.value.size === 0) return;
    const updated = guardrailsContent.value.filter(
      (_, idx) => !bulkSelectedIds.value.has(idx)
    );
    await saveGuardrails(updated);
    bulkSelectedIds.value.clear();
    useAlert(t('CAPTAIN.ASSISTANTS.GUARDRAILS.API.DELETE.SUCCESS'));
  } catch {
    useAlert(t('CAPTAIN.ASSISTANTS.GUARDRAILS.API.DELETE.ERROR'));
  }
};

const addAllExample = () => {
  updateUISettings({ show_guardrails_suggestions: false });
  try {
    const exampleContents = guardrailsExample.map(example => example.content);
    const newGuardrails = [...guardrailsContent.value, ...exampleContents];
    saveGuardrails(newGuardrails);
  } catch {
    useAlert(t('CAPTAIN.ASSISTANTS.GUARDRAILS.API.ADD.ERROR'));
  }
};
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.ASSISTANTS.GUARDRAILS.TITLE')"
    :is-fetching="isFetching"
    :back-url="backUrl"
    :show-know-more="false"
    :show-pagination-footer="false"
    :show-assistant-switcher="false"
  >
    <template #body>
      <SettingsHeader
        :heading="$t('CAPTAIN.ASSISTANTS.GUARDRAILS.TITLE')"
        :description="$t('CAPTAIN.ASSISTANTS.GUARDRAILS.DESCRIPTION')"
      />
      <div v-if="shouldShowSuggestedRules" class="flex mt-7 flex-col gap-4">
        <SuggestedRules
          :title="$t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.SUGGESTED.TITLE')"
          :items="guardrailsExample"
          @add="addAllExample"
          @close="closeSuggestedRules"
        >
          <template #default="{ item }">
            <div class="flex items-center justify-between w-full">
              <span class="text-sm text-n-slate-12">
                {{ item.content }}
              </span>
              <Button
                :label="
                  $t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.SUGGESTED.ADD_SINGLE')
                "
                ghost
                xs
                slate
                class="!text-sm !text-n-slate-11 flex-shrink-0"
                @click="addGuardrail(item.content)"
              />
            </div>
          </template>
        </SuggestedRules>
      </div>
      <div class="flex mt-7 flex-col gap-4">
        <div class="flex justify-between items-center">
          <BulkSelectBar
            v-model="bulkSelectedIds"
            :all-items="displayGuardrails"
            :select-all-label="buildSelectedCountLabel"
            :selected-count-label="selectedCountLabel"
            :delete-label="
              $t('CAPTAIN.ASSISTANTS.GUARDRAILS.BULK_ACTION.BULK_DELETE_BUTTON')
            "
            @bulk-delete="bulkDeleteGuardrails"
          >
            <template #default-actions>
              <AddNewRulesDialog
                v-model="newDialogRule"
                :placeholder="
                  t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.NEW.PLACEHOLDER')
                "
                :button-label="t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.NEW.TITLE')"
                :confirm-label="
                  t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.NEW.CREATE')
                "
                :cancel-label="
                  t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.NEW.CANCEL')
                "
                @add="addGuardrail"
              />
              <!-- Will enable this feature in future -->
              <!-- <div class="h-4 w-px bg-n-strong" />
              <Button
                :label="t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.NEW.TEST_ALL')"
                xs
                ghost
                slate
                class="!text-sm"
              /> -->
            </template>
          </BulkSelectBar>
          <div
            v-if="displayGuardrails.length && bulkSelectedIds.size === 0"
            class="max-w-[22.5rem] w-full min-w-0"
          >
            <Input
              v-model="searchQuery"
              :placeholder="
                t('CAPTAIN.ASSISTANTS.GUARDRAILS.LIST.SEARCH_PLACEHOLDER')
              "
            />
          </div>
        </div>
        <div v-if="displayGuardrails.length === 0" class="mt-1 mb-2">
          <span class="text-n-slate-11 text-sm">
            {{ t('CAPTAIN.ASSISTANTS.GUARDRAILS.EMPTY_MESSAGE') }}
          </span>
        </div>
        <div v-else-if="filteredGuardrails.length === 0" class="mt-1 mb-2">
          <span class="text-n-slate-11 text-sm">
            {{ t('CAPTAIN.ASSISTANTS.GUARDRAILS.SEARCH_EMPTY_MESSAGE') }}
          </span>
        </div>
        <div v-else class="flex flex-col gap-2">
          <RuleCard
            v-for="guardrail in filteredGuardrails"
            :id="guardrail.id"
            :key="guardrail.id"
            :content="guardrail.content"
            :is-selected="bulkSelectedIds.has(guardrail.id)"
            :selectable="
              hoveredCard === guardrail.id || bulkSelectedIds.size > 0
            "
            @select="handleRuleSelect"
            @edit="editGuardrail"
            @delete="deleteGuardrail"
            @hover="isHovered => handleRuleHover(isHovered, guardrail.id)"
          />
        </div>
        <AddNewRulesInput
          v-model="newInlineRule"
          :placeholder="
            t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.SUGGESTED.PLACEHOLDER')
          "
          :label="t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.SUGGESTED.SAVE')"
          @add="addGuardrail"
        />
      </div>
    </template>
  </PageLayout>
</template>
