<script setup>
import { ref, computed, onMounted } from 'vue';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';

import Integration from './Integration.vue';
import Spinner from 'shared/components/Spinner.vue';

const store = useStore();

const integrationLoaded = ref(false);

const integration = useFunctionGetter('integrations/getIntegration', 'github');

const uiFlags = useMapGetter('integrations/getUIFlags');

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return integration.value.action;
});

const initializeGithubIntegration = async () => {
  await store.dispatch('integrations/get', 'github');
  integrationLoaded.value = true;
};

onMounted(() => {
  initializeGithubIntegration();
});
</script>

<template>
  <div class="flex-grow flex-shrink max-w-6xl p-4 mx-auto overflow-auto">
    <div v-if="integrationLoaded && !uiFlags.isCreatingGithub">
      <Integration
        :integration-id="integration.id"
        :integration-logo="integration.logo"
        :integration-name="integration.name"
        :integration-description="integration.description"
        :integration-enabled="integration.enabled"
        :integration-action="integrationAction"
        :delete-confirmation-text="{
          title: $t('INTEGRATION_SETTINGS.GITHUB.DELETE.TITLE'),
          message: $t('INTEGRATION_SETTINGS.GITHUB.DELETE.MESSAGE'),
        }"
      />
    </div>
    <div v-else class="flex items-center justify-center flex-1">
      <Spinner size="" color-scheme="primary" />
    </div>
  </div>
</template>
