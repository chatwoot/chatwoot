<script setup>
import { computed, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';

import RuleCard from 'dashboard/components-next/captain/assistant/RuleCard.vue';
import GuardrailsSVG from 'dashboard/components-next/captain/AnimatingImg/Guardrails.vue';
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

const guardrailsExample = ref([
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
  const count = guardrailsExample.value.length || 0;
  const isAllSelected = bulkSelectedIds.value.size === count && count > 0;
  return isAllSelected
    ? t('CAPTAIN.ASSISTANTS.ONBOARDING.GUARDRAILS.BULK_ACTION.UNSELECT_ALL', {
        count,
      })
    : t('CAPTAIN.ASSISTANTS.ONBOARDING.GUARDRAILS.BULK_ACTION.SELECT_ALL', {
        count,
      });
});

const selectedCountLabel = computed(() => {
  return t('CAPTAIN.ASSISTANTS.ONBOARDING.GUARDRAILS.BULK_ACTION.SELECTED', {
    count: bulkSelectedIds.value.size,
  });
});

const bulkDeleteGuardrails = async () => {
  try {
    if (bulkSelectedIds.value.size === 0) return;
    const updated = guardrailsExample.value.filter(
      item => !bulkSelectedIds.value.has(item.id)
    );
    guardrailsExample.value = updated;
    bulkSelectedIds.value.clear();
  } catch {
    // error
  }
};

const editGuardrail = async ({ id, content }) => {
  try {
    guardrailsExample.value = guardrailsExample.value.map(item => {
      if (item.id === id) {
        return { id, content };
      }
      return item;
    });
  } catch {
    // error
  }
};

const deleteGuardrail = async id => {
  try {
    guardrailsExample.value = guardrailsExample.value.filter(
      item => item.id !== id
    );
  } catch {
    // error
  }
};

const handleSaveAndNext = () => {
  router.push({
    name: 'captain_assistants_create_scenarios',
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
        :title="t('CAPTAIN.ASSISTANTS.ONBOARDING.GUARDRAILS.TITLE')"
        icon="i-lucide-traffic-cone"
        :subtitle="t('CAPTAIN.ASSISTANTS.ONBOARDING.GUARDRAILS.SUBTITLE')"
        :description="t('CAPTAIN.ASSISTANTS.ONBOARDING.GUARDRAILS.DESCRIPTION')"
      >
        <div class="w-[12.5rem] h-[9.75rem] flex-shrink-0">
          <GuardrailsSVG class="w-full h-full" />
        </div>
      </OnboardingHeader>

      <div class="pt-8 flex flex-col items-start gap-3 w-full">
        <span class="text-base text-n-slate-11 font-medium mb-3">
          {{ t('CAPTAIN.ASSISTANTS.ONBOARDING.GUARDRAILS.TITLE') }}
        </span>
        <div class="w-full gap-2 flex flex-col">
          <BulkSelectBar
            v-model="bulkSelectedIds"
            :all-items="guardrailsExample"
            :select-all-label="buildSelectedCountLabel"
            :selected-count-label="selectedCountLabel"
            :delete-label="
              $t(
                'CAPTAIN.ASSISTANTS.ONBOARDING.GUARDRAILS.BULK_ACTION.BULK_DELETE_BUTTON'
              )
            "
            class="w-fit"
            @bulk-delete="bulkDeleteGuardrails"
          />
          <RuleCard
            v-for="guardrail in guardrailsExample"
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
      </div>
    </template>
  </SettingsPageLayout>
</template>
