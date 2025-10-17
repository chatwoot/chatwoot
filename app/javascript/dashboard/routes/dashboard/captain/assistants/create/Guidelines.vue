<script setup>
import { computed, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import RuleCard from 'dashboard/components-next/captain/assistant/RuleCard.vue';
import ResponseGuidelinesSVG from 'dashboard/components-next/captain/AnimatingImg/ResponseGuidelines.vue';
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

const guidelinesExample = ref([
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
  const count = guidelinesExample.value.length || 0;
  const isAllSelected = bulkSelectedIds.value.size === count && count > 0;
  return isAllSelected
    ? t('CAPTAIN.ASSISTANTS.ONBOARDING.GUIDELINES.BULK_ACTION.UNSELECT_ALL', {
        count,
      })
    : t('CAPTAIN.ASSISTANTS.ONBOARDING.GUIDELINES.BULK_ACTION.SELECT_ALL', {
        count,
      });
});

const selectedCountLabel = computed(() => {
  return t('CAPTAIN.ASSISTANTS.ONBOARDING.GUIDELINES.BULK_ACTION.SELECTED', {
    count: bulkSelectedIds.value.size,
  });
});

const bulkDeleteGuidelines = async () => {
  try {
    if (bulkSelectedIds.value.size === 0) return;
    const updated = guidelinesExample.value.filter(
      item => !bulkSelectedIds.value.has(item.id)
    );
    guidelinesExample.value = updated;
    bulkSelectedIds.value.clear();
  } catch {
    // error
  }
};

const editGuideline = async ({ id, content }) => {
  try {
    guidelinesExample.value = guidelinesExample.value.map(item => {
      if (item.id === id) {
        return { id, content };
      }
      return item;
    });
  } catch {
    // error
  }
};

const deleteGuideline = async id => {
  try {
    guidelinesExample.value = guidelinesExample.value.filter(
      item => item.id !== id
    );
  } catch {
    // error
  }
};

const handleSave = () => {
  router.push({
    name: 'captain_assistants_index',
  });
};

const handleGoBackSettings = () => {
  router.push({
    name: 'captain_assistants_edit',
  });
};
</script>

<template>
  <SettingsPageLayout
    :breadcrumb-items="breadcrumbItems"
    :header-button-label="t('CAPTAIN.ASSISTANTS.ONBOARDING.HEADER.BUTTON_SAVE')"
    @click="handleSave"
  >
    <template #headerControls>
      <Button slate @click="handleGoBackSettings">
        {{ t('CAPTAIN.ASSISTANTS.ONBOARDING.HEADER.GO_SETTINGS') }}
      </Button>
    </template>
    <template #body>
      <OnboardingHeader
        :title="t('CAPTAIN.ASSISTANTS.ONBOARDING.GUIDELINES.TITLE')"
        icon="i-lucide-pencil-ruler"
        :subtitle="t('CAPTAIN.ASSISTANTS.ONBOARDING.GUIDELINES.SUBTITLE')"
        :description="t('CAPTAIN.ASSISTANTS.ONBOARDING.GUIDELINES.DESCRIPTION')"
      >
        <div class="w-[12.5rem] h-[9.75rem] flex-shrink-0">
          <ResponseGuidelinesSVG class="w-full h-full" />
        </div>
      </OnboardingHeader>

      <div class="pt-8 flex flex-col items-start gap-3 w-full">
        <span class="text-base text-n-slate-11 font-medium mb-3">
          {{ t('CAPTAIN.ASSISTANTS.ONBOARDING.GUIDELINES.TITLE') }}
        </span>
        <div class="w-full gap-2 flex flex-col">
          <BulkSelectBar
            v-model="bulkSelectedIds"
            :all-items="guidelinesExample"
            :select-all-label="buildSelectedCountLabel"
            :selected-count-label="selectedCountLabel"
            :delete-label="
              $t(
                'CAPTAIN.ASSISTANTS.ONBOARDING.GUIDELINES.BULK_ACTION.BULK_DELETE_BUTTON'
              )
            "
            class="w-fit"
            @bulk-delete="bulkDeleteGuidelines"
          />
          <RuleCard
            v-for="guideline in guidelinesExample"
            :id="guideline.id"
            :key="guideline.id"
            :content="guideline.content"
            :is-selected="bulkSelectedIds.has(guideline.id)"
            :selectable="
              hoveredCard === guideline.id || bulkSelectedIds.size > 0
            "
            @select="handleRuleSelect"
            @edit="editGuideline"
            @delete="deleteGuideline"
            @hover="isHovered => handleRuleHover(isHovered, guideline.id)"
          />
        </div>
      </div>
    </template>
  </SettingsPageLayout>
</template>
