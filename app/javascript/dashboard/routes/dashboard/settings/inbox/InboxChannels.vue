<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useBranding } from 'shared/composables/useBranding';

import PageHeader from '../SettingsSubPageHeader.vue';

const { t } = useI18n();
const route = useRoute();
const { replaceInstallationName } = useBranding();

const createFlowSteps = computed(() => {
  const steps = ['CHANNEL', 'INBOX', 'AGENT', 'FINISH'];

  const routes = {
    CHANNEL: 'settings_inbox_new',
    INBOX: 'settings_inboxes_page_channel',
    AGENT: 'settings_inboxes_add_agents',
    FINISH: 'settings_inbox_finish',
  };

  return steps.map(step => {
    return {
      title: t(`INBOX_MGMT.CREATE_FLOW.${step}.TITLE`),
      body: t(`INBOX_MGMT.CREATE_FLOW.${step}.BODY`),
      route: routes[step],
    };
  });
});

const isFirstStep = computed(() => {
  return route.name === 'settings_inbox_new';
});

const isFinishStep = computed(() => {
  return route.name === 'settings_inbox_finish';
});

const pageTitle = computed(() => {
  if (isFirstStep.value) {
    return t('INBOX_MGMT.CREATE_FLOW.CONNECT.TITLE');
  }
  if (isFinishStep.value) {
    return t('INBOX_MGMT.ADD.AUTH.TITLE_FINISH');
  }
  return t('INBOX_MGMT.ADD.AUTH.TITLE_NEXT');
});

const items = computed(() => {
  return createFlowSteps.value.map(item => ({
    ...item,
    body: replaceInstallationName(item.body),
  }));
});
</script>

<template>
  <div
    class="mx-auto mb-8 flex w-full max-w-7xl flex-col gap-8 px-4 pb-4 pt-2 lg:px-6"
  >
    <PageHeader
      class="mb-0 block lg:!mb-0 lg:hidden"
      :header-title="pageTitle"
    />
    <div class="grid grid-cols-1 gap-12 lg:grid-cols-12">
      <aside class="hidden lg:col-span-3 lg:block">
        <div class="sticky top-24">
          <woot-wizard
            :items="items"
            show-step-index
            step-label-key="INBOX_MGMT.CREATE_FLOW.STEP_LABEL"
          />
        </div>
      </aside>
      <div class="min-w-0 lg:col-span-9">
        <router-view />
      </div>
    </div>
  </div>
</template>
