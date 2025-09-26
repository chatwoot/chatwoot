<script setup>
import { computed, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';

import ScenariosCard from 'dashboard/components-next/captain/assistant/ScenariosCard.vue';
import ScenariosSVG from 'dashboard/components-next/captain/AnimatingImg/Scenarios.vue';
import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';
import OnboardingHeader from 'dashboard/components-next/captain/assistant/OnboardingHeader.vue';
import SettingsPageLayout from 'dashboard/components-next/captain/SettingsPageLayout.vue';

const router = useRouter();
const { t } = useI18n();

const breadcrumbItems = computed(() => [
  {
    label: t('CAPTAIN.ASSISTANTS.SETTINGS.BREADCRUMB.ASSISTANT'),
    routeName: 'captain_assistants_index',
  },
  {
    label: t('CAPTAIN.ASSISTANTS.ONBOARDING.HEADER.TITLE'),
    routeName: 'captain_assistants_create',
  },
]);

const scenariosExample = ref([
  {
    id: 1,
    title: 'Prospective Buyer',
    description:
      'Handle customers who are showing interest in purchasing a license',
    instruction:
      'If someone is interested in purchasing a license, ask them for following:\n\n1. How many licenses are they willing to purchase?\n2. Are they migrating from another platform?\n. Once these details are collected, do the following steps\n1. add a private note to with the information you collected using [Add Private Note](tool://add_private_note)\n2. Add label "sales" to the contact using [Add Label to Conversation](tool://add_label_to_conversation)\n3. Reply saying "one of us will reach out soon" and provide an estimated timeline for the response and [Handoff to Human](tool://handoff)',
    tools: ['add_private_note', 'add_label_to_conversation', 'handoff'],
  },
]);

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
  const count = scenariosExample.value.length || 0;
  const isAllSelected = bulkSelectedIds.value.size === count && count > 0;
  return isAllSelected
    ? t('CAPTAIN.ASSISTANTS.ONBOARDING.SCENARIOS.BULK_ACTION.UNSELECT_ALL', {
        count,
      })
    : t('CAPTAIN.ASSISTANTS.ONBOARDING.SCENARIOS.BULK_ACTION.SELECT_ALL', {
        count,
      });
});

const selectedCountLabel = computed(() => {
  return t('CAPTAIN.ASSISTANTS.ONBOARDING.SCENARIOS.BULK_ACTION.SELECTED', {
    count: bulkSelectedIds.value.size,
  });
});

const bulkDeleteScenarios = async () => {
  try {
    if (bulkSelectedIds.value.size === 0) return;
    const updated = scenariosExample.value.filter(
      item => !bulkSelectedIds.value.has(item.id)
    );
    scenariosExample.value = updated;
    bulkSelectedIds.value.clear();
  } catch {
    // error
  }
};

const updateScenario = async scenario => {
  try {
    scenariosExample.value = scenariosExample.value.map(item => {
      if (item.id === scenario.id) {
        return scenario;
      }
      return item;
    });
  } catch (error) {
    // error
  }
};

const deleteScenario = async id => {
  try {
    scenariosExample.value = scenariosExample.value.filter(
      item => item.id !== id
    );
  } catch (error) {
    // error
  }
};

const handleSaveAndNext = () => {
  router.push({
    name: 'captain_assistants_create_guidelines',
  });
};
</script>

<template>
  <SettingsPageLayout
    :breadcrumb-items="breadcrumbItems"
    :header-button-label="
      t('CAPTAIN.ASSISTANTS.ONBOARDING.HEADER.BUTTON_LABEL')
    "
    @click="handleSaveAndNext"
  >
    <template #body>
      <OnboardingHeader
        :title="t('CAPTAIN.ASSISTANTS.ONBOARDING.SCENARIOS.TITLE')"
        icon="i-lucide-shapes"
        :subtitle="t('CAPTAIN.ASSISTANTS.ONBOARDING.SCENARIOS.SUBTITLE')"
        :description="t('CAPTAIN.ASSISTANTS.ONBOARDING.SCENARIOS.DESCRIPTION')"
      >
        <div class="w-[12.5rem] h-[9.75rem] flex-shrink-0">
          <ScenariosSVG class="w-full h-full" />
        </div>
      </OnboardingHeader>

      <div class="pt-8 flex flex-col items-start gap-3 w-full">
        <span class="text-base text-n-slate-11 font-medium mb-3">
          {{ t('CAPTAIN.ASSISTANTS.ONBOARDING.SCENARIOS.TITLE') }}
        </span>
        <div class="w-full gap-2 flex flex-col">
          <BulkSelectBar
            v-model="bulkSelectedIds"
            :all-items="scenariosExample"
            :select-all-label="buildSelectedCountLabel"
            :selected-count-label="selectedCountLabel"
            :delete-label="
              $t(
                'CAPTAIN.ASSISTANTS.ONBOARDING.SCENARIOS.BULK_ACTION.BULK_DELETE_BUTTON'
              )
            "
            class="w-fit"
            @bulk-delete="bulkDeleteScenarios"
          />
          <ScenariosCard
            v-for="scenario in scenariosExample"
            :id="scenario.id"
            :key="scenario.id"
            :title="scenario.title"
            :description="scenario.description"
            :instruction="scenario.instruction"
            :tools="scenario.tools"
            :is-selected="bulkSelectedIds.has(scenario.id)"
            :selectable="
              hoveredCard === scenario.id || bulkSelectedIds.size > 0
            "
            @select="handleRuleSelect"
            @delete="deleteScenario(scenario.id)"
            @update="updateScenario"
            @hover="isHovered => handleRuleHover(isHovered, scenario.id)"
          />
        </div>
      </div>
    </template>
  </SettingsPageLayout>
</template>
