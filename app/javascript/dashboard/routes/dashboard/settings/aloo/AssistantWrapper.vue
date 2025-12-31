<script setup>
import { computed, provide, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';

import PageHeader from '../SettingsSubPageHeader.vue';

const { t } = useI18n();
const route = useRoute();

const globalConfig = useMapGetter('globalConfig/get');

// Wizard state - shared across all steps
const wizardData = ref({
  name: '',
  description: '',
  tone: 'friendly',
  formality: 'medium',
  empathy_level: 'medium',
  verbosity: 'balanced',
  emoji_usage: 'minimal',
  greeting_style: 'warm',
  custom_greeting: '',
  language: 'en',
  dialect: '',
  personality_description: '',
  documents: [],
  inbox_ids: [],
});

// Provide wizard data to child components
provide('wizardData', wizardData);

const steps = ['BASIC', 'PERSONALITY', 'KNOWLEDGE', 'INBOXES'];

const routes = {
  BASIC: 'settings_aloo_new',
  PERSONALITY: 'settings_aloo_new_personality',
  KNOWLEDGE: 'settings_aloo_new_knowledge',
  INBOXES: 'settings_aloo_new_assign',
};

const createFlowSteps = computed(() => {
  return steps.map((step, index) => {
    return {
      title: t(`ALOO.WIZARD.STEP_${index + 1}`),
      body: t(`ALOO.WIZARD.STEP_${index + 1}_BODY`),
      route: routes[step],
    };
  });
});

const isFirstStep = computed(() => {
  return route.name === 'settings_aloo_new';
});

const isFinishStep = computed(() => {
  return route.name === 'settings_aloo_new_assign';
});

const pageTitle = computed(() => {
  if (isFirstStep.value) {
    return t('ALOO.WIZARD.TITLE');
  }
  if (isFinishStep.value) {
    return t('ALOO.WIZARD.STEP_4');
  }
  return t('ALOO.WIZARD.TITLE');
});
</script>

<template>
  <div class="mx-2 flex flex-col gap-6 mb-8">
    <PageHeader class="block lg:hidden !mb-0" :header-title="pageTitle" />
    <div
      class="grid grid-cols-1 lg:grid-cols-8 lg:divide-x lg:divide-n-weak rounded-xl border border-n-weak min-h-[52rem]"
    >
      <woot-wizard
        class="hidden lg:block col-span-2 h-fit py-8 px-6"
        :global-config="globalConfig"
        :items="createFlowSteps"
      />
      <div class="col-span-6 overflow-visible">
        <router-view />
      </div>
    </div>
  </div>
</template>
