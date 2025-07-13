<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

import SettingsPageLayout from 'dashboard/components-next/captain/SettingsPageLayout.vue';
import SettingsHeader from 'dashboard/components-next/captain/pageComponents/settings/SettingsHeader.vue';
import SuggestedRules from 'dashboard/components-next/captain/assistant/SuggestedRules.vue';
import AddNewRulesInput from 'dashboard/components-next/captain/assistant/AddNewRulesInput.vue';
import AddNewRulesDialog from 'dashboard/components-next/captain/assistant/AddNewRulesDialog.vue';
import RuleCard from 'dashboard/components-next/captain/assistant/RuleCard.vue';

const { t } = useI18n();
const route = useRoute();
const store = useStore();
const assistantId = route.params.assistantId;
const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingItem);
const assistant = computed(() =>
  store.getters['captainAssistants/getRecord'](Number(assistantId))
);

const breadcrumbItems = computed(() => {
  return [
    {
      label: t('CAPTAIN.ASSISTANTS.SETTINGS.BREADCRUMB.ASSISTANT'),
      routeName: 'captain_assistants_index',
    },
    { label: assistant.value?.name, routeName: 'captain_assistants_edit' },
    { label: t('CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.TITLE') },
  ];
});

// Hardcoded example guidelines
const guidelinesExample = [
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

const searchQuery = ref('');

const filteredGuidelines = computed(() => {
  return guidelinesExample.filter(guideline => {
    return guideline.content
      .toLowerCase()
      .includes(searchQuery.value.toLowerCase());
  });
});

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

const bulkSelectionState = computed(() => {
  const selectedCount = bulkSelectedIds.value.size;
  const totalCount = guidelinesExample.length || 0;

  return {
    hasSelected: selectedCount > 0,
    isIndeterminate: selectedCount > 0 && selectedCount < totalCount,
    allSelected: totalCount > 0 && selectedCount === totalCount,
  };
});

const buildSelectedCountLabel = computed(() => {
  const count = guidelinesExample.length || 0;
  return bulkSelectionState.value.allSelected
    ? t('CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.BULK_ACTION.UNSELECT_ALL', {
        count,
      })
    : t('CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.BULK_ACTION.SELECT_ALL', {
        count,
      });
});

const bulkCheckbox = computed({
  get: () => bulkSelectionState.value.allSelected,
  set: value => {
    bulkSelectedIds.value = value
      ? new Set(guidelinesExample.map(r => r.id))
      : new Set();
  },
});
</script>

<template>
  <SettingsPageLayout
    :breadcrumb-items="breadcrumbItems"
    :is-fetching="isFetching"
    show-pagination-footer
  >
    <template #body>
      <SettingsHeader
        :heading="t('CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.TITLE')"
        :description="t('CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.DESCRIPTION')"
      />
      <div class="flex mt-7 flex-col gap-4">
        <SuggestedRules
          :title="t('CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.TITLE')"
          :items="guidelinesExample"
        >
          <template #default="{ item }">
            <span class="text-sm text-n-slate-12">
              {{ item.content }}
            </span>
            <Button
              :label="
                t(
                  'CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.ADD.SUGGESTED.ADD_SINGLE'
                )
              "
              ghost
              xs
              slate
              class="!text-sm !text-n-slate-11 flex-shrink-0"
            />
          </template>
        </SuggestedRules>
      </div>
      <div class="flex mt-7 flex-col gap-4">
        <div class="flex justify-between items-center">
          <transition
            name="slide-fade"
            enter-active-class="transition-all duration-300 ease-out"
            enter-from-class="opacity-0 transform ltr:-translate-x-4 rtl:translate-x-4"
            enter-to-class="opacity-100 transform translate-x-0"
            leave-active-class="hidden opacity-0"
          >
            <div
              v-if="bulkSelectionState.hasSelected"
              class="flex items-center gap-3 py-1 ltr:pl-3 rtl:pr-3 ltr:pr-4 rtl:pl-4 rounded-lg bg-n-solid-2 outline outline-1 outline-n-container shadow"
            >
              <div class="flex items-center gap-3">
                <div class="flex items-center gap-1.5">
                  <Checkbox
                    v-model="bulkCheckbox"
                    :indeterminate="bulkSelectionState.isIndeterminate"
                  />
                  <span
                    class="text-sm text-n-slate-12 font-medium tabular-nums"
                  >
                    {{ buildSelectedCountLabel }}
                  </span>
                </div>
                <span class="text-sm text-n-slate-10 tabular-nums">
                  {{
                    $t(
                      'CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.BULK_ACTION.SELECTED',
                      {
                        count: bulkSelectedIds.size,
                      }
                    )
                  }}
                </span>
              </div>
              <div class="h-4 w-px bg-n-strong" />
              <div class="flex gap-3 items-center">
                <Button
                  :label="
                    $t(
                      'CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.BULK_ACTION.BULK_DELETE_BUTTON'
                    )
                  "
                  sm
                  ruby
                  ghost
                  class="!px-1.5"
                  icon="i-lucide-trash"
                />
              </div>
            </div>
            <div v-else class="flex items-center gap-3">
              <AddNewRulesDialog
                :placeholder="
                  t(
                    'CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.ADD.NEW.PLACEHOLDER'
                  )
                "
                :label="
                  t('CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.ADD.NEW.TITLE')
                "
                :confirm-label="
                  t('CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.ADD.NEW.CREATE')
                "
                :cancel-label="
                  t('CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.ADD.NEW.CANCEL')
                "
              />
              <div class="h-4 w-px bg-n-strong" />
              <Button
                :label="
                  t('CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.ADD.NEW.TEST_ALL')
                "
                sm
                ghost
                slate
              />
            </div>
          </transition>
          <div class="max-w-[22.5rem] w-full min-w-0">
            <Input
              v-model="searchQuery"
              :placeholder="
                t(
                  'CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.LIST.SEARCH_PLACEHOLDER'
                )
              "
            />
          </div>
        </div>
        <div class="flex flex-col gap-2">
          <RuleCard
            v-for="guideline in filteredGuidelines"
            :id="guideline.id"
            :key="guideline.id"
            :content="guideline.content"
            :is-selected="bulkSelectedIds.has(guideline.id)"
            :selectable="
              hoveredCard === guideline.id || bulkSelectedIds.size > 0
            "
            @select="handleRuleSelect"
            @hover="isHovered => handleRuleHover(isHovered, guideline.id)"
          />
        </div>
        <AddNewRulesInput
          :placeholder="
            t(
              'CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.ADD.SUGGESTED.PLACEHOLDER'
            )
          "
          :label="
            t('CAPTAIN.ASSISTANTS.RESPONSE_GUIDELINES.ADD.SUGGESTED.SAVE')
          "
        />
      </div>
    </template>
  </SettingsPageLayout>
</template>
