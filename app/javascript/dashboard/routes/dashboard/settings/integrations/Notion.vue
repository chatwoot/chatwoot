<script setup>
import { ref, computed, onMounted } from 'vue';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import ButtonNext from 'next/button/Button.vue';
import notionClient from 'dashboard/api/notion_auth.js';

import Integration from './Integration.vue';
import Spinner from 'shared/components/Spinner.vue';

const { t } = useI18n();
const store = useStore();
const integrationLoaded = ref(false);

const integration = useFunctionGetter('integrations/getIntegration', 'notion');

const uiFlags = useMapGetter('integrations/getUIFlags');

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }

  return '';
});

const authorize = async () => {
  const response = await notionClient.generateAuthorization();
  const {
    data: { url },
  } = response;

  window.location.href = url;
};

const initializeNotionIntegration = async () => {
  await store.dispatch('integrations/get', 'notion');
  integrationLoaded.value = true;
};

onMounted(() => {
  initializeNotionIntegration();
});
</script>

<template>
  <div class="flex-grow flex-shrink p-4 overflow-auto mx-auto">
    <div v-if="integrationLoaded && !uiFlags.isCreatingNotion">
      <Integration
        :integration-id="integration.id"
        :integration-logo="integration.logo"
        :integration-name="integration.name"
        :integration-description="integration.description"
        :integration-enabled="integration.enabled"
        :integration-action="integrationAction"
        :delete-confirmation-text="{
          title: t('INTEGRATION_SETTINGS.NOTION.DELETE.TITLE'),
          message: t('INTEGRATION_SETTINGS.NOTION.DELETE.MESSAGE'),
        }"
      >
        <template #action>
          <ButtonNext
            faded
            blue
            :label="t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT')"
            @click="authorize"
          />
        </template>
      </Integration>
    </div>
    <div v-else class="flex items-center justify-center flex-1">
      <Spinner size="" color-scheme="primary" />
    </div>
  </div>
</template>
