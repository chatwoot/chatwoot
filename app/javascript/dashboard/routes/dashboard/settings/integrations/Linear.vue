<script setup>
import { ref, computed, onMounted } from 'vue';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';

import Integration from './Integration.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const store = useStore();

const integrationLoaded = ref(false);

const integration = useFunctionGetter('integrations/getIntegration', 'linear');

const uiFlags = useMapGetter('integrations/getUIFlags');

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return integration.value.action;
});

const initializeLinearIntegration = async () => {
  await store.dispatch('integrations/get', 'linear');
  integrationLoaded.value = true;
};

onMounted(() => {
  initializeLinearIntegration();
});
</script>

<template>
  <SettingsLayout :is-loading="!integrationLoaded || uiFlags.isCreatingLinear">
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.LINEAR.HEADER')"
        description=""
        feature-name="linear_integration"
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
      />
    </template>
    <template #body>
      <Integration
        :integration-id="integration.id"
        :integration-logo="integration.logo"
        :integration-name="integration.name"
        :integration-description="integration.description"
        :integration-enabled="integration.enabled"
        :integration-action="integrationAction"
        :delete-confirmation-text="{
          title: $t('INTEGRATION_SETTINGS.LINEAR.DELETE.TITLE'),
          message: $t('INTEGRATION_SETTINGS.LINEAR.DELETE.MESSAGE'),
        }"
      />
    </template>
  </SettingsLayout>
</template>
