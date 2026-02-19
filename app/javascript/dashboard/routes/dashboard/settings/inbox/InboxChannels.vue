<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { useBranding } from 'shared/composables/useBranding';

import PageHeader from '../SettingsSubPageHeader.vue';

const { t } = useI18n();
const route = useRoute();
const { replaceInstallationName } = useBranding();

const globalConfig = useMapGetter('globalConfig/get');

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
    return t('INBOX_MGMT.ADD.AUTH.TITLE');
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
  <div class="mx-auto flex flex-col gap-6 mb-8 max-w-7xl w-full !px-6">
    <PageHeader class="block lg:hidden !mb-0" :header-title="pageTitle" />
    <div
      class="grid grid-cols-1 lg:grid-cols-8 lg:divide-x lg:divide-n-weak rounded-xl border border-n-weak min-h-[52rem]"
    >
      <woot-wizard
        class="hidden lg:block col-span-2 h-fit py-8 px-6"
        :global-config="globalConfig"
        :items="items"
      />
      <div class="col-span-6 overflow-hidden">
        <router-view />
      </div>
    </div>
  </div>
</template>
