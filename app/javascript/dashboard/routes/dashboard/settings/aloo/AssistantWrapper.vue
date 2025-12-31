<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import {
  useMapGetter,
  useStore,
  useStoreGetters,
} from 'dashboard/composables/store';

import PageHeader from '../SettingsSubPageHeader.vue';

const { t } = useI18n();
const route = useRoute();
const store = useStore();
const getters = useStoreGetters();

const globalConfig = useMapGetter('globalConfig/get');

// Only reset wizard when entering fresh on the first step with no data
// This prevents resetting when navigating between wizard steps
onMounted(() => {
  const currentName = getters['alooWizard/getName'].value;
  const isFirstStep = route.name === 'settings_aloo_new';

  if (isFirstStep && !currentName) {
    store.dispatch('alooWizard/reset');
  }
});

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
